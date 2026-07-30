import 'package:isar_community/isar.dart';
part 'media.g.dart';

enum MediaType { image, video, unknown }

@collection
class Folder {
  Id id = Isar.autoIncrement;
  late String path;
  late String name;
  final entities = IsarLinks<Media>();
}

@collection
class Media {
  Id id = Isar.autoIncrement;
  late String path;
  late String name;
  String? thumbnailPath;
  int durationMs = 0;
  int playbackPositionMs = 0;
  int dominantColorValue = 0;
  bool hasSubtitles = false;
  DateTime? addedAt;
  DateTime? lastWatchedAt;
  DateTime? watchedTogetherAt;
  List<String> watchedWith = [];

  @Backlink(to: 'entities')
  final folder = IsarLinks<Folder>();

  double get watchedFraction {
    if (durationMs <= 0) return 0;
    return (playbackPositionMs / durationMs).clamp(0, 1);
  }

  bool get isFinished => watchedFraction >= .95;
}
