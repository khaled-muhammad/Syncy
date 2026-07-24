import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A snapshot of playback state, mirroring the subset of `VideoPlayerValue`
/// the app actually reads.
@immutable
class SyncPlayerValue {
  const SyncPlayerValue({
    this.isInitialized = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isPlaying = false,
    this.aspectRatio = 1.0,
    this.playbackSpeed = 1.0,
    this.hasError = false,
    this.errorDescription,
  });

  final bool isInitialized;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final double aspectRatio;
  final double playbackSpeed;

  /// True once playback has failed — e.g. a LAN stream whose host went away, or
  /// a file whose codec the device can't decode. Drives the room's retry UI.
  final bool hasError;
  final String? errorDescription;

  SyncPlayerValue copyWith({
    bool? isInitialized,
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    double? aspectRatio,
    double? playbackSpeed,
    bool? hasError,
    String? errorDescription,
  }) {
    return SyncPlayerValue(
      isInitialized: isInitialized ?? this.isInitialized,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      hasError: hasError ?? this.hasError,
      errorDescription: errorDescription ?? this.errorDescription,
    );
  }
}

/// The playback surface the room uses, independent of the engine behind it.
///
/// `video_player` has no Windows implementation, so desktop runs on media_kit
/// while mobile stays on `video_player`. Both are exposed through this
/// interface so the player chrome, the gesture handling, and — most
/// importantly — the websocket sync logic in `RoomController` stay written
/// against one API.
abstract class SyncPlayer extends ChangeNotifier {
  SyncPlayerValue get value;

  /// Opens the media and blocks until the first frame is decodable, so callers
  /// can rely on [SyncPlayerValue.duration] and aspect ratio afterwards.
  Future<void> initialize();

  Future<void> play();

  Future<void> pause();

  Future<void> seekTo(Duration position);

  Future<void> setPlaybackSpeed(double speed);

  /// The engine's authoritative position, which can be fresher than
  /// [SyncPlayerValue.position] between notifications. Sync messages are
  /// stamped with this.
  Future<Duration?> get position;

  /// The video surface itself, without any controls — Syncy draws its own.
  Widget buildSurface();
}
