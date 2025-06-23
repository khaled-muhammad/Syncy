import 'dart:io';
import 'package:flutter_video_info/flutter_video_info.dart';
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:syncy/constants/app_constants.dart';
import 'package:syncy/models/media.dart';

final videoInfo = FlutterVideoInfo();

Image imageFromPath(String filePath) {
  Uri myUri = Uri.parse(filePath);
  File file = File.fromUri(myUri);

  return Image.file(file);
}

Future<String> localStorageDir() async {
  if (Platform.isAndroid) {
    try {
      // Try to get the external storage directory
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        // On Android, we want to access the root of external storage
        // The path typically looks like: /storage/emulated/0/Android/data/com.example.app/files
        // We want to get to /storage/emulated/0/
        final String path = directory.path;
        final List<String> pathSegments = path.split('/');
        int index = pathSegments.indexOf('Android');
        if (index != -1) {
          return pathSegments.sublist(0, index).join('/');
        }
        return path;
      }
    } catch (e) {
      print('Error getting external storage directory: $e');
    }

    // Fallback to a common location on Android
    return '/storage/emulated/0';
  } else if (Platform.isIOS) {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
  return '';
}

Future<List<FileSystemEntity>> listTreeHomeStorage(String path) async {
  String wantedDir = "${await localStorageDir()}$path";

  List<FileSystemEntity> tree = Directory(wantedDir).listSync();

  return tree;
}

Future<Image> genVideoThumbnailFromPath(String path) async {
  return imageFromPath(
    (await VideoThumbnail.thumbnailFile(
          video: path,
          thumbnailPath: (await getTemporaryDirectory()).path,
          imageFormat: ImageFormat.JPEG,
          maxHeight:
              200, // specify the height of the thumbnail, let the width auto-scaled to keep the source aspect ratio
          quality: 80,
        ))
        as String,
  );
}

String getFileSystemEntityExtension(FileSystemEntity fse) {
  return getFileSystemEntityName(fse).split('.').last;
}

String getFileSystemEntityName(FileSystemEntity fse) {
  return fse.path.split('/').last;
}

List<FileSystemEntity> filterMedia(List<FileSystemEntity> dirTree) {
  return dirTree
      .where(
        (element) =>
            !element.path.startsWith('.') &&
            mediaExtensions.contains(getFileSystemEntityExtension(element)),
      )
      .toList();
}

MediaType getMediaType(FileSystemEntity fse) {
  String extension = getFileSystemEntityExtension(fse);

  if (imageExtensions.contains(extension)) {
    return MediaType.image;
  } else if (videoExtensions.contains(extension)) {
    return MediaType.video;
  } else {
    return MediaType.unknown;
  }
}

Future<Uint8List> compressImage(
  File file, {
  int width = 100,
  int height = 100,
  int quality = 90,
}) async {
  var result = await FlutterImageCompress.compressWithFile(
    file.absolute.path,
    minWidth: width,
    minHeight: height,
    quality: quality,
    rotate: 0,
  );

  return result!;
}

Future<String> compressImageV2(
  File file,
  String outputPath, {
  int width = 200,
  int height = 200,
  int quality = 80,
}) async {
  var result = await FlutterImageCompress.compressAndGetFile(
    file.absolute.path,
    outputPath,
    minWidth: width,
    minHeight: height,
    quality: quality,
    rotate: 0,
  );

  return result!.path;
}

Future<String> genVideoThumbnailFromPathV2(
  String path,
  String outputPath,
) async {
  return (await VideoThumbnail.thumbnailFile(
    video: path,
    thumbnailPath: outputPath,
    imageFormat: ImageFormat.JPEG,
    maxHeight:
        200, // specify the height of the thumbnail, let the width auto-scaled to keep the source aspect ratio
    quality: 100,
  )).path;
}

