import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncy/models/recent_room.dart';
import 'package:syncy/models/room.dart';

class RecentRoomsService extends GetxService {
  static const storageKey = 'recent_rooms_v1';
  static const maxRooms = 8;

  final rooms = <RecentRoom>[].obs;
  late SharedPreferences _preferences;

  Future<RecentRoomsService> init() async {
    _preferences = await SharedPreferences.getInstance();
    _load();
    return this;
  }

  void _load() {
    final decoded = <RecentRoom>[];
    for (final value in _preferences.getStringList(storageKey) ?? const []) {
      try {
        final json = jsonDecode(value);
        if (json is Map) {
          decoded.add(RecentRoom.fromJson(Map<String, dynamic>.from(json)));
        }
      } catch (_) {
        // A single malformed legacy entry should not hide valid recent rooms.
      }
    }
    decoded.sort((a, b) => b.lastJoinedAt.compareTo(a.lastJoinedAt));
    rooms.assignAll(decoded.take(maxRooms));
  }

  Future<void> remember(Room room, {required bool wasHost}) async {
    final recent = RecentRoom(
      roomId: room.id,
      joinCode: room.joinCode,
      name: room.name,
      mode: room.mode,
      mediaTitle: room.currentVideoTitle,
      wasHost: wasHost,
      lastJoinedAt: DateTime.now().toUtc(),
    );

    final updated = [
      recent,
      ...rooms.where((entry) => entry.roomId != room.id),
    ].take(maxRooms).toList(growable: false);
    rooms.assignAll(updated);
    await _persist();
  }

  Future<void> remove(String roomId) async {
    rooms.removeWhere((entry) => entry.roomId == roomId);
    await _persist();
  }

  Future<void> clear() async {
    rooms.clear();
    await _preferences.remove(storageKey);
  }

  Future<void> _persist() async {
    await _preferences.setStringList(
      storageKey,
      rooms.map((room) => jsonEncode(room.toJson())).toList(growable: false),
    );
  }
}
