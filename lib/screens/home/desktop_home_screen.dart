import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:syncy/bottomsheets/create_room_bottom_sheet.dart';
import 'package:syncy/bottomsheets/join_room_bottom_sheet.dart';
import 'package:syncy/controllers/library_controller.dart';
import 'package:syncy/models/media.dart';
import 'package:syncy/routes/app_routes.dart';
import 'package:syncy/screens/lan/pc_pairing_screen.dart';
import 'package:syncy/screens/search/seach_screen.dart';
import 'package:syncy/utils/platform_utils.dart';
import 'package:syncy/widgets/adaptive_sheet.dart';
import 'package:syncy/widgets/media_card.dart';
import 'package:syncy/widgets/native_purple_mesh_background.dart';

/// The desktop library: chosen folders on the left, their contents on the
/// right.
///
/// Unlike the mobile home screen, nothing appears until the user adds a
/// folder — a PC has no camera roll to surface, and indexing a whole drive
/// unasked would be both slow and wrong.
class DesktopHomeScreen extends GetView<LibraryController> {
  const DesktopHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NativePurpleMeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Row(
            children: [
              _LibrarySidebar(controller: controller),
              Expanded(child: _LibraryContent(controller: controller)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibrarySidebar extends StatelessWidget {
  const _LibrarySidebar({required this.controller});

  final LibraryController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 268,
      margin: const EdgeInsets.fromLTRB(16, 16, 0, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SidebarBrand(),
              Expanded(
                child: Obx(() {
                  if (controller.roots.isEmpty) {
                    return const _SidebarEmptyHint();
                  }
                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    children: [
                      for (final folder in controller.roots)
                        _RootFolderTile(controller: controller, folder: folder),
                    ],
                  );
                }),
              ),
              const Divider(height: 1, color: Colors.white12),
              _SidebarAction(
                icon: Icons.create_new_folder_rounded,
                label: 'Add folder',
                onPressed: controller.addFolder,
                emphasized: true,
              ),
              _SidebarAction(
                icon: IonIcons.log_in,
                label: 'Join a room',
                onPressed: () => showAdaptiveSheet(const JoinRoomBottomSheet()),
              ),
              _SidebarAction(
                icon: Icons.smartphone_rounded,
                label: 'Pair a phone',
                onPressed: () => Get.to(() => const PcPairingScreen()),
              ),
              if (!isWindows)
                _SidebarAction(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  onPressed: () => Get.toNamed(Routes.SETTINGS),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B00EA), Color(0xFFCD34E8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
          ),
          const SizedBox(width: 11),
          const Text(
            'Syncy',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: .3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarEmptyHint extends StatelessWidget {
  const _SidebarEmptyHint();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Text(
          'No folders yet.\nAdd one to build your library.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, height: 1.5, fontSize: 13),
        ),
      ),
    );
  }
}

class _RootFolderTile extends StatelessWidget {
  const _RootFolderTile({required this.controller, required this.folder});

  final LibraryController controller;
  final Folder folder;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSelected = controller.selectedRoot.value?.id == folder.id;
      final subFolders = isSelected ? controller.folderTree : <FolderNode>[];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FolderRow(
            label: folder.name,
            icon: isSelected ? Icons.folder_open_rounded : Icons.folder_rounded,
            depth: 0,
            isActive: isSelected && controller.selectedSubPath.value == null,
            onTap: () => controller.selectRoot(folder),
            trailing: _RootMenu(controller: controller, folder: folder),
          ),
          for (final node in subFolders)
            _FolderRow(
              label: node.name,
              icon: Icons.subdirectory_arrow_right_rounded,
              depth: node.depth + 1,
              count: node.totalCount,
              isActive: controller.selectedSubPath.value == node.path,
              onTap: () => controller.selectSubPath(node.path),
            ),
        ],
      );
    });
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required this.label,
    required this.icon,
    required this.depth,
    required this.isActive,
    required this.onTap,
    this.count,
    this.trailing,
  });

  final String label;
  final IconData icon;
  final int depth;
  final bool isActive;
  final VoidCallback onTap;
  final int? count;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 12.0, bottom: 2),
      child: Material(
        color: isActive
            ? Colors.white.withValues(alpha: .12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: isActive ? Colors.purpleAccent : Colors.white54,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
                if (count != null)
                  Text(
                    '$count',
                    style: const TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RootMenu extends StatelessWidget {
  const _RootMenu({required this.controller, required this.folder});

  final LibraryController controller;
  final Folder folder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 22,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        iconSize: 16,
        tooltip: '',
        icon: const Icon(Icons.more_horiz_rounded, color: Colors.white38),
        color: const Color(0xFF1A0E2E),
        onSelected: (value) {
          if (value == 'rescan') {
            controller.rescanFolder(folder);
          } else if (value == 'remove') {
            _confirmRemove(context);
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'rescan', child: Text('Rescan folder')),
          PopupMenuItem(value: 'remove', child: Text('Remove from library')),
        ],
      ),
    );
  }

  void _confirmRemove(BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A0E2E),
        title: const Text('Remove folder?'),
        content: Text(
          '“${folder.name}” will be removed from your library along with its '
          'thumbnails. The video files on disk are not touched.',
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.removeFolder(folder);
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarAction extends StatelessWidget {
  const _SidebarAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: emphasized
            ? Colors.purpleAccent.withValues(alpha: .22)
            : Colors.white.withValues(alpha: .04),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Colors.white70),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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

class _LibraryContent extends StatelessWidget {
  const _LibraryContent({required this.controller});

  final LibraryController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ContentHeader(controller: controller),
        Expanded(
          child: Obx(() {
            if (controller.roots.isEmpty) {
              return _EmptyLibraryPrompt(onAddFolder: controller.addFolder);
            }
            if (controller.visibleMedia.isEmpty) {
              return _EmptyFolderPrompt(
                isScanning: controller.isScanning.value,
              );
            }
            return _MediaGrid(media: controller.visibleMedia);
          }),
        ),
      ],
    );
  }
}

