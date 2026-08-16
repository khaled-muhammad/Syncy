import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncy/controllers/room_controller.dart';
import 'package:syncy/services/player/sync_player.dart';
import 'package:syncy/services/player/sync_player_factory.dart';
import 'package:syncy/widgets/ambient_video_surface.dart';
import 'package:syncy/widgets/custom_video_player.dart';
import 'package:syncy/widgets/native_purple_mesh_background.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Standalone phone player for media streamed from a paired PC.
///
/// It reuses Syncy's player chrome and per-device subtitle selection, but it
/// never creates, joins, or connects to a room.
class DirectPcPlayerScreen extends StatefulWidget {
  const DirectPcPlayerScreen({
    super.key,
    required this.streamUrl,
    required this.title,
  });

  final String streamUrl;
  final String title;

  @override
  State<DirectPcPlayerScreen> createState() => _DirectPcPlayerScreenState();
}

class _DirectPcPlayerScreenState extends State<DirectPcPlayerScreen> {
  late SyncPlayer _player;
  final RoomController _playbackOptions = Get.find<RoomController>();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _player = _newPlayer();
    _open();
  }

  SyncPlayer _newPlayer() =>
      createSyncPlayerFromUrl(widget.streamUrl)..addListener(_onPlayerChanged);

  Future<void> _open() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      await _player.initialize();
      _playbackOptions.currentMediaPath = widget.streamUrl;
      if (mounted) setState(() => _loading = false);
      // Subtitle discovery is optional and may take a few seconds when the PC
      // is under load. A decodable first frame should never wait behind it.
      unawaited(_playbackOptions.discoverSubtitles(widget.streamUrl));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            "Couldn't play this video. Keep the PC awake and make sure "
            "this phone is on the same Wi-Fi network.";
      });
    }
  }

  Future<void> _retry() async {
    _player.removeListener(_onPlayerChanged);
    _player.dispose();
    _player = _newPlayer();
    await _open();
  }

  void _onPlayerChanged() {
    if (!mounted) return;
    final value = _player.value;
    if (value.hasError && _error == null) {
      _error =
          value.errorDescription ??
          'The stream stopped. Check the PC and Wi-Fi connection.';
    }
    setState(() {});
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _player.removeListener(_onPlayerChanged);
    _player.dispose();
    if (_playbackOptions.currentMediaPath == widget.streamUrl) {
      _playbackOptions.currentMediaPath = null;
      _playbackOptions.availableSubtitles.clear();
      _playbackOptions.currentSubtitlePath.value = null;
      _playbackOptions.currentSubtitleLabel.value = '';
      _playbackOptions.subtitleDelay.value = 0;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NativePurpleMeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'Watching directly',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        body: Center(
          child: AspectRatio(
            aspectRatio: _player.value.aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AmbientVideoSurface(child: _player.buildSurface()),
                ControlsOverlay(
                  controller: _player,
                  roomController: _playbackOptions,
                  showReactionsInFullscreen: false,
                  onPlayToggle: (play) =>
                      play ? _player.play() : _player.pause(),
                  onSeek: _player.seekTo,
                ),
                if (_loading || _error != null)
                  ColoredBox(
                    color: Colors.black.withValues(alpha: .76),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: _loading
                            ? const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Opening stream from PC…'),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.wifi_off_rounded, size: 42),
                                  const SizedBox(height: 12),
                                  Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(height: 1.4),
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: _retry,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Retry'),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
