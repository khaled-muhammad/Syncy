import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:get/get.dart';
import 'package:syncy/constants/app_constants.dart';
import 'package:syncy/models/message.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

typedef WebSocketConnector = WebSocketChannel Function(Uri uri);

class ReliableWebSocketService extends GetxService {
  ReliableWebSocketService({WebSocketConnector? connector})
    : _connector = connector ?? ((uri) => WebSocketChannel.connect(uri));

  final WebSocketConnector _connector;
  final RxList<Message> messages = <Message>[].obs;
  final RxBool isConnected = false.obs;
  final RxBool isJoined = false.obs;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Future<void>? _connectionAttempt;
  Timer? _heartbeatTimer;
  Timer? _retryTimer;
  Timer? _reconnectTimer;
  DateTime? _lastReceivedAt;
  int _generation = 0;
  int _reconnectAttempt = 0;
  bool _shouldReconnect = false;
  bool _closed = false;

  String? _roomId;
  String? _userId;
  String? _userName;
  Completer<void>? _joinCompleter;
  final Map<String, Message> _pending = {};

  void Function(Message message)? _onReceive;
  void Function()? _onConnected;
  void Function()? _onDisconnected;
  void Function(String error)? _onError;

  void setReceiveMsgFunction(void Function(Message message) callback) {
    _onReceive = callback;
  }

  void setConnectionCallbacks({
    void Function()? onConnected,
    void Function()? onDisconnected,
    void Function(String error)? onError,
  }) {
    _onConnected = onConnected;
    _onDisconnected = onDisconnected;
    _onError = onError;
  }

  Future<void> joinRoom(String roomId, String userId, String userName) async {
    final roomChanged = _roomId != null && _roomId != roomId;
    if (roomChanged) {
      ++_generation;
      await _disposeTransport();
      isConnected.value = false;
      isJoined.value = false;
    }
    _roomId = roomId;
    _userId = userId;
    _userName = userName;
    _shouldReconnect = true;
    _closed = false;
    await _ensureConnection();
    await _joinCurrentSocket();
  }

  Future<void> _ensureConnection() {
    if (isConnected.value && _channel != null) return Future.value();
    return _connectionAttempt ??= _connect().whenComplete(() {
      _connectionAttempt = null;
    });
  }

  Future<void> _connect() async {
    final roomId = _roomId;
    if (roomId == null || !_shouldReconnect) return;
    final generation = ++_generation;
    await _disposeTransport();
    isConnected.value = false;
    isJoined.value = false;

    try {
      final channel = _connector(
        Uri.parse('${AppConstants.wssBaseUrl}/room/$roomId/'),
      );
      _channel = channel;
      _subscription = channel.stream.listen(
        (data) => _handleMessage(generation, data),
        onError: (Object error, StackTrace stack) {
          _handleTransportFailure(generation, 'WebSocket error: $error');
        },
        onDone: () {
          _handleTransportFailure(generation, 'WebSocket connection closed');
        },
        cancelOnError: false,
      );
      await channel.ready.timeout(const Duration(seconds: 10));
      if (generation != _generation || _channel != channel) return;
      isConnected.value = true;
      _lastReceivedAt = DateTime.now();
      _startHeartbeat(generation);
    } catch (error) {
      if (generation == _generation) {
        _handleTransportFailure(generation, 'Connection failed: $error');
      }
      rethrow;
    }
  }

  Future<void> _joinCurrentSocket() async {
    if (!isConnected.value || _channel == null) {
      throw StateError('WebSocket transport is not connected');
    }
    final roomId = _roomId;
    final userId = _userId;
    final userName = _userName;
    if (roomId == null || userId == null || userName == null) {
      throw StateError('Room identity is incomplete');
    }

    _joinCompleter = Completer<void>();
    _sendNow(
      Message.joinRoom(roomId: roomId, userId: userId, userName: userName),
    );
    await _joinCompleter!.future.timeout(const Duration(seconds: 10));
  }

  void _handleMessage(int generation, dynamic raw) {
    if (generation != _generation) return;
    _lastReceivedAt = DateTime.now();
    try {
      final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
      if (decoded['type'] == 'ack') {
        final eventId = decoded['data']?['eventId']?.toString();
        if (eventId != null) _pending.remove(eventId);
        return;
      }
      final message = Message.fromJson(decoded);
      if (message.type == MessageType.heartbeat) return;

      if (message.type == MessageType.error && !isJoined.value) {
        final completer = _joinCompleter;
        if (completer != null && !completer.isCompleted) {
          completer.completeError(
            StateError(message.data['error']?.toString() ?? 'Join failed'),
          );
        }
      }

      if (message.type == MessageType.roomUpdate) {
        final wasJoined = isJoined.value;
        isJoined.value = true;
        _reconnectAttempt = 0;
        final completer = _joinCompleter;
        if (completer != null && !completer.isCompleted) completer.complete();
        if (!wasJoined) _onConnected?.call();
        _flushPending();
        _startRetryTimer();
      }
      messages.add(message);
      _onReceive?.call(message);
    } catch (error) {
      _onError?.call('Invalid server message: $error');
    }
  }

