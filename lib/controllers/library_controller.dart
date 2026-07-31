import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar_community/isar.dart';
import 'package:syncy/models/media.dart';
import 'package:syncy/services/media_discovery_service.dart';
import 'package:syncy/services/media_reconciliation_service.dart';
import 'package:syncy/services/thumbnail_service.dart';
import 'package:syncy/services/subtitle_discovery_service.dart';
import 'package:syncy/utils/native_pickers.dart';

/// A directory inside an indexed root, derived from the paths of the media
/// found beneath it.
class FolderNode {
  FolderNode({required this.path, required this.name, required this.depth});

  final String path;
  final String name;

  /// Nesting level below the root, used purely for indentation.
  final int depth;

  /// Videos sitting directly in this directory, excluding subdirectories.
  int directCount = 0;

  /// Videos anywhere beneath this directory, including subdirectories.
  int totalCount = 0;
}

/// Derives the subdirectory tree beneath [rootPath] from the paths of the
/// media indexed under it, ordered so a parent always precedes its children.
///
/// Storing only roots keeps the Isar schema untouched, and deriving the tree
/// from the media itself means it can never drift out of step with what is
/// actually indexed. Callers must pass only paths that live under [rootPath].
List<FolderNode> buildFolderTree(String rootPath, Iterable<String> mediaPaths) {
  // Paths are split on their original casing, never a normalized form —
  // normalizing lowercases, and a folder called "Movies" must not be listed
  // as "movies".
  final unifiedRoot = rootPath.replaceAll('\\', '/');
  final rootLength = unifiedRoot.endsWith('/')
      ? unifiedRoot.length - 1
      : unifiedRoot.length;
  final prefix = unifiedRoot.substring(0, rootLength);
  final nodes = <String, FolderNode>{};

  for (final mediaPath in mediaPaths) {
    final relative = mediaPath
        .replaceAll('\\', '/')
        .substring(rootLength)
        .replaceFirst(RegExp(r'^/'), '');
    final segments = relative.split('/');
    if (segments.length < 2) continue; // Sits directly in the root.

    var currentPath = prefix;
    for (var depth = 0; depth < segments.length - 1; depth++) {
      currentPath = '$currentPath/${segments[depth]}';
      final node = nodes.putIfAbsent(
        currentPath,
        () =>
            FolderNode(path: currentPath, name: segments[depth], depth: depth),
      );
      node.totalCount++;
      if (depth == segments.length - 2) node.directCount++;
    }
  }

  return nodes.values.toList()
    ..sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
}

/// Owns the desktop media library: the set of folders the user has chosen to
/// index, and which slice of them the grid is currently showing.
///
/// Desktop deliberately does not scan the machine. A PC has no equivalent of a
/// phone's camera roll, so the library starts empty and only ever contains
/// what the user explicitly adds.
class LibraryController extends GetxController {
  final isar = Get.find<Isar>();
  final thumbnailService = Get.find<ThumbnailService>();
  final MediaDiscoveryService _discovery = MediaDiscoveryService();

  /// Root folders the user has added, persisted across launches.
  final roots = <Folder>[].obs;

  /// Media belonging to [selectedRoot], filtered to [selectedSubPath].
  final visibleMedia = <Media>[].obs;

  final selectedRoot = Rxn<Folder>();
  final selectedSubPath = RxnString();
  final folderTree = <FolderNode>[].obs;

  final isScanning = false.obs;
  final scanStatus = ''.obs;
  final selectedAccentValue = const Color(0xFF7137E8).toARGB32().obs;

  bool _scanInProgress = false;

  @override
  void onInit() {
    super.onInit();
    _loadRoots();
    _setupThumbnailCallbacks();
  }

  void _loadRoots() {
    final unstamped = isar.medias
        .where()
        .findAllSync()
        .where((item) => item.addedAt == null)
        .toList();
    if (unstamped.isNotEmpty) {
      final now = DateTime.now();
      isar.writeTxnSync(() {
        for (final item in unstamped) {
          item.addedAt = now;
        }
        isar.medias.putAllSync(unstamped);
      });
    }
    roots.value = isar.folders.where().findAllSync();
    if (roots.isNotEmpty) {
      selectRoot(roots.first);
    }
  }

