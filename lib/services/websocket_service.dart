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

  Function(Message msg)? _onReceiveMsg;

  void setReceiveMsgFunction(Function(Message msg) function) {
    _onReceiveMsg = function;
  }

  Future<void> connect(String roomId) async {
    try {
      if (_channel != null) {
        await disconnect();
      }

      final wsUrl = "${AppConstants.wssBaseUrl}/room/$roomId/";
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        (data) {
          try {
            log('MSG: $data');
            final messageData = jsonDecode(data) as Map<String, dynamic>;
            final message = Message.fromJson(messageData);
            log('PARSED MSG: type=${message.type}, data=${message.data}');
            messages.add(message);
            if (_onReceiveMsg != null) {
              _onReceiveMsg!(message);
            }
          } catch (e) {
            log('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          log('WebSocket error: $error');
          _handleConnectionError(roomId);
        },
        onDone: () {
          log('WebSocket connection closed');
          _handleConnectionClosed();
        },
      );

      log('WebSocket connected successfully to room: $roomId');
    } catch (e) {
      log('WebSocket connection failed: $e');
      _handleConnectionError(roomId);
    }
  }

  Future<void> joinRoom(String roomId, String userId, String userName) async {
    await connect(roomId);

    final message = Message.joinRoom(
      roomId: roomId,
      userId: userId,
      userName: userName,
    );
    await sendMessage(message);
  }

  Future<void> leaveRoom(String roomId, String userId) async {
    final message = Message.leaveRoom(
      roomId: roomId,
      userId: userId,
    );
    await sendMessage(message);
    await disconnect();
  }

  Future<void> playVideo(
      String roomId, String userId, Duration position) async {
    log('PLAY VIDEO - roomId: $roomId, userId: $userId, position: ${position.inSeconds}s');
    final message = Message.play(
      roomId: roomId,
      userId: userId,
      position: position,
    );
    log('PLAY MESSAGE: ${message.toJson()}');
    await sendMessage(message);
  }

  Future<void> pauseVideo(
      String roomId, String userId, Duration position) async {
    log('⏸PAUSE VIDEO - roomId: $roomId, userId: $userId, position: ${position.inSeconds}s');
    final message = Message.pause(
      roomId: roomId,
      userId: userId,
      position: position,
    );
    log('⏸PAUSE MESSAGE: ${message.toJson()}');
    await sendMessage(message);
  }

  Future<void> seekVideo(
      String roomId, String userId, Duration position) async {
    final message = Message.seek(
      roomId: roomId,
      userId: userId,
      position: position,
    );
    await sendMessage(message);
  }

  Future<void> sendHeartbeat(String roomId, String userId) async {
    final message = Message(
      type: MessageType.heartbeat,
      roomId: roomId,
      userId: userId,
      data: {'timestamp': DateTime.now().millisecondsSinceEpoch},
    );
    await sendMessage(message);
  }

  Future<void> sendMessage(Message message) async {
    if (_channel == null) {
      log('WebSocket XXXXXXXX');
      return;
    }

    try {
      final messageJson = jsonEncode(message.toJson());
      log('Sending: $messageJson');

      _channel!.sink.add(messageJson);
      log('MSG SUCCESS');
    } catch (e) {
      log('ERR: $e');
    }
  }

  void _handleConnectionError(String roomId) {
    log('WebSocket connection error occurred');
    _channel = null;

    Future.delayed(const Duration(seconds: 5), () {
      if (!isConnected.value) {
        log('Attempting to reconnect to WebSocket...');
        connect(roomId);
      }
    });
  }

  void _handleConnectionClosed() {
    _channel = null;
    log('WebSocket connection was closed');
  }

  Future<void> disconnect() async {
    if (_channel != null) {
      try {
        await _channel!.sink.close(status.goingAway);
      } catch (e) {
        log('Error closing WebSocket connection: $e');
      }
      _channel = null;
      log('WebSocket disconnected');
    }
  }
}