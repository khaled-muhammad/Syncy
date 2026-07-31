import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar_community/isar.dart';
import 'package:flutter_video_info/flutter_video_info.dart';
import 'package:syncy/models/media.dart';
import 'package:syncy/services/media_discovery_service.dart';
import 'package:syncy/services/media_reconciliation_service.dart';
import 'package:syncy/services/thumbnail_service.dart';
import 'package:syncy/services/subtitle_discovery_service.dart';
import 'package:syncy/utils/files.dart';
import 'package:syncy/utils/platform_utils.dart';
import 'package:syncy/utils/storage_helper.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  final media = <Media>[].obs;
  final isLoading = true.obs;
  final isSyncing = true.obs;
  final syncStatusMessage = 'Checking for new media…'.obs;
  final syncErrorMessage = ''.obs;
  final newMediaCount = 0.obs;
  final currentDirectory = ''.obs;
  final hasPermission = false.obs;
  final selectedAccentValue = const Color(0xFF7137E8).toARGB32().obs;
  final isar = Get.find<Isar>();
  final thumbnailService = Get.find<ThumbnailService>();
  final MediaDiscoveryService _mediaDiscovery = MediaDiscoveryService();

  bool _scanInProgress = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _setupThumbnailCallbacks();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await _loadCachedMedia();
    await checkPermissions();
  }

  Future<void> _loadCachedMedia() async {
    media.value = await isar.medias.where().findAll();
    final unstamped = media.where((item) => item.addedAt == null).toList();
    if (unstamped.isNotEmpty) {
      final now = DateTime.now();
      await isar.writeTxn(() async {
        for (final item in unstamped) {
          item.addedAt = now;
        }
        await isar.medias.putAll(unstamped);
      });
    }
    isLoading.value = media.isEmpty;
  }

  void selectMediaAccent(Media item) {
    final value = item.dominantColorValue;
    selectedAccentValue.value = value == 0
        ? const Color(0xFF7137E8).toARGB32()
        : value;
  }

  void _setupThumbnailCallbacks() {
    thumbnailService.onThumbnailCompleted((media) {
      final index = this.media.indexWhere((m) => m.path == media.path);
      if (index != -1) {
        this.media[index] = media;
        this.media.refresh();
      }
    });

    thumbnailService.onThumbnailFailed((videoPath, error) {
      // A missing preview must not interrupt media discovery or playback.
    });
  }

  Future<void> checkPermissions() async {
    final hasStoragePermission = await StorageHelper.checkStoragePermission();
    final hasManagePermission = hasStoragePermission
        ? false
        : await StorageHelper.checkManageExternalStoragePermission();

    hasPermission.value = hasStoragePermission || hasManagePermission;

    if (hasPermission.value) {
      await loadMediaFiles();
    } else {
      isLoading.value = false;
      isSyncing.value = false;
      Get.snackbar(
        'Permission Required',
        'Storage permission is required to access media files',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> loadMediaFiles() async {
    if (_scanInProgress) return;

    var syncStage = 'starting media discovery';
    _scanInProgress = true;
    final startedAt = DateTime.now();
    isLoading.value = media.isEmpty;
    isSyncing.value = true;
    syncErrorMessage.value = '';
    newMediaCount.value = 0;
    syncStatusMessage.value = 'Checking for new media…';

    try {
      syncStage = 'opening device storage';
      final localStoragePath = await localStorageDir();
      currentDirectory.value = localStoragePath;

      if (localStoragePath.isEmpty) {
        throw const FileSystemException('Media storage is unavailable');
      }

      syncStage = 'reading Android media';
      final discovery = await _mediaDiscovery.discoverVideoPathsWithResult(
        localStoragePath,
      );
      syncStage = 'checking the saved library';
      final existingMedia = await isar.medias.where().findAll();
      final diff = calculateMediaPathDiff(
        knownPaths: existingMedia.map((item) => item.path),
        discoveredPaths: discovery.paths,
      );
      final canRemoveMissing =
          discovery.isComplete &&
          await StorageHelper.canReconcileDeletedMedia();
      final removedPaths = canRemoveMissing
          ? diff.removedPaths.toSet()
          : const <String>{};
      final removedMedia = existingMedia
          .where((item) => removedPaths.contains(item.path))
          .toList(growable: false);
      final newVideoPaths = diff.addedPaths;

      newMediaCount.value = newVideoPaths.length;
      if (newVideoPaths.isNotEmpty || removedMedia.isNotEmpty) {
        syncStatusMessage.value = newVideoPaths.length == 1
            ? 'Adding 1 new video…'
            : 'Updating your media library…';

        final newRecords = newVideoPaths
            .map((path) {
              return Media()
                ..path = path
                ..name = _fileName(path)
                ..thumbnailPath = ''
                ..addedAt = DateTime.now()
                ..hasSubtitles = false;
            })
            .toList(growable: false);

        // Cancel first so a thumbnail completing during this transaction can
        // never recreate a record that discovery proved was deleted.
        thumbnailService.cancelRequestsForPaths(removedPaths);

        // One transaction keeps additions and deletions atomic and avoids a
        // per-file database round trip.
        syncStage = 'reconciling the media library';
        await isar.writeTxn(() async {
          if (removedMedia.isNotEmpty) {
            await isar.medias.deleteAll(
              removedMedia.map((item) => item.id).toList(growable: false),
            );
          }
          if (newRecords.isNotEmpty) await isar.medias.putAll(newRecords);
        });
        media.value = await isar.medias.where().findAll();
        await thumbnailService.deleteArtifactsForMedia(removedMedia);
        if (newVideoPaths.isNotEmpty) {
          unawaited(_enrichSubtitleBadges(newVideoPaths));
        }
      }

      // Thumbnail extraction can take minutes on a library with thousands of
      // videos. Queue it in the background so discovery never keeps the UI in
      // a blocking syncing state.
      unawaited(_queueThumbnails(newVideoPaths));
      if (!isDesktop) unawaited(_enrichVideoMetadata());
      syncStatusMessage.value = _syncSummary(
        addedCount: newVideoPaths.length,
        removedCount: removedMedia.length,
      );
    } catch (error, stackTrace) {
      debugPrint('Media sync failed while $syncStage: $error\n$stackTrace');
      syncStatusMessage.value = 'Couldn’t finish $syncStage';
      syncErrorMessage.value =
          'Sync stopped while $syncStage. Your media was not removed.';
      Get.snackbar(
        'Media sync paused',
        'Sync stopped while $syncStage. Pull to refresh and try again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      // Keep very fast MediaStore checks visible long enough to be understood,
      // without delaying access to the cached library.
      final elapsed = DateTime.now().difference(startedAt);
      const minimumVisibleTime = Duration(milliseconds: 700);
      if (elapsed < minimumVisibleTime) {
        await Future<void>.delayed(minimumVisibleTime - elapsed);
      }
      isLoading.value = false;
      isSyncing.value = false;
      _scanInProgress = false;
    }
  }

  String _fileName(String path) {
    return path.replaceAll('\\', '/').split('/').last;
  }

  String _syncSummary({required int addedCount, required int removedCount}) {
    if (addedCount == 0 && removedCount == 0) return 'Media is up to date';
    if (addedCount > 0 && removedCount > 0) {
      return '$addedCount added · $removedCount removed';
    }
    if (addedCount > 0) {
      return addedCount == 1
          ? '1 new video added'
          : '$addedCount new videos added';
    }
    return removedCount == 1
        ? '1 deleted video removed'
        : '$removedCount deleted videos removed';
  }

  Future<void> _queueThumbnails(List<String> newVideoPaths) async {
    if (newVideoPaths.isNotEmpty) {
      await thumbnailService.requestMultipleThumbnails(newVideoPaths);
    }
    await thumbnailService.generateMissingThumbnails();
  }

  Future<void> _enrichSubtitleBadges(List<String> videoPaths) async {
    try {
      final matches = await findVideoPathsWithMatchingSubtitles(videoPaths);
      if (matches.isEmpty) return;

      final candidates = (await isar.medias.where().findAll())
          .where((item) => matches.contains(item.path))
          .toList(growable: false);
      var matchingRecords = <Media>[];
      await isar.writeTxn(() async {
        matchingRecords =
            (await isar.medias.getAll(
                  candidates.map((item) => item.id).toList(growable: false),
                ))
                .whereType<Media>()
                .where((item) => matches.contains(item.path))
                .toList();
        for (final item in matchingRecords) {
          item.hasSubtitles = true;
        }
        if (matchingRecords.isNotEmpty) {
          await isar.medias.putAll(matchingRecords);
        }
      });
      for (final item in matchingRecords) {
        final index = media.indexWhere((candidate) => candidate.id == item.id);
        if (index != -1) media[index] = item;
      }
      media.refresh();
    } catch (error, stackTrace) {
      // Subtitle badges are optional. Restricted Android directories or a
      // malformed sidecar must never prevent the videos from being saved.
      debugPrint('Subtitle discovery skipped: $error\n$stackTrace');
    }
  }

  Future<void> refreshMediaFiles() async {
    await loadMediaFiles();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && hasPermission.value) {
      loadMediaFiles();
    }
  }

  Future<void> generateThumbnails() async {
    await thumbnailService.generateMissingThumbnails();
  }

  Future<void> _enrichVideoMetadata() async {
    final pending = media.where((item) => item.durationMs <= 0).take(30);
    final info = FlutterVideoInfo();
    for (final item in pending) {
      try {
        final metadata = await info.getVideoInfo(item.path);
        final duration = metadata?.duration?.round() ?? 0;
        if (duration <= 0) continue;
        Media? updated;
        isar.writeTxnSync(() {
          final current = isar.medias.getSync(item.id);
          if (current == null || current.path != item.path) return;
          current.durationMs = duration;
          isar.medias.putSync(current);
          updated = current;
        });
        if (updated == null) continue;
        final index = media.indexWhere(
          (candidate) => candidate.path == updated!.path,
        );
        if (index != -1) {
          media[index] = updated!;
          media.refresh();
        }
      } catch (_) {
        // Some Android providers do not expose metadata; playback will fill it.
      }
    }
  }

  Map<String, int> getThumbnailStats() {
    return thumbnailService.getStats();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