class _ContentHeader extends StatelessWidget {
  const _ContentHeader({required this.controller});

  final LibraryController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
      child: Obx(() {
        final root = controller.selectedRoot.value;
        final subPath = controller.selectedSubPath.value;
        final title = root == null
            ? 'Your library'
            : subPath == null
            ? root.name
            : subPath.split('/').last;

        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (controller.isScanning.value) ...[
                        const SizedBox.square(
                          dimension: 11,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 7),
                      ],
                      Flexible(
                        child: Text(
                          controller.isScanning.value
                              ? controller.scanStatus.value
                              : '${controller.visibleMedia.length} video'
                                    '${controller.visibleMedia.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (subPath != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: () => controller.selectSubPath(null),
                  icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                  label: const Text('All in folder'),
                ),
              ),
            if (controller.visibleMedia.isNotEmpty)
              IconButton(
                tooltip: 'Search',
                onPressed: () => Get.to(
                  () => SearchScreen(media: controller.visibleMedia),
                  opaque: false,
                  fullscreenDialog: true,
                  transition: Transition.fadeIn,
                ),
                icon: const Icon(Icons.search_rounded),
              ),
          ],
        );
      }),
    );
  }
}

class _MediaGrid extends StatelessWidget {
  const _MediaGrid({required this.media});

  final List<Media> media;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 28),
      itemCount: media.length,
      // Columns grow with the window instead of staying pinned at the phone's
      // two, so a wide monitor is actually used.
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        crossAxisSpacing: 20,
        mainAxisSpacing: 24,
        childAspectRatio: 3 / 4,
      ),
      itemBuilder: (context, index) {
        final item = media[index];
        return MediaCard(
          mediaElement: item,
          isAudio: false,
          onPressed: () =>
              showAdaptiveSheet(CreateRoomBottomSheet(media: item)),
        );
      },
    );
  }
}

class _EmptyLibraryPrompt extends StatelessWidget {
  const _EmptyLibraryPrompt({required this.onAddFolder});

  final VoidCallback onAddFolder;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.folder_special_rounded,
              size: 62,
              color: Colors.white24,
            ),
            const SizedBox(height: 20),
            const Text(
              'Build your library',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 9),
            const Text(
              'Pick the folders your videos live in. Syncy indexes only what '
              'you choose — nothing else on this PC is scanned.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, height: 1.45),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddFolder,
              icon: const Icon(Icons.create_new_folder_rounded),
              label: const Text('Choose a folder'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 16,
                ),
                backgroundColor: Colors.purpleAccent.withValues(alpha: .3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFolderPrompt extends StatelessWidget {
  const _EmptyFolderPrompt({required this.isScanning});

  final bool isScanning;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isScanning) ...[
            const SizedBox.square(
              dimension: 30,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            const Text(
              'Looking for videos…',
              style: TextStyle(color: Colors.white60),
            ),
          ] else ...[
            const Icon(
              Icons.videocam_off_rounded,
              size: 46,
              color: Colors.white24,
            ),
            const SizedBox(height: 14),
            const Text(
              'No videos in this folder',
              style: TextStyle(color: Colors.white60),
            ),
          ],
        ],
      ),
    );
  }
}
