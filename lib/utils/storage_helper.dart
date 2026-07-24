import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class StorageHelper {
  static Future<bool> checkStoragePermission() async {
    if (Platform.isAndroid) {
      final videoPermission = await Permission.videos.request();
      if (videoPermission.isGranted || videoPermission.isLimited) return true;

      // Android 12 and older expose media through the legacy storage
      // permission instead of READ_MEDIA_VIDEO.
      final storagePermission = await Permission.storage.request();
      return storagePermission.isGranted;
    }

    if (Platform.isIOS) {
      final mediaPermission = await Permission.mediaLibrary.request();
      return mediaPermission.isGranted || mediaPermission.isLimited;
    }

    return true;
  }

  static Future<bool> checkManageExternalStoragePermission() async {
    // MANAGE_EXTERNAL_STORAGE is an Android permission. Requesting it anywhere
    // else resolves to denied and would gate the whole library behind a
    // permission prompt the user can never satisfy.
    if (!Platform.isAndroid) return true;

    var status = await Permission.manageExternalStorage.status;
    if (status.isGranted) {
      return true;
    } else {
      var result = await Permission.manageExternalStorage.request();
      return result.isGranted;
    }
  }

  static Future<String> getAppDocumentsPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<String> getExternalStoragePath() async {
    if (Platform.isAndroid) {
      final directory = await getExternalStorageDirectory();
      return directory?.path ?? '';
    } else if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    }
    return '';
  }

  static Future<List<Directory>?> getExternalStorageDirectories() async {
    if (Platform.isAndroid) {
      return await getExternalCacheDirectories();
    }
    return null;
  }

  static Future<bool> createDirectory(String path) async {
    try {
      final directory = Directory(path);
      if (!(await directory.exists())) {
        await directory.create(recursive: true);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> fileExists(String path) async {
    try {
      final file = File(path);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  static Future<String> readFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsString();
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  static Future<bool> writeFile(String path, String content) async {
    try {
      final file = File(path);
      await file.writeAsString(content);
      return true;
    } catch (e) {
      return false;
    }
  }
}
