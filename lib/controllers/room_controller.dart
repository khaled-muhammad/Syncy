import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncy/models/message.dart';
import 'package:uuid/uuid.dart' as u;
import 'package:isar_community/isar.dart';
import 'package:dio/dio.dart';
import 'package:syncy/constants/app_constants.dart';
import 'package:syncy/models/media.dart';
import 'package:syncy/models/room.dart';
import 'package:syncy/models/user.dart';
import 'package:syncy/routes/app_routes.dart';
import 'package:syncy/services/websocket_service.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';

class RoomUser {
  final String name;
  final bool online;
  final String id;

  const RoomUser({required this.id, required this.name, required this.online});
}

class RoomController extends GetxController {
  final isar = Get.find<Isar>();
  User get user => isar.users.where().findFirstSync() ?? User()
    ..name = 'Guest';
  String _uuid = const u.Uuid().v4();

  late RxList<RoomUser> users = <RoomUser>[].obs;

  // Chat messages
  RxList<Map<String, dynamic>> chatMessages = <Map<String, dynamic>>[].obs;

  // Floating reactions
  RxList<Map<String, dynamic>> floatingReactions = <Map<String, dynamic>>[].obs;

  Rx<Room> room = Room(
    id: '',
    name: '',
    hostId: '',
    currentVideoUrl: '',
    currentPosition: Duration.zero,
    isPlaying: false,
    createdAt: DateTime.now(),
  ).obs;

  WebSocketService wsService = WebSocketService();

  VideoPlayerController? videoController;

  // Add subtitle path storage
  Rx<String?> currentSubtitlePath = Rx<String?>(null);

  // Add subtitle delay in milliseconds (can be positive or negative)
  Rx<int> subtitleDelay = Rx<int>(0);

  // Callback for when subtitles change
  Function()? onSubtitleChanged;