  void _setupThumbnailCallbacks() {
    thumbnailService.onThumbnailCompleted((media) {
      final index = visibleMedia.indexWhere((m) => m.path == media.path);
      if (index != -1) {
        visibleMedia[index] = media;
        visibleMedia.refresh();
      }
    });

    thumbnailService.onThumbnailFailed((videoPath, error) {
      // A missing preview must not interrupt browsing or playback.
    });
  }

  /// Prompts for a directory and indexes the videos inside it.
  Future<void> addFolder() async {
    final picked = await pickDirectory(
      title: 'Choose a folder to add to your library',
    );
    if (picked == null || picked.isEmpty) return;

    final normalized = _normalizePath(picked);
    final alreadyIndexed = roots.any(
      (folder) => _normalizePath(folder.path) == normalized,
    );
    if (alreadyIndexed) {
      Get.snackbar(
        'Already added',
        'That folder is already in your library.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final folder = Folder()
      ..path = picked
      ..name = _directoryName(picked);
    isar.writeTxnSync(() => isar.folders.putSync(folder));
    roots.add(folder);
    selectRoot(folder);

    await rescanFolder(folder);
  }

  /// Re-walks [folder] and records any videos not already known.
  Future<void> rescanFolder(Folder folder) async {
    if (_scanInProgress) return;
    _scanInProgress = true;
    isScanning.value = true;
    scanStatus.value = 'Scanning ${folder.name}…';

    try {
      final discovery = await _discovery.scanDirectoryWithResult(folder.path);
      final existingUnderRoot = _mediaUnder(folder.path);
      final diff = calculateMediaPathDiff(
        knownPaths: existingUnderRoot.map((item) => item.path),
        discoveredPaths: discovery.paths,
        normalizePath: _normalizePath,
      );
      final newPaths = diff.addedPaths;
      final removedPaths = discovery.isComplete
          ? diff.removedPaths.map(_normalizePath).toSet()
          : const <String>{};
      final removedMedia = existingUnderRoot
          .where((item) => removedPaths.contains(_normalizePath(item.path)))
          .toList(growable: false);

      if (newPaths.isNotEmpty || removedMedia.isNotEmpty) {
        scanStatus.value = newPaths.length == 1
            ? 'Adding 1 video…'
            : 'Updating ${folder.name}…';

        Set<String> videosWithSubtitles = const {};
        try {
          videosWithSubtitles = await findVideoPathsWithMatchingSubtitles(
            newPaths,
          );
        } catch (error, stackTrace) {
          debugPrint('Subtitle discovery skipped: $error\n$stackTrace');
        }

        final records = newPaths
            .map(
              (path) => Media()
                ..path = path
                ..name = _fileName(path)
                ..thumbnailPath = ''
                ..addedAt = DateTime.now()
                ..hasSubtitles = videosWithSubtitles.contains(path),
            )
            .toList(growable: false);

        thumbnailService.cancelRequestsForPaths(
          removedMedia.map((item) => item.path).toSet(),
        );

        // One atomic transaction for the complete set diff.
        await isar.writeTxn(() async {
          if (removedMedia.isNotEmpty) {
            await isar.medias.deleteAll(
              removedMedia.map((item) => item.id).toList(growable: false),
            );
          }
          if (records.isNotEmpty) await isar.medias.putAll(records);
        });
        await thumbnailService.deleteArtifactsForMedia(removedMedia);
      }

      _refreshVisibleMedia();

      if (newPaths.isNotEmpty) {
        await thumbnailService.requestMultipleThumbnails(newPaths);
      }
      await thumbnailService.generateMissingThumbnails();

      scanStatus.value = _scanSummary(
        addedCount: newPaths.length,
        removedCount: removedMedia.length,
      );
    } catch (error) {
      scanStatus.value = 'Couldn’t finish scanning';
      Get.snackbar(
        'Scan failed',
        'Some of ${folder.name} could not be read. Anything already indexed is still available.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isScanning.value = false;
      _scanInProgress = false;
    }
  }

  Future<void> rescanAll() async {
    for (final folder in List<Folder>.from(roots)) {
      await rescanFolder(folder);
    }
  }

  /// Removes a root and every media record beneath it, along with the
  /// thumbnails those records owned.
  Future<void> removeFolder(Folder folder) async {
    final owned = _mediaUnder(folder.path);
    thumbnailService.cancelRequestsForPaths(
      owned.map((item) => item.path).toSet(),
    );

    isar.writeTxnSync(() {
      isar.medias.deleteAllSync(owned.map((m) => m.id).toList());
      isar.folders.deleteSync(folder.id);
    });
    await thumbnailService.deleteArtifactsForMedia(owned);

    roots.removeWhere((item) => item.id == folder.id);
    if (selectedRoot.value?.id == folder.id) {
      selectedRoot.value = roots.isNotEmpty ? roots.first : null;
      selectedSubPath.value = null;
    }
    _refreshVisibleMedia();
  }

  void selectRoot(Folder? folder) {
    selectedRoot.value = folder;
    selectedSubPath.value = null;
    _refreshVisibleMedia();
  }

  /// Narrows the grid to a subdirectory. Passing null shows the whole root.
  void selectSubPath(String? path) {
    selectedSubPath.value = path;
    _refreshVisibleMedia();
  }

  void selectMediaAccent(Media item) {
    selectedAccentValue.value = item.dominantColorValue == 0
        ? const Color(0xFF7137E8).toARGB32()
        : item.dominantColorValue;
  }

  void _refreshVisibleMedia() {
    final root = selectedRoot.value;
    if (root == null) {
      visibleMedia.clear();
      folderTree.clear();
      return;
    }

    final underRoot = _mediaUnder(root.path);
    _rebuildFolderTree(root, underRoot);

    final subPath = selectedSubPath.value;
    visibleMedia.value = subPath == null
        ? underRoot
        : underRoot
              .where(
                (media) => _normalizePath(
                  media.path,
                ).startsWith('${_normalizePath(subPath)}/'),
              )
              .toList();
  }

  void _rebuildFolderTree(Folder root, List<Media> mediaUnderRoot) {
    folderTree.value = buildFolderTree(
      root.path,
      mediaUnderRoot.map((media) => media.path),
    );
  }

  List<Media> _mediaUnder(String folderPath) {
    final prefix = '${_normalizePath(folderPath)}/';
    return isar.medias
        .where()
        .findAllSync()
        .where((media) => _normalizePath(media.path).startsWith(prefix))
        .toList();
  }

  /// Lower-cased, forward-slashed, trailing-separator-free form of a path.
  ///
  /// Windows paths mix separators and are case-insensitive, so raw string
  /// comparison would miss matches that are actually the same directory.
  String _normalizePath(String path) {
    final unified = path.replaceAll('\\', '/').toLowerCase();
    return unified.endsWith('/')
        ? unified.substring(0, unified.length - 1)
        : unified;
  }

  String _fileName(String path) => path.replaceAll('\\', '/').split('/').last;

  String _scanSummary({required int addedCount, required int removedCount}) {
    if (addedCount == 0 && removedCount == 0) return 'Up to date';
    if (addedCount > 0 && removedCount > 0) {
      return '$addedCount added · $removedCount removed';
    }
    if (addedCount > 0) {
      return addedCount == 1 ? '1 video added' : '$addedCount videos added';
    }
    return removedCount == 1
        ? '1 deleted video removed'
        : '$removedCount deleted videos removed';
  }

  String _directoryName(String path) {
    final segments = path
        .replaceAll('\\', '/')
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .toList();
    // A drive root ("D:/") has no name segment of its own.
    return segments.isEmpty ? path : segments.last;
  }
}
