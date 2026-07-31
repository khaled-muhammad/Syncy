import 'dart:io';

import 'package:flutter/services.dart';
import 'package:syncy/constants/app_constants.dart';

class MediaDiscoveryResult {
  const MediaDiscoveryResult({required this.paths, required this.isComplete});

  final List<String> paths;

  /// Whether missing paths can safely be treated as deleted.
  final bool isComplete;
}

/// Discovers videos through the platform's indexed media database when
/// possible. This avoids recursively reading every file on every app launch.
class MediaDiscoveryService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.syncy/media',
  );

  Future<List<String>> discoverVideoPaths(String rootPath) async {
    return (await discoverVideoPathsWithResult(rootPath)).paths;
  }

  Future<MediaDiscoveryResult> discoverVideoPathsWithResult(
    String rootPath,
  ) async {
    if (Platform.isAndroid) {
      try {
        final paths = await _channel.invokeListMethod<String>('getVideoPaths', {
          'extensions': videoExtensions,
        });
        if (paths != null) {
          return MediaDiscoveryResult(
            paths: _normalize(paths),
            isComplete: true,
          );
        }
      } on PlatformException {
        // Older/unusual Android devices can reject MediaStore queries. The
        // filesystem fallback preserves discovery in that case.
      } on MissingPluginException {
        // Allows tests and non-standard Flutter embeddings to use fallback.
      }
    }

    return scanDirectoryWithResult(rootPath);
  }

  /// Recursively collects supported video files under [rootPath].
  ///
  /// Desktop calls this directly, once per folder the user has chosen to
  /// index, rather than going through [discoverVideoPaths] — there is no
  /// platform media database to consult and no single device-wide root worth
  /// scanning.
  Future<List<String>> scanDirectory(String rootPath) async {
    return (await scanDirectoryWithResult(rootPath)).paths;
  }

  Future<MediaDiscoveryResult> scanDirectoryWithResult(String rootPath) =>
      _scanFileSystem(rootPath);

  List<String> _normalize(Iterable<String> paths) {
    final supported = videoExtensions.toSet();
    final uniquePaths = <String>{};
    for (final path in paths) {
      if (path.isEmpty) continue;
      final extension = _extensionOf(path);
      if (supported.contains(extension)) uniquePaths.add(path);
    }
    return uniquePaths.toList(growable: false);
  }

  Future<MediaDiscoveryResult> _scanFileSystem(String rootPath) async {
    if (rootPath.isEmpty) {
      return const MediaDiscoveryResult(paths: [], isComplete: false);
    }

    final root = Directory(rootPath);
    if (!await root.exists()) {
      // A disconnected drive and a deleted root are indistinguishable here.
      // Preserve cached records until the root is available or removed.
      return const MediaDiscoveryResult(paths: [], isComplete: false);
    }

    final supported = videoExtensions.toSet();
    final paths = <String>[];
    final pendingDirectories = <Directory>[root];
    var isComplete = true;

    while (pendingDirectories.isNotEmpty) {
      final directory = pendingDirectories.removeLast();
      try {
        await for (final entity in directory.list(followLinks: false)) {
          if (entity is Directory) {
            if (!_shouldSkipDirectory(entity.path)) {
              pendingDirectories.add(entity);
            }
          } else if (entity is File &&
              supported.contains(_extensionOf(entity.path))) {
            paths.add(entity.path);
          }
        }
      } on FileSystemException {
        // Protected directories are expected on modern mobile operating
        // systems. Additions are safe, but deletions cannot be inferred from
        // a scan that could not inspect every directory.
        isComplete = false;
      }
    }

    return MediaDiscoveryResult(paths: paths, isComplete: isComplete);
  }

  String _extensionOf(String path) {
    final fileName = path.replaceAll('\\', '/').split('/').last;
    final dot = fileName.lastIndexOf('.');
    return dot == -1 ? '' : fileName.substring(dot + 1).toLowerCase();
  }

  bool _shouldSkipDirectory(String path) {
    final normalized = path.replaceAll('\\', '/').toLowerCase();
    return const [
      '/android/data',
      '/android/obb',
      '/.android',
      '/.thumbnails',
      '/.cache',
      '/.tmp',
      // Windows system locations. A user who points the picker at a whole
      // drive should not pay to walk these, and most are unreadable anyway.
      '/\$recycle.bin',
      '/system volume information',
      '/windows/',
      '/program files',
      '/programdata',
      '/appdata/local/temp',
      '/node_modules',
    ].any(normalized.contains);
  }
}
