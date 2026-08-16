import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncy/bottomsheets/create_room_bottom_sheet.dart';
import 'package:syncy/controllers/lan_controller.dart';
import 'package:syncy/models/remote_media.dart';
import 'package:syncy/widgets/adaptive_sheet.dart';
import 'package:syncy/widgets/native_purple_mesh_background.dart';

/// Phone screen: explore a paired PC's folders, search its videos, then either
/// watch directly or create a room that streams the selected file over LAN.
class PcLibraryScreen extends StatefulWidget {
  const PcLibraryScreen({super.key});

  @override
  State<PcLibraryScreen> createState() => _PcLibraryScreenState();
}

class _PcLibraryScreenState extends State<PcLibraryScreen> {
  final _searchController = TextEditingController();
  late final LanController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<LanController>();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    controller.searchLibrary('');
  }

  void _handleBack() {
    if (controller.isSearching) {
      _clearSearch();
    } else if (controller.currentDirectory.value.isNotEmpty) {
      controller.navigateToParentDirectory();
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final canPop =
          !controller.isSearching && controller.currentDirectory.value.isEmpty;
      return PopScope(
        canPop: canPop,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _handleBack();
        },
        child: NativePurpleMeshBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              leading: IconButton(
                tooltip: canPop ? 'Back' : 'Up',
                icon: Icon(
                  canPop
                      ? Icons.arrow_back_rounded
                      : Icons.arrow_upward_rounded,
                ),
                onPressed: _handleBack,
              ),
              title: Text(controller.selectedPc.value?.name ?? 'PC library'),
              actions: [
                IconButton(
                  tooltip: controller.isRefreshingLibrary
                      ? 'Restart refresh'
                      : 'Refresh library',
                  icon: Icon(
                    controller.isRefreshingLibrary
                        ? Icons.sync_rounded
                        : Icons.refresh_rounded,
                  ),
                  onPressed: () {
                    final pc = controller.selectedPc.value;
                    if (pc != null) {
                      _searchController.clear();
                      controller.openLibrary(pc);
                    }
                  },
                ),
              ],
            ),
            body: _LibraryBody(
              controller: controller,
              searchController: _searchController,
              onClearSearch: _clearSearch,
            ),
          ),
        ),
      );
    });
  }
}

class _LibraryBody extends StatelessWidget {
  const _LibraryBody({
    required this.controller,
    required this.searchController,
    required this.onClearSearch,
  });

  final LanController controller;
  final TextEditingController searchController;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    if (controller.isInitialLibraryLoad) return const _LibrarySkeleton();
    final error = controller.libraryError.value;
    if (error != null) return _LibraryError(message: error);
    if (controller.remoteLibrary.isEmpty) {
      return const Center(
        child: Text(
          'This PC has no videos in its library yet.',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }

    return Column(
      children: [
        if (controller.isRefreshingLibrary)
          const LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: Colors.transparent,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: TextField(
            controller: searchController,
            onChanged: controller.searchLibrary,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search this PC',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.isSearching
                  ? IconButton(
                      tooltip: 'Clear search',
                      onPressed: onClearSearch,
                      icon: const Icon(Icons.close_rounded),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withValues(alpha: .07),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (controller.isSearching)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${controller.visibleRemoteMedia.length} result${controller.visibleRemoteMedia.length == 1 ? '' : 's'} across this PC',
                style: const TextStyle(color: Colors.white54, fontSize: 12.5),
              ),
            ),
          )
        else
          _Breadcrumbs(controller: controller),
        Expanded(child: _LibraryExplorer(controller: controller)),
      ],
    );
  }
}

class _LibrarySkeleton extends StatefulWidget {
  const _LibrarySkeleton();

  @override
  State<_LibrarySkeleton> createState() => _LibrarySkeletonState();
}

class _LibrarySkeletonState extends State<_LibrarySkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
      lowerBound: 0,
      upperBound: 1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final color = Colors.white.withValues(alpha: .07 + _pulse.value * .07);
        return IgnorePointer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SkeletonBox(
                height: 56,
                color: color,
                margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: _SkeletonBox(
                  height: 30,
                  width: 116,
                  color: color,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: _SkeletonBox(height: 68, color: color)),
                    const SizedBox(width: 12),
                    Expanded(child: _SkeletonBox(height: 68, color: color)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 18,
                    childAspectRatio: 3 / 4,
                  ),
                  itemCount: 6,
                  itemBuilder: (_, _) => _SkeletonBox(color: color),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    this.height,
    this.width,
    required this.color,
    this.margin,
  });

  final double? height;
  final double? width;
  final Color color;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .04)),
      ),
    );
  }
}

