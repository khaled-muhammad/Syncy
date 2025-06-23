import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:realm/realm.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:syncy/models/media.dart';
import 'package:syncy/utils/files.dart';

enum ThumbnailRequestStatus { pending, processing, completed, failed }

class ThumbnailRequest {
  final String id;
  final String videoPath;
  final String outputPath;
  final DateTime createdAt;
  ThumbnailRequestStatus status;
  String? errorMessage;

  ThumbnailRequest({
    required this.id,
    required this.videoPath,
    required this.outputPath,
    required this.createdAt,
    this.status = ThumbnailRequestStatus.pending,
    this.errorMessage,
  });
}

class ThumbnailService extends GetxService {
  static ThumbnailService get to => Get.find<ThumbnailService>();

  final Realm _realm = Get.find<Realm>();
  final RxList<ThumbnailRequest> _requestQueue = <ThumbnailRequest>[].obs;
  final RxBool _isProcessing = false.obs;
  final RxInt _processedCount = 0.obs;
  final RxInt _failedCount = 0.obs;

  final List<Function(Media)> _onThumbnailCompleted = [];
  final List<Function(String, String)> _onThumbnailFailed = [];

  Timer? _processingTimer;
  late String _thumbnailsDirectory;

  List<ThumbnailRequest> get requestQueue => _requestQueue.toList();
  bool get isProcessing => _isProcessing.value;
  int get processedCount => _processedCount.value;
  int get failedCount => _failedCount.value;
  int get pendingCount => _requestQueue
      .where((r) => r.status == ThumbnailRequestStatus.pending)
      .length;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeThumbnailsDirectory();
    _startProcessingQueue();
  }

  @override
  void onClose() {
    _processingTimer?.cancel();
    super.onClose();
  }

  Future<void> _initializeThumbnailsDirectory() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _thumbnailsDirectory = '${appDir.path}/thumbnails';

      final thumbnailDir = Directory(_thumbnailsDirectory);
      if (!await thumbnailDir.exists()) {
        await thumbnailDir.create(recursive: true);
        print('Created thumbnails directory: $_thumbnailsDirectory');
      }
    } catch (e) {
      print('Error initializing thumbnails directory: $e');
      rethrow;
    }
  }

  void onThumbnailCompleted(Function(Media) callback) {
    _onThumbnailCompleted.add(callback);
  }

  void onThumbnailFailed(Function(String, String) callback) {
    _onThumbnailFailed.add(callback);
  }

  Future<String?> requestThumbnail(String videoPath) async {
    try {
      final videoFile = File(videoPath);
      if (!await videoFile.exists()) {
        print('Video file does not exist: $videoPath');
        return null;
      }

      if (!isVideo(videoPath)) {
        print('File is not a video: $videoPath');
        return null;
      }

      final fileName = videoPath.split('/').last;
      final nameWithoutExtension = fileName.split('.').first;
      final thumbnailPath =
          '$_thumbnailsDirectory/${nameWithoutExtension}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final existingMedia = _realm
          .query<Media>("path == '$videoPath'")
          .firstOrNull;
      if (existingMedia != null && existingMedia.thumbnailPath.isNotEmpty) {
        final existingThumbnail = File(existingMedia.thumbnailPath);
        if (await existingThumbnail.exists()) {
          print('Thumbnail already exists for: $videoPath');
          return existingMedia.thumbnailPath;
        }
      }

      final request = ThumbnailRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        videoPath: videoPath,
        outputPath: thumbnailPath,
        createdAt: DateTime.now(),
      );

      _requestQueue.add(request);
      print('Added thumbnail request for: $videoPath');

      return thumbnailPath;
    } catch (e) {
      print('Error requesting thumbnail for $videoPath: $e');
      return null;
    }
  }

  Future<void> requestMultipleThumbnails(List<String> videoPaths) async {
    for (final videoPath in videoPaths) {
      await requestThumbnail(videoPath);
    }
  }

  Future<void> generateMissingThumbnails() async {
    try {
      final mediaWithoutThumbnails = _realm
          .query<Media>("thumbnailPath == ''")
          .toList();
      print(
        'Found ${mediaWithoutThumbnails.length} media files without thumbnails',
      );

      for (final media in mediaWithoutThumbnails) {
        if (isVideo(media.path)) {
          await requestThumbnail(media.path);
        }
      }
    } catch (e) {
      print('Error generating missing thumbnails: $e');
    }
  }

  void _startProcessingQueue() {
    _processingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isProcessing.value && _requestQueue.isNotEmpty) {
        _processNextRequest();
      }
    });
  }

  Future<void> _processNextRequest() async {
    if (_isProcessing.value || _requestQueue.isEmpty) return;

    final pendingRequests = _requestQueue
        .where((r) => r.status == ThumbnailRequestStatus.pending)
        .toList();
    if (pendingRequests.isEmpty) return;

    final request = pendingRequests.first;
    _isProcessing.value = true;
    request.status = ThumbnailRequestStatus.processing;

    try {
      print('Processing thumbnail request: ${request.id}');

      final thumbnailPath = await _generateThumbnailInIsolate(
        request.videoPath,
        request.outputPath,
      );

      if (thumbnailPath != null && await File(thumbnailPath).exists()) {
        await _updateMediaWithThumbnail(request.videoPath, thumbnailPath);

        request.status = ThumbnailRequestStatus.completed;
        _processedCount.value++;

        print('Thumbnail generated successfully: $thumbnailPath');

        final media = _realm
            .query<Media>("path == '${request.videoPath}'")
            .firstOrNull;
        if (media != null) {
          for (final callback in _onThumbnailCompleted) {
            callback(media);
          }
        }
      } else {
        throw Exception('Failed to generate thumbnail file');
      }
    } catch (e) {
      print('Error processing thumbnail request ${request.id}: $e');
      request.status = ThumbnailRequestStatus.failed;
      request.errorMessage = e.toString();
      _failedCount.value++;

      for (final callback in _onThumbnailFailed) {
        callback(request.videoPath, e.toString());
      }
    } finally {
      _isProcessing.value = false;

      Timer(const Duration(minutes: 5), () {
        _requestQueue.removeWhere(
          (r) =>
              r.status == ThumbnailRequestStatus.completed ||
              r.status == ThumbnailRequestStatus.failed,
        );
      });
    }
  }

  Future<String?> _generateThumbnailInIsolate(
    String videoPath,
    String outputPath,
  ) async {
    try {
      final result = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: outputPath,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200,
        quality: 85,
      );

      return result?.path;
    } catch (e) {
      print('Error generating thumbnail in isolate: $e');
      return null;
    }
  }

  Future<void> _updateMediaWithThumbnail(
    String videoPath,
    String thumbnailPath,
  ) async {
    try {
      _realm.write(() {
        final existingMedia = _realm
            .query<Media>("path == '$videoPath'")
            .firstOrNull;

        if (existingMedia != null) {
          existingMedia.thumbnailPath = thumbnailPath;
          print('Updated existing media with thumbnail: $videoPath');
        } else {
          final fileName = videoPath.split('/').last;
          final newMedia = Media(
            ObjectId(),
            videoPath,
            fileName,
            thumbnailPath,
          );
          _realm.add(newMedia);
          print('Created new media record with thumbnail: $videoPath');
        }
      });
    } catch (e) {
      print('Error updating media with thumbnail: $e');
      rethrow;
    }
  }

  String? getThumbnailPath(String videoPath) {
    try {
      final media = _realm.query<Media>("path == '$videoPath'").firstOrNull;
      if (media != null && media.thumbnailPath.isNotEmpty) {
        final thumbnailFile = File(media.thumbnailPath);
        if (thumbnailFile.existsSync()) {
          return media.thumbnailPath;
        }
      }
      return null;
    } catch (e) {
      print('Error getting thumbnail path for $videoPath: $e');
      return null;
    }
  }

  bool hasThumbnail(String videoPath) {
    return getThumbnailPath(videoPath) != null;
  }

  void clearQueue() {
    _requestQueue.removeWhere(
      (r) => r.status == ThumbnailRequestStatus.pending,
    );
    print('Cleared thumbnail request queue');
  }

  Map<String, int> getStats() {
    return {
      'pending': pendingCount,
      'processing': _requestQueue
          .where((r) => r.status == ThumbnailRequestStatus.processing)
          .length,
      'completed': _processedCount.value,
      'failed': _failedCount.value,
      'total': _requestQueue.length,
    };
  }

  Future<void> cleanupOrphanedThumbnails() async {
    try {
      final thumbnailDir = Directory(_thumbnailsDirectory);
      if (!await thumbnailDir.exists()) return;

      final thumbnailFiles = await thumbnailDir
          .list()
          .where((entity) => entity is File)
          .cast<File>()
          .toList();
      final referencedThumbnails = _realm
          .all<Media>()
          .map((m) => m.thumbnailPath)
          .where((path) => path.isNotEmpty)
          .toSet();

      int deletedCount = 0;
      for (final file in thumbnailFiles) {
        if (!referencedThumbnails.contains(file.path)) {
          try {
            await file.delete();
            deletedCount++;
          } catch (e) {
            print('Error deleting orphaned thumbnail ${file.path}: $e');
          }
        }
      }

      print('Cleaned up $deletedCount orphaned thumbnail files');
    } catch (e) {
      print('Error cleaning up orphaned thumbnails: $e');
    }
  }
}