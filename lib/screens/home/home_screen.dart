import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:syncy/bottomsheets/create_room_bottom_sheet.dart';
import 'package:syncy/bottomsheets/join_room_bottom_sheet.dart';
import 'package:syncy/controllers/home_controller.dart';
import 'package:syncy/models/media.dart';
import 'package:syncy/models/media_shelf.dart';
import 'package:syncy/screens/home/desktop_home_screen.dart';
import 'package:syncy/screens/lan/connect_pc_screen.dart';
import 'package:syncy/screens/search/seach_screen.dart';
import 'package:syncy/utils/platform_utils.dart';
import 'package:syncy/widgets/adaptive_sheet.dart';
import 'package:syncy/widgets/floating_navbar.dart';
import 'package:syncy/widgets/media_card.dart';
import 'package:syncy/widgets/native_purple_mesh_background.dart';

/// Entry screen for both form factors.
///
/// Desktop and mobile browse fundamentally different libraries — curated
/// folders versus a device-wide scan — so they get separate screens and
/// separate controllers rather than one widget tree full of platform checks.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return isDesktop ? const DesktopHomeScreen() : const _MobileHomeScreen();
  }
}

class _MobileHomeScreen extends GetView<HomeController> {
  const _MobileHomeScreen();

  @override
  Widget build(BuildContext context) {
    final PageController pageController = PageController(
      initialPage: controller.activeIndex.value,
    );

    return Obx(
      () => NativePurpleMeshBackground(
        accent: Color(controller.selectedAccentValue.value),
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
                        controller.isSyncing.value &&
                            controller.media.isNotEmpty
                        ? Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: SafeArea(
                              child: _MediaRefreshBanner(
                                message: controller.syncStatusMessage.value,
                              ),
                            ),
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
                                  showAdaptiveSheet(
                                    const JoinRoomBottomSheet(),
                                  );
                                },
                              ),
                              NavItem(
                                icon: IonIcons.desktop,
                                label: "PC",
                                onPressed: () =>
                                    Get.to(() => const ConnectPcScreen()),
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

    final shelves = buildMediaShelves(controller.media);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 22, 0, 118),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your cinema',
                  style: TextStyle(
                    fontSize: 29,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Pick a mood, invite your people, stay in sync.',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          for (final shelf in shelves)
            _MediaShelfSection(
              shelf: shelf,
              onFocused: controller.selectMediaAccent,
            ),
        ],
      ),
    );
  }
}

class _MediaShelfSection extends StatelessWidget {
  const _MediaShelfSection({required this.shelf, required this.onFocused});

  final MediaShelf shelf;
  final ValueChanged<Media> onFocused;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 27),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shelf.title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        shelf.subtitle,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${shelf.items.length}',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 244,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: shelf.items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final item = shelf.items[index];
                return SizedBox(
                  width: 158,
                  child: MediaCard(
                    mediaElement: item,
                    compact: true,
                    onFocused: onFocused,
                    onPressed: () =>
                        showAdaptiveSheet(CreateRoomBottomSheet(media: item)),
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
              'Syncing your media',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 7),
            Text(
              'Checking this device for videos. Your library will appear as soon as they are found.',
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
  const _MediaRefreshBanner({required this.message});

  final String message;

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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox.square(
              dimension: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 9),
            Text(
              message,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
