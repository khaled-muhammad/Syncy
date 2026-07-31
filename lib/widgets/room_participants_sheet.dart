import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncy/controllers/room_controller.dart';
import 'package:syncy/models/room.dart';
import 'package:syncy/utils/platform_utils.dart';

class RoomParticipantsSheet extends StatelessWidget {
  final RoomController controller;

  const RoomParticipantsSheet({super.key, required this.controller});

  String _permissionLabel(RoomSeekPermission permission) {
    return switch (permission) {
      RoomSeekPermission.host => 'Host only',
      RoomSeekPermission.everyone => 'Everyone',
      RoomSeekPermission.selected => 'Selected people',
    };
  }

  Future<void> _confirmRemoval(
    BuildContext context,
    RoomUser participant,
  ) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${participant.name}?'),
        content: const Text(
          'They will be disconnected immediately. They can only return if the '
          'room is unlocked.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (remove == true) await controller.removeParticipant(participant);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: isDesktop
          ? BorderRadius.circular(20)
          : const BorderRadius.vertical(top: Radius.circular(26)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 680),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
          decoration: BoxDecoration(
            color: const Color(0xFF160B27).withValues(alpha: .96),
            borderRadius: isDesktop
                ? BorderRadius.circular(20)
                : const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border.all(color: Colors.white12),
          ),
          child: Obx(() {
            final room = controller.room.value;
            final participants = controller.users.toList(growable: false);
            return ListView(
              shrinkWrap: true,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Room participants',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${participants.where((user) => user.online).length} online',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
                if (controller.isHost) ...[
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .055),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          value: room.isLocked,
                          onChanged: controller.setRoomLocked,
                          secondary: Icon(
                            room.isLocked
                                ? Icons.lock_rounded
                                : Icons.lock_open_rounded,
                          ),
                          title: const Text('Lock room'),
                          subtitle: const Text(
                            'Prevent new people from joining',
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.swipe_rounded),
                          title: const Text('Who can seek'),
                          trailing: DropdownButton<RoomSeekPermission>(
                            value: room.seekPermission,
                            underline: const SizedBox.shrink(),
                            dropdownColor: const Color(0xFF24123D),
                            onChanged: (permission) {
                              if (permission != null) {
                                controller.setSeekPermission(permission);
                              }
                            },
                            items: RoomSeekPermission.values
                                .map(
                                  (permission) => DropdownMenuItem(
                                    value: permission,
                                    child: Text(
                                      _permissionLabel(permission),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                const Text(
                  'PEOPLE',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                for (final participant in participants)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          backgroundColor: participant.isHost
                              ? Colors.purpleAccent.withValues(alpha: .22)
                              : Colors.white10,
                          child: Text(
                            participant.name.isEmpty
                                ? '?'
                                : participant.name.characters.first
                                      .toUpperCase(),
                          ),
                        ),
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: participant.online
                                  ? Colors.greenAccent
                                  : Colors.white30,
                              border: Border.all(
                                color: const Color(0xFF160B27),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      participant.id == controller.currentUserId
                          ? '${participant.name} (you)'
                          : participant.name,
                    ),
                    subtitle: Text(
                      participant.isHost
                          ? 'Host'
                          : participant.canSeek
                          ? 'Allowed to seek'
                          : participant.online
                          ? 'Participant'
                          : 'Offline',
                    ),
                    trailing: controller.isHost && !participant.isHost
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (room.seekPermission ==
                                  RoomSeekPermission.selected)
                                Switch.adaptive(
                                  value: participant.canSeek,
                                  onChanged: (value) =>
                                      controller.setParticipantCanSeek(
                                        participant,
                                        value,
                                      ),
                                ),
                              IconButton(
                                tooltip: 'Remove participant',
                                onPressed: () =>
                                    _confirmRemoval(context, participant),
                                icon: const Icon(
                                  Icons.person_remove_rounded,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
