import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Adds a low-key theatre-light glow around the current video frame.
///
/// The capture is intentionally tiny and infrequent; it keeps the effect
/// decorative without competing with the actual playback texture.
class AmbientVideoSurface extends StatefulWidget {
  const AmbientVideoSurface({
    super.key,
    required this.child,
    this.fallback = const Color(0xFF7137E8),
  });

  final Widget child;
  final Color fallback;

  @override
  State<AmbientVideoSurface> createState() => _AmbientVideoSurfaceState();
}

class _AmbientVideoSurfaceState extends State<AmbientVideoSurface> {
  final _boundaryKey = GlobalKey();
  Timer? _timer;
  Color? _ambient;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(milliseconds: 1800),
      (_) => _sample(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sample() async {
    try {
      final renderObject = _boundaryKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary || !renderObject.hasSize)
        return;
      final image = await renderObject.toImage(pixelRatio: .12);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      if (data == null || data.lengthInBytes < 4) return;
      final bytes = data.buffer.asUint8List();
      var red = 0.0;
      var green = 0.0;
      var blue = 0.0;
      var samples = 0;
      for (var offset = 0; offset + 3 < bytes.length; offset += 4) {
        final brightness =
            (bytes[offset] + bytes[offset + 1] + bytes[offset + 2]) / 3;
        if (brightness < 14 || brightness > 245) continue;
        red += bytes[offset];
        green += bytes[offset + 1];
        blue += bytes[offset + 2];
        samples++;
      }
      if (samples == 0 || !mounted) return;
      setState(
        () => _ambient = Color.fromARGB(
          255,
          (red / samples).round(),
          (green / samples).round(),
          (blue / samples).round(),
        ),
      );
    } catch (_) {
      // Platform textures can be temporarily unavailable during a seek.
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _ambient ?? widget.fallback;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 700),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .3),
            blurRadius: 48,
            spreadRadius: 10,
          ),
        ],
      ),
      child: RepaintBoundary(key: _boundaryKey, child: widget.child),
    );
  }
}
