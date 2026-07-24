import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncy/bottomsheets/create_room_bottom_sheet.dart';
import 'package:syncy/controllers/lan_controller.dart';
import 'package:syncy/models/remote_media.dart';
import 'package:syncy/widgets/adaptive_sheet.dart';
import 'package:syncy/widgets/native_purple_mesh_background.dart';

/// Phone screen: browse a paired PC's videos and start a room streaming one.
class PcLibraryScreen extends StatelessWidget {
  const PcLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LanController>();

    return NativePurpleMeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Obx(() => Text(controller.selectedPc.value?.name ?? 'PC')),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                final pc = controller.selectedPc.value;
                if (pc != null) controller.openLibrary(pc);
              },
            ),
          ],
        ),
        body: Obx(() {
          if (controller.isLoadingLibrary.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final error = controller.libraryError.value;
          if (error != null) {
            return _LibraryError(message: error);
          }
          if (controller.remoteLibrary.isEmpty) {
            return const Center(
              child: Text(
                'This PC has no videos in its library yet.',
                style: TextStyle(color: Colors.white60),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              crossAxisSpacing: 14,
              mainAxisSpacing: 18,
              childAspectRatio: 3 / 4,
            ),
            itemCount: controller.remoteLibrary.length,
            itemBuilder: (context, index) {
              final media = controller.remoteLibrary[index];
              return _RemoteCard(
                controller: controller,
                media: media,
                onTap: () => showAdaptiveSheet(
                  CreateRoomBottomSheet(remoteMedia: media),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class _RemoteCard extends StatelessWidget {
  const _RemoteCard({
    required this.controller,
    required this.media,
    required this.onTap,
  });

  final LanController controller;
  final RemoteMedia media;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final thumb = controller.thumbnailUrl(media);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumb != null)
              Image.network(
                thumb,
                headers: controller.authHeader(),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _CardFallback(),
              )
            else
              const _CardFallback(),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black54,
                child: Text(
                  media.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 12.5),
                ),
              ),
            ),
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(Icons.cloud_outlined, size: 16, color: Colors.white70),
            ),
          ],
        ),
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
            const Icon(Icons.cloud_off_rounded, size: 44, color: Colors.white24),
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
