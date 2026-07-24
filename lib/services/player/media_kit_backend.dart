import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:syncy/services/player/sync_player.dart';

/// [SyncPlayer] backed by media_kit (libmpv), used on desktop.
///
/// libmpv ships its own decoders, so this plays the containers and codecs a PC
/// media library actually holds (MKV, HEVC, AV1) without depending on
/// OS-installed codec packs the way a Media Foundation backend would.
class MediaKitBackend extends SyncPlayer {
  /// Plays a local file. [source] is a filesystem path.
  MediaKitBackend(String source) : _source = source {
    _controller = VideoController(_player);
    _listen();
  }

  /// Streams from an `http(s)` URL — libmpv accepts a URL as a media source
  /// just like a path, so a desktop peer can stream from another PC on the LAN.
  MediaKitBackend.network(String url) : _source = url {
    _controller = VideoController(_player);
    _listen();
  }

  void _listen() {
    _subscriptions.addAll([
      _player.stream.position.listen((position) {
        _update(_value.copyWith(position: position));
      }),
      _player.stream.duration.listen((duration) {
        _update(_value.copyWith(duration: duration));
      }),
      _player.stream.playing.listen((playing) {
        _update(_value.copyWith(isPlaying: playing));
      }),
      _player.stream.rate.listen((rate) {
        _update(_value.copyWith(playbackSpeed: rate));
      }),
      _player.stream.width.listen((_) => _updateAspectRatio()),
      _player.stream.height.listen((_) => _updateAspectRatio()),
      _player.stream.error.listen((error) {
        // Surface the first failure to whoever is awaiting initialize(); a
        // later error (e.g. a LAN host that vanished mid-stream) is reflected
        // in the value so the room can offer a retry.
        if (!_ready.isCompleted) {
          _ready.completeError(StateError(error));
        } else {
          _update(_value.copyWith(hasError: true, errorDescription: error));
        }
      }),
    ]);
  }

  final String _source;
  final Player _player = Player();
  late final VideoController _controller;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final Completer<void> _ready = Completer<void>();

  SyncPlayerValue _value = const SyncPlayerValue();
  bool _disposed = false;

  @override
  SyncPlayerValue get value => _value;

  void _update(SyncPlayerValue next) {
    if (_disposed) return;
    _value = next;
    notifyListeners();
  }

  void _updateAspectRatio() {
    final width = _player.state.width;
    final height = _player.state.height;
    if (width == null || height == null || width <= 0 || height <= 0) return;
    _update(_value.copyWith(aspectRatio: width / height));
  }

  @override
  Future<void> initialize() async {
    // Playback always starts paused: the room decides when to play, and
    // autoplaying here would desync everyone else before the first sync
    // message is applied.
    await _player.open(Media(_source), play: false);

    await Future.any([
      _controller.waitUntilFirstFrameRendered,
      _ready.future, // Only completes on error.
    ]);
    if (!_ready.isCompleted) _ready.complete();

    _updateAspectRatio();
    _update(
      _value.copyWith(
        isInitialized: true,
        duration: _player.state.duration,
        position: _player.state.position,
        isPlaying: _player.state.playing,
        playbackSpeed: _player.state.rate,
      ),
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seekTo(Duration position) => _player.seek(position);

  @override
  Future<void> setPlaybackSpeed(double speed) => _player.setRate(speed);

  @override
  Future<Duration?> get position async => _player.state.position;

  @override
  Widget buildSurface() {
    return Video(
      controller: _controller,
      controls: NoVideoControls,
      fill: Colors.transparent,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    unawaited(_player.dispose());
    super.dispose();
  }
}
