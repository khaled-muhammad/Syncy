import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncy/models/lan_device.dart';
import 'package:syncy/services/lan/pairing_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<PairingStore> store() => PairingStore.open();

  test('deviceId is stable across reads', () async {
    final s = await store();
    final first = s.deviceId();
    expect(first, isNotEmpty);
    expect(s.deviceId(), first);
    // A fresh store over the same prefs sees the same id.
    expect((await store()).deviceId(), first);
  });

  test('generated codes are six digits and tokens are non-trivial', () {
    for (var i = 0; i < 50; i++) {
      final code = PairingStore.generateCode();
      expect(code.length, 6);
      expect(int.tryParse(code), isNotNull);
    }
    final token = PairingStore.generateToken();
    expect(token.length, 32);
    expect(PairingStore.generateToken(), isNot(token));
  });

  test('host records a pairing and validates its token', () async {
    final s = await store();
    expect(s.isValidToken('nope'), isFalse);

    await s.addHostPairing(
      token: 'tok-123',
      deviceId: 'phone-a',
      deviceName: 'Pixel',
    );
    expect(s.isValidToken('tok-123'), isTrue);

    await s.revokeHostPairing('phone-a');
    expect(s.isValidToken('tok-123'), isFalse);
  });

  test('re-pairing the same device replaces its record', () async {
    final s = await store();
    await s.addHostPairing(token: 't1', deviceId: 'p', deviceName: 'A');
    await s.addHostPairing(token: 't2', deviceId: 'p', deviceName: 'A');
    expect(s.hostPairings().length, 1);
    expect(s.isValidToken('t1'), isFalse);
    expect(s.isValidToken('t2'), isTrue);
  });

  test('phone persists and reloads paired PCs with their tokens', () async {
    final s = await store();
    await s.savePairedPc(
      const LanDevice(
        deviceId: 'pc-1',
        name: 'Studio',
        host: '192.168.1.5',
        port: 8770,
        token: 'abc',
      ),
    );
    final reloaded = (await store()).pairedPc('pc-1');
    expect(reloaded, isNotNull);
    expect(reloaded!.token, 'abc');
    expect(reloaded.isPaired, isTrue);
    expect(reloaded.baseUrl, 'http://192.168.1.5:8770');
  });
}
