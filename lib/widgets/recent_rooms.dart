import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncy/controllers/room_controller.dart';
import 'package:syncy/models/recent_room.dart';
import 'package:syncy/models/room_preset.dart';
import 'package:syncy/routes/app_routes.dart';
import 'package:syncy/services/recent_rooms_service.dart';

class RecentRoomsView extends StatefulWidget {
  final bool compact;

  const RecentRoomsView({super.key, this.compact = false});

  @override
  State<RecentRoomsView> createState() => _RecentRoomsViewState();
}

class _RecentRoomsViewState extends State<RecentRoomsView> {
  String? _joiningRoomId;

  Future<void> _rejoin(RecentRoom recent) async {
    if (_joiningRoomId != null) return;
    setState(() => _joiningRoomId = recent.roomId);

    final joined = await Get.find<RoomController>().joinRoom(recent.reference);
    if (!mounted) return;
    setState(() => _joiningRoomId = null);
    if (joined) Get.toNamed(Routes.ROOM);
  }

  @override
  Widget build(BuildContext context) {
    final service = Get.find<RecentRoomsService>();
    return Obx(() {
      final rooms = service.rooms;
      if (rooms.isEmpty) return const SizedBox.shrink();
      return widget.compact
          ? _buildCompact(context, rooms)
          : _buildStrip(context, rooms);
    });
  }

  Widget _buildCompact(BuildContext context, List<RecentRoom> rooms) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 5, 8, 7),
            child: Text(
              'RECENT ROOMS',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ),
          for (final room in rooms.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _RecentRoomCard(
                recent: room,
                compact: true,
                joining: _joiningRoomId == room.roomId,
                enabled: _joiningRoomId == null,
                onTap: () => _rejoin(room),
                onRemove: () =>
                    Get.find<RecentRoomsService>().remove(room.roomId),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStrip(BuildContext context, List<RecentRoom> rooms) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jump back in',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Your latest rooms, one tap away',
                        style: TextStyle(color: Colors.white54, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${rooms.length}',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: rooms.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final room = rooms[index];
                return SizedBox(
                  width: 230,
                  child: _RecentRoomCard(
                    recent: room,
                    joining: _joiningRoomId == room.roomId,
                    enabled: _joiningRoomId == null,
                    onTap: () => _rejoin(room),
                    onRemove: () =>
                        Get.find<RecentRoomsService>().remove(room.roomId),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentRoomCard extends StatelessWidget {
  final RecentRoom recent;
  final bool compact;
  final bool joining;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RecentRoomCard({
    required this.recent,
    required this.joining,
    required this.enabled,
    required this.onTap,
    required this.onRemove,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final preset = recent.mode.preset;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(compact ? 12 : 18),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                preset.accent.withValues(alpha: compact ? .19 : .3),
                preset.secondary.withValues(alpha: compact ? .08 : .16),
              ],
            ),
            borderRadius: BorderRadius.circular(compact ? 12 : 18),
            border: Border.all(color: preset.accent.withValues(alpha: .28)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 14,
              vertical: compact ? 8 : 12,
            ),
            child: Row(
              children: [
                Container(
                  width: compact ? 33 : 42,
                  height: compact ? 33 : 42,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(compact ? 10 : 13),
                  ),
                  alignment: Alignment.center,
                  child: joining
                      ? SizedBox.square(
                          dimension: compact ? 16 : 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: preset.accent,
                          ),
                        )
                      : Icon(
                          preset.icon,
                          size: compact ? 17 : 22,
                          color: preset.accent,
                        ),
                ),
                SizedBox(width: compact ? 9 : 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recent.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 12.5 : 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: compact ? 2 : 4),
                      Text(
                        recent.displayJoinCode.isEmpty
                            ? _relativeTime(recent.lastJoinedAt)
                            : '${recent.displayJoinCode}  •  ${_relativeTime(recent.lastJoinedAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: compact ? 9.5 : 10.5,
                        ),
                      ),
                      if (!compact &&
                          recent.mediaTitle?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          recent.mediaTitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Recent room options',
                  padding: EdgeInsets.zero,
                  iconSize: compact ? 17 : 20,
                  color: const Color(0xFF1A0E2E),
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white38,
                  ),
                  onSelected: (value) {
                    if (value == 'remove') onRemove();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove from recent'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _relativeTime(DateTime value) {
    final difference = DateTime.now().toUtc().difference(value.toUtc());
    if (difference.isNegative || difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${value.day}/${value.month}/${value.year}';
  }
}