Future<List<FileSystemEntity>> getAllDirsUnderDir(Directory mainDir) async {
  List<FileSystemEntity> allDirs = [];
  List<FileSystemEntity> dirsToLoopIn = [];

  mainDir
      .listSync()
      .where(
        (element) => element.statSync().type == FileSystemEntityType.directory,
      )
      .where((element) => element.path.split('/').last != "Android")
      .toList()
      .forEach((dir) {
        allDirs.add(dir);
        dirsToLoopIn.add(dir);
      });

  while (dirsToLoopIn.isNotEmpty) {
    Directory(dirsToLoopIn.first.path)
        .listSync()
        .where(
          (element) =>
              element.statSync().type == FileSystemEntityType.directory,
        )
        .forEach((dir) {
          allDirs.add(dir);
          dirsToLoopIn.add(dir);
        });
    dirsToLoopIn.removeAt(0);
  }

  return allDirs;
}

Map<String, int> dirStatSync(String dirPath) {
  int fileNum = 0;
  int totalSize = 0;
  var dir = Directory(dirPath);
  try {
    if (dir.existsSync()) {
      dir.listSync(recursive: true, followLinks: false).forEach((
        FileSystemEntity entity,
      ) {
        if (entity is File) {
          fileNum++;
          totalSize += entity.lengthSync();
        }
      });
    }
  } catch (e) {
    if (kDebugMode) {
      print(e.toString());
    }
  }

  return {'fileNum': fileNum, 'size': totalSize};
}

/// Wait for a file to be fully written.
Future<void> waitForFileCompletion(
  File file, {
  Duration checkInterval = const Duration(milliseconds: 500),
  int maxRetries = 10,
}) async {
  try {
    int retries = 0;
    int previousSize = 0;

    while (retries < maxRetries) {
      final currentSize = await file.length();
      if (currentSize == previousSize) {
        // File writing is complete
        return;
      }

      await Future.delayed(checkInterval);
      previousSize = currentSize;
      retries++;
    }

    throw Exception('File writing did not complete in time: ${file.path}');
  } catch (e, traceback) {
    rethrow;
  }
}

/// Returns a [Size] object containing the width and height of the media.
/// Supports common image formats and video formats.
Future<Map<String, dynamic>> getMediaSize(File file) async {
  // Get file extension (e.g., jpg, mp4)
  final ext = file.path.split('.').last.toLowerCase();

  if (imageExtensions.contains(ext)) {
    final SizeResult image = ImageSizeGetter.getSizeResult(FileInput(file));
    return {'width': image.size.width, 'height': image.size.height};
  } else if (videoExtensions.contains(ext)) {
    final info = await videoInfo.getVideoInfo(file.path);
    return {
      'width': info?.width,
      'height': info?.height,
      'duration': info?.duration,
    };
  } else {
    throw UnsupportedError('Unsupported file format: .$ext');
  }
}

@pragma('vm:entry-point')
void genVideoThumbnailFromPathV2Worker(Map<String, dynamic> params) async {
  final String videoPath = params['videoPath'];
  final String outputPath = params['outputPath'];

  await VideoThumbnail.thumbnailFile(
    video: videoPath,
    thumbnailPath: outputPath,
    imageFormat: ImageFormat.JPEG,
    maxHeight: 200, // Specify height and let width auto-scale.
    quality: 100,
  );
}

@pragma('vm:entry-point')
void compressImageV2Worker(Map<String, dynamic> params) async {
  final String filePath = params['filePath'];
  final String outputPath = params['outputPath'];
  final int width = params['width'];
  final int height = params['height'];
  final int quality = params['quality'];

  await FlutterImageCompress.compressAndGetFile(
    filePath,
    outputPath,
    minWidth: width,
    minHeight: height,
    quality: quality,
    rotate: 0,
  );
}

Future<bool> isValidMediaFile(String path) {
  final extension = path.split('.').last.toLowerCase();
  // This will be implemented in HomeController
  return Future.value(true);
}

bool isImage(String path) {
  final extension = path.split('.').last.toLowerCase();
  return imageExtensions.contains(extension);
}

bool isVideo(String path) {
  final extension = path.split('.').last.toLowerCase();
  return videoExtensions.contains(extension);
}