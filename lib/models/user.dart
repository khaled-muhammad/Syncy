import 'package:isar_community/isar.dart';
part 'user.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement;
  late String name;
}
