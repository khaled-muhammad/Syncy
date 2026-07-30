import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar_community/isar.dart';
import 'package:syncy/controllers/lan_controller.dart';
import 'package:syncy/controllers/room_controller.dart';
import 'package:syncy/models/media.dart';
import 'package:syncy/models/remote_media.dart';
import 'package:syncy/models/room.dart';
import 'package:syncy/models/room_preset.dart';
import 'package:syncy/models/user.dart';
import 'package:syncy/services/lan/lan_host_service.dart';
import 'package:syncy/utils/platform_utils.dart';
import 'package:syncy/widgets/modern_input.dart';

class CreateRoomBottomSheet extends StatefulWidget {
  /// Local media on this device (mobile scan / desktop library).
  final Media? media;

  /// Media hosted on a paired PC, streamed over the LAN. Exactly one of
  /// [media] / [remoteMedia] is set.
  final RemoteMedia? remoteMedia;

  const CreateRoomBottomSheet({super.key, this.media, this.remoteMedia})
    : assert(media != null || remoteMedia != null);

  @override
  State<CreateRoomBottomSheet> createState() => _CreateRoomBottomSheetState();
}

class _CreateRoomBottomSheetState extends State<CreateRoomBottomSheet> {
  final _nameController = TextEditingController();
  final _roomNameController = TextEditingController();
  final isar = Get.find<Isar>();
  late User user;
  RoomMode _roomMode = RoomMode.friends;
  bool _creating = false;

  Future<void> _create() async {
    final roomName = _roomNameController.text.trim();
    if (roomName.isEmpty) return;

    // Remote media (phone → PC library): resolve a LAN stream URL from the
    // paired PC and create the room around it.
    if (widget.remoteMedia != null) {
      setState(() => _creating = true);
      final error = await Get.find<LanController>().createRoomFromRemote(
        widget.remoteMedia!,
        roomName,
        _roomMode,
      );
      if (!mounted) return;
      setState(() => _creating = false);
      if (error != null) {
        Get.snackbar('Could not create room', error);
      }
      return;
    }

    final media = widget.media!;
    // Desktop host: if the LAN host is running, publish this local file as a
    // stream URL so phones can join and watch without a copy (Case B). The
    // host streams from its own address; everyone in the room shares one URL.
    final streamUrl = _hostStreamUrl(media);
    if (streamUrl != null) {
      Get.find<RoomController>().createRoom(
        roomName,
        streamUrl: streamUrl,
        streamTitle: media.name,
        mode: _roomMode,
      );
      return;
    }

    Get.find<RoomController>().createRoom(
      roomName,
      mediaItem: media,
      mode: _roomMode,
    );
  }

  /// The LAN stream URL for a locally-owned [media] when this device is hosting
  /// on the network, or null when it is not (mobile, or host not running).
  String? _hostStreamUrl(Media media) {
    if (!isDesktop || !Get.isRegistered<LanHostService>()) return null;
    final host = LanHostService.to;
    if (!host.isRunning.value) return null;
    return host.streamUrlForMedia(media.id);
  }

  @override
  void initState() {
    super.initState();

    final res = isar.users.where().findAllSync();
    if (res.isNotEmpty) {
      user = res.first;
    } else {
      user = User()..name = '';
      isar.writeTxnSync(() {
        isar.users.putSync(user);
      });
    }

    _nameController.text = user.name;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.purple.withAlpha(100),
            // A bottom sheet only rounds the edge it slides away from; inside
            // a desktop dialog the same shape needs all four corners.
            borderRadius: isDesktop
                ? BorderRadius.circular(20)
                : const BorderRadius.only(
                    topLeft: Radius.circular(26),
                    topRight: Radius.circular(26),
                  ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Create Room", style: Get.textTheme.headlineSmall),
                const SizedBox(height: 20),
                ModernInput(
                  controller: _nameController,
                  icon: Icons.person_2_rounded,
                  hintText: "Enter your name",
                  onChanged: (newUserName) {
                    user.name = newUserName;
                    isar.writeTxnSync(() {
                      isar.users.putSync(user);
                    });
                  },
                ),
                const SizedBox(height: 20),
                ModernInput(
                  controller: _roomNameController,
                  icon: Icons.door_front_door_rounded,
                  hintText: "Enter room name here",
                  onChanged: (newRoomName) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Choose a room vibe',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 142,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: roomPresets.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final preset = roomPresets[index];
                      return _RoomPresetCard(
                        preset: preset,
                        selected: preset.mode == _roomMode,
                        onTap: () => setState(() => _roomMode = preset.mode),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed:
                      _roomNameController.text.trim().isEmpty || _creating
                      ? null
                      : _create,
                  icon: const Icon(Icons.start_rounded, color: Colors.white),
                  label: const Text(
                    "Create",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                  style:
                      ElevatedButton.styleFrom(
                        disabledBackgroundColor: Colors.white12,
                        disabledForegroundColor: Colors.white38,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        backgroundColor: Colors.purpleAccent.withValues(
                          alpha: 0.3,
                        ),
                        shadowColor: Colors.purpleAccent.withValues(alpha: 0.5),
                        elevation: 12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ).copyWith(
                        overlayColor: WidgetStateProperty.resolveWith<Color?>((
                          states,
                        ) {
                          if (states.contains(WidgetState.pressed)) {
                            return Colors.deepPurpleAccent.withValues(
                              alpha: 0.2,
                            );
                          }
                          return null;
                        }),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomPresetCard extends StatelessWidget {
  const _RoomPresetCard({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final RoomPreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: '${preset.label}: ${preset.tagline}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 132,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              preset.accent.withValues(alpha: selected ? .56 : .2),
              preset.secondary.withValues(alpha: selected ? .44 : .12),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? preset.accent : Colors.white12,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: preset.accent.withValues(alpha: .28),
                    blurRadius: 20,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .2),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(7),
                          child: Icon(
                            preset.icon,
                            color: preset.accent,
                            size: 20,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (selected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: preset.accent,
                          size: 18,
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    preset.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    preset.tagline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white60,
                      height: 1.15,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
