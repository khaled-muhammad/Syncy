import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class StorageHelper {
  static Future<bool> checkStoragePermission() async {
    var status = await Permission.storage.status;
    await Permission.photos.request();
    await Permission.videos.request();
    await Permission.mediaLibrary.request();
    await Permission.audio.request();
    if (status.isGranted) {
      return true;
    } else {
      var result = await Permission.storage.request();
      return result.isGranted;
    }

  }

  static Future<bool> checkManageExternalStoragePermission() async {
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
