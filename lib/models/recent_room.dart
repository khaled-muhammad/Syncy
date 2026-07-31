import 'package:syncy/models/room.dart';

class RecentRoom {
  final String roomId;
  final String joinCode;
  final String name;
  final RoomMode mode;
  final String? mediaTitle;
  final bool wasHost;
  final DateTime lastJoinedAt;

  const RecentRoom({
    required this.roomId,
    required this.joinCode,
    required this.name,
    required this.mode,
    required this.mediaTitle,
    required this.wasHost,
    required this.lastJoinedAt,
  });

  String get reference => joinCode.isNotEmpty ? joinCode : roomId;

  String get displayJoinCode {
    final code = joinCode.toUpperCase();
    return code.length == 8
        ? '${code.substring(0, 4)}-${code.substring(4)}'
        : code;
  }

  Map<String, dynamic> toJson() => {
    'roomId': roomId,
    'joinCode': joinCode,
    'name': name,
    'mode': mode.name,
    'mediaTitle': mediaTitle,
    'wasHost': wasHost,
    'lastJoinedAt': lastJoinedAt.toIso8601String(),
  };

  factory RecentRoom.fromJson(Map<String, dynamic> json) {
    final roomId = json['roomId']?.toString() ?? '';
    if (roomId.isEmpty) {
      throw const FormatException('Recent room is missing its room ID.');
    }

    return RecentRoom(
      roomId: roomId,
      joinCode: json['joinCode']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Room',
      mode: RoomMode.values.firstWhere(
        (mode) => mode.name == json['mode'],
        orElse: () => RoomMode.friends,
      ),
      mediaTitle: json['mediaTitle']?.toString(),
      wasHost: json['wasHost'] == true,
      lastJoinedAt:
          DateTime.tryParse(json['lastJoinedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
