import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncy/services/player/playback_synchronizer.dart';
import 'package:syncy/services/player/sync_player.dart';

void main() {
  test('a newer pause invalidates an in-flight play', () async {
    final player = _FakeSyncPlayer();
    final synchronizer = PlaybackSynchronizer(
      now: () => DateTime.utc(2026, 1, 1),
    )..attach(player);
    final blockedSeek = Completer<void>();
    player.blockedSeek = blockedSeek;

    final play = synchronizer.submitAuthoritative(
      PlaybackSyncState(
        revision: 1,
        position: const Duration(seconds: 20),
        isPlaying: true,
        receivedAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final pause = synchronizer.submitAuthoritative(
      PlaybackSyncState(
        revision: 2,
        position: const Duration(seconds: 30),
        isPlaying: false,
        receivedAt: DateTime.utc(2026, 1, 1),
      ),
    );
    blockedSeek.complete();
    await Future.wait([play, pause]);

    expect(player.playCalls, 0);
    expect(player.value.isPlaying, isFalse);
    expect(player.value.position, const Duration(seconds: 30));
    synchronizer.dispose();
  });

  test('unexpected platform autoplay is corrected to room pause', () async {
    final player = _FakeSyncPlayer();
    final synchronizer = PlaybackSynchronizer(
      now: () => DateTime.utc(2026, 1, 1),
    )..attach(player);

    await synchronizer.submitAuthoritative(
      PlaybackSyncState(
        revision: 1,
        position: Duration.zero,
        isPlaying: false,
        receivedAt: DateTime.utc(2026, 1, 1),
      ),
    );
    player.simulatePlaying(true);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(player.pauseCalls, 1);
    expect(player.value.isPlaying, isFalse);
    synchronizer.dispose();
  });

  test(
    'inactive clients wait for authoritative resume before playing',
    () async {
      final player = _FakeSyncPlayer();
      final synchronizer = PlaybackSynchronizer(
        now: () => DateTime.utc(2026, 1, 1),
      )..attach(player);
      synchronizer.setActive(false);

      await synchronizer.submitAuthoritative(
        PlaybackSyncState(
          revision: 1,
          position: const Duration(seconds: 12),
          isPlaying: true,
          receivedAt: DateTime.utc(2026, 1, 1),
        ),
      );
      expect(player.playCalls, 0);

      synchronizer.setActive(true);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(player.playCalls, 1);
      expect(player.value.isPlaying, isTrue);
      synchronizer.dispose();
    },
  );
}

class _FakeSyncPlayer extends SyncPlayer {
  SyncPlayerValue _value = const SyncPlayerValue(
    isInitialized: true,
    duration: Duration(minutes: 2),
  );

  Completer<void>? blockedSeek;
  int playCalls = 0;
  int pauseCalls = 0;

  @override
  SyncPlayerValue get value => _value;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> play() async {
    playCalls++;
    _value = _value.copyWith(isPlaying: true);
    notifyListeners();
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
    _value = _value.copyWith(isPlaying: false);
    notifyListeners();
  }

  @override
  Future<void> seekTo(Duration position) async {
    final blocker = blockedSeek;
    if (blocker != null) {
      blockedSeek = null;
      await blocker.future;
    }
    _value = _value.copyWith(position: position);
    notifyListeners();
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    _value = _value.copyWith(playbackSpeed: speed);
  }

  @override
  Future<Duration?> get position async => _value.position;

  @override
  Widget buildSurface() => const SizedBox.shrink();

  void simulatePlaying(bool isPlaying) {
    _value = _value.copyWith(isPlaying: isPlaying);
    notifyListeners();
  }
}
