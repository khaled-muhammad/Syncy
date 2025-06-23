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
}

class Message {
  final MessageType type;
  final String roomId;
  final String userId;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  Message({
    required this.type,
    required this.roomId,
    required this.userId,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'roomId': roomId,
      'userId': userId,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
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
      data: {'position': position.inSeconds},
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
      data: {'position': position.inSeconds},
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
      data: {'position': position.inSeconds},
    );
  }

  factory Message.videoChanged({
    required String roomId,
    required String userId,
    required String videoUrl,
    required String videoTitle,
  }) {
    return Message(
      type: MessageType.videoChanged,
      roomId: roomId,
      userId: userId,
      data: {
        'videoUrl': videoUrl,
        'videoTitle': videoTitle,
      },
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
      data: {
        'userName': userName,
        'name': userName,
        'id': userId,
      },
    );
  }

  factory Message.leaveRoom({
    required String roomId,
    required String userId,
  }) {
    return Message(
      type: MessageType.leave,
      roomId: roomId,
      userId: userId,
      data: {},
    );
  }
}