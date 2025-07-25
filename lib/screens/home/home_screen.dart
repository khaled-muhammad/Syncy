import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:syncy/bottomsheets/create_room_bottom_sheet.dart';
import 'package:syncy/bottomsheets/join_room_bottom_sheet.dart';
import 'package:syncy/controllers/home_controller.dart';
import 'package:syncy/screens/search/seach_screen.dart';
import 'package:syncy/widgets/floating_navbar.dart';
import 'package:syncy/widgets/media_card.dart';
import 'package:syncy/models/media.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PageController pageController = PageController(initialPage: controller.activeIndex.value);

    return Stack(
      children: [
        const BlurHash(hash: "^2701,bB6rW-Sbj[SpW,sHa{WmjuW~W,sHj[a#fQwmWlfOo4Wma}R~f9o3jujwfPn:aya^fRa_fOSZfSn.fPfRfOssa_Wnjua^a|W*jvjvjsfRa#"),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Obx(() => PageView(
                    controller: pageController,
                    onPageChanged: (index) => controller.activeIndex.value = index,
                    children: [
                      _buildAudioPage(),
                      _buildVideoPage(),
                    ],
                  )),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Obx(() => FloatingBottomBar(
                          activeIndex: controller.activeIndex.value,
                          navItems: [
                            NavItem(
                              icon: IonIcons.disc,
                              label: "Audio",
                              onPressed: () {
                                controller.activeIndex.value = 0;
                                pageController.jumpToPage(0);
                              },
                            ),
                            NavItem(
                              icon: IonIcons.home,
                              label: "Home",
                              onPressed: () {
                                controller.activeIndex.value = 1;
                                pageController.jumpToPage(1);
                              },
                            ),
                            NavItem(
                              icon: IonIcons.log_in,
                              label: "Join",
                              onPressed: () {
                                controller.activeIndex.value = 1;
                                Get.bottomSheet(JoinRoomBottomSheet());
                              },
                            ),
                          ],
                        )),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                top: 36,
                child: Hero(
                  tag: 'search-btn',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white24,
                        ),
                        child: IconButton(
                          style: IconButton.styleFrom(
                            foregroundColor: Colors.white,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            fixedSize: const Size(52, 52),
                          ),
                          onPressed: () {
                            Get.to(() => SearchScreen(media: controller.media),
                                opaque: false, fullscreenDialog: true, transition: Transition.fadeIn);
                          },
                          icon: const Icon(Icons.search_rounded),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAudioPage() {
    return SafeArea(
      child: Center(child: Text("Currently: Under development"),),
    );
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(IonIcons.musical_note, size: 80, color: Colors.white),
            const SizedBox(height: 16),
            const Text('Audio feature coming soon!', style: TextStyle(fontSize: 18, color: Colors.white70)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => controller.refreshMediaFiles(),
              child: const Text('Refresh Media'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPage() {
    if (!controller.hasPermission.value) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Storage permission required', style: TextStyle(fontSize: 18, color: Colors.white)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: controller.checkPermissions,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      );
    }

    if (controller.isLoading.value && controller.media.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading media files...', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    if (controller.media.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No media files found', style: TextStyle(fontSize: 18, color: Colors.white)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: controller.refreshMediaFiles,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: GridView.builder(
          itemCount: controller.media.length,
          padding: const EdgeInsets.only(bottom: 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 25,
            childAspectRatio: 3 / 5,
          ),
          itemBuilder: (context, index) {
            final mediaElement = controller.media[index];
            return MediaCard(
              mediaElement: mediaElement,
              isAudio: false, // update this when audio support is added
              onPressed: () => Get.bottomSheet(CreateRoomBottomSheet(media: mediaElement)),
            );
          },
        ),
      ),
    );
  }
}