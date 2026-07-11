import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:syncy/bottomsheets/create_room_bottom_sheet.dart';
import 'package:syncy/bottomsheets/join_room_bottom_sheet.dart';
import 'package:syncy/controllers/home_controller.dart';
import 'package:syncy/screens/search/seach_screen.dart';
import 'package:syncy/widgets/floating_navbar.dart';
import 'package:syncy/widgets/media_card.dart';
import 'package:syncy/widgets/native_purple_mesh_background.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PageController pageController = PageController(
      initialPage: controller.activeIndex.value,
    );

    return NativePurpleMeshBackground(
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                Obx(
                  () => PageView(
                    controller: pageController,
                    onPageChanged: (index) =>
                        controller.activeIndex.value = index,
                    children: [_buildAudioPage(), _buildVideoPage()],
                  ),
                ),
                Obx(
                  () =>
                      controller.isLoading.value && controller.media.isNotEmpty
                      ? const Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(child: _MediaRefreshBanner()),
                        )
                      : const SizedBox.shrink(),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Obx(
                        () => FloatingBottomBar(
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
                        ),
                      ),
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
                              Get.to(
                                () => SearchScreen(media: controller.media),
                                opaque: false,
                                fullscreenDialog: true,
                                transition: Transition.fadeIn,
                              );
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
      ),
    );
  }

  Widget _buildAudioPage() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(IonIcons.musical_note, size: 80, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Audio feature coming soon!',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
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
            const Text(
              'Storage permission required',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
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
      return const _InitialMediaLoadingState();
    }

    if (controller.media.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No media files found',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
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
              onPressed: () =>
                  Get.bottomSheet(CreateRoomBottomSheet(media: mediaElement)),
            );
          },
        ),
      ),
    );
  }
}

class _InitialMediaLoadingState extends StatelessWidget {
  const _InitialMediaLoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(28),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF120C20).withValues(alpha: .82),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: .1)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 38,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(height: 18),
            Text(
              'Building your media library',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 7),
            Text(
              'Finding videos and preparing previews. Your files stay on this device.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaRefreshBanner extends StatelessWidget {
  const _MediaRefreshBanner();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF181023).withValues(alpha: .94),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 9),
            Text(
              'Refreshing media library…',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
