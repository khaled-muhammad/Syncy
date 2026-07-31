import 'package:uuid/uuid.dart';

enum MessageType {
  join,
  leave,
  play,
  pause,
  seek,
  videoChanged,
  roomUpdate,
  userJoined,
  userLeft,
  error,
  heartbeat,
  chat,
  reaction,
  typing,
  countdown,
  rating,
  roomSettings,
  kickParticipant,
  participantRemoved,
  ack,
}

class Message {
  final MessageType type;
  final String roomId;
  final String userId;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String eventId;

  Message({
    required this.type,
    required this.roomId,
    required this.userId,
    required this.data,
    DateTime? timestamp,
    String? eventId,
  }) : timestamp = timestamp ?? DateTime.now(),
       eventId = eventId ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'type': switch (type) {
        MessageType.videoChanged => 'video_changed',
        MessageType.roomUpdate => 'room_update',
        MessageType.userJoined => 'user_joined',
        MessageType.userLeft => 'user_left',
        MessageType.roomSettings => 'room_settings',
        MessageType.kickParticipant => 'kick_participant',
        MessageType.participantRemoved => 'participant_removed',
        _ => type.name,
      },
      'roomId': roomId,
      'userId': userId,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'eventId': eventId,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    String messageTypeString = json['type'] ?? '';
    MessageType messageType;

    switch (messageTypeString) {
      case 'user_joined':
        messageType = MessageType.userJoined;
        break;
      case 'user_left':
        messageType = MessageType.userLeft;
        break;
      case 'room_update':
        messageType = MessageType.roomUpdate;
        break;
      case 'video_changed':
        messageType = MessageType.videoChanged;
        break;
      case 'room_settings':
        messageType = MessageType.roomSettings;
        break;
      case 'participant_removed':
        messageType = MessageType.participantRemoved;
        break;
      default:
        messageType = MessageType.values.firstWhere(
          (e) => e.name == messageTypeString,
          orElse: () => MessageType.error,
        );
    }

    String roomId = json['roomId'] ?? json['room_id'] ?? '';
    String userId = json['userId'] ?? json['user_id'] ?? '';

    if (messageType == MessageType.userJoined && userId.isEmpty) {
      userId = json['data']?['id'] ?? '';
    }

    DateTime timestamp;
    if (json['timestamp'] != null) {
      timestamp = DateTime.parse(json['timestamp']);
    } else if (json['data']?['joined_at'] != null) {
      timestamp = DateTime.parse(json['data']['joined_at']);
    } else {
      timestamp = DateTime.now();
    }

    return Message(
      type: messageType,
      roomId: roomId,
      userId: userId,
      data: json['data'] ?? {},
      timestamp: timestamp,
      eventId: json['eventId'] ?? json['event_id'],
    );
  }

  factory Message.play({
    required String roomId,
    required String userId,
    required Duration position,
  }) {
    return Message(
      type: MessageType.play,
      roomId: roomId,
      userId: userId,
      data: {'positionMs': position.inMilliseconds},
    );
  }

  factory Message.pause({
    required String roomId,
    required String userId,
    required Duration position,
  }) {
    return Message(
      type: MessageType.pause,
      roomId: roomId,
      userId: userId,
      data: {'positionMs': position.inMilliseconds},
    );
  }

  factory Message.seek({
    required String roomId,
    required String userId,
    required Duration position,
  }) {
    return Message(
      type: MessageType.seek,
      roomId: roomId,
      userId: userId,
      data: {'positionMs': position.inMilliseconds},
    );
  }

  factory Message.videoChanged({
    required String roomId,
    required String userId,
    String videoUrl = '',
    required String videoTitle,
  }) {
    return Message(
      type: MessageType.videoChanged,
      roomId: roomId,
      userId: userId,
      data: {'videoUrl': videoUrl, 'videoTitle': videoTitle},
    );
  }

  factory Message.joinRoom({
    required String roomId,
    required String userId,
    required String userName,
  }) {
    return Message(
      type: MessageType.join,
      roomId: roomId,
      userId: userId,
      data: {'userName': userName, 'name': userName, 'id': userId},
    );
  }

  factory Message.leaveRoom({required String roomId, required String userId}) {
    return Message(
      type: MessageType.leave,
      roomId: roomId,
      userId: userId,
      data: {},
    );
  }

  factory Message.chat({
    required String roomId,
    required String userId,
    required String userName,
    required String message,
  }) {
    return Message(
      type: MessageType.chat,
      roomId: roomId,
      userId: userId,
      data: {'message': message, 'userName': userName},
    );
  }

  factory Message.reaction({
    required String roomId,
    required String userId,
    required String userName,
    required String emoji,
    int? positionMs,
  }) {
    return Message(
      type: MessageType.reaction,
      roomId: roomId,
      userId: userId,
      data: {
        'emoji': emoji,
        'userName': userName,
        if (positionMs != null) 'positionMs': positionMs,
      },
    );
  }

  factory Message.typing({
    required String roomId,
    required String userId,
    required String userName,
    required bool isTyping,
  }) {
    return Message(
      type: MessageType.typing,
      roomId: roomId,
      userId: userId,
      data: {'isTyping': isTyping, 'userName': userName},
    );
  }

  factory Message.countdown({
    required String roomId,
    required String userId,
    required int seconds,
  }) {
    return Message(
      type: MessageType.countdown,
      roomId: roomId,
      userId: userId,
      data: {'seconds': seconds},
    );
  }

  factory Message.rating({
    required String roomId,
    required String userId,
    required int rating,
  }) {
    return Message(
      type: MessageType.rating,
      roomId: roomId,
      userId: userId,
      data: {'rating': rating},
    );
  }

  factory Message.roomSettings({
    required String roomId,
    required String userId,
    bool? isLocked,
    String? seekPermission,
    String? participantId,
    bool? canSeek,
  }) {
    return Message(
      type: MessageType.roomSettings,
      roomId: roomId,
      userId: userId,
      data: {
        if (isLocked != null) 'isLocked': isLocked,
        if (seekPermission != null) 'seekPermission': seekPermission,
        if (participantId != null) 'participantId': participantId,
        if (canSeek != null) 'canSeek': canSeek,
      },
    );
  }

  factory Message.kickParticipant({
    required String roomId,
    required String userId,
    required String participantId,
  }) {
    return Message(
      type: MessageType.kickParticipant,
      roomId: roomId,
      userId: userId,
      data: {'userId': participantId},
    );
  }
}
