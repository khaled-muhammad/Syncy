// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:syncy/models/room.dart';

void main() {
  test('room snapshots prefer precise millisecond positions', () {
    final room = Room.fromJson({
      'id': 'room',
      'name': 'Movie night',
      'host_id': 'host',
      'position_ms': 9876,
      'current_position': 9,
      'is_playing': true,
      'created_at': '2026-01-01T00:00:00Z',
    });

    expect(room.currentPosition, const Duration(milliseconds: 9876));
    expect(room.isPlaying, isTrue);
  });

  test('room snapshots preserve the selected room mode', () {
    final room = Room.fromJson({
      'id': 'room',
      'name': 'Date night',
      'host_id': 'host',
      'room_mode': 'couple',
      'position_ms': 0,
      'is_playing': false,
      'created_at': '2026-01-01T00:00:00Z',
    });

    expect(room.mode, RoomMode.couple);
  });
}
