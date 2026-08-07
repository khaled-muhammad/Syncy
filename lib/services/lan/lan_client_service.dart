import 'package:dio/dio.dart';
import 'package:syncy/models/lan_device.dart';
import 'package:syncy/models/remote_media.dart';
import 'package:syncy/services/lan/lan_discovery.dart';
import 'package:syncy/services/lan/pairing_store.dart';

/// Raised when a paired PC rejects the phone's token — the caller should send
/// the user back through pairing.
class LanUnauthorized implements Exception {
  const LanUnauthorized();
}

/// Phone-side LAN client: discovers PC hosts, pairs with a one-time code, and
/// browses / builds stream URLs for a paired PC's library.
class LanClientService {
  LanClientService(this._pairing);

  final PairingStore _pairing;

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 8),
      // We handle non-2xx ourselves so a 401/404 does not throw generically.
      validateStatus: (_) => true,
    ),
  );

  /// PCs previously paired with, resolved to their current LAN address when
  /// possible (a stored address can be stale after a DHCP change).
  Future<List<LanDevice>> knownAndDiscovered() async {
    final saved = {for (final pc in _pairing.pairedPcs()) pc.deviceId: pc};
    final live = await discoverHosts();
    for (final device in live) {
      final existing = saved[device.deviceId];
      if (existing != null) {
        // Keep the token; refresh the address to where it answered just now.
        saved[device.deviceId] = existing.copyWith(
          host: device.host,
          port: device.port,
          name: device.name,
        );
      } else {
        saved[device.deviceId] = device; // unpaired, discoverable
      }
    }
    return saved.values.toList(growable: false);
  }

  Future<List<LanDevice>> discover() => discoverHosts();

  /// Confirms a manually-entered address is a Syncy host and returns it.
  Future<LanDevice?> probe(String host, int port) async {
    try {
      final res = await _dio.getUri(Uri.parse('http://$host:$port/info'));
      if (res.statusCode != 200 || res.data is! Map) return null;
      final data = res.data as Map;
      return LanDevice(
        deviceId: data['deviceId']?.toString() ?? '',
        name: data['name']?.toString() ?? 'PC',
        host: host,
        port: port,
      );
    } catch (_) {
      return null;
    }
  }

  /// Exchanges the one-time [code] for a persistent token and saves the pairing.
  /// Returns the paired device, or throws [LanUnauthorized] on a bad code.
  Future<LanDevice> pair(LanDevice device, String code) async {
    final res = await _dio.post(
      '${device.baseUrl}/pair',
      data: {
        'code': code,
        'deviceId': _pairing.deviceId(),
        'deviceName': _pairing.deviceName(),
      },
    );
    if (res.statusCode == 401) throw const LanUnauthorized();
    if (res.statusCode != 200 || res.data is! Map) {
      throw Exception('Pairing failed');
    }
    final data = res.data as Map;
    final paired = device.copyWith(
      token: data['token']?.toString(),
      name: data['name']?.toString() ?? device.name,
    );
    await _pairing.savePairedPc(paired);
    return paired;
  }

  Future<void> unpair(String deviceId) => _pairing.removePairedPc(deviceId);

  /// Fetches the PC's library. Throws [LanUnauthorized] if the token is stale.
  Future<RemoteLibrary> fetchLibrary(LanDevice pc) async {
    final res = await _dio.get(
      '${pc.baseUrl}/library',
      options: Options(headers: {'authorization': 'Bearer ${pc.token}'}),
    );
    if (res.statusCode == 401) throw const LanUnauthorized();
    if (res.statusCode != 200 || res.data is! Map) {
      throw Exception('Could not load the library');
    }
    return RemoteLibrary.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  /// Asks the PC for a media-scoped stream URL to put into a room. Using a
  /// scoped token (not the phone's pairing token) keeps full-library access
  /// off the wire when the URL is shared with other room members.
  Future<String> streamUrlFor(LanDevice pc, RemoteMedia media) async {
    final res = await _dio.post(
      '${pc.baseUrl}/stream-token',
      data: {'mediaId': media.id},
      options: Options(headers: {'authorization': 'Bearer ${pc.token}'}),
    );
    if (res.statusCode == 401) throw const LanUnauthorized();
    final url = (res.data is Map) ? (res.data as Map)['url']?.toString() : null;
    if (url == null || url.isEmpty) throw Exception('Could not start stream');
    return url;
  }

  /// Authenticated thumbnail URL for display. The token rides as a query param
  /// so a plain `Image.network` can load it without custom headers.
  String thumbnailUrl(LanDevice pc, RemoteMedia media) =>
      '${pc.baseUrl}/thumb/${media.id}';

  Map<String, String> authHeader(LanDevice pc) => {
    'authorization': 'Bearer ${pc.token}',
  };
}
