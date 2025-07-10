import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:syncy/controllers/home_controller.dart';
import 'package:syncy/controllers/room_controller.dart';
import 'package:syncy/screens/search/seach_screen.dart';
import 'package:syncy/widgets/custom_video_player.dart';
import 'package:video_player/video_player.dart';

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

    if (controller.room.value.currentVideoUrl != null) {
      setupPlayer();
    }
  }

  void exitPop() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.scale,
      title: 'Confirmation',
      desc: 'Are you sure you want to leave the room?',
      btnCancelOnPress: () {},
      btnOkOnPress: () {
        Get.back();
        Get.back();
      },
    ).show();
  }

  Future setupPlayer() async {
    controller.videoController = VideoPlayerController.file(
      File(controller.room.value.currentVideoUrl!),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    controller.videoController?.addListener(() {
      if (mounted) {
        setState(() {});
        // print(controller.videoController!.value.position);
        // print(controller.videoController!.value.isPlaying);
      }
    });
    await controller.videoController?.initialize();
    
    // Trigger subtitle reload if subtitles are available
    if (controller.currentSubtitlePath.value != null) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    controller.videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: 0.3,
          child: const BlurHash(
            hash:
                "^2701,bB6rW-Sbj[SpW,sHa{WmjuW~W,sHj[a#fQwmWlfOo4Wma}R~f9o3jujwfPn:aya^fRa_fOSZfSn.fPfRfOssa_Wnjua^a|W*jvjvjsfRa#",
          ),
        ),
        Scaffold(
          appBar: AppBar(
            title: Text(controller.room.value.name),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              onPressed: exitPop,
              icon: const Icon(Icons.exit_to_app_rounded),
            ),
            actions: [
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
                            child: Obx(() => ListView.builder(
                                itemCount: controller.users.length,
                                itemBuilder: (ctx, i) => ListTile(
                                  title: Text(controller.users[i].name),
                                  trailing: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    width: 15,
                                    height: 15,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: controller.users[i].online
                                            ? [Colors.greenAccent, Colors.green]
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
              if (didPop) {
                print("Route Popped!");
              } else {
                exitPop();
              }
            },
            child: Column(
              children: [
                controller.videoController != null
                    ? AspectRatio(
                        aspectRatio:
                            controller.videoController!.value.aspectRatio,
                        child: Stack(
                          children: [
                            VideoPlayer(controller.videoController!),
                            ControlsOverlay(
                              controller: controller.videoController!,
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
                          ],
                        ),
                      )
                    : Center(
                        child: Container(
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
                            onPressed: () {
                              Get.to(
                                () => SearchScreen(
                                  media: Get.find<HomeController>().media,
                                  onSelect: (selectedMedia) {
                                    controller.setMedia(selectedMedia);
                                    setupPlayer();
                                  },
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                            child: const Text(
                              "Choose Media",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
