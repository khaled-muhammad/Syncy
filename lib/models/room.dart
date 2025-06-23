class Room {
  String id;
  String name;
  String hostId;
  // final List<User> users;
  String? currentVideoUrl;
  String? currentVideoTitle;
  Duration currentPosition;
  bool isPlaying;
  DateTime createdAt;

  Room({
    required this.id,
    required this.name,
    required this.hostId,
    // required this.users,
    this.currentVideoUrl,
    this.currentVideoTitle,
    this.currentPosition = Duration.zero,
    this.isPlaying = false,
    required this.createdAt,
  });

  Room copyWith({
    String? id,
    String? name,
    String? hostId,
    // List<User>? users,
    String? currentVideoUrl,
    String? currentVideoTitle,
    Duration? currentPosition,
    bool? isPlaying,
    DateTime? createdAt,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      hostId: hostId ?? this.hostId,
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
      'name': name,
      'hostId': hostId,
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
      name: json['name'],
      hostId: json['host_id'],
      // users: (json['users'] as List)
      //     .map((userJson) => User.fromJson(userJson))
      //     .toList(),
      currentVideoUrl: json['current_video_url'],
      currentVideoTitle: json['current_video_title'],
      currentPosition: Duration(seconds: int.tryParse(json['current_position']) ?? 0),
      isPlaying: json['is_playing'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}