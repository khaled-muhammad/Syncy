import 'dart:io';

import 'package:get/get.dart';
import 'package:realm/realm.dart';
import 'package:syncy/constants/app_constants.dart';
import 'package:syncy/models/media.dart';
import 'package:syncy/services/thumbnail_service.dart';
import 'package:syncy/utils/files.dart';
import 'package:syncy/utils/storage_helper.dart';

class HomeController extends GetxController {
  final media = <Media>[].obs;
  final isLoading = true.obs;
  final currentDirectory = ''.obs;
  final hasPermission = false.obs;
  final realm = Get.find<Realm>();
  final thumbnailService = Get.find<ThumbnailService>();

  final activeIndex = 1.obs;

  @override
  void onInit() {
    super.onInit();
    checkPermissions();
    _setupThumbnailCallbacks();
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
      print('Thumbnail generation failed for $videoPath: $error');
    });
  }

  Future<void> checkPermissions() async {
    final hasStoragePermission = await StorageHelper.checkStoragePermission();
    final hasManagePermission =
        await StorageHelper.checkManageExternalStoragePermission();

    hasPermission.value = hasStoragePermission || hasManagePermission;

    if (hasPermission.value) {
      loadMediaFiles();
    } else {
      Get.snackbar(
        'Permission Required',
        'Storage permission is required to access media files',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> loadMediaFiles() async {
    isLoading.value = true;
    media.clear();
    print("REALM");
    media.value = realm.all<Media>().toList();
    try {
      // final localStoragePath = await localStorageDir(); XXX
      final localStoragePath = "${await localStorageDir()}/testing_syncy";
      print('Local storage path: $localStoragePath');
      currentDirectory.value = localStoragePath;

      if (localStoragePath.isEmpty) {
        print('Local storage path is empty');
        isLoading.value = false;
        return;
      }

      final directory = Directory(localStoragePath);
      if (!await directory.exists()) {
        print('Directory does not exist: $localStoragePath');
        isLoading.value = false;
        return;
      }

      final List<String> mediaFiles = [];

      await _scanDirectory(directory, mediaFiles);

      final List<String> newVideoPaths = [];
      for (String path in mediaFiles) {
        final existingMedia = realm.query<Media>("path == '$path'").firstOrNull;
        if (existingMedia == null) {
          realm.write(() {
            final fileName = path.split('/').last;
            final newMedia = Media(
              ObjectId(),
              path,
              fileName,
              '',
            );
            realm.add(newMedia);
          });
          newVideoPaths.add(path);
          print("Created new media record for: $path");
        }
      }

      if (newVideoPaths.isNotEmpty) {
        print('Requesting thumbnails for ${newVideoPaths.length} new videos');
        await thumbnailService.requestMultipleThumbnails(newVideoPaths);
      }

      await thumbnailService.generateMissingThumbnails();

      media.value = realm.all<Media>().toList();
      print('Found ${media.length} media files');
    } catch (e) {
      print('Error loading media files: $e');
      Get.snackbar(
        'Error',
        'Failed to load media files: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _scanDirectory(
    Directory directory,
    List<String> mediaFiles,
  ) async {
    try {
      await for (final entity in directory.list()) {
        try {
          if (entity is Directory) {
            if (_shouldSkipDirectory(entity.path)) {
              print('Skipping protected directory: ${entity.path}');
              continue;
            }
            await _scanDirectory(entity, mediaFiles);
          } else if (entity is File) {
            final extension = entity.path.split('.').last.toLowerCase();
            if (videoExtensions.contains(extension)) {
              print('Found media file: ${entity.path}');
              mediaFiles.add(entity.path);
            }
          }
        } catch (e) {
          print('Skipping entity due to error: ${entity.path} - $e');
        }
      }
    } catch (e) {
      print(
        'Skipping directory due to permission error: ${directory.path} - $e',
      );
    }
  }

  bool _shouldSkipDirectory(String path) {
    final List<String> skipDirs = [
      'Android/data',
      'Android/obb',
      'Android/media',
      '.android',
      '.thumbnails',
      '.cache',
      '.tmp',
    ];

    return skipDirs.any((dir) => path.contains(dir));
  }

  Future<void> refreshMediaFiles() async {
    await loadMediaFiles();
  }

  Future<void> generateThumbnails() async {
    await thumbnailService.generateMissingThumbnails();
  }

  Map<String, int> getThumbnailStats() {
    return thumbnailService.getStats();
  }

  @override
  void onClose() {
    super.onClose();
  }
}
