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
import 'package:syncy/services/player/playback_synchronizer.dart';
import 'package:syncy/services/player/sync_player.dart';
import 'package:syncy/services/reliable_websocket_service.dart';
import 'package:syncy/utils/native_pickers.dart';

class RoomUser {
  final String name;
  final bool online;
  final String id;

  const RoomUser({required this.id, required this.name, required this.online});
}

class RoomController extends GetxController with WidgetsBindingObserver {
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
  final Rxn<DateTime> countdownEndsAt = Rxn<DateTime>();
  final RxBool lobbyVisible = false.obs;
  final RxBool showScorecard = false.obs;
  final RxMap<String, int> reactionTotals = <String, int>{}.obs;
  final RxMap<String, int> chatTotals = <String, int>{}.obs;
  final RxMap<String, int> ratings = <String, int>{}.obs;
  final Map<int, int> _reactionMoments = {};
  Timer? _countdownTimer;
  DateTime? _lastProgressPersistedAt;
  String? currentMediaPath;
  bool _openingCountdownUsed = false;

  // Ephemeral remote typing state, keyed by sender ID.
  final RxMap<String, String> typingUsers = <String, String>{}.obs;
  final Map<String, Timer> _typingExpiryTimers = {};
  Timer? _localTypingIdleTimer;
  bool _localTypingActive = false;
  DateTime? _lastTypingSignalAt;

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

  SyncPlayer? videoController;
  int _lastPlaybackRevision = -1;
  late final PlaybackSynchronizer _playbackSynchronizer;
  final RxBool isMediaLoading = false.obs;
  final RxBool isApplyingSync = false.obs;
  final RxString mediaLoadMessage = 'Preparing media…'.obs;
  final RxnString mediaLoadError = RxnString();
  final RxString syncStatus = 'Connecting…'.obs;
  final RxBool requiresMediaSelection = false.obs;

  /// Set when a LAN stream URL arrives from sync and the RoomScreen should
  /// (re)open the player against it. The screen watches this and clears it.
  final RxnString pendingStreamUrl = RxnString();

  String get currentUserId => _uuid;

  // Add subtitle path storage
  Rx<String?> currentSubtitlePath = Rx<String?>(null);

  // Add subtitle delay in milliseconds (can be positive or negative)
  Rx<int> subtitleDelay = Rx<int>(0);

  // Callback for when subtitles change
  Function()? onSubtitleChanged;

  bool get isHost => _uuid == room.value.hostId;

  String get mostUsedReaction => reactionTotals.isEmpty
      ? '—'
      : reactionTotals.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

  String get biggestChatter => chatTotals.isEmpty
      ? 'Quiet legends'
      : chatTotals.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

  Duration? get crowdFavoriteMoment {
    if (_reactionMoments.isEmpty) return null;
    final entry = _reactionMoments.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    return Duration(milliseconds: entry.key);
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _playbackSynchronizer = PlaybackSynchronizer(
      onApplyingChanged: (applying) {
        isApplyingSync.value = applying;
        syncStatus.value = applying
            ? 'Syncing playback...'
            : wsService.isJoined.value
            ? 'Synced'
            : 'Reconnecting...';
      },
    );

    wsService.setConnectionCallbacks(
      onConnected: () => syncStatus.value = 'Synced',
      onDisconnected: () {
        syncStatus.value = 'Reconnecting…';
        _clearTypingUsers();
        _localTypingIdleTimer?.cancel();
        _localTypingActive = false;
        _lastTypingSignalAt = null;
      },
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
        final sender = msg.data['userName']?.toString() ?? 'Unknown';
        chatTotals[sender] = (chatTotals[sender] ?? 0) + 1;
        _upsertChatMessage({
          'id': msg.eventId,
          'message': msg.data['message'] ?? '',
          'userName': msg.data['userName'] ?? 'Unknown',
          'userId': msg.data['userId'] ?? '',
          'timestamp':
              msg.data['timestamp'] ?? DateTime.now().toIso8601String(),
        });
      } else if (msg.type == MessageType.reaction) {
        final emoji = msg.data['emoji']?.toString() ?? '❤️';
        reactionTotals[emoji] = (reactionTotals[emoji] ?? 0) + 1;
        final positionMs = (msg.data['positionMs'] as num?)?.round();
        if (positionMs != null) {
          final bucket = (positionMs / 5000).round() * 5000;
          _reactionMoments[bucket] = (_reactionMoments[bucket] ?? 0) + 1;
        }
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
      } else if (msg.type == MessageType.typing) {
        _applyTypingState(msg);
      } else if (msg.type == MessageType.countdown) {
        _applyCountdown(msg.data);
      } else if (msg.type == MessageType.rating) {
        final userId = msg.data['userId']?.toString() ?? msg.userId;
        final rating = (msg.data['rating'] as num?)?.round() ?? 0;
        if (userId.isNotEmpty && rating > 0) ratings[userId] = rating;
      }
    });
  }

  List<String> get typingUserNames =>
      typingUsers.values.toList(growable: false);

  void _applyCountdown(Map<String, dynamic> data) {
    final endsAt = DateTime.tryParse(data['endsAt']?.toString() ?? '');
    if (endsAt == null) return;
    _countdownTimer?.cancel();
    countdownEndsAt.value = endsAt;
    final delay = endsAt.difference(DateTime.now());
    _countdownTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
      countdownEndsAt.value = null;
      if (isHost && !room.value.isPlaying) {
        unawaited(_playVideoNow());
      }
    });
  }

  Future<void> startCountdown() async {
    if (room.value.id.isEmpty || !wsService.isJoined.value || !isHost) return;
    await wsService.sendCountdown(room.value.id, _uuid, seconds: 3);
  }

  Future<void> _playVideoNow() async {
    final position =
        videoController?.value.position ?? room.value.currentPosition;
    room.value = room.value.copyWith(
      isPlaying: true,
      currentPosition: position,
    );
    lobbyVisible.value = false;
    unawaited(
      _playbackSynchronizer.submitLocal(position: position, isPlaying: true),
    );
    await wsService.playVideo(room.value.id, _uuid, position);
  }

  Future<void> startMovieFromLobby() async {
    if (countdownEndsAt.value != null) return;
    _openingCountdownUsed = true;
    await startCountdown();
  }

  Future<void> recordPlaybackProgress(
    Duration position, {
    Duration? duration,
    bool force = false,
  }) async {
    final path = currentMediaPath;
    if (path == null || path.isEmpty) return;
    final now = DateTime.now();
    if (!force &&
        _lastProgressPersistedAt != null &&
        now.difference(_lastProgressPersistedAt!) <
            const Duration(seconds: 4)) {
      return;
    }
    _lastProgressPersistedAt = now;
    final media = isar.medias.filter().pathEqualTo(path).findFirstSync();
    if (media == null) return;
    media.playbackPositionMs = position.inMilliseconds
        .clamp(0, 1 << 31)
        .toInt();
    if (duration != null && duration > Duration.zero) {
      media.durationMs = duration.inMilliseconds;
    }
    media.lastWatchedAt = now;
    final onlineNames = users
        .where((user) => user.online && user.name.isNotEmpty)
        .map((user) => user.name)
        .toSet()
        .toList();
    if (onlineNames.length > 1) {
      media.watchedTogetherAt = now;
      media.watchedWith = onlineNames;
    }
    isar.writeTxnSync(() => isar.medias.putSync(media));
    if (media.durationMs > 0 &&
        media.playbackPositionMs >= media.durationMs * .97) {
      showScorecard.value = true;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Wait for a fresh server snapshot before allowing a paused Android
      // surface to start itself again.
      _playbackSynchronizer.setActive(false);
      if (room.value.id.isNotEmpty) {
        syncStatus.value = 'Refreshing playback...';
        unawaited(wsService.requestRoomState());
      }
      return;
    }
    _playbackSynchronizer.setActive(false);
  }

  void _applyTypingState(Message message) {
    final userId =
        message.data['userId']?.toString() ?? message.userId.toString();
    if (userId.isEmpty || userId == _uuid) return;

    _typingExpiryTimers.remove(userId)?.cancel();
    if (message.data['isTyping'] == true) {
      typingUsers[userId] = message.data['userName']?.toString() ?? 'Someone';
      // App suspension or network loss must not leave a stale indicator.
      _typingExpiryTimers[userId] = Timer(const Duration(seconds: 4), () {
        typingUsers.remove(userId);
        _typingExpiryTimers.remove(userId);
      });
    } else {
      typingUsers.remove(userId);
    }
  }

  void _clearTypingUsers() {
    for (final timer in _typingExpiryTimers.values) {
      timer.cancel();
    }
    _typingExpiryTimers.clear();
    typingUsers.clear();
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
        final messageId = item['id']?.toString() ?? '';
        if (!chatMessages.any((message) => message['id'] == messageId)) {
          final sender = payload['userName']?.toString() ?? 'Unknown';
          chatTotals[sender] = (chatTotals[sender] ?? 0) + 1;
        }
        _upsertChatMessage({
          'id': messageId,
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
    if (_revisionOf(data) < _lastPlaybackRevision) return;
    final title =
        data['current_video_title']?.toString() ??
        data['videoTitle']?.toString();
    if (title == null || title.isEmpty) return;

    // A LAN-hosted room carries a playable http(s) stream URL. When present,
    // every peer streams that URL directly — no local copy, no "pick your
    // matching file" step. Absent, we fall back to the classic behavior where
    // each peer supplies its own local file.
    final url =
        data['current_video_url']?.toString() ?? data['videoUrl']?.toString();
    final isStream = url != null && _isNetworkUrl(url);

    final alreadyLoaded =
        (isStream
            ? room.value.currentVideoUrl == url
            : room.value.currentVideoTitle == title) &&
        (isMediaLoading.value || videoController?.value.isInitialized == true);

    room.value = room.value.copyWith(
      currentVideoTitle: title,
      currentVideoUrl: isStream ? url : room.value.currentVideoUrl,
      currentPosition: Duration.zero,
      isPlaying: false,
    );
    lobbyVisible.value = true;
    showScorecard.value = false;
    if (isHost) _openingCountdownUsed = false;
    unawaited(
      _playbackSynchronizer.submitLocal(
        position: Duration.zero,
        isPlaying: false,
      ),
    );

    if (!alreadyLoaded) {
      if (isStream) {
        // Signal the RoomScreen to (re)open the stream.
        requiresMediaSelection.value = false;
        beginMediaLoad('Loading $title…');
        pendingStreamUrl.value = url;
      } else {
        requiresMediaSelection.value = true;
        mediaLoadMessage.value = '$title is ready to sync';
      }
    }
    unawaited(_applyPlaybackState(data));
  }

  bool _isNetworkUrl(String value) =>
      value.startsWith('http://') || value.startsWith('https://');

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
    final revision = _revisionOf(state);
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

    room.value = room.value.copyWith(
      currentPosition: Duration(milliseconds: positionMs),
      isPlaying: isPlaying,
    );
    if (isPlaying || positionMs > 1000) {
      lobbyVisible.value = false;
    }

    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    if (lifecycleState == null || lifecycleState == AppLifecycleState.resumed) {
      _playbackSynchronizer.setActive(true);
    }
    await _playbackSynchronizer.submitAuthoritative(
      PlaybackSyncState(
        revision: revision,
        position: Duration(milliseconds: positionMs),
        isPlaying: isPlaying,
        receivedAt: DateTime.now(),
      ),
    );
  }

  int _revisionOf(Map<String, dynamic> state) =>
      (state['playback_revision'] as num?)?.toInt() ??
      (state['revision'] as num?)?.toInt() ??
      0;

  void attachVideoController(SyncPlayer player) {
    videoController = player;
    _playbackSynchronizer.attach(player);
  }

  void detachVideoController([SyncPlayer? player]) {
    _playbackSynchronizer.detach(player);
    if (player == null || identical(videoController, player)) {
      videoController = null;
    }
  }

  Future<void> onPlayerReady() => _playbackSynchronizer.reconcile();

  void _resetPlaybackSync() {
    _lastPlaybackRevision = -1;
    _playbackSynchronizer.clear();
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

  void failMediaLoad(Object error, {String? message}) {
    isMediaLoading.value = false;
    if (message != null) {
      mediaLoadError.value = message;
      return;
    }
    // A LAN stream and a local file fail for different reasons, so the message
    // points the user at the likely cause.
    final url = room.value.currentVideoUrl ?? '';
    mediaLoadError.value = _isNetworkUrl(url)
        ? "Couldn't play this stream. The PC may be offline, off this network, "
              "or the video's format isn't supported on your phone."
        : 'Could not load this media';
  }

  /// True while the current media is a LAN stream (vs a local file).
  bool get isStreamingMedia => _isNetworkUrl(room.value.currentVideoUrl ?? '');

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
    currentMediaPath = media.path;
    lobbyVisible.value = true;
    showScorecard.value = false;
    _openingCountdownUsed = false;
    room.value.currentVideoUrl = media.path;
    // Reset subtitle when changing media
    currentSubtitlePath.value = null;
    requiresMediaSelection.value = false;
    beginMediaLoad('Loading ${media.name}…');
    room.value = room.value.copyWith(
      currentPosition: Duration.zero,
      isPlaying: false,
    );
    unawaited(
      _playbackSynchronizer.submitLocal(
        position: Duration.zero,
        isPlaying: false,
      ),
    );
    if (_uuid == room.value.hostId && room.value.id.isNotEmpty) {
      unawaited(wsService.changeVideo(room.value.id, _uuid, media.name));
    }
  }

  // Add method to pick subtitle file
  Future<void> selectSubtitleFile() async {
    try {
      final path = await pickSubtitleFile();

      if (path != null && path.isNotEmpty) {
        currentSubtitlePath.value = path;
        // Notify listeners that subtitle changed
        if (onSubtitleChanged != null) {
          onSubtitleChanged!();
        }

        Get.snackbar(
          'Subtitle Selected',
          'Subtitle file loaded: ${_fileNameOf(path)}',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
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

  String _fileNameOf(String path) => path.replaceAll('\\', '/').split('/').last;

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
    String? streamUrl,
    String? streamTitle,
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
        _resetPlaybackSync();
        room.value = Room.fromJson(res.data['room']);
        if (streamUrl != null && streamUrl.isNotEmpty) {
          // Media hosted on a PC over the LAN: peers stream the same URL.
          room.value.currentVideoUrl = streamUrl;
          room.value.currentVideoTitle = streamTitle;
        } else if (mediaItem != null) {
          room.value.currentVideoUrl = mediaItem.path;
          room.value.currentVideoTitle = mediaItem.name;
        }
        currentMediaPath = mediaItem?.path;
        lobbyVisible.value = true;
        showScorecard.value = false;
        _openingCountdownUsed = false;
        reactionTotals.clear();
        chatTotals.clear();
        ratings.clear();
        _reactionMoments.clear();
        _uuid = res.data['user']['id'];
        await wsService.joinRoom(room.value.id, _uuid, user.name);

        // A LAN stream must be broadcast so joiners receive the URL; a local
        // file stays on this device and needs no broadcast at create time.
        if (streamUrl != null && streamUrl.isNotEmpty) {
          unawaited(
            wsService.changeVideo(
              room.value.id,
              _uuid,
              streamTitle ?? '',
              videoUrl: streamUrl,
            ),
          );
        }

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
        _resetPlaybackSync();
        room.value = Room.fromJson(res.data['room']);
        currentMediaPath = _isNetworkUrl(room.value.currentVideoUrl ?? '')
            ? null
            : room.value.currentVideoUrl;
        lobbyVisible.value = true;
        showScorecard.value = false;
        _openingCountdownUsed = true;
        reactionTotals.clear();
        chatTotals.clear();
        ratings.clear();
        _reactionMoments.clear();
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
    if (room.value.id.isEmpty || !wsService.isJoined.value) {
      unawaited(wsService.requestRoomState());
      return;
    }
    final position =
        videoController?.value.position ?? room.value.currentPosition;
    if (isHost &&
        !_openingCountdownUsed &&
        position <= const Duration(seconds: 1)) {
      _openingCountdownUsed = true;
      await startCountdown();
      return;
    }
    await _playVideoNow();
  }

  Future<void> pauseVideo() async {
    if (room.value.id.isEmpty || !wsService.isJoined.value) {
      unawaited(wsService.requestRoomState());
      return;
    }
    final position =
        videoController?.value.position ?? room.value.currentPosition;

    room.value = room.value.copyWith(
      isPlaying: false,
      currentPosition: position,
    );
    unawaited(
      _playbackSynchronizer.submitLocal(position: position, isPlaying: false),
    );
    await wsService.pauseVideo(room.value.id, _uuid, position);
  }

  Future<void> seekVideo(Duration position) async {
    if (room.value.id.isEmpty || !wsService.isJoined.value) {
      unawaited(wsService.requestRoomState());
      return;
    }

    room.value = room.value.copyWith(currentPosition: position);
    unawaited(
      _playbackSynchronizer.submitLocal(
        position: position,
        isPlaying: room.value.isPlaying,
      ),
    );
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
    } catch (_) {
      // Local room state still needs to be released if transport cleanup fails.
    } finally {
      users.clear();
      chatMessages.clear();
      floatingReactions.clear();
      countdownEndsAt.value = null;
      _countdownTimer?.cancel();
      lobbyVisible.value = false;
      showScorecard.value = false;
      _clearTypingUsers();
      _localTypingIdleTimer?.cancel();
      _localTypingActive = false;
      _lastTypingSignalAt = null;
      _resetPlaybackSync();
      room.value = Room(
        createdAt: DateTime.now(),
        id: '',
        name: '',
        hostId: '',
      );
      currentMediaPath = null;
    }
  }

  // Send chat message
  Future<void> sendChatMessage(String messageText) async {
    if (room.value.id == '' || messageText.trim().isEmpty) return;
    stopTyping();
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
    await wsService.sendReaction(
      room.value.id,
      _uuid,
      user.name,
      emoji,
      positionMs: videoController?.value.position.inMilliseconds,
    );
  }

  Future<void> submitRating(int rating) async {
    if (room.value.id.isEmpty || rating < 1 || rating > 5) return;
    ratings[_uuid] = rating;
    await wsService.sendRating(room.value.id, _uuid, rating);
  }

  void chatInputChanged(String value) {
    _localTypingIdleTimer?.cancel();
    if (room.value.id.isEmpty || value.trim().isEmpty) {
      stopTyping();
      return;
    }

    final now = DateTime.now();
    final shouldRefreshSignal =
        _lastTypingSignalAt == null ||
        now.difference(_lastTypingSignalAt!) >= const Duration(seconds: 1);
    if (!_localTypingActive || shouldRefreshSignal) {
      _localTypingActive = true;
      _lastTypingSignalAt = now;
      unawaited(wsService.sendTyping(room.value.id, _uuid, user.name, true));
    }
    _localTypingIdleTimer = Timer(
      const Duration(milliseconds: 1800),
      stopTyping,
    );
  }

  void stopTyping() {
    _localTypingIdleTimer?.cancel();
    _localTypingIdleTimer = null;
    if (!_localTypingActive) return;
    _localTypingActive = false;
    _lastTypingSignalAt = null;
    if (room.value.id.isNotEmpty) {
      unawaited(wsService.sendTyping(room.value.id, _uuid, user.name, false));
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _playbackSynchronizer.dispose();
    _localTypingIdleTimer?.cancel();
    _clearTypingUsers();
    _countdownTimer?.cancel();
    super.onClose();
  }
}
