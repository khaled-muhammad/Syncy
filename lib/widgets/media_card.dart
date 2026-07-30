import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:syncy/models/media.dart';

class MediaCard extends StatelessWidget {
  const MediaCard({
    super.key,
    required this.mediaElement,
    this.onPressed,
    this.onFocused,
    this.isAudio = false,
    this.compact = false,
  });

  final Media mediaElement;
  final VoidCallback? onPressed;
  final ValueChanged<Media>? onFocused;
  final bool isAudio;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final thumbnailPath = mediaElement.thumbnailPath;
    final hasThumbnail =
        !isAudio &&
        thumbnailPath != null &&
        thumbnailPath.isNotEmpty &&
        File(thumbnailPath).existsSync();
    final accent = mediaElement.dominantColorValue == 0
        ? const Color(0xFF9A54FF)
        : Color(mediaElement.dominantColorValue);
    final progress = mediaElement.watchedFraction;

    return MouseRegion(
      onEnter: (_) => onFocused?.call(mediaElement),
      child: FocusableActionDetector(
        onShowFocusHighlight: (focused) {
          if (focused) onFocused?.call(mediaElement);
        },
        child: Semantics(
          button: true,
          label: 'Open ${mediaElement.name}',
          child: Material(
            color: const Color(0xFF171020),
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                onFocused?.call(mediaElement);
                onPressed?.call();
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasThumbnail)
                    Image.file(
                      File(thumbnailPath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _FallbackArt(accent: accent, isAudio: isAudio),
                    )
                  else
                    _FallbackArt(accent: accent, isAudio: isAudio),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [.3, .68, 1],
                        colors: [
                          Colors.transparent,
                          Color(0x33000000),
                          Color(0xED08050C),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Row(
                      children: [
                        if (mediaElement.durationMs > 0)
                          _Badge(
                            icon: Icons.schedule_rounded,
                            label: _durationLabel(mediaElement.durationMs),
                          ),
                        const Spacer(),
                        if (mediaElement.hasSubtitles)
                          const _Badge(
                            icon: Icons.closed_caption_rounded,
                            label: 'CC',
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: compact ? 12 : 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (mediaElement.watchedWith.isNotEmpty) ...[
                          _WatchedTogetherAvatars(
                            names: mediaElement.watchedWith,
                            accent: accent,
                          ),
                          const SizedBox(height: 7),
                        ],
                        Text(
                          mediaElement.name,
                          maxLines: compact ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 13 : 15,
                            height: 1.18,
                            fontWeight: FontWeight.w700,
                            shadows: const [
                              Shadow(color: Colors.black87, blurRadius: 8),
                            ],
                          ),
                        ),
                        if (progress > .01 && progress < .95) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 4,
                              color: accent,
                              backgroundColor: Colors.white24,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: compact ? 54 : 66,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .88),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: .38),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(compact ? 8 : 10),
                        child: Icon(
                          isAudio
                              ? Icons.headphones_rounded
                              : progress > .01
                              ? Icons.play_arrow_rounded
                              : Icons.add_rounded,
                          color: Colors.white,
                          size: compact ? 19 : 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _durationLabel(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return hours > 0 ? '${hours}h ${minutes}m' : '${duration.inMinutes}m';
  }
}

class _FallbackArt extends StatelessWidget {
  const _FallbackArt({required this.accent, required this.isAudio});

  final Color accent;
  final bool isAudio;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: .78), const Color(0xFF13091F)],
        ),
      ),
      child: Center(
        child: Icon(
          isAudio ? Icons.graphic_eq_rounded : Icons.movie_creation_outlined,
          size: 46,
          color: Colors.white38,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: .52),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WatchedTogetherAvatars extends StatelessWidget {
  const _WatchedTogetherAvatars({required this.names, required this.accent});

  final List<String> names;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final visible = names.take(3).toList();
    return SizedBox(
      height: 24,
      width: visible.length * 17 + 8,
      child: Stack(
        children: [
          for (var index = 0; index < visible.length; index++)
            Positioned(
              left: index * 17,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFF100A17),
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: accent,
                  child: Text(
                    visible[index].trim().isEmpty
                        ? '?'
                        : visible[index].trim()[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
