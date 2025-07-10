import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:syncy/models/message.dart';
import 'package:uuid/uuid.dart' as u;
import 'package:realm/realm.dart';
import 'package:syncy/constants/app_constants.dart';
import 'package:syncy/models/media.dart';
import 'package:syncy/models/room.dart';
import 'package:syncy/models/user.dart';
import 'package:syncy/routes/app_routes.dart';
import 'package:syncy/services/websocket_service.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';

class RoomUser {
  final String name;
  final bool online;
  final String id;

  const RoomUser({required this.id, required this.name, required this.online});
}

class RoomController extends GetxController {
  final realm = Get.find<Realm>();
  User get user => realm.all<User>().first;
  String _uuid = const u.Uuid().v4();

  late RxList<RoomUser> users = <RoomUser>[].obs;

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
        RoomUser(
          id: data['id'],
          name: data['name'],
          online: data['is_online'],
        ),
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
    final res = await AppConstants.dio.post(
      '/rooms/create/',
      data: {'room_name': roomName, 'user_name': user.name},
    );

    if (res.data['status'] == 'success') {
      showTopSnackBar(
        Overlay.of(Get.overlayContext!),
        CustomSnackBar.success(message: res.data['message']),
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
      showTopSnackBar(
        Overlay.of(Get.overlayContext!),
        CustomSnackBar.error(message: res.data['message']),
      );
    }
  }

  Future joinRoom(String roomId) async {
    final res = await AppConstants.dio.post(
      '/rooms/join/',
      data: {'room_id': roomId, 'user_name': user.name},
    );

    if (res.data['status'] == 'success') {
      showTopSnackBar(
        Overlay.of(Get.overlayContext!),
        CustomSnackBar.success(message: res.data['message']),
      );
      room.value = Room.fromJson(res.data['room']);
      for (Map user in res.data['room']['users']) {
        setUser(user);
      }

      await wsService.joinRoom(room.value.id, _uuid, user.name);
      Get.toNamed(Routes.ROOM);
    } else {
      showTopSnackBar(
        Overlay.of(Get.overlayContext!),
        CustomSnackBar.error(
          message: res.data['message'] ?? 'Failed to join room',
        ),
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
}
