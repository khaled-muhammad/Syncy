import 'package:syncy/models/media.dart';

enum MediaShelfKind {
  continueWatching,
  almostFinished,
  recentlyAdded,
  shortTonight,
  watchedTogether,
  longCommitment,
}

class MediaShelf {
  const MediaShelf({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final MediaShelfKind kind;
  final String title;
  final String subtitle;
  final List<Media> items;
}

List<MediaShelf> buildMediaShelves(Iterable<Media> source, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  final media = source.toList(growable: false);

  List<Media> sorted(
    bool Function(Media item) include,
    DateTime? Function(Media item) date,
  ) {
    final result = media.where(include).toList();
    result.sort(
      (a, b) => (date(b) ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
        date(a) ?? DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
    return result;
  }

  final recentCutoff = clock.subtract(const Duration(days: 30));
  final shelves = <MediaShelf>[
    MediaShelf(
      kind: MediaShelfKind.continueWatching,
      title: 'Continue Watching',
      subtitle: 'Pick up exactly where you left off',
      items: sorted(
        (item) => item.watchedFraction > .01 && item.watchedFraction < .95,
        (item) => item.lastWatchedAt,
      ),
    ),
    MediaShelf(
      kind: MediaShelfKind.almostFinished,
      title: 'Almost Finished',
      subtitle: 'The ending is waiting',
      items: sorted(
        (item) => item.watchedFraction >= .75 && item.watchedFraction < .95,
        (item) => item.lastWatchedAt,
      ),
    ),
    MediaShelf(
      kind: MediaShelfKind.recentlyAdded,
      title: 'Recently Added',
      subtitle: 'Fresh arrivals in your library',
      items: sorted(
        (item) => item.addedAt == null || item.addedAt!.isAfter(recentCutoff),
        (item) => item.addedAt,
      ),
    ),
    MediaShelf(
      kind: MediaShelfKind.shortTonight,
      title: 'Short Enough for Tonight',
      subtitle: 'Under 100 minutes and easy to start',
      items: sorted(
        (item) =>
            item.durationMs > 0 &&
            item.durationMs <= const Duration(minutes: 100).inMilliseconds &&
            !item.isFinished,
        (item) => item.addedAt,
      ),
    ),
    MediaShelf(
      kind: MediaShelfKind.watchedTogether,
      title: 'Recently Watched Together',
      subtitle: 'Shared memories, ready for another round',
      items: sorted(
        (item) => item.watchedTogetherAt != null,
        (item) => item.watchedTogetherAt,
      ),
    ),
    MediaShelf(
      kind: MediaShelfKind.longCommitment,
      title: 'Long Movies — Commitment Required',
      subtitle: 'Epic stories over 150 minutes',
      items: sorted(
        (item) =>
            item.durationMs >= const Duration(minutes: 150).inMilliseconds,
        (item) => item.addedAt,
      ),
    ),
  ];

  return shelves.where((shelf) => shelf.items.isNotEmpty).toList();
}
