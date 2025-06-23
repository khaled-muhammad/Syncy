import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:get/get.dart';
import 'package:syncy/bottomsheets/create_room_bottom_sheet.dart';
import 'package:syncy/bottomsheets/join_room_bottom_sheet.dart';
import 'package:syncy/controllers/home_controller.dart';
import 'package:syncy/screens/search/seach_screen.dart';
import 'package:syncy/widgets/floating_navbar.dart';
import 'package:syncy/widgets/media_card.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BlurHash(hash: "^2701,bB6rW-Sbj[SpW,sHa{WmjuW~W,sHj[a#fQwmWlfOo4Wma}R~f9o3jujwfPn:aya^fRa_fOSZfSn.fPfRfOssa_Wnjua^a|W*jvjvjsfRa#"),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Obx(() {
                if (!controller.hasPermission.value) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Storage permission required',
                          style: TextStyle(fontSize: 18),
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
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading media files...'),
                      ],
                    ),
                  );
                }
        
                if (controller.media.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'No media files found',
                          style: TextStyle(fontSize: 18),
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 20,
                    ),
                    child: GridView.builder(
                      itemCount: controller.media.length,
                      padding: const EdgeInsets.only(bottom: 100),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 25,
                        childAspectRatio: 3 / 5,
                      ),
                      itemBuilder: (context, index) {
                        final mediaElement = controller.media[index];
                        return MediaCard(
                          mediaElement: mediaElement,
                          onPressed: () {
                            Get.bottomSheet(CreateRoomBottomSheet(media: mediaElement,));
                          },
                        );
                      },
                    ),
                  ),
                );
              }),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Obx(() => FloatingBottomBar(
                        activeIndex: controller.activeIndex.value,
                        navItems: [
                          NavItem(
                            icon: Icons.folder_outlined,
                            label: "Files",
                            onPressed: () => controller.activeIndex.value = 0,
                          ),
                          NavItem(
                            icon: Icons.home_rounded,
                            label: "Home",
                            onPressed: () => controller.activeIndex.value = 1,
                          ),
                          NavItem(
                            icon: Icons.login_outlined,
                            label: "Join",
                            onPressed: () {
                              controller.activeIndex.value = 2;
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
                    borderRadius: BorderRadiusGeometry.circular(100),
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
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            fixedSize: Size(52, 52),
                          ),
                          onPressed: () {
                            Get.to(() => SearchScreen(media: controller.media,), opaque: false, fullscreenDialog: true, transition: Transition.fadeIn);
                          },
                          icon: Icon(Icons.search_rounded)
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
}