import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:syncy/models/media.dart';

class MediaCard extends StatelessWidget {
  final Media mediaElement;
  final void Function()? onPressed;
  final bool isAudio;

  const MediaCard({
    super.key,
    required this.mediaElement,
    this.onPressed,
    this.isAudio = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasThumbnail = mediaElement.thumbnailPath.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isAudio ? Colors.deepPurple.shade300 : null,
        image: !isAudio && hasThumbnail
            ? DecorationImage(
                image: FileImage(File(mediaElement.thumbnailPath)),
                fit: BoxFit.cover,
              )
            : null,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Stack(
          children: [
            GestureDetector(
              onTap: onPressed,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    color: Colors.black26,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 8, right: 8, bottom: 4, top: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isAudio ? Icons.music_note : Icons.videocam,
                                size: 18,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  mediaElement.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Transform.translate(
                  offset: const Offset(0, -22),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isAudio
                            ? [Colors.pinkAccent, Colors.deepPurpleAccent]
                            : [Colors.purple, Colors.deepPurple],
                      ),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: IconButton(
                      onPressed: onPressed,
                      icon: Icon(
                        isAudio ? Icons.headphones_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}