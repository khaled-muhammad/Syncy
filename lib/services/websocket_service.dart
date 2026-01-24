import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:syncy/constants/app_constants.dart';
import 'package:syncy/models/message.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService extends GetxService {
  WebSocketChannel? _channel;
  RxList<Message> messages = <Message>[].obs;
  RxBool isConnected = false.obs;
  String? _currentRoomId;
  String? _currentUserId;
  String? _currentUserName;
  Timer? _heartbeatTimer;
  DateTime? _lastHeartbeat;
  static const int _heartbeatInterval = 30; // seconds
  static const int _heartbeatTimeout = 60; // seconds
  Timer? _reconnectTimer;
  bool _shouldReconnect = false;
  static const int _reconnectInterval = 5; // seconds

  Function(Message msg)? _onReceiveMsg;
  Function()? _onConnected;
  Function()? _onDisconnected;
  Function(String error)? _onError;

  void setReceiveMsgFunction(Function(Message msg) function) {
    _onReceiveMsg = function;
  }

  void setConnectionCallbacks({
    Function()? onConnected,
    Function()? onDisconnected,
    Function(String error)? onError,
  }) {
    _onConnected = onConnected;
    _onDisconnected = onDisconnected;
    _onError = onError;
  }

  Future<void> connect(String roomId) async {
    log('🔌 Attempting to connect to room: $roomId');
    _currentRoomId = roomId;

    try {
      if (_channel != null) {
        await _safeDisconnect();
      }

      final wsUrl = "${AppConstants.wssBaseUrl}/room/$roomId/";
      log('🌐 WebSocket URL: $wsUrl');

      _channel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
        protocols: ['websocket'],
      );

      _channel!.stream.listen(
        _handleMessage,
        onError: _handleStreamError,
        onDone: _handleStreamClosed,
        cancelOnError: false,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      if (_channel != null) {
        _onConnectionSuccess();
      }
    } catch (e) {
      log('❌ WebSocket connection failed: $e');
      _handleConnectionError(e.toString());
    }
  }

  void _handleMessage(dynamic data) {
    try {
      _lastHeartbeat = DateTime.now();
      log('📨 Received message: $data');

      final messageData = jsonDecode(data) as Map<String, dynamic>;
      final message = Message.fromJson(messageData);

      log('✅ Parsed message: type=${message.type}, data=${message.data}');
      messages.add(message);

      if (_onReceiveMsg != null) {
        _onReceiveMsg!(message);
      }
    } catch (e) {
      log('❌ Error parsing WebSocket message: $e');
      _onError?.call('Message parsing error: $e');
    }
  }

  void _handleStreamError(dynamic error) {
    log('❌ WebSocket stream error: $error');
    _handleConnectionError('Stream error: $error');
  }

  void _handleStreamClosed() {
    log('🔌 WebSocket stream closed');
    _handleConnectionLost();
  }

  void _onConnectionSuccess() {
    log('✅ WebSocket connected successfully');
    isConnected.value = true;
    _lastHeartbeat = DateTime.now();

    _startHeartbeat();
    _onConnected?.call();
    // Auto rejoin if needed
    if (_shouldReconnect &&
        _currentRoomId != null &&
        _currentUserId != null &&
        _currentUserName != null) {
      final joinMsg = Message.joinRoom(
        roomId: _currentRoomId!,
        userId: _currentUserId!,
        userName: _currentUserName!,
      );
      sendMessage(joinMsg);
      log('✅ Rejoin room message sent');
    }
  }

  void _handleConnectionError(String error) {
    log('❌ Connection error: $error');
    isConnected.value = false;
    _onError?.call(error);
    // Schedule auto reconnect
    _scheduleReconnect();
  }

  void _handleConnectionLost() {
    log('📡 Connection lost');
    isConnected.value = false;
    _stopHeartbeat();
    _onDisconnected?.call();
    // Schedule auto reconnect
    _scheduleReconnect();
  }

  void _startHeartbeat() {
    _stopHeartbeat();

    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: _heartbeatInterval),
      (timer) {
        if (!isConnected.value ||
            _currentRoomId == null ||
            _currentUserId == null) {
          return;
        }

        // Check if we've received a message recently
        if (_lastHeartbeat != null &&
            DateTime.now().difference(_lastHeartbeat!).inSeconds >
                _heartbeatTimeout) {
          log('💔 Heartbeat timeout - connection appears dead');
          _handleConnectionLost();
          return;
        }

        // Send heartbeat
        sendHeartbeat(_currentRoomId!, _currentUserId!);
      },
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // Add auto reconnect scheduler
  void _scheduleReconnect() {
    if (!_shouldReconnect || _currentRoomId == null) return;
    if (_reconnectTimer != null) return;
    log('🔄 Scheduling reconnect in $_reconnectInterval seconds');
    _reconnectTimer = Timer(Duration(seconds: _reconnectInterval), () {
      _reconnectTimer = null;
      log('🔌 Attempting to reconnect to room: $_currentRoomId');
      connect(_currentRoomId!);
    });
  }

  Future<void> joinRoom(String roomId, String userId, String userName) async {
    log('🚪 Joining room: $roomId as $userName ($userId)');
    // Enable auto reconnect
    _shouldReconnect = true;
    _currentRoomId = roomId;
    _currentUserId = userId;
    _currentUserName = userName;

    if (!isConnected.value) {
      await connect(roomId);
    }

    // Wait for connection before sending join message
    int attempts = 0;
    while (!isConnected.value && attempts < 50) {
      // 5 seconds max wait
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (isConnected.value) {
      final message = Message.joinRoom(
        roomId: roomId,
        userId: userId,
        userName: userName,
      );
      await sendMessage(message);
      log('✅ Join room message sent');
    } else {
      log('❌ Failed to join room - not connected');
      throw Exception('Failed to connect to room');
    }
  }

  Future<void> leaveRoom(String roomId, String userId) async {
    log('🚪 Leaving room: $roomId');
    // Disable auto reconnect
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    if (isConnected.value) {
      final message = Message.leaveRoom(roomId: roomId, userId: userId);
      await sendMessage(message);
    }

    await disconnect();
  }

  Future<void> playVideo(
    String roomId,
    String userId,
    Duration position,
  ) async {
    log(
      '▶️ Play video - roomId: $roomId, userId: $userId, position: ${position.inSeconds}s',
    );

    if (!_ensureConnected()) return;

    final message = Message.play(
      roomId: roomId,
      userId: userId,
      position: position,
    );
    log('▶️ Play message: ${message.toJson()}');
    await sendMessage(message);
  }

  Future<void> pauseVideo(
    String roomId,
    String userId,
    Duration position,
  ) async {
    log(
      '⏸️ Pause video - roomId: $roomId, userId: $userId, position: ${position.inSeconds}s',
    );

    if (!_ensureConnected()) return;

    final message = Message.pause(
      roomId: roomId,
      userId: userId,
      position: position,
    );
    log('⏸️ Pause message: ${message.toJson()}');
    await sendMessage(message);
  }

  Future<void> seekVideo(
    String roomId,
    String userId,
    Duration position,
  ) async {
    log('⏩ Seek video - position: ${position.inSeconds}s');

    if (!_ensureConnected()) return;

    final message = Message.seek(
      roomId: roomId,
      userId: userId,
      position: position,
    );
    await sendMessage(message);
  }

  Future<void> sendHeartbeat(String roomId, String userId) async {
    if (!isConnected.value) return;

    final message = Message(
      type: MessageType.heartbeat,
      roomId: roomId,
      userId: userId,
      data: {'timestamp': DateTime.now().millisecondsSinceEpoch},
    );
    await sendMessage(message);
  }

  Future<void> sendChat(
    String roomId,
    String userId,
    String userName,
    String messageText,
  ) async {
    if (!_ensureConnected()) return;

    final message = Message.chat(
      roomId: roomId,
      userId: userId,
      userName: userName,
      message: messageText,
    );
    await sendMessage(message);
  }

  Future<void> sendReaction(
    String roomId,
    String userId,
    String userName,
    String emoji,
  ) async {
    if (!_ensureConnected()) return;

    final message = Message.reaction(
      roomId: roomId,
      userId: userId,
      userName: userName,
      emoji: emoji,
    );
    await sendMessage(message);
  }

  bool _ensureConnected() {
    if (!isConnected.value) {
      log('⚠️ Not connected');
      return false;
    }
    return true;
  }

  Future<void> sendMessage(Message message) async {
    if (_channel == null || !isConnected.value) {
      log('❌ Cannot send message - WebSocket not connected');
      return;
    }

    try {
      final messageJson = jsonEncode(message.toJson());
      log('📤 Sending: $messageJson');

      _channel!.sink.add(messageJson);
      log('✅ Message sent successfully');
    } catch (e) {
      log('❌ Error sending message: $e');
      _handleConnectionError('Send error: $e');
    }
  }

  Future<void> _safeDisconnect() async {
    if (_channel != null) {
      try {
        await _channel!.sink.close(status.goingAway);
      } catch (e) {
        log('⚠️ Error during safe disconnect: $e');
      }
      _channel = null;
    }
  }

  Future<void> disconnect() async {
    log('🔌 Disconnecting WebSocket');
    // Disable auto reconnect
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _stopHeartbeat();
    isConnected.value = false;

    await _safeDisconnect();

    // Clear connection info
    _currentRoomId = null;
    _currentUserId = null;
    _currentUserName = null;
    _lastHeartbeat = null;

    log('✅ WebSocket disconnected');
  }

  // Get connection health info
  Map<String, dynamic> getConnectionInfo() {
    return {
      'isConnected': isConnected.value,
      'currentRoom': _currentRoomId,
      'lastHeartbeat': _lastHeartbeat?.toIso8601String(),
    };
  }

  @override
  void onClose() {
    log('🛑 WebSocketService closing');
    disconnect();
    super.onClose();
  }
}
