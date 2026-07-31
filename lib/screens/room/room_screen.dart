import 'dart:async';
import 'dart:io';

import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:syncy/controllers/home_controller.dart';
import 'package:syncy/controllers/library_controller.dart';
import 'package:syncy/controllers/room_controller.dart';
import 'package:syncy/screens/search/seach_screen.dart';
import 'package:syncy/widgets/adaptive_sheet.dart';
import 'package:syncy/widgets/ambient_video_surface.dart';
import 'package:syncy/widgets/enhanced_chat_panel.dart';
import 'package:syncy/widgets/custom_video_player.dart';
import 'package:syncy/widgets/reliable_reaction_overlay.dart';
import 'package:syncy/widgets/native_purple_mesh_background.dart';
import 'package:syncy/widgets/room_invite_sheet.dart';
import 'package:syncy/widgets/room_participants_sheet.dart';
import 'package:syncy/widgets/session_scorecard.dart';
import 'package:syncy/widgets/watch_lobby.dart';
import 'package:syncy/services/player/sync_player_factory.dart';
import 'package:syncy/models/room_preset.dart';
import 'package:syncy/utils/platform_utils.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final RoomController controller = Get.find<RoomController>();
  Worker? _streamWorker;

  @override
  void initState() {
    super.initState();

    // Enable wake lock to prevent screen from turning off
    WakelockPlus.enable();

    if (controller.room.value.currentVideoUrl != null) {
      setupPlayer();
    }

    // When the host switches to (or a joiner receives) a LAN stream URL after
    // the screen is already open, re-open the player against it.
    _streamWorker = ever(controller.pendingStreamUrl, (String? url) {
      if (url != null && url.isNotEmpty) {
        controller.pendingStreamUrl.value = null;
        setupPlayer();
      }
    });
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
    // A LAN-hosted video arrives as an http(s) URL (streamed from a paired
    // PC); anything else is a local file path on this device.
    final isNetwork = path.startsWith('http://') || path.startsWith('https://');
    final player = isNetwork
        ? createSyncPlayerFromUrl(path)
        : createSyncPlayer(File(path));
    if (previous != null) {
      controller.detachVideoController(previous);
    }
    controller.attachVideoController(player);
    if (mounted) setState(() {});
    previous?.dispose();

    player.addListener(() {
      if (!mounted || controller.videoController != player) return;
      // A stream that drops after it was already playing (host slept, phone
      // left Wi-Fi) surfaces as an error on the value; reflect it so the
      // overlay offers a retry rather than silently freezing.
      if (player.value.hasError && controller.mediaLoadError.value == null) {
        controller.failMediaLoad(
          player.value.errorDescription ?? 'stream error',
        );
      }
      unawaited(
        controller.recordPlaybackProgress(
          player.value.position,
          duration: player.value.duration,
        ),
      );
      setState(() {});
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
    // The two form factors keep their libraries in different controllers:
    // desktop indexes user-chosen folders, mobile scans the device.
    final library = isDesktop
        ? Get.find<LibraryController>().visibleMedia
        : Get.find<HomeController>().media;

    Get.to(
      () => SearchScreen(
        media: library,
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

    _streamWorker?.dispose();
    final player = controller.videoController;
    if (player != null) {
      unawaited(
        controller.recordPlaybackProgress(
          player.value.position,
          duration: player.value.duration,
          force: true,
        ),
      );
    }
    controller.detachVideoController(player);
    player?.dispose();
    unawaited(controller.leaveRoom());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => NativePurpleMeshBackground(
        accent: controller.room.value.mode.preset.accent,
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
                    tooltip: 'Session scorecard',
                    onPressed: () => controller.showScorecard.value = true,
                    icon: const Icon(Icons.auto_awesome_rounded),
                  ),
                  IconButton(
                    tooltip: 'Invite people',
                    onPressed: () {
                      showAdaptiveSheet(
                        RoomInviteSheet(room: controller.room.value),
                      );
                    },
                    icon: const Icon(Icons.share_rounded),
                  ),
                  IconButton(
                    onPressed: () {
                      showAdaptiveSheet(
                        RoomParticipantsSheet(controller: controller),
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
                        if (isDesktop)
                          _buildDesktopBody()
                        else
                          _buildMobileBody(context, keyboardOpen),
                        // Floating reactions overlay
                        ReactionOverlay(controller: controller),
                        Obx(
                          () => controller.lobbyVisible.value
                              ? Positioned.fill(
                                  child: WatchLobby(
                                    controller: controller,
                                    onStart: controller.startMovieFromLobby,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        Obx(
                          () => controller.showScorecard.value
                              ? Positioned.fill(
                                  child: SessionScorecard(
                                    controller: controller,
                                    onClose: () =>
                                        controller.showScorecard.value = false,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Phone layout: video, reactions, and chat stacked in one scroll view.
  Widget _buildMobileBody(BuildContext context, bool keyboardOpen) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      child: Column(
        children: [
          controller.videoController != null
              ? Container(
                  constraints: BoxConstraints(maxHeight: screenHeight * 0.4),
                  alignment: Alignment.center,
                  child: _buildStage(),
                )
              : Center(child: _buildChooseMediaButton()),
          // Reaction bar - hidden when keyboard is open
          if (!keyboardOpen) ...[
            const SizedBox(height: 12),
            ReactionBar(controller: controller),
          ],
          const SizedBox(height: 12),
          // Chat panel with fixed height
          SizedBox(
            height: keyboardOpen ? screenHeight * 0.4 : screenHeight * 0.45,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: ChatPanel(),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /// Desktop layout: the video takes the window, chat sits alongside it.
  ///
  /// The phone's 40%-height cap and vertical stacking exist because a portrait
  /// screen has no room for both. A desktop window does, so the video is given
  /// all the space left over instead of being boxed into a strip.
  Widget _buildDesktopBody() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: Center(
                    child: controller.videoController != null
                        ? _buildStage()
                        : _buildChooseMediaButton(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ReactionBar(controller: controller),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 360,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 12, 12),
            child: const ChatPanel(),
          ),
        ),
      ],
    );
  }

  /// The video surface with Syncy's controls and load-status overlay on top.
  Widget _buildStage() {
    final player = controller.videoController!;

    return AspectRatio(
      aspectRatio: player.value.aspectRatio,
      child: Stack(
        children: [
          AmbientVideoSurface(
            fallback: controller.room.value.mode.preset.accent,
            child: player.buildSurface(),
          ),
          ControlsOverlay(
            controller: player,
            roomController: controller,
            onPlayToggle: (isPlaying) {
              if (isPlaying) {
                controller.playVideo();
              } else {
                controller.pauseVideo();
              }
            },
            onSeek: controller.canSeek
                ? (position) => controller.seekVideo(position)
                : null,
          ),
          Positioned.fill(
            child: _MediaStatusOverlay(
              onChooseMedia: _chooseMedia,
              onRetry: setupPlayer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChooseMediaButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.4),
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
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        child: Text(
          controller.room.value.currentVideoTitle == null
              ? 'Choose Media'
              : 'Choose Matching Media',
          style: const TextStyle(color: Colors.white),
        ),
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
  const _MediaStatusOverlay({
    required this.onChooseMedia,
    required this.onRetry,
  });

  final VoidCallback onChooseMedia;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RoomController>();
    return Obx(() {
      final loading = controller.isMediaLoading.value;
      final error = controller.mediaLoadError.value;
      final requiresMedia = controller.requiresMediaSelection.value;
      final canRetry = error != null && controller.isStreamingMedia;
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
                ] else if (canRetry) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
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
