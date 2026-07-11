import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:isar_community/isar.dart';
import 'package:syncy/models/media.dart';
import 'package:syncy/services/media_discovery_service.dart';
import 'package:syncy/services/thumbnail_service.dart';
import 'package:syncy/utils/files.dart';
import 'package:syncy/utils/storage_helper.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  final media = <Media>[].obs;
  final isLoading = true.obs;
  final isSyncing = true.obs;
  final syncStatusMessage = 'Checking for new media…'.obs;
  final newMediaCount = 0.obs;
  final currentDirectory = ''.obs;
  final hasPermission = false.obs;
  final isar = Get.find<Isar>();
  final thumbnailService = Get.find<ThumbnailService>();
  final MediaDiscoveryService _mediaDiscovery = MediaDiscoveryService();

  bool _scanInProgress = false;

  final activeIndex = 1.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _loadCachedMedia();
    checkPermissions();
    _setupThumbnailCallbacks();
  }

  void _loadCachedMedia() {
    media.value = isar.medias.where().findAllSync();
    isLoading.value = media.isEmpty;
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
    final hasManagePermission =
        await StorageHelper.checkManageExternalStoragePermission();

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

    _scanInProgress = true;
    final startedAt = DateTime.now();
    isLoading.value = media.isEmpty;
    isSyncing.value = true;
    newMediaCount.value = 0;
    syncStatusMessage.value = 'Checking for new media…';

    try {
      final localStoragePath = await localStorageDir();
      currentDirectory.value = localStoragePath;

      if (localStoragePath.isEmpty) {
        throw const FileSystemException('Media storage is unavailable');
      }

      final mediaFiles = await _mediaDiscovery.discoverVideoPaths(
        localStoragePath,
      );
      final existingPaths = isar.medias
          .where()
          .findAllSync()
          .map((item) => item.path)
          .toSet();
      final newVideoPaths = mediaFiles
          .where((path) => !existingPaths.contains(path))
          .toList(growable: false);

      newMediaCount.value = newVideoPaths.length;
      if (newVideoPaths.isNotEmpty) {
        syncStatusMessage.value = newVideoPaths.length == 1
            ? 'Adding 1 new video…'
            : 'Adding ${newVideoPaths.length} new videos…';

        final newRecords = newVideoPaths
            .map((path) {
              return Media()
                ..path = path
                ..name = _fileName(path)
                ..thumbnailPath = '';
            })
            .toList(growable: false);

        // A single transaction is dramatically faster than opening a database
        // transaction for every discovered file.
        isar.writeTxnSync(() => isar.medias.putAllSync(newRecords));
        media.value = isar.medias.where().findAllSync();
      }

      if (newVideoPaths.isNotEmpty) {
        await thumbnailService.requestMultipleThumbnails(newVideoPaths);
      }

      await thumbnailService.generateMissingThumbnails();
      syncStatusMessage.value = newVideoPaths.isEmpty
          ? 'Media is up to date'
          : newVideoPaths.length == 1
          ? '1 new video added'
          : '${newVideoPaths.length} new videos added';
    } catch (e) {
      syncStatusMessage.value = 'Couldn’t finish media sync';
      Get.snackbar(
        'Media sync paused',
        'Your saved library is still available. Pull to refresh and try again.',
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

  Map<String, int> getThumbnailStats() {
    return thumbnailService.getStats();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
