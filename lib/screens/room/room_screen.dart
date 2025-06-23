import 'dart:io';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:get/get.dart';
import 'package:syncy/controllers/home_controller.dart';
import 'package:syncy/controllers/room_controller.dart';
import 'package:syncy/screens/search/seach_screen.dart';
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
    controller.videoController?.initialize();
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
            hash: "^2701,bB6rW-Sbj[SpW,sHa{WmjuW~W,sHj[a#fQwmWlfOo4Wma}R~f9o3jujwfPn:aya^fRa_fOSZfSn.fPfRfOssa_Wnjua^a|W*jvjvjsfRa#",
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
                  Clipboard.setData(ClipboardData(text: controller.room.value.id)).then((_) {
                    Get.snackbar('Copied', 'The room ID was copied successfully!');
                  });
                },
                icon: Icon(Icons.share_rounded),
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
            child: controller.videoController != null? AspectRatio(
              aspectRatio: controller.videoController!.value.aspectRatio,
              child: Stack(
                children: [
                  VideoPlayer(controller.videoController!),
                  _ControlsOverlay(
                    controller: controller.videoController!,
                    onPlayToggle: (isPlaying) {
                      if (isPlaying) {
                        controller.playVideo();
                      } else {
                        controller.pauseVideo();
                      }
                    },
                  ),
                ],
              ),
            ) : Center(
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
                    Get.to(() => SearchScreen(
                      media: Get.find<HomeController>().media,
                      onSelect: (selectedMedia) {
                        controller.setMedia(selectedMedia);
                        setupPlayer();
                      },
                    ));
                  },
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
                  child: const Text("Choose Media", style: TextStyle(color: Colors.white),),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({required this.controller, this.onPlayToggle});

  static const List<Duration> _exampleCaptionOffsets = <Duration>[
    Duration(seconds: -10),
    Duration(seconds: -3),
    Duration(seconds: -1, milliseconds: -500),
    Duration(milliseconds: -250),
    Duration.zero,
    Duration(milliseconds: 250),
    Duration(seconds: 1, milliseconds: 500),
    Duration(seconds: 3),
    Duration(seconds: 10),
  ];
  static const List<double> _examplePlaybackRates = <double>[
    0.25,
    0.5,
    1.0,
    1.5,
    2.0,
    3.0,
    5.0,
    10.0,
  ];

  final VideoPlayerController controller;
  final Function(bool isPlaying)? onPlayToggle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: controller.value.isPlaying
              ? const SizedBox.shrink()
              : Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 100.0,
                      semanticLabel: 'Play',
                    ),
                  ),
                ),
        ),
        GestureDetector(
          onTap: () {
            controller.value.isPlaying ? controller.pause() : controller.play();
            
            if (onPlayToggle != null) {
              onPlayToggle!(controller.value.isPlaying);
            }
          },
        ),
        Align(
          alignment: Alignment.topLeft,
          child: PopupMenuButton<Duration>(
            initialValue: controller.value.captionOffset,
            tooltip: 'Caption Offset',
            onSelected: (Duration delay) {
              controller.setCaptionOffset(delay);
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem<Duration>>[
                for (final Duration offsetDuration in _exampleCaptionOffsets)
                  PopupMenuItem<Duration>(
                    value: offsetDuration,
                    child: Text('${offsetDuration.inMilliseconds}ms'),
                  )
              ];
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                // Using less vertical padding as the text is also longer
                // horizontally, so it feels like it would need more spacing
                // horizontally (matching the aspect ratio of the video).
                vertical: 12,
                horizontal: 16,
              ),
              child: Text('${controller.value.captionOffset.inMilliseconds}ms'),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: PopupMenuButton<double>(
            initialValue: controller.value.playbackSpeed,
            tooltip: 'Playback speed',
            onSelected: (double speed) {
              controller.setPlaybackSpeed(speed);
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem<double>>[
                for (final double speed in _examplePlaybackRates)
                  PopupMenuItem<double>(
                    value: speed,
                    child: Text('${speed}x'),
                  )
              ];
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                // Using less vertical padding as the text is also longer
                // horizontally, so it feels like it would need more spacing
                // horizontally (matching the aspect ratio of the video).
                vertical: 12,
                horizontal: 16,
              ),
              child: Text('${controller.value.playbackSpeed}x'),
            ),
          ),
        ),
      ],
    );
  }
}