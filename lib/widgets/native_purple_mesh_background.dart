import 'dart:math' as math;

import 'package:flutter/material.dart';

class NativePurpleMeshBackground extends StatefulWidget {
  const NativePurpleMeshBackground({
    super.key,
    required this.child,
    this.animate = true,
    this.accent,
  });

  final Widget child;
  final bool animate;
  final Color? accent;

  @override
  State<NativePurpleMeshBackground> createState() =>
      _NativePurpleMeshBackgroundState();
}

class _NativePurpleMeshBackgroundState extends State<NativePurpleMeshBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animationsDisabled = MediaQuery.disableAnimationsOf(context);
    if (widget.animate && !animationsDisabled) {
      if (!_animation.isAnimating) _animation.repeat();
    } else {
      _animation.stop();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF090512),
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) => CustomPaint(
            painter: _PurpleMeshPainter(
              _animation.value,
              widget.accent ?? const Color(0xFF7137E8),
            ),
            child: child,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _PurpleMeshPainter extends CustomPainter {
  const _PurpleMeshPainter(this.phase, this.accent);

  final double phase;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF120824), Color(0xFF090512), Color(0xFF18072A)],
        ).createShader(rect),
    );

    final t = phase * math.pi * 2;
    _drawGlow(
      canvas,
      size,
      center: Offset(
        size.width * (0.16 + math.sin(t) * 0.04),
        size.height * (0.22 + math.cos(t * .7) * 0.04),
      ),
      radius: size.shortestSide * .72,
      color: accent,
      opacity: .34,
    );
    _drawGlow(
      canvas,
      size,
      center: Offset(
        size.width * (0.88 + math.cos(t * .8) * 0.05),
        size.height * (0.38 + math.sin(t * .6) * 0.05),
      ),
      radius: size.shortestSide * .62,
      color: const Color(0xFFD03AAE),
      opacity: .22,
    );
    _drawGlow(
      canvas,
      size,
      center: Offset(
        size.width * (0.42 + math.sin(t * .55) * 0.06),
        size.height * .92,
      ),
      radius: size.shortestSide * .82,
      color: const Color(0xFF3C5DE8),
      opacity: .18,
    );

    final meshPaint = Paint()
      ..color = Colors.white.withValues(alpha: .025)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7;
    for (var i = 1; i < 7; i++) {
      final y = size.height * i / 7;
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += 24) {
        path.lineTo(x, y + math.sin((x / size.width * 4) + t + i) * 9);
      }
      canvas.drawPath(path, meshPaint);
    }
  }

  void _drawGlow(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required Color color,
    required double opacity,
  }) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_PurpleMeshPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.accent != accent;
}