class _Breadcrumbs extends StatelessWidget {
  const _Breadcrumbs({required this.controller});

  final LanController controller;

  @override
  Widget build(BuildContext context) {
    final crumbs = controller.libraryBreadcrumbs;
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        scrollDirection: Axis.horizontal,
        itemCount: crumbs.length,
        separatorBuilder: (_, _) => const Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: Colors.white30,
        ),
        itemBuilder: (context, index) {
          final crumb = crumbs[index];
          final active = index == crumbs.length - 1;
          return ActionChip(
            avatar: index == 0
                ? const Icon(Icons.home_rounded, size: 16)
                : null,
            label: Text(crumb.label),
            onPressed: active
                ? null
                : () => controller.openDirectory(crumb.key),
            backgroundColor: active
                ? Theme.of(context).colorScheme.primary.withValues(alpha: .28)
                : Colors.white.withValues(alpha: .06),
            side: BorderSide(
              color: active
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: .5)
                  : Colors.white12,
            ),
            labelStyle: TextStyle(
              color: active ? Colors.white : Colors.white70,
              fontSize: 12,
            ),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}

class _LibraryExplorer extends StatelessWidget {
  const _LibraryExplorer({required this.controller});

  final LanController controller;

  @override
  Widget build(BuildContext context) {
    final folders = controller.childDirectories;
    final videos = controller.visibleRemoteMedia;
    if (folders.isEmpty && videos.isEmpty) {
      return _ExplorerEmpty(isSearch: controller.isSearching);
    }

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        if (folders.isNotEmpty) ...[
          const _SectionHeader(label: 'Folders'),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.75,
              ),
              itemCount: folders.length,
              itemBuilder: (context, index) => _FolderCard(
                folder: folders[index],
                onTap: () => controller.openDirectory(folders[index].key),
              ),
            ),
          ),
        ],
        if (videos.isNotEmpty) ...[
          _SectionHeader(
            label: controller.isSearching ? 'Search results' : 'Videos',
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                crossAxisSpacing: 14,
                mainAxisSpacing: 18,
                childAspectRatio: 3 / 4,
              ),
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final media = videos[index];
                return _RemoteCard(
                  controller: controller,
                  media: media,
                  showPath: controller.isSearching,
                  onTap: () => showAdaptiveSheet(
                    CreateRoomBottomSheet(remoteMedia: media),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({required this.folder, required this.onTap});

  final RemoteDirectory folder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.folder_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 30,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      folder.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${folder.mediaCount} video${folder.mediaCount == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .46),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemoteCard extends StatelessWidget {
  const _RemoteCard({
    required this.controller,
    required this.media,
    required this.onTap,
    required this.showPath,
  });

  final LanController controller;
  final RemoteMedia media;
  final VoidCallback onTap;
  final bool showPath;

  @override
  Widget build(BuildContext context) {
    final thumb = controller.thumbnailUrl(media);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumb != null)
              Image.network(
                thumb,
                headers: controller.authHeader(),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _CardFallback(),
              )
            else
              const _CardFallback(),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(9),
                color: Colors.black.withValues(alpha: .68),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      media.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                      ),
                    ),
                    if (showPath) ...[
                      const SizedBox(height: 3),
                      Text(
                        media.displayFolder,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Positioned(
              top: 8,
              right: 8,
              child: _MediaBadge(
                icon: Icons.cloud_outlined,
                tooltip: 'Streamed from PC',
              ),
            ),
            if (media.hasSubtitles)
              const Positioned(
                top: 8,
                left: 8,
                child: _MediaBadge(
                  icon: Icons.closed_caption_rounded,
                  tooltip: 'Subtitles sync automatically',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MediaBadge extends StatelessWidget {
  const _MediaBadge({required this.icon, required this.tooltip});

  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}

class _CardFallback extends StatelessWidget {
  const _CardFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.deepPurple.shade900.withValues(alpha: .5),
      child: const Center(
        child: Icon(Icons.movie_rounded, size: 34, color: Colors.white38),
      ),
    );
  }
}

class _ExplorerEmpty extends StatelessWidget {
  const _ExplorerEmpty({required this.isSearch});

  final bool isSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearch ? Icons.search_off_rounded : Icons.folder_off_rounded,
              size: 44,
              color: Colors.white24,
            ),
            const SizedBox(height: 12),
            Text(
              isSearch
                  ? 'No videos match this search.'
                  : 'This folder has no videos.',
              style: const TextStyle(color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryError extends StatelessWidget {
  const _LibraryError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 44,
              color: Colors.white24,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
