import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncy/constants/app_constants.dart';
import 'package:syncy/models/room.dart';
import 'package:syncy/utils/platform_utils.dart';

class RoomInviteSheet extends StatelessWidget {
  final Room room;

  const RoomInviteSheet({super.key, required this.room});

  String get _inviteLink => AppConstants.roomInviteUrl(room.joinCode);

  String get _inviteMessage =>
      'Join “${room.name}” on Syncy.\n'
      'Room code: ${room.displayJoinCode}\n'
      'Open invite: $_inviteLink';

  Future<void> _copy(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    Get.snackbar('Copied', message, snackPosition: SnackPosition.TOP);
  }

  Future<void> _share(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;
    final origin = renderBox == null
        ? null
        : renderBox.localToGlobal(Offset.zero) & renderBox.size;
    return SharePlus.instance
        .share(
          ShareParams(
            text: _inviteMessage,
            title: 'Invite to ${room.name}',
            subject: 'Join my Syncy room',
            sharePositionOrigin: origin,
          ),
        )
        .then((_) {});
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
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
          decoration: BoxDecoration(
            color: const Color(0xFF1A0E2E).withValues(alpha: .94),
            borderRadius: isDesktop
                ? BorderRadius.circular(20)
                : const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border.all(color: Colors.white.withValues(alpha: .12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              const Icon(
                Icons.group_add_rounded,
                size: 38,
                color: Colors.purpleAccent,
              ),
              const SizedBox(height: 10),
              Text(
                'Invite people to ${room.name}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Share the link or send this code.',
                style: TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 20),
              Material(
                color: Colors.white.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: () => _copy(room.displayJoinCode, 'Room code copied.'),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 17,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ROOM CODE',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                room.displayJoinCode,
                                style: const TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.copy_rounded, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _copy(_inviteLink, 'Invite link copied.'),
                      icon: const Icon(Icons.link_rounded),
                      label: const Text('Copy link'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _share(context),
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Share invite'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent.withValues(
                          alpha: .28,
                        ),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
