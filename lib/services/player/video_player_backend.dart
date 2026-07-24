import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:syncy/services/player/sync_player.dart';
import 'package:video_player/video_player.dart';

/// [SyncPlayer] backed by `video_player`, used on Android and iOS.
///
/// This is a straight pass-through: the underlying controller remains the
/// source of truth and its notifications are forwarded unchanged, so mobile
/// playback behaves exactly as it did before the abstraction existed.
class VideoPlayerBackend extends SyncPlayer {
  VideoPlayerBackend(File file)
    : _controller = VideoPlayerController.file(
        file,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      ) {
    _controller.addListener(_onControllerUpdate);
  }

  /// Streams from an `http(s)` URL, e.g. a video hosted by a paired PC on the
  /// LAN. ExoPlayer/AVFoundation handle HTTP range requests, so seeking works
  /// as long as the server answers with `206 Partial Content`.
  VideoPlayerBackend.network(String url)
    : _controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      ) {
    _controller.addListener(_onControllerUpdate);
  }

  final VideoPlayerController _controller;

  void _onControllerUpdate() => notifyListeners();

  @override
  SyncPlayerValue get value {
    final v = _controller.value;
    return SyncPlayerValue(
      isInitialized: v.isInitialized,
      position: v.position,
      duration: v.duration,
      isPlaying: v.isPlaying,
      // An uninitialized controller reports a 1.0 aspect ratio already, but
      // guard anyway so layout never divides by zero on a broken file.
      aspectRatio: v.aspectRatio <= 0 ? 1.0 : v.aspectRatio,
      playbackSpeed: v.playbackSpeed,
      hasError: v.hasError,
      errorDescription: v.errorDescription,
    );
  }

  @override
  Future<void> initialize() => _controller.initialize();

  @override
  Future<void> play() => _controller.play();

  @override
  Future<void> pause() => _controller.pause();

  @override
  Future<void> seekTo(Duration position) => _controller.seekTo(position);

  @override
  Future<void> setPlaybackSpeed(double speed) =>
      _controller.setPlaybackSpeed(speed);

  @override
  Future<Duration?> get position => _controller.position;

  @override
  Widget buildSurface() => VideoPlayer(_controller);

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }
}
