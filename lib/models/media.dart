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

  @Backlink(to: 'entities')
  final folder = IsarLinks<Folder>();
}
