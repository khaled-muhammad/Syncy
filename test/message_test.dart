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
  });
}
