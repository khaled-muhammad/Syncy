import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:syncy/services/player/sync_player.dart';

@immutable
class PlaybackSyncState {
  const PlaybackSyncState({
    required this.revision,
    required this.position,
    required this.isPlaying,
    required this.receivedAt,
  });

  final int revision;
  final Duration position;
  final bool isPlaying;
  final DateTime receivedAt;

  Duration positionAt(DateTime now) {
    if (!isPlaying || now.isBefore(receivedAt)) return position;
    return position + now.difference(receivedAt);
  }
}

/// Applies playback commands in order and invalidates an in-flight command as
/// soon as a newer state arrives.
///
/// Android may recreate or suspend its video surface during system UI and
/// split-screen transitions. The player listener also corrects any resulting
/// play/pause change back to the latest room state.
class PlaybackSynchronizer {
  PlaybackSynchronizer({DateTime Function()? now, this.onApplyingChanged})
    : _now = now ?? DateTime.now;

  static const Duration seekTolerance = Duration(milliseconds: 250);

  final DateTime Function() _now;
  final ValueChanged<bool>? onApplyingChanged;

  SyncPlayer? _player;
  PlaybackSyncState? _desired;
  Future<void> _tail = Future<void>.value();
  int _generation = 0;
  bool _isApplying = false;
  bool _active = true;
  bool _correctionScheduled = false;

  PlaybackSyncState? get desired => _desired;

  void attach(SyncPlayer player) {
    if (identical(_player, player)) return;
    _player?.removeListener(_handlePlayerChanged);
    _player = player;
    player.addListener(_handlePlayerChanged);
  }

  void detach([SyncPlayer? player]) {
    if (player != null && !identical(_player, player)) return;
    _player?.removeListener(_handlePlayerChanged);
    _player = null;
    _generation++;
  }

  void clear() {
    _desired = null;
    _generation++;
  }

  void setActive(bool active) {
    if (_active == active) return;
    _active = active;
    _generation++;
    if (active) {
      unawaited(reconcile());
    } else if (_desired?.isPlaying == false) {
      unawaited(reconcile());
    }
  }

  Future<void> submitAuthoritative(PlaybackSyncState state) {
    final current = _desired;
    if (current != null && state.revision < current.revision) {
      return Future<void>.value();
    }
    _desired = state;
    return _scheduleApply();
  }

  Future<void> submitLocal({
    required Duration position,
    required bool isPlaying,
  }) {
    _desired = PlaybackSyncState(
      revision: _desired?.revision ?? -1,
      position: position,
      isPlaying: isPlaying,
      receivedAt: _now(),
    );
    return _scheduleApply();
  }

  Future<void> reconcile() {
    if (_desired == null) return Future<void>.value();
    return _scheduleApply();
  }

  Future<void> _scheduleApply() {
    final generation = ++_generation;
    final operation = _tail.then((_) => _apply(generation));
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operation;
  }

  Future<void> _apply(int generation) async {
    if (generation != _generation) return;
    final player = _player;
    final desired = _desired;
    if (player == null || desired == null || !player.value.isInitialized) {
      return;
    }

    _setApplying(true);
    try {
      final unclampedTarget = desired.positionAt(_now());
      final target = unclampedTarget < Duration.zero
          ? Duration.zero
          : unclampedTarget > player.value.duration
          ? player.value.duration
          : unclampedTarget;

      if ((player.value.position - target).abs() > seekTolerance) {
        await player.seekTo(target);
      }
      if (generation != _generation) return;

      // Do not start background playback while Android is inactive. A pause is
      // always enforced, including when the platform changes player state.
      if (desired.isPlaying) {
        if (_active && !player.value.isPlaying) {
          await player.play();
        }
      } else if (player.value.isPlaying) {
        await player.pause();
      }
    } finally {
      _setApplying(false);
    }
  }

  void _handlePlayerChanged() {
    if (_isApplying || _correctionScheduled) return;
    final player = _player;
    final desired = _desired;
    if (player == null || desired == null || !player.value.isInitialized) {
      return;
    }

    final shouldCorrectPause = !desired.isPlaying && player.value.isPlaying;
    final shouldCorrectPlay =
        _active && desired.isPlaying && !player.value.isPlaying;
    if (!shouldCorrectPause && !shouldCorrectPlay) return;

    _correctionScheduled = true;
    scheduleMicrotask(() {
      _correctionScheduled = false;
      unawaited(reconcile());
    });
  }

  void _setApplying(bool value) {
    if (_isApplying == value) return;
    _isApplying = value;
    onApplyingChanged?.call(value);
  }

  void dispose() {
    detach();
    _desired = null;
  }
}
