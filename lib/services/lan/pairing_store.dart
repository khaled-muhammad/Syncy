import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncy/models/lan_device.dart';
import 'package:uuid/uuid.dart';

/// Persistent storage for LAN pairing, backed by shared_preferences.
///
/// Two roles share it:
/// * the **PC host** records the phones it has paired with (their tokens), so a
///   token stays valid across restarts;
/// * the **phone** records the PCs it has paired with (with their tokens), so
///   it never has to re-enter the 6-digit code.
///
/// Tokens and device ids are opaque randoms; the 6-digit code is short-lived
/// and never stored (it only gates the initial `/pair` exchange).
class PairingStore {
  static const _deviceIdKey = 'lan_device_id';
  static const _hostPairingsKey = 'lan_host_pairings'; // PC: paired phones
  static const _clientPairingsKey = 'lan_client_pairings'; // phone: paired PCs

  static final _random = Random.secure();

  final SharedPreferences _prefs;
  PairingStore(this._prefs);

  static Future<PairingStore> open() async =>
      PairingStore(await SharedPreferences.getInstance());

  /// A stable identity for this device, created once and reused forever. It is
  /// what lets a stored pairing survive the peer's IP changing.
  String deviceId() {
    final existing = _prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = const Uuid().v4();
    _prefs.setString(_deviceIdKey, id);
    return id;
  }

  /// A human-friendly name for this device shown to the peer while pairing.
  String deviceName() {
    try {
      final host = Platform.localHostname;
      if (host.isNotEmpty) return host;
    } catch (_) {}
    if (Platform.isAndroid) return 'Android phone';
    if (Platform.isIOS) return 'iPhone';
    if (Platform.isWindows) return 'Windows PC';
    return 'Syncy device';
  }

  /// 32 hex chars — an unguessable bearer token for a paired device.
  static String generateToken() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// A 6-digit one-time pairing code shown on the host.
  static String generateCode() =>
      (_random.nextInt(900000) + 100000).toString();

  // --- PC host side: the phones this PC has paired with ---------------------

  List<Map<String, dynamic>> hostPairings() {
    final raw = _prefs.getString(_hostPairingsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addHostPairing({
    required String token,
    required String deviceId,
    required String deviceName,
  }) async {
    final pairings = hostPairings()
      ..removeWhere((p) => p['deviceId'] == deviceId)
      ..add({
        'token': token,
        'deviceId': deviceId,
        'deviceName': deviceName,
        'pairedAt': DateTime.now().toIso8601String(),
      });
    await _prefs.setString(_hostPairingsKey, jsonEncode(pairings));
  }

  bool isValidToken(String token) =>
      token.isNotEmpty && hostPairings().any((p) => p['token'] == token);

  Future<void> revokeHostPairing(String deviceId) async {
    final pairings = hostPairings()
      ..removeWhere((p) => p['deviceId'] == deviceId);
    await _prefs.setString(_hostPairingsKey, jsonEncode(pairings));
  }

  // --- Phone side: the PCs this phone has paired with -----------------------

  List<LanDevice> pairedPcs() {
    final raw = _prefs.getString(_clientPairingsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map>()
          .map((e) => LanDevice.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  LanDevice? pairedPc(String deviceId) {
    for (final pc in pairedPcs()) {
      if (pc.deviceId == deviceId) return pc;
    }
    return null;
  }

  Future<void> savePairedPc(LanDevice device) async {
    final pcs = pairedPcs()
      ..removeWhere((p) => p.deviceId == device.deviceId)
      ..add(device);
    await _prefs.setString(
      _clientPairingsKey,
      jsonEncode(pcs.map((p) => p.toJson()).toList()),
    );
  }

  Future<void> removePairedPc(String deviceId) async {
    final pcs = pairedPcs()..removeWhere((p) => p.deviceId == deviceId);
    await _prefs.setString(
      _clientPairingsKey,
      jsonEncode(pcs.map((p) => p.toJson()).toList()),
    );
  }
}
