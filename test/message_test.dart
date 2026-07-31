import 'package:flutter_test/flutter_test.dart';
import 'package:syncy/models/message.dart';

void main() {
  test(
    'playback messages preserve millisecond precision and event identity',
    () {
      final message = Message.seek(
        roomId: 'room',
        userId: 'user',
        position: const Duration(milliseconds: 1234),
      );

      final encoded = message.toJson();
      final decoded = Message.fromJson(encoded);

      expect(encoded['data'], {'positionMs': 1234});
      expect(decoded.eventId, message.eventId);
      expect(decoded.type, MessageType.seek);
    },
  );

  test('media changes synchronize metadata without local file paths', () {
    final message = Message.videoChanged(
      roomId: 'room',
      userId: 'host',
      videoTitle: 'Movie.mp4',
    );

    expect(message.data['videoTitle'], 'Movie.mp4');
    expect(message.data['videoUrl'], isEmpty);
    expect(message.toJson()['type'], 'video_changed');
  });

  test('join errors remain actionable transport errors', () {
    final message = Message.fromJson({
      'type': 'error',
      'data': {'error': 'Room or user not found'},
    });

    expect(message.type, MessageType.error);
    expect(message.data['error'], 'Room or user not found');
  });

  test('typing state round-trips as an ephemeral protocol message', () {
    final message = Message.typing(
      roomId: 'room',
      userId: 'user',
      userName: 'Alice',
      isTyping: true,
    );

    final decoded = Message.fromJson(message.toJson());

    expect(decoded.type, MessageType.typing);
    expect(decoded.eventId, message.eventId);
    expect(decoded.data, {'isTyping': true, 'userName': 'Alice'});
  });

  test('host controls use backend wire names', () {
    final settings = Message.roomSettings(
      roomId: 'room',
      userId: 'host',
      isLocked: true,
      seekPermission: 'selected',
    );
    final kick = Message.kickParticipant(
      roomId: 'room',
      userId: 'host',
      participantId: 'member',
    );

    expect(settings.toJson()['type'], 'room_settings');
    expect(settings.data['isLocked'], isTrue);
    expect(kick.toJson()['type'], 'kick_participant');
  });
}
