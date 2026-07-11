import 'dart:io';

import 'package:flutter/services.dart';
import 'package:syncy/constants/app_constants.dart';

/// Discovers videos through the platform's indexed media database when
/// possible. This avoids recursively reading every file on every app launch.
class MediaDiscoveryService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.syncy/media',
  );

  Future<List<String>> discoverVideoPaths(String rootPath) async {
    if (Platform.isAndroid) {
      try {
        final paths = await _channel.invokeListMethod<String>('getVideoPaths', {
          'extensions': videoExtensions,
        });
        if (paths != null) {
          return _normalize(paths);
        }
      } on PlatformException {
        // Older/unusual Android devices can reject MediaStore queries. The
        // filesystem fallback preserves discovery in that case.
      } on MissingPluginException {
        // Allows tests and non-standard Flutter embeddings to use fallback.
      }
    }

    return _scanFileSystem(rootPath);
  }

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

  Future<List<String>> _scanFileSystem(String rootPath) async {
    if (rootPath.isEmpty) return const [];

    final root = Directory(rootPath);
    if (!await root.exists()) return const [];

    final supported = videoExtensions.toSet();
    final paths = <String>[];
    final pendingDirectories = <Directory>[root];

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
        // systems; skipping one should not abort the complete scan.
      }
    }

    return paths;
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
    ].any(normalized.contains);
  }
}
