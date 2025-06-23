import 'package:realm/realm.dart';
part 'media.realm.dart';

enum MediaType { image, video, unknown }

@RealmModel()
class _Folder {
  @PrimaryKey()
  late ObjectId id;
  late String path;
  late String name;
  late List<_Media> entities;
}

@RealmModel()
class _Media {
  @PrimaryKey()
  late ObjectId id;
  late String path;
  late String name;
  late String thumbnailPath;
  @Backlink(#entities)
  late Iterable<_Folder> folder;
}
