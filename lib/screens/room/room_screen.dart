import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:syncy/controllers/home_controller.dart';
import 'package:syncy/controllers/room_controller.dart';
import 'package:syncy/screens/search/seach_screen.dart';
import 'package:syncy/widgets/enhanced_chat_panel.dart';
import 'package:syncy/widgets/custom_video_player.dart';
import 'package:syncy/widgets/reliable_reaction_overlay.dart';
import 'package:syncy/widgets/native_purple_mesh_background.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final RoomController controller = Get.find<RoomController>();

  @override
  void initState() {
    super.initState();

    // Enable wake lock to prevent screen from turning off
    WakelockPlus.enable();

    if (controller.room.value.currentVideoUrl != null) {
      setupPlayer();
    }
  }

  void exitPop() {
    PanaraConfirmDialog.showAnimatedGrow(
      context,
      title: 'Confirmation',
      message: 'Are you sure you want to leave the room?',
      confirmButtonText: 'Leave',
      cancelButtonText: 'Cancel',
      onTapCancel: () {
        Navigator.pop(context);
      },
      onTapConfirm: () {
        Navigator.pop(context);
        Get.back();
        Get.back();
      },
      panaraDialogType: PanaraDialogType.warning,
    );
  }

  Future setupPlayer() async {
    final path = controller.room.value.currentVideoUrl;
    if (path == null || path.isEmpty) return;
    controller.beginMediaLoad('Opening media…');
    final previous = controller.videoController;
    final player = VideoPlayerController.file(
      File(path),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    controller.videoController = player;
    if (mounted) setState(() {});
    await previous?.dispose();

    player.addListener(() {
      if (mounted && controller.videoController == player) setState(() {});
    });
    try {
      await player.initialize();
      await controller.onPlayerReady();
      controller.finishMediaLoad();
      if (mounted) setState(() {});
    } catch (error) {
      controller.failMediaLoad(error);
      if (mounted) setState(() {});
    }
  }

  void _chooseMedia() {
    Get.to(
      () => SearchScreen(
        media: Get.find<HomeController>().media,
        onSelect: (selectedMedia) {
          controller.setMedia(selectedMedia);
          setupPlayer();
        },
      ),
    );
  }

  @override
  void dispose() {
    // Disable wake lock when leaving the room
    WakelockPlus.disable();

    controller.videoController?.dispose();
    controller.videoController = null;
    unawaited(controller.leaveRoom());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NativePurpleMeshBackground(
      child: Stack(
        children: [
          Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              title: Text(controller.room.value.name),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              leading: IconButton(
                onPressed: exitPop,
                icon: const Icon(Icons.exit_to_app_rounded),
              ),
              actions: [
                Center(child: _SyncStatusPill(controller: controller)),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: controller.room.value.id),
                    ).then((_) {
                      Get.snackbar(
                        'Copied',
                        'The room ID was copied successfully!',
                      );
                    });
                  },
                  icon: Icon(Icons.share_rounded),
                ),
                IconButton(
                  onPressed: () {
                    Get.bottomSheet(
                      ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.purple.withAlpha(100),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(26),
                                topRight: Radius.circular(26),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 6,
                              ),
                              child: Obx(
                                () => ListView.builder(
                                  itemCount: controller.users.length,
                                  itemBuilder: (ctx, i) => ListTile(
                                    title: Text(controller.users[i].name),
                                    trailing: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      width: 15,
                                      height: 15,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: controller.users[i].online
                                              ? [
                                                  Colors.greenAccent,
                                                  Colors.green,
                                                ]
                                              : [Colors.redAccent, Colors.red],
                                          // center: Alignment.center,
                                          // radius: 0.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  icon: Icon(Iconsax.profile_2user_outline),
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            body: PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop) exitPop();
              },
              child: Builder(
                builder: (context) {
                  final keyboardOpen =
                      MediaQuery.of(context).viewInsets.bottom > 0;
                  return Stack(
                    children: [
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            controller.videoController != null
                                ? Container(
                                    constraints: BoxConstraints(
                                      maxHeight:
                                          MediaQuery.of(context).size.height *
                                          0.4,
                                    ),
                                    alignment: Alignment.center,
                                    child: AspectRatio(
                                      aspectRatio: controller
                                          .videoController!
                                          .value
                                          .aspectRatio,
                                      child: Stack(
                                        children: [
                                          VideoPlayer(
                                            controller.videoController!,
                                          ),
                                          ControlsOverlay(
                                            controller:
                                                controller.videoController!,
                                            roomController: controller,
                                            onPlayToggle: (isPlaying) {
                                              if (isPlaying) {
                                                controller.playVideo();
                                              } else {
                                                controller.pauseVideo();
                                              }
                                            },
                                            onSeek: (position) {
                                              controller.seekVideo(position);
                                            },
                                          ),
                                          Positioned.fill(
                                            child: _MediaStatusOverlay(
                                              onChooseMedia: _chooseMedia,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF8E2DE2),
                                            Color(0xFF4A00E0),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.purple.withValues(
                                              alpha: 0.4,
                                            ),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _chooseMedia,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 32,
                                            vertical: 18,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                        child: Text(
                                          controller
                                                      .room
                                                      .value
                                                      .currentVideoTitle ==
                                                  null
                                              ? 'Choose Media'
                                              : 'Choose Matching Media',
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                            // Reaction bar - hidden when keyboard is open
                            if (!keyboardOpen) ...[
                              const SizedBox(height: 12),
                              ReactionBar(controller: controller),
                            ],
                            const SizedBox(height: 12),
                            // Chat panel with fixed height
                            SizedBox(
                              height: keyboardOpen
                                  ? MediaQuery.of(context).size.height * 0.4
                                  : MediaQuery.of(context).size.height * 0.45,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: ChatPanel(),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                      // Floating reactions overlay
                      ReactionOverlay(controller: controller),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncStatusPill extends StatelessWidget {
  const _SyncStatusPill({required this.controller});

  final RoomController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final connected = controller.wsService.isJoined.value;
      final syncing = controller.isApplyingSync.value;
      final color = connected && !syncing
          ? const Color(0xFF55D6A7)
          : const Color(0xFFFFC857);
      return Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .26),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: .45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              controller.syncStatus.value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    });
  }
}

class _MediaStatusOverlay extends StatelessWidget {
  const _MediaStatusOverlay({required this.onChooseMedia});

  final VoidCallback onChooseMedia;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RoomController>();
    return Obx(() {
      final loading = controller.isMediaLoading.value;
      final error = controller.mediaLoadError.value;
      final requiresMedia = controller.requiresMediaSelection.value;
      if (!loading && error == null && !requiresMedia) {
        return const SizedBox.shrink();
      }
      return ColoredBox(
        color: Colors.black.withValues(alpha: .72),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading)
                  const SizedBox.square(
                    dimension: 34,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                else if (error != null)
                  const Icon(Icons.error_outline_rounded, size: 38),
                if (requiresMedia && error == null)
                  const Icon(Icons.video_file_rounded, size: 38),
                const SizedBox(height: 14),
                Text(
                  error ?? controller.mediaLoadMessage.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                if (loading) ...[
                  const SizedBox(height: 5),
                  const Text(
                    'Preparing playback and matching the room position',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ] else if (requiresMedia) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: onChooseMedia,
                    icon: const Icon(Icons.folder_open_rounded),
                    label: const Text('Choose matching file'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}