  @override
  void onInit() {
    super.onInit();

    wsService.setReceiveMsgFunction((msg) {
      if (msg.type == MessageType.pause) {
        videoController?.pause();
        videoController?.seekTo(Duration(seconds: msg.data['position']));
      } else if (msg.type == MessageType.play) {
        videoController?.seekTo(Duration(seconds: msg.data['position']));
        videoController?.play();
      } else if (msg.type == MessageType.seek) {
        videoController?.seekTo(Duration(seconds: msg.data['position']));
      } else if (msg.type == MessageType.userJoined) {
        setUser(msg.data);
      } else if (msg.type == MessageType.userLeft) {
        print("LEFT");
        print(msg.data);
        final index = users.indexWhere((u) => u.id == msg.data['id']);
        if (index != -1) {
          users[index] = RoomUser(
            id: msg.data['id'],
            name: msg.data['name'],
            online: false,
          );
        }
      } else if (msg.type == MessageType.chat) {
        // Add chat message to list
        chatMessages.add({
          'message': msg.data['message'] ?? '',
          'userName': msg.data['userName'] ?? 'Unknown',
          'userId': msg.data['userId'] ?? '',
          'timestamp':
              msg.data['timestamp'] ?? DateTime.now().toIso8601String(),
        });
      } else if (msg.type == MessageType.reaction) {
        // Add floating reaction
        final reactionId = DateTime.now().millisecondsSinceEpoch.toString();
        floatingReactions.add({
          'id': reactionId,
          'emoji': msg.data['emoji'] ?? '❤️',
          'userName': msg.data['userName'] ?? 'Unknown',
        });
        // Auto-remove after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          floatingReactions.removeWhere((r) => r['id'] == reactionId);
        });
      }
    });
  }

  void setUser(Map data) {
    final index = users.indexWhere((u) => u.id == data['id']);
    if (index != -1) {
      users[index] = RoomUser(
        id: data['id'],
        name: data['name'],
        online: data['is_online'],
      );
    } else {
      users.add(
        RoomUser(id: data['id'], name: data['name'], online: data['is_online']),
      );
    }
  }

  setMedia(Media media) {
    room.value.currentVideoUrl = media.path;
    // Reset subtitle when changing media
    currentSubtitlePath.value = null;
  }

  // Add method to pick subtitle file
  Future<void> selectSubtitleFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['srt', 'vtt', 'sub', 'ass', 'ssa', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          currentSubtitlePath.value = file.path;
          print('Subtitle file selected: ${file.path}');

          // Notify listeners that subtitle changed
          if (onSubtitleChanged != null) {
            onSubtitleChanged!();
          }

          Get.snackbar(
            'Subtitle Selected',
            'Subtitle file loaded: ${file.name}',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to select subtitle file: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Method to clear subtitle
  void clearSubtitle() {
    currentSubtitlePath.value = null;

    // Notify listeners that subtitle changed
    if (onSubtitleChanged != null) {
      onSubtitleChanged!();
    }

    Get.snackbar(
      'Subtitle Cleared',
      'Subtitle has been removed',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

  // Method to set subtitle delay
  void setSubtitleDelay(int delayMs) {
    subtitleDelay.value = delayMs;

    // Notify listeners that subtitle settings changed
    if (onSubtitleChanged != null) {
      onSubtitleChanged!();
    }

    Get.snackbar(
      'Subtitle Delay',
      'Subtitle delay set to ${delayMs}ms',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  Future createRoom(String roomName, {Media? mediaItem}) async {
    try {
      final res = await AppConstants.dio.post(
        '/rooms/create/',
        data: {'room_name': roomName, 'user_name': user.name},
      );

      if (res.data['status'] == 'success') {
        Get.snackbar(
          'Success',
          res.data['message'],
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        room.value = Room.fromJson(res.data['room']);
        if (mediaItem != null) {
          room.value.currentVideoUrl = mediaItem.path;
          room.value.currentVideoTitle = mediaItem.name;
        }
        _uuid = res.data['user']['id'];
        await wsService.joinRoom(room.value.id, _uuid, user.name);

        Get.toNamed(Routes.ROOM);
      } else {
        Get.snackbar(
          'Error',
          res.data['message'],
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } on DioException catch (e) {
      final serverMessage =
          e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to create room';
      Get.snackbar(
        'Error',
        serverMessage,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Future joinRoom(String roomId) async {
    try {
      final res = await AppConstants.dio.post(
        '/rooms/join/',
        data: {'room_id': roomId, 'user_name': user.name},
      );

      if (res.data['status'] == 'success') {
        Get.snackbar(
          'Success',
          res.data['message'],
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        room.value = Room.fromJson(res.data['room']);
        for (Map user in res.data['room']['users']) {
          setUser(user);
        }

        await wsService.joinRoom(room.value.id, _uuid, user.name);
        Get.toNamed(Routes.ROOM);
      } else {
        Get.snackbar(
          'Error',
          res.data['message'] ?? 'Failed to join room',
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } on DioException catch (e) {
      final serverMessage =
          e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to join room';
      Get.snackbar(
        'Error',
        serverMessage,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Future<void> playVideo() async {
    Duration? position = await videoController?.position;
    print("played AT: ${position?.inSeconds}s");
    if (room.value.id == '') {
      print('playVideo blocked');
      return;
    }

    print('playVideo called - position: ${position?.inSeconds}s');

    room.value = room.value.copyWith(
      isPlaying: true,
      currentPosition: position,
    );

    await wsService.playVideo(room.value.id, _uuid, position ?? Duration.zero);
  }

  Future<void> pauseVideo() async {
    Duration? position = await videoController?.position;
    print("PAUSE AT: ${position?.inSeconds}s");
    if (room.value.id == '') {
      print('pauseVideo blocked');
      return;
    }

    print('pauseVideo called - position: ${position?.inSeconds}s');

    room.value = room.value.copyWith(
      isPlaying: false,
      currentPosition: position,
    );

    await wsService.pauseVideo(room.value.id, _uuid, position ?? Duration.zero);
  }

  Future<void> seekVideo(Duration position) async {
    if (room.value.id == '') return;

    room.value = room.value.copyWith(currentPosition: position);

    await wsService.seekVideo(room.value.id, _uuid, position);
  }

  Future<void> leaveRoom() async {
    if (room.value.id == '') return;

    try {
      await wsService.leaveRoom(room.value.id, _uuid);

      await AppConstants.dio.delete(
        '/rooms/${room.value.id}/leave/',
        data: {'user_id': _uuid},
      );

      users.clear();
      chatMessages.clear();
      floatingReactions.clear();
      room.value = Room(
        createdAt: DateTime.now(),
        id: '',
        name: '',
        hostId: '',
      );
    } catch (e) {
      room.value = Room(
        createdAt: DateTime.now(),
        id: '',
        name: '',
        hostId: '',
      );
    }
  }

  // Send chat message
  Future<void> sendChatMessage(String messageText) async {
    if (room.value.id == '' || messageText.trim().isEmpty) return;
    await wsService.sendChat(
      room.value.id,
      _uuid,
      user.name,
      messageText.trim(),
    );
  }

  // Send reaction
  Future<void> sendReaction(String emoji) async {
    if (room.value.id == '') return;
    await wsService.sendReaction(room.value.id, _uuid, user.name, emoji);
  }
}
