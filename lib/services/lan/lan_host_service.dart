import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart' hide Response;
import 'package:isar_community/isar.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:syncy/constants/app_constants.dart';
import 'package:syncy/models/media.dart';
import 'package:syncy/services/lan/lan_discovery.dart';
import 'package:syncy/services/lan/pairing_store.dart';

/// Runs the desktop's LAN media host: an authenticated HTTP server that lists
/// the indexed library and streams files (with HTTP range support) to paired
/// phones, plus a UDP responder so phones can find it.
///
/// Playback sync still flows through the cloud backend; only the video bytes
/// travel over the LAN through this server.
class LanHostService extends GetxService {
  static LanHostService get to => Get.find<LanHostService>();

  static const int _preferredPort = 8770;

  final Isar _isar = Get.find<Isar>();
  final LanDiscoveryResponder _discovery = LanDiscoveryResponder();

  late final PairingStore _pairing;
  HttpServer? _server;

  /// The one-time pairing code currently shown on screen. Observable so the
  /// pairing UI updates when it rotates after a successful pair.
  final code = ''.obs;
  final isRunning = false.obs;
  final RxnString lanIp = RxnString();
  final RxInt port = 0.obs;

  String _deviceId = '';
  String _deviceName = '';

  /// Media-scoped stream tokens: token -> (mediaId, expiry). These authorize
  /// streaming exactly one file for a while, so a room's stream URL can be
  /// shared with peers without leaking a device's full-access pairing token.
  final Map<String, _StreamGrant> _streamTokens = {};

  String get deviceName => _deviceName;

  Future<LanHostService> start() async {
    _pairing = await PairingStore.open();
    _deviceId = _pairing.deviceId();
    _deviceName = _pairing.deviceName();
    code.value = PairingStore.generateCode();
    lanIp.value = await localIPv4();

    await _bindServer();

    if (_server != null) {
      port.value = _server!.port;
      isRunning.value = true;
      await _discovery.start(
        deviceId: _deviceId,
        name: _deviceName,
        httpPort: _server!.port,
      );
    }
    return this;
  }

