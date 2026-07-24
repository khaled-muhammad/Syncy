import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:isar_community/isar.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:get_thumbnail_video/index.dart';
// Prefixed: media_kit also exports a `Media` type, which would collide with
// Syncy's own media model below.
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' show VideoController;
import 'package:syncy/models/media.dart';
import 'package:syncy/utils/files.dart';
import 'package:syncy/utils/platform_utils.dart';

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

  final Isar _isar = Get.find<Isar>();
  final RxList<ThumbnailRequest> _requestQueue = <ThumbnailRequest>[].obs;
  final RxBool _isProcessing = false.obs;
  final RxInt _processedCount = 0.obs;
  final RxInt _failedCount = 0.obs;

  final List<Function(Media)> _onThumbnailCompleted = [];
  final List<Function(String, String)> _onThumbnailFailed = [];

  Timer? _processingTimer;
  late String _thumbnailsDirectory;

  // Shared across every desktop thumbnail; see _generateThumbnailWithMediaKit
  // for why a single reused output is required rather than one per video.
  mk.Player? _thumbnailPlayer;
  // ignore: unused_field
  VideoController? _thumbnailController;

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
    _thumbnailController = null;
    unawaited(_thumbnailPlayer?.dispose());
    _thumbnailPlayer = null;
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
      final queuedRequest = _requestQueue.firstWhereOrNull(
        (request) =>
            request.videoPath == videoPath &&
            (request.status == ThumbnailRequestStatus.pending ||
                request.status == ThumbnailRequestStatus.processing),
      );
      if (queuedRequest != null) return queuedRequest.outputPath;

      final videoFile = File(videoPath);
      if (!await videoFile.exists()) {
        print('Video file does not exist: $videoPath');
        return null;
      }

      if (!isVideo(videoPath)) {
        print('File is not a video: $videoPath');
        return null;
      }

      // Windows paths use backslashes, so splitting on '/' alone would leave
      // the whole path as the "file name" and produce unusable thumbnails.
      final fileName = _fileNameOf(videoPath);
      final nameWithoutExtension = fileName.split('.').first;
      final thumbnailPath =
          '$_thumbnailsDirectory/${nameWithoutExtension}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final existingMedia = _isar.medias
          .filter()
          .pathEqualTo(videoPath)
          .findFirstSync();
      if (existingMedia != null &&
          existingMedia.thumbnailPath != null &&
          existingMedia.thumbnailPath!.isNotEmpty) {
        final existingThumbnail = File(existingMedia.thumbnailPath!);
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
      final mediaWithoutThumbnails = _isar.medias
          .filter()
          .thumbnailPathIsNull()
          .or()
          .thumbnailPathEqualTo('')
          .findAllSync();
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

        final media = _isar.medias
            .filter()
            .pathEqualTo(request.videoPath)
            .findFirstSync();
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
      // get_thumbnail_video has no desktop implementation, so desktop grabs a
      // frame through media_kit — the same engine that plays the file.
      if (isDesktop) return await _generateThumbnailWithMediaKit(
        videoPath,
        outputPath,
      );

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

  /// Decodes a single frame with a shared, headless media_kit player and
  /// writes it as a JPEG.
  ///
  /// The player and its video output are created once and reused for every
  /// thumbnail. Creating and disposing a [VideoController] per video crashes
  /// the ANGLE/Direct3D surface manager on Windows — the second texture
  /// creation faults and takes the whole app down. Reusing one long-lived
  /// output sidesteps that entirely. Callers must keep this serialized (the
  /// queue's `_isProcessing` guard does) since it drives a single player.
  Future<String?> _generateThumbnailWithMediaKit(
    String videoPath,
    String outputPath,
  ) async {
    final player = _thumbnailPlayer ??= _createThumbnailPlayer();
    try {
      // Arm the readiness signal before opening so the new file's first
      // duration emission is never missed. duration fires once the file is
      // loaded and its first frame decodable.
      final loaded = player.stream.duration.first;
      await player.open(mk.Media(videoPath), play: false);
      final duration = await loaded.timeout(
        const Duration(seconds: 20),
        onTimeout: () => Duration.zero,
      );
      // Give the decoded frame a moment to present on the shared texture.
      await Future<void>.delayed(const Duration(milliseconds: 400));

      // The opening frames of a video are very often black or a fade-in, so
      // sample slightly into the file instead.
      if (duration > const Duration(seconds: 4)) {
        final target = duration * 0.1;
        await player.seek(
          target < const Duration(seconds: 1)
              ? const Duration(seconds: 1)
              : target,
        );
        // seek() returns before the new frame is presented; screenshotting
        // immediately would capture the pre-seek frame.
        await Future<void>.delayed(const Duration(milliseconds: 600));
      }

      final bytes = await player.screenshot(format: 'image/jpeg');
      if (bytes == null || bytes.isEmpty) return null;

      final file = File(outputPath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      return outputPath;
    } catch (e) {
      print('Error generating thumbnail with media_kit: $e');
      return null;
    }
  }

  /// Builds the shared thumbnail player. The [VideoController] must exist for
  /// frames to be decoded into something `screenshot()` can read back.
  mk.Player _createThumbnailPlayer() {
    final player = mk.Player();
    _thumbnailController = VideoController(player);
    return player;
  }

  String _fileNameOf(String path) =>
      path.replaceAll('\\', '/').split('/').last;

  Future<void> _updateMediaWithThumbnail(
    String videoPath,
    String thumbnailPath,
  ) async {
    try {
      final existingMedia = _isar.medias
          .filter()
          .pathEqualTo(videoPath)
          .findFirstSync();

      if (existingMedia != null) {
        existingMedia.thumbnailPath = thumbnailPath;
        _isar.writeTxnSync(() {
          _isar.medias.putSync(existingMedia);
        });
        print('Updated existing media with thumbnail: $videoPath');
      } else {
        final fileName = _fileNameOf(videoPath);
        final newMedia = Media()
          ..path = videoPath
          ..name = fileName
          ..thumbnailPath = thumbnailPath;
        _isar.writeTxnSync(() {
          _isar.medias.putSync(newMedia);
        });
        print('Created new media record with thumbnail: $videoPath');
      }
    } catch (e) {
      print('Error updating media with thumbnail: $e');
      rethrow;
    }
  }

  String? getThumbnailPath(String videoPath) {
    try {
      final media = _isar.medias
          .filter()
          .pathEqualTo(videoPath)
          .findFirstSync();
      if (media != null &&
          media.thumbnailPath != null &&
          media.thumbnailPath!.isNotEmpty) {
        final thumbnailFile = File(media.thumbnailPath!);
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
      final allMedia = _isar.medias.where().findAllSync();
      final referencedThumbnails = allMedia
          .map((m) => m.thumbnailPath)
          .where((path) => path != null && path.isNotEmpty)
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
