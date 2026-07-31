import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncy/models/room.dart';
import 'package:syncy/services/recent_rooms_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'recent rooms are deduplicated, ordered, capped, and restored',
    () async {
      final service = await RecentRoomsService().init();

      for (var index = 0; index < RecentRoomsService.maxRooms + 2; index++) {
        await service.remember(_room(index), wasHost: index.isEven);
      }

      expect(service.rooms, hasLength(RecentRoomsService.maxRooms));
      expect(service.rooms.first.roomId, 'room-9');
      expect(service.rooms.last.roomId, 'room-2');

      await service.remember(_room(5, name: 'Updated room'), wasHost: false);
      expect(service.rooms, hasLength(RecentRoomsService.maxRooms));
      expect(service.rooms.first.roomId, 'room-5');
      expect(service.rooms.first.name, 'Updated room');

      final restored = await RecentRoomsService().init();
      expect(restored.rooms, hasLength(RecentRoomsService.maxRooms));
      expect(restored.rooms.first.roomId, 'room-5');

      await restored.remove('room-5');
      expect(restored.rooms.any((room) => room.roomId == 'room-5'), isFalse);
    },
  );
}

Room _room(int index, {String? name}) {
  return Room(
    id: 'room-$index',
    joinCode: 'ABCD${(2000 + index).toString()}',
    name: name ?? 'Room $index',
    mode: RoomMode.friends,
    currentVideoTitle: 'Movie $index',
    hostId: 'host',
    createdAt: DateTime.utc(2026),
  );
}
