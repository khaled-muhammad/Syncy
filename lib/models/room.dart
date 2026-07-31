enum RoomMode { friends, couple, party, horror, roast, movieClub }

enum RoomSeekPermission { host, everyone, selected }

class Room {
  String id;
  String joinCode;
  String name;
  String hostId;
  RoomMode mode;
  bool isLocked;
  RoomSeekPermission seekPermission;
  // final List<User> users;
  String? currentVideoUrl;
  String? currentVideoTitle;
  Duration currentPosition;
  bool isPlaying;
  DateTime createdAt;

  Room({
    required this.id,
    String? joinCode,
    required this.name,
    required this.hostId,
    this.mode = RoomMode.friends,
    this.isLocked = false,
    this.seekPermission = RoomSeekPermission.everyone,
    // required this.users,
    this.currentVideoUrl,
    this.currentVideoTitle,
    this.currentPosition = Duration.zero,
    this.isPlaying = false,
    required this.createdAt,
  }) : joinCode = joinCode ?? id;

  String get displayJoinCode {
    final code = joinCode.toUpperCase();
    return code.length == 8
        ? '${code.substring(0, 4)}-${code.substring(4)}'
        : code;
  }

  Room copyWith({
    String? id,
    String? joinCode,
    String? name,
    String? hostId,
    RoomMode? mode,
    bool? isLocked,
    RoomSeekPermission? seekPermission,
    // List<User>? users,
    String? currentVideoUrl,
    String? currentVideoTitle,
    Duration? currentPosition,
    bool? isPlaying,
    DateTime? createdAt,
  }) {
    return Room(
      id: id ?? this.id,
      joinCode: joinCode ?? this.joinCode,
      name: name ?? this.name,
      hostId: hostId ?? this.hostId,
      mode: mode ?? this.mode,
      isLocked: isLocked ?? this.isLocked,
      seekPermission: seekPermission ?? this.seekPermission,
      // users: users ?? this.users,
      currentVideoUrl: currentVideoUrl ?? this.currentVideoUrl,
      currentVideoTitle: currentVideoTitle ?? this.currentVideoTitle,
      currentPosition: currentPosition ?? this.currentPosition,
      isPlaying: isPlaying ?? this.isPlaying,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'join_code': joinCode,
      'name': name,
      'hostId': hostId,
      'roomMode': mode.name,
      'isLocked': isLocked,
      'seekPermission': seekPermission.name,
      // 'users': users.map((user) => user.toJson()).toList(),
      'currentVideoUrl': currentVideoUrl,
      'currentVideoTitle': currentVideoTitle,
      'currentPosition': currentPosition.inSeconds,
      'isPlaying': isPlaying,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      joinCode: json['join_code']?.toString(),
      name: json['name'],
      hostId: json['host_id'],
      mode: RoomMode.values.firstWhere(
        (mode) => mode.name == (json['room_mode'] ?? 'friends'),
        orElse: () => RoomMode.friends,
      ),
      isLocked: json['is_locked'] == true,
      seekPermission: RoomSeekPermission.values.firstWhere(
        (permission) =>
            permission.name == (json['seek_permission'] ?? 'everyone'),
        orElse: () => RoomSeekPermission.everyone,
      ),
      // users: (json['users'] as List)
      //     .map((userJson) => User.fromJson(userJson))
      //     .toList(),
      currentVideoUrl: json['current_video_url'],
      currentVideoTitle: json['current_video_title'],
      currentPosition: Duration(
        milliseconds:
            (json['position_ms'] as num?)?.round() ??
            (((json['current_position'] as num?) ??
                        num.tryParse(
                          json['current_position']?.toString() ?? '0',
                        ) ??
                        0) *
                    1000)
                .round(),
      ),
      isPlaying: json['is_playing'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
