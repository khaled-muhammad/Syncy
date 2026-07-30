import 'package:flutter_test/flutter_test.dart';
import 'package:syncy/models/media.dart';
import 'package:syncy/models/media_shelf.dart';

Media _media(
  String name, {
  int durationMs = 0,
  int playbackMs = 0,
  DateTime? addedAt,
  DateTime? watchedTogetherAt,
}) {
  return Media()
    ..name = name
    ..path = '/videos/$name.mp4'
    ..durationMs = durationMs
    ..playbackPositionMs = playbackMs
    ..addedAt = addedAt
    ..lastWatchedAt = addedAt
    ..watchedTogetherAt = watchedTogetherAt;
}

void main() {
  test('builds useful shelves from local watch metadata', () {
    final now = DateTime(2026, 7, 30);
    final continueItem = _media(
      'continue',
      durationMs: const Duration(minutes: 90).inMilliseconds,
      playbackMs: const Duration(minutes: 20).inMilliseconds,
      addedAt: now.subtract(const Duration(days: 2)),
    );
    final shortItem = _media(
      'short',
      durationMs: const Duration(minutes: 80).inMilliseconds,
      addedAt: now.subtract(const Duration(days: 1)),
    );
    final togetherItem = _media(
      'together',
      durationMs: const Duration(minutes: 160).inMilliseconds,
      addedAt: now.subtract(const Duration(days: 40)),
      watchedTogetherAt: now.subtract(const Duration(days: 3)),
    );

    final shelves = buildMediaShelves([
      continueItem,
      shortItem,
      togetherItem,
    ], now: now);

    expect(
      shelves
          .firstWhere((shelf) => shelf.kind == MediaShelfKind.continueWatching)
          .items
          .single
          .name,
      'continue',
    );
    expect(
      shelves
          .firstWhere((shelf) => shelf.kind == MediaShelfKind.shortTonight)
          .items
          .map((item) => item.name),
      contains('short'),
    );
    expect(
      shelves
          .firstWhere((shelf) => shelf.kind == MediaShelfKind.watchedTogether)
          .items
          .single
          .name,
      'together',
    );
    expect(
      shelves.any((shelf) => shelf.kind == MediaShelfKind.longCommitment),
      isTrue,
    );
  });

  test('does not put completed media in continue or short shelves', () {
    final now = DateTime(2026, 7, 30);
    final finished = _media(
      'finished',
      durationMs: 100000,
      playbackMs: 99000,
      addedAt: now,
    );

    final shelves = buildMediaShelves([finished], now: now);

    expect(
      shelves.any((shelf) => shelf.kind == MediaShelfKind.continueWatching),
      isFalse,
    );
    expect(
      shelves.any((shelf) => shelf.kind == MediaShelfKind.shortTonight),
      isFalse,
    );
  });
}
