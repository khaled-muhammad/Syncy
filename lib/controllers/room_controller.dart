import 'dart:async';

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
import 'package:syncy/services/reliable_websocket_service.dart';
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

  User get user {
    final existingUser = isar.users.where().findFirstSync();
    if (existingUser != null) {
      return existingUser;
    }
    // Create and save a default user if none exists
    final newUser = User()..name = 'Guest';
    isar.writeTxnSync(() {
      isar.users.putSync(newUser);
    });
    return newUser;
  }

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

  ReliableWebSocketService wsService = ReliableWebSocketService();

  VideoPlayerController? videoController;
  int _lastPlaybackRevision = -1;
  Map<String, dynamic>? _pendingPlaybackState;
  final RxBool isMediaLoading = false.obs;
  final RxBool isApplyingSync = false.obs;
  final RxString mediaLoadMessage = 'Preparing media…'.obs;
  final RxnString mediaLoadError = RxnString();
  final RxString syncStatus = 'Connecting…'.obs;
  final RxBool requiresMediaSelection = false.obs;

  String get currentUserId => _uuid;

  // Add subtitle path storage
  Rx<String?> currentSubtitlePath = Rx<String?>(null);

  // Add subtitle delay in milliseconds (can be positive or negative)
  Rx<int> subtitleDelay = Rx<int>(0);

  // Callback for when subtitles change
  Function()? onSubtitleChanged;

  @override
  void onInit() {
    super.onInit();

    wsService.setConnectionCallbacks(
      onConnected: () => syncStatus.value = 'Synced',
      onDisconnected: () => syncStatus.value = 'Reconnecting…',
      onError: (_) {
        if (!wsService.isJoined.value) syncStatus.value = 'Reconnecting…';
      },
    );

    wsService.setReceiveMsgFunction((msg) {
      if (msg.type == MessageType.pause ||
          msg.type == MessageType.play ||
          msg.type == MessageType.seek) {
        unawaited(_applyPlaybackState(msg.data, fallbackType: msg.type));
      } else if (msg.type == MessageType.roomUpdate) {
        _applyRoomSnapshot(msg.data);
      } else if (msg.type == MessageType.videoChanged) {
        _applyRemoteMediaChange(msg.data);
      } else if (msg.type == MessageType.userJoined) {
        setUser(msg.data);
      } else if (msg.type == MessageType.userLeft) {
        final index = users.indexWhere((u) => u.id == msg.data['id']);
        if (index != -1) {
          users[index] = RoomUser(
            id: msg.data['id'],
            name: msg.data['name'],
            online: false,
          );
        }
      } else if (msg.type == MessageType.chat) {
        _upsertChatMessage({
          'id': msg.eventId,
          'message': msg.data['message'] ?? '',
          'userName': msg.data['userName'] ?? 'Unknown',
          'userId': msg.data['userId'] ?? '',
          'timestamp':
              msg.data['timestamp'] ?? DateTime.now().toIso8601String(),
        });
      } else if (msg.type == MessageType.reaction) {
        // Add floating reaction
        final reactionId = msg.eventId;
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

  void _applyRoomSnapshot(Map<String, dynamic> data) {
    final modeName = data['room_mode']?.toString();
    if (modeName != null) {
      room.value = room.value.copyWith(
        mode: RoomMode.values.firstWhere(
          (mode) => mode.name == modeName,
          orElse: () => RoomMode.friends,
        ),
      );
    }
    final usersData = data['users'];
    if (usersData is List) {
      users.assignAll(
        usersData.whereType<Map>().map(
          (entry) => RoomUser(
            id: entry['id']?.toString() ?? '',
            name: entry['name']?.toString() ?? 'Unknown',
            online: entry['is_online'] == true,
          ),
        ),
      );
    }

    final history = data['messages'];
    if (history is List) {
      for (final item in history.whereType<Map>()) {
        final payload = item['data'];
        if (payload is! Map) continue;
        _upsertChatMessage({
          'id': item['id']?.toString() ?? '',
          'message': payload['message'] ?? '',
          'userName': payload['userName'] ?? 'Unknown',
          'userId': item['user_id']?.toString() ?? '',
          'timestamp': item['timestamp'] ?? DateTime.now().toIso8601String(),
        });
      }
    }
    unawaited(_applyPlaybackState(data));
  }

  void _applyRemoteMediaChange(Map<String, dynamic> data) {
    final title =
        data['current_video_title']?.toString() ??
        data['videoTitle']?.toString();
    if (title == null || title.isEmpty) return;
    final alreadyLoaded =
        room.value.currentVideoTitle == title &&
        (isMediaLoading.value || videoController?.value.isInitialized == true);
    room.value = room.value.copyWith(
      currentVideoTitle: title,
      currentPosition: Duration.zero,
      isPlaying: false,
    );
    unawaited(videoController?.pause());
    if (!alreadyLoaded) {
      requiresMediaSelection.value = true;
      mediaLoadMessage.value = '$title is ready to sync';
    }
    unawaited(_applyPlaybackState(data));
  }

  void _upsertChatMessage(Map<String, dynamic> value) {
    final id = value['id']?.toString() ?? '';
    if (id.isNotEmpty && chatMessages.any((message) => message['id'] == id)) {
      return;
    }
    chatMessages.add(value);
    chatMessages.sort(
      (a, b) => (a['timestamp']?.toString() ?? '').compareTo(
        b['timestamp']?.toString() ?? '',
      ),
    );
  }

  Future<void> _applyPlaybackState(
    Map<String, dynamic> state, {
    MessageType? fallbackType,
  }) async {
    final revision =
        (state['playback_revision'] as num?)?.toInt() ??
        (state['revision'] as num?)?.toInt() ??
        0;
    if (revision < _lastPlaybackRevision) return;
    _lastPlaybackRevision = revision;

    var positionMs =
        (state['position_ms'] as num?)?.round() ??
        (state['positionMs'] as num?)?.round() ??
        (((state['position'] as num?) ?? 0) * 1000).round();
    final isPlaying =
        state['is_playing'] as bool? ??
        (fallbackType == MessageType.play
            ? true
            : fallbackType == MessageType.pause
            ? false
            : room.value.isPlaying);
    if (isPlaying) {
      final updatedAt = DateTime.tryParse(
        state['playback_updated_at']?.toString() ?? '',
      );
      final serverTime = DateTime.tryParse(
        state['server_time']?.toString() ?? '',
      );
      if (updatedAt != null &&
          serverTime != null &&
          serverTime.isAfter(updatedAt)) {
        positionMs += serverTime.difference(updatedAt).inMilliseconds;
      }
    }

    final normalized = <String, dynamic>{
      ...state,
      'position_ms': positionMs,
      'is_playing': isPlaying,
      'playback_revision': revision,
    };
    room.value = room.value.copyWith(
      currentPosition: Duration(milliseconds: positionMs),
      isPlaying: isPlaying,
    );

    final player = videoController;
    if (player == null || !player.value.isInitialized) {
      _pendingPlaybackState = normalized;
      return;
    }
    _pendingPlaybackState = null;
    isApplyingSync.value = true;
    syncStatus.value = 'Syncing playback…';
    try {
      final requested = Duration(milliseconds: positionMs);
      final target = requested < Duration.zero
          ? Duration.zero
          : requested > player.value.duration
          ? player.value.duration
          : requested;
      if ((player.value.position - target).abs() >
          const Duration(milliseconds: 250)) {
        await player.seekTo(target);
      }
      if (isPlaying && !player.value.isPlaying) {
        await player.play();
      } else if (!isPlaying && player.value.isPlaying) {
        await player.pause();
      }
    } finally {
      isApplyingSync.value = false;
      syncStatus.value = wsService.isJoined.value ? 'Synced' : 'Reconnecting…';
    }
  }

  Future<void> onPlayerReady() async {
    final state = _pendingPlaybackState;
    if (state != null) await _applyPlaybackState(state);
  }

  void beginMediaLoad([String message = 'Loading media…']) {
    mediaLoadError.value = null;
    mediaLoadMessage.value = message;
    isMediaLoading.value = true;
  }

  void finishMediaLoad() {
    isMediaLoading.value = false;
    mediaLoadError.value = null;
  }

  void failMediaLoad(Object error) {
    isMediaLoading.value = false;
    mediaLoadError.value = 'Could not load this media';
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
    requiresMediaSelection.value = false;
    beginMediaLoad('Loading ${media.name}…');
    if (_uuid == room.value.hostId && room.value.id.isNotEmpty) {
      unawaited(wsService.changeVideo(room.value.id, _uuid, media.name));
    }
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

  Future createRoom(
    String roomName, {
    Media? mediaItem,
    RoomMode mode = RoomMode.friends,
  }) async {
    try {
      final res = await AppConstants.dio.post(
        '/rooms/create/',
        data: {
          'room_name': roomName,
          'user_name': user.name,
          'room_mode': mode.name,
        },
      );

      if (res.data['status'] == 'success') {
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

  Future<bool> joinRoom(String roomId) async {
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
        _uuid = res.data['user']['id'].toString();
        users.clear();
        final roomUsers = res.data['room']['users'];
        if (roomUsers is List) {
          for (final entry in roomUsers.whereType<Map>()) {
            setUser(entry);
          }
        }

        // A successful REST response is enough to enter the room. The socket
        // reconnects independently and the room UI already exposes its status.
        syncStatus.value = 'Connecting…';
        unawaited(_connectRoomRealtime());
        Get.snackbar(
          'Joined',
          'Opening ${room.value.name}',
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          res.data['message'] ?? 'Failed to join room',
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return false;
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
      return false;
    } catch (error) {
      Get.snackbar(
        'Couldn’t join room',
        'The room responded, but its details could not be opened. Please try again.',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }

  Future<void> _connectRoomRealtime() async {
    try {
      await wsService.joinRoom(room.value.id, _uuid, user.name);
    } catch (_) {
      // ReliableWebSocketService has already scheduled a reconnect.
      syncStatus.value = 'Reconnecting…';
    }
  }

  Future<void> playVideo() async {
    Duration? position = await videoController?.position;
    if (room.value.id == '') {
      return;
    }

    room.value = room.value.copyWith(
      isPlaying: true,
      currentPosition: position,
    );

    await wsService.playVideo(room.value.id, _uuid, position ?? Duration.zero);
  }

  Future<void> pauseVideo() async {
    Duration? position = await videoController?.position;
    if (room.value.id == '') {
      return;
    }

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
