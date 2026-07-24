import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:syncy/models/lan_device.dart';

/// UDP port both sides use for discovery. Separate from the HTTP media port so
/// discovery keeps working even if the HTTP server lands on a fallback port.
const int kDiscoveryPort = 8771;

/// Probe payload the phone broadcasts; the version suffix lets the protocol
/// evolve without older builds mis-parsing newer replies.
const String _kProbe = 'SYNCY_DISCOVER_V1';

/// Prefix on the host's reply so stray datagrams on the port are ignored.
const String _kReplyPrefix = 'SYNCY_HOST_V1:';

/// Answers discovery probes on the LAN. Runs on the PC host.
class LanDiscoveryResponder {
  RawDatagramSocket? _socket;

  /// Begins replying to probes with this host's identity and HTTP port.
  Future<void> start({
    required String deviceId,
    required String name,
    required int httpPort,
  }) async {
    await stop();
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      kDiscoveryPort,
      reuseAddress: true,
    );
    _socket = socket;

    final reply = utf8.encode(
      '$_kReplyPrefix${jsonEncode({'deviceId': deviceId, 'name': name, 'httpPort': httpPort})}',
    );

    socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = socket.receive();
      if (datagram == null) return;
      // Only answer genuine Syncy probes; ignore anything else on the port.
      if (utf8.decode(datagram.data, allowMalformed: true) != _kProbe) return;
      socket.send(reply, datagram.address, datagram.port);
    });
  }

  Future<void> stop() async {
    _socket?.close();
    _socket = null;
  }
}

/// Broadcasts a probe and collects host replies for [timeout]. Runs on the
/// phone. De-duplicates by `deviceId`, keeping the most recent address so a
/// host that changed IP is reported at its current one.
Future<List<LanDevice>> discoverHosts({
  Duration timeout = const Duration(milliseconds: 1500),
}) async {
  final results = <String, LanDevice>{};
  RawDatagramSocket? socket;
  try {
    socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;

    final found = Completer<void>();
    socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = socket!.receive();
      if (datagram == null) return;
      final text = utf8.decode(datagram.data, allowMalformed: true);
      if (!text.startsWith(_kReplyPrefix)) return;
      try {
        final json =
            jsonDecode(text.substring(_kReplyPrefix.length))
                as Map<String, dynamic>;
        final deviceId = json['deviceId']?.toString() ?? '';
        if (deviceId.isEmpty) return;
        results[deviceId] = LanDevice(
          deviceId: deviceId,
          name: json['name']?.toString() ?? 'PC',
          host: datagram.address.address,
          port: (json['httpPort'] as num?)?.toInt() ?? 0,
        );
      } catch (_) {
        // Malformed reply — skip it rather than aborting discovery.
      }
    });

    final probe = utf8.encode(_kProbe);
    final broadcast = InternetAddress('255.255.255.255');
    // Send a few probes across the window; a single datagram can be dropped.
    for (var i = 0; i < 3; i++) {
      socket.send(probe, broadcast, kDiscoveryPort);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    await found.future.timeout(timeout, onTimeout: () {});
  } on SocketException {
    // No usable network interface; return whatever (if anything) replied.
  } finally {
    socket?.close();
  }
  return results.values.toList(growable: false);
}

/// The device's primary private IPv4 address, used to build stream URLs that
/// peers on the LAN can reach. Returns null if no such interface exists.
Future<String?> localIPv4() async {
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    // Prefer addresses in the common private ranges (a machine can have
    // several interfaces — VPNs, virtual adapters — and only LAN ones work).
    for (final wantPrivate in [true, false]) {
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.isLoopback) continue;
          if (_isPrivateV4(addr.address) == wantPrivate) return addr.address;
        }
      }
    }
  } on OSError {
    // Interface enumeration can fail on locked-down configs.
  }
  return null;
}

bool _isPrivateV4(String ip) {
  if (ip.startsWith('192.168.') || ip.startsWith('10.')) return true;
  if (ip.startsWith('172.')) {
    final second = int.tryParse(ip.split('.')[1]) ?? 0;
    return second >= 16 && second <= 31;
  }
  return false;
}
