import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:syncy/models/media.dart';

class MediaCard extends StatelessWidget {
  final void Function()? onPressed;

  const MediaCard({
    super.key,
    required this.mediaElement,
    this.onPressed,
  });

  final Media mediaElement;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: mediaElement.thumbnailPath != ''
            ? DecorationImage(
                image: FileImage(
                  File(mediaElement.thumbnailPath),
                ),
                fit: BoxFit.cover,
              )
            : DecorationImage(
                image: AssetImage(
                  'assets/broken_thumb.png',
                ),
                fit: BoxFit.cover,
              ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Stack(
          children: [
            GestureDetector(
              onTap: onPressed,
              child: ClipRRect(
                borderRadius: BorderRadius.only(
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
                            left: 8,
                            right: 8,
                            bottom: 4,
                            top: 20,
                          ),
                          child: Text(mediaElement.name),
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
                  offset: Offset(0, -22),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple,
                          Colors.deepPurpleAccent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: IconButton(
                      onPressed: onPressed,
                      icon: Icon(Icons.play_arrow_rounded),
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        tapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
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