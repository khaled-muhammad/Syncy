import 'package:flutter_test/flutter_test.dart';
import 'package:syncy/utils/room_reference.dart';

void main() {
  test('normalizes readable join codes and invite links', () {
    expect(normalizeRoomReference(' abcd-2345 '), 'ABCD2345');
    expect(
      normalizeRoomReference('Join me on Syncy: syncy://join/ABCD-2345'),
      'ABCD2345',
    );
    expect(
      normalizeRoomReference(
        'Join me: https://syncy-backend.mywire.org/join/ABCD-2345',
      ),
      'ABCD2345',
    );
    expect(
      roomReferenceFromUri(Uri.parse('syncy://join/ABCD2345')),
      'ABCD2345',
    );
  });

  test('preserves legacy UUID room references', () {
    const uuid = '9e86c9de-9b64-4a8b-b752-8726bb8ff9cc';
    expect(normalizeRoomReference(uuid.toUpperCase()), uuid);
    expect(normalizeRoomReference('syncy://join/$uuid'), uuid);
    expect(roomReferenceFromUri(Uri.parse('syncy://join/$uuid')), uuid);
  });

  test('rejects malformed and ambiguous room codes', () {
    expect(normalizeRoomReference(''), isNull);
    expect(normalizeRoomReference('ABCD'), isNull);
    expect(normalizeRoomReference('ABCO-1234'), isNull);
    expect(
      roomReferenceFromUri(Uri.parse('https://example.com/join/ABCD2345')),
      isNull,
    );
  });
}
