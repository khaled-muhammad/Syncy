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

class RoomController extends GetxController {
  final realm = Get.find<Realm>();
  User get user => realm.all<User>().first;
  String _uuid = const u.Uuid().v4();

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
      }
    });
  }

  setMedia(Media media) {
    room.value.currentVideoUrl = media.path;
  }

  Future createRoom(String roomName, {Media? mediaItem}) async {
    final res = await AppConstants.dio.post('/rooms/create/', data: {
      'room_name': roomName,
      'user_name': user.name,
    });

    if (res.data['status'] == 'success') {
      showTopSnackBar(Overlay.of(Get.overlayContext!), CustomSnackBar.success(message: res.data['message']));
      room.value = Room.fromJson(res.data['room']);
      if (mediaItem != null) {
        room.value.currentVideoUrl = mediaItem.path;
        room.value.currentVideoTitle = mediaItem.name;
      }
      _uuid = res.data['user']['id'];
      await wsService.joinRoom(
          room.value.id, _uuid, user.name);

      Get.toNamed(Routes.ROOM);
    } else {
      showTopSnackBar(Overlay.of(Get.overlayContext!), CustomSnackBar.error(message: res.data['message']));
    }
  }

  Future joinRoom(String roomId) async {
    final res = await AppConstants.dio.post('/rooms/join/', data: {
      'room_id': roomId,
      'user_name': user.name,
    });

    if (res.data['status'] == 'success') {
      showTopSnackBar(Overlay.of(Get.overlayContext!), CustomSnackBar.success(message: res.data['message']));
      room.value = Room.fromJson(res.data['room']);
      print(res.data['users']);
      await wsService.joinRoom(
          room.value.id, _uuid, user.name);
      Get.toNamed(Routes.ROOM);
    } else {
      showTopSnackBar(Overlay.of(Get.overlayContext!), CustomSnackBar.error(message: res.data['message'] ?? 'Failed to join room'));
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

    await wsService.playVideo(
        room.value.id, _uuid, position ?? Duration.zero);
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

    await wsService.pauseVideo(
        room.value.id, _uuid, position ?? Duration.zero);
  }

  Future<void> seekVideo(Duration position) async {
    if (room.value.id == '') return;

    room.value = room.value.copyWith(currentPosition: position);

    await wsService.seekVideo(
        room.value.id, _uuid, position);
  }

  Future<void> leaveRoom() async {
    if (room.value.id == '') return;

    try {
      await wsService.leaveRoom(room.value.id, _uuid);

      await AppConstants.dio.delete(
        '/rooms/${room.value.id}/leave/',
        data: {
          'user_id': _uuid,
        },
      );

      room.value = Room(createdAt: DateTime.now(), id: '', name: '', hostId: '');
    } catch (e) {
      room.value = Room(createdAt: DateTime.now(), id: '', name: '', hostId: '');
    }
  }


  Duration _parseDuration(dynamic durationValue) {
    if (durationValue == null) return Duration.zero;

    if (durationValue is String) {
      // Parse HH:MM:SS format
      final parts = durationValue.split(':');
      if (parts.length == 3) {
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts[1]) ?? 0;
        final seconds = int.tryParse(parts[2]) ?? 0;
        return Duration(hours: hours, minutes: minutes, seconds: seconds);
      }
    }

    // Fallback to seconds if it's a number
    if (durationValue is int) {
      return Duration(seconds: durationValue);
    }

    if (durationValue is double) {
      return Duration(seconds: durationValue.round());
    }

    return Duration.zero;
  }
}