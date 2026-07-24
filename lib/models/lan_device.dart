/// A Syncy PC host discovered on (or paired over) the local network.
///
/// [deviceId] is the stable identity of the host — it survives IP changes, so
/// a stored pairing is re-resolved to the current [host]/[port] at connect
/// time rather than trusting a possibly-stale address.
class LanDevice {
  const LanDevice({
    required this.deviceId,
    required this.name,
    required this.host,
    required this.port,
    this.token,
  });

  final String deviceId;
  final String name;
  final String host;
  final int port;

  /// The persistent pairing token, present once this device has been paired.
  final String? token;

  bool get isPaired => token != null && token!.isNotEmpty;

  String get baseUrl => 'http://$host:$port';

  LanDevice copyWith({String? host, int? port, String? token, String? name}) {
    return LanDevice(
      deviceId: deviceId,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      token: token ?? this.token,
    );
  }

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'name': name,
    'host': host,
    'port': port,
    'token': token,
  };

  factory LanDevice.fromJson(Map<String, dynamic> json) {
    return LanDevice(
      deviceId: json['deviceId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'PC',
      host: json['host']?.toString() ?? '',
      port: (json['port'] as num?)?.toInt() ?? 0,
      token: json['token']?.toString(),
    );
  }
}