  /// Binds the HTTP server, walking a few ports so a busy [_preferredPort]
  /// (e.g. a second instance) does not stop hosting entirely.
  Future<void> _bindServer() async {
    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(_router.call);
    for (var p = _preferredPort; p < _preferredPort + 8; p++) {
      try {
        _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, p);
        return;
      } on SocketException {
        // Port in use — try the next one.
      }
    }
  }

  Router get _router => Router()
    ..get('/info', _info)
    ..post('/pair', _pair)
    ..post('/stream-token', _streamToken)
    ..get('/library', _library)
    ..get('/thumb/<id>', _thumb)
    ..get('/media/<id>', _media);

  /// Regenerates the visible pairing code (e.g. user taps "new code").
  void refreshCode() => code.value = PairingStore.generateCode();

  List<Map<String, dynamic>> pairedDevices() => _pairing.hostPairings();

  Future<void> revoke(String deviceId) => _pairing.revokeHostPairing(deviceId);

  /// Builds a stream URL for [mediaId] that any LAN peer in a room can open.
  /// Returns null if the host has no reachable LAN address.
  String? streamUrlForMedia(int mediaId) {
    final ip = lanIp.value;
    final p = port.value;
    if (ip == null || p == 0) return null;
    final token = _mintStreamToken(mediaId);
    return 'http://$ip:$p/media/$mediaId?t=$token';
  }

  String _mintStreamToken(int mediaId) {
    final token = PairingStore.generateToken();
    _streamTokens[token] = _StreamGrant(
      mediaId,
      DateTime.now().add(const Duration(hours: 12)),
    );
    return token;
  }

  // --- request handlers -----------------------------------------------------

  Response _info(Request request) {
    return _json({
      'deviceId': _deviceId,
      'name': _deviceName,
      'appVersion': AppConstants.appVersion,
      'needsPairing': true,
    });
  }

  Future<Response> _pair(Request request) async {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return Response.badRequest(body: 'Invalid request');
    }
    final providedCode = body['code']?.toString() ?? '';
    if (providedCode.isEmpty || providedCode != code.value) {
      return _json({'error': 'Incorrect or expired code'}, status: 401);
    }

    final token = PairingStore.generateToken();
    await _pairing.addHostPairing(
      token: token,
      deviceId: body['deviceId']?.toString() ?? token,
      deviceName: body['deviceName']?.toString() ?? 'Phone',
    );
    // The code is one-time: rotate it so a leaked code cannot be reused.
    refreshCode();

    return _json({'token': token, 'deviceId': _deviceId, 'name': _deviceName});
  }

  Future<Response> _streamToken(Request request) async {
    if (!_bearerValid(request)) return _unauthorized();
    Map<String, dynamic> body;
    try {
      body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return Response.badRequest(body: 'Invalid request');
    }
    final mediaId = (body['mediaId'] as num?)?.toInt();
    if (mediaId == null) return Response.badRequest(body: 'mediaId required');
    final url = streamUrlForMedia(mediaId);
    if (url == null) {
      return _json({'error': 'Host has no LAN address'}, status: 503);
    }
    return _json({'url': url});
  }

  Response _library(Request request) {
    if (!_bearerValid(request)) return _unauthorized();
    final items = _isar.medias.where().findAllSync().map((m) {
      int? size;
      try {
        final f = File(m.path);
        if (f.existsSync()) size = f.lengthSync();
      } catch (_) {}
      return {
        'id': m.id,
        'name': m.name,
        'folder': _folderOf(m.path),
        'sizeBytes': size,
        'hasThumbnail':
            m.thumbnailPath != null && m.thumbnailPath!.isNotEmpty,
      };
    }).toList();
    return _json({'media': items});
  }

  Future<Response> _thumb(Request request, String id) async {
    if (!_bearerValid(request)) return _unauthorized();
    final mediaId = int.tryParse(id);
    if (mediaId == null) return Response.notFound('bad id');
    final media = _isar.medias.getSync(mediaId);
    final path = media?.thumbnailPath;
    if (path == null || path.isEmpty) return Response.notFound('no thumbnail');
    final file = File(path);
    if (!file.existsSync()) return Response.notFound('no thumbnail');
    return Response.ok(
      file.openRead(),
      headers: {'content-type': 'image/jpeg'},
    );
  }

  /// Streams a media file, honoring HTTP Range so the player can seek.
  Future<Response> _media(Request request, String id) async {
    final mediaId = int.tryParse(id);
    if (mediaId == null) return Response.notFound('bad id');
    if (!_streamAuthValid(request, mediaId)) return _unauthorized();

    final media = _isar.medias.getSync(mediaId);
    if (media == null) return Response.notFound('no media');
    final file = File(media.path);
    if (!file.existsSync()) {
      return _json({'error': 'The host no longer has this file'}, status: 404);
    }

    final total = await file.length();
    final contentType = _contentTypeFor(media.path);
    final rangeHeader = request.headers['range'];

    if (rangeHeader == null) {
      return Response.ok(
        file.openRead(),
        headers: {
          'content-type': contentType,
          'content-length': '$total',
          'accept-ranges': 'bytes',
        },
      );
    }

    final range = computeByteRange(rangeHeader, total);
    if (range == null) {
      return Response(
        416, // Range Not Satisfiable
        headers: {'content-range': 'bytes */$total'},
        body: 'Range not satisfiable',
      );
    }

    return Response(
      206,
      body: file.openRead(range.start, range.end + 1),
      headers: {
        'content-type': contentType,
        'content-length': '${range.length}',
        'accept-ranges': 'bytes',
        'content-range': 'bytes ${range.start}-${range.end}/$total',
      },
    );
  }

  // --- auth helpers ---------------------------------------------------------

  bool _bearerValid(Request request) {
    final auth = request.headers['authorization'] ?? '';
    if (!auth.startsWith('Bearer ')) return false;
    return _pairing.isValidToken(auth.substring(7).trim());
  }

  bool _streamAuthValid(Request request, int mediaId) {
    // A media-scoped ?t= token (shared into rooms), or a full pairing token.
    final t = request.url.queryParameters['t'];
    if (t != null) {
      final grant = _streamTokens[t];
      if (grant != null &&
          grant.mediaId == mediaId &&
          grant.expiry.isAfter(DateTime.now())) {
        return true;
      }
    }
    return _bearerValid(request);
  }

  Response _unauthorized() => _json({'error': 'Unauthorized'}, status: 401);

  Response _json(Map<String, dynamic> data, {int status = 200}) => Response(
    status,
    body: jsonEncode(data),
    headers: {'content-type': 'application/json'},
  );

  String _folderOf(String path) {
    final unified = path.replaceAll('\\', '/');
    final parts = unified.split('/');
    return parts.length >= 2 ? parts[parts.length - 2] : '';
  }

  String _contentTypeFor(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'mp4':
      case 'm4v':
        return 'video/mp4';
      case 'webm':
        return 'video/webm';
      case 'mkv':
        return 'video/x-matroska';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'ts':
        return 'video/mp2t';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  void onClose() {
    _server?.close(force: true);
    _discovery.stop();
    super.onClose();
  }
}

class _StreamGrant {
  _StreamGrant(this.mediaId, this.expiry);
  final int mediaId;
  final DateTime expiry;
}

/// A resolved HTTP byte range, inclusive of both ends.
class ByteRange {
  const ByteRange(this.start, this.end);
  final int start;
  final int end;
  int get length => end - start + 1;
}

/// Resolves a `Range: bytes=…` header against a file of [total] bytes.
///
/// Handles `bytes=START-`, `bytes=START-END`, and suffix `bytes=-N` (last N
/// bytes). Returns null for malformed or unsatisfiable ranges, which the
/// caller answers with `416`. Kept a pure top-level function so the range math
/// — the part video seeking depends on — is unit-testable without a server.
ByteRange? computeByteRange(String header, int total) {
  if (total <= 0) return null;
  final match = RegExp(r'bytes=(\d*)-(\d*)').firstMatch(header);
  if (match == null) return null;
  final startStr = match.group(1) ?? '';
  final endStr = match.group(2) ?? '';
  if (startStr.isEmpty && endStr.isEmpty) return null;

  int start;
  int end;
  if (startStr.isEmpty) {
    // Suffix range: the final N bytes.
    final n = int.parse(endStr);
    if (n <= 0) return null;
    start = n >= total ? 0 : total - n;
    end = total - 1;
  } else {
    start = int.parse(startStr);
    end = endStr.isEmpty ? total - 1 : int.parse(endStr);
  }
  if (start < 0 || end >= total || start > end) return null;
  return ByteRange(start, end);
}