  void _handleTransportFailure(int generation, String reason) {
    if (generation != _generation) return;
    final wasActive = isConnected.value || isJoined.value;
    isConnected.value = false;
    isJoined.value = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    final completer = _joinCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(StateError(reason));
    }
    if (wasActive) _onDisconnected?.call();
    _onError?.call(reason);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect ||
        _closed ||
        _roomId == null ||
        _reconnectTimer != null) {
      return;
    }
    final exponent = min(_reconnectAttempt, 5);
    final baseMs = 1000 * (1 << exponent);
    final jitterMs = Random().nextInt(max(1, baseMs ~/ 3));
    _reconnectAttempt++;
    _reconnectTimer = Timer(
      Duration(milliseconds: baseMs + jitterMs),
      () async {
        _reconnectTimer = null;
        try {
          await _ensureConnection();
          await _joinCurrentSocket();
        } catch (error) {
          developer.log('Reconnect attempt failed: $error');
          _scheduleReconnect();
        }
      },
    );
  }

  void _startHeartbeat(int generation) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (generation != _generation || !isConnected.value) return;
      if (_lastReceivedAt == null ||
          DateTime.now().difference(_lastReceivedAt!) >
              const Duration(seconds: 45)) {
        _handleTransportFailure(generation, 'Heartbeat timed out');
        unawaited(_channel?.sink.close(status.normalClosure));
        return;
      }
      final roomId = _roomId;
      final userId = _userId;
      if (roomId != null && userId != null) {
        _sendNow(
          Message(
            type: MessageType.heartbeat,
            roomId: roomId,
            userId: userId,
            data: const {},
          ),
        );
      }
    });
  }

  Future<void> _sendReliable(
    Message message, {
    bool coalescePlayback = false,
  }) async {
    if (coalescePlayback) {
      _pending.removeWhere(
        (_, value) =>
            value.type == MessageType.play ||
            value.type == MessageType.pause ||
            value.type == MessageType.seek,
      );
    }
    _pending[message.eventId] = message;
    if (isJoined.value) _sendNow(message);
  }

  void _sendNow(Message message) {
    final channel = _channel;
    if (channel == null || !isConnected.value) return;
    try {
      channel.sink.add(jsonEncode(message.toJson()));
    } catch (error) {
      _handleTransportFailure(_generation, 'Send failed: $error');
    }
  }

  void _flushPending() {
    for (final message in List<Message>.of(_pending.values)) {
      _sendNow(message);
    }
  }

  void _startRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (isJoined.value && _pending.isNotEmpty) _flushPending();
    });
  }

  Future<void> playVideo(String roomId, String userId, Duration position) =>
      _sendReliable(
        Message.play(roomId: roomId, userId: userId, position: position),
        coalescePlayback: true,
      );

  Future<void> pauseVideo(String roomId, String userId, Duration position) =>
      _sendReliable(
        Message.pause(roomId: roomId, userId: userId, position: position),
        coalescePlayback: true,
      );

  Future<void> seekVideo(String roomId, String userId, Duration position) =>
      _sendReliable(
        Message.seek(roomId: roomId, userId: userId, position: position),
        coalescePlayback: true,
      );

  Future<void> changeVideo(String roomId, String userId, String videoTitle) =>
      _sendReliable(
        Message.videoChanged(
          roomId: roomId,
          userId: userId,
          videoTitle: videoTitle,
        ),
        coalescePlayback: true,
      );

  Future<void> sendChat(
    String roomId,
    String userId,
    String userName,
    String text,
  ) => _sendReliable(
    Message.chat(
      roomId: roomId,
      userId: userId,
      userName: userName,
      message: text,
    ),
  );

  Future<void> sendReaction(
    String roomId,
    String userId,
    String userName,
    String emoji,
  ) async {
    if (!isJoined.value) return;
    _sendNow(
      Message.reaction(
        roomId: roomId,
        userId: userId,
        userName: userName,
        emoji: emoji,
      ),
    );
  }

  Future<void> leaveRoom(String roomId, String userId) async {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    if (isJoined.value) {
      _sendNow(Message.leaveRoom(roomId: roomId, userId: userId));
    }
    await disconnect();
  }

  Future<void> _disposeTransport() async {
    final subscription = _subscription;
    final channel = _channel;
    _subscription = null;
    _channel = null;
    if (subscription != null) await subscription.cancel();
    if (channel != null) {
      try {
        await channel.sink.close(status.normalClosure);
      } catch (_) {}
    }
  }

  Future<void> disconnect() async {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    ++_generation;
    isConnected.value = false;
    isJoined.value = false;
    await _disposeTransport();
    _roomId = _userId = _userName = null;
    _pending.clear();
  }

  @override
  void onClose() {
    _closed = true;
    unawaited(disconnect());
    super.onClose();
  }
}
