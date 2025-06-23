import 'package:flutter/material.dart';

class GlowingPurpleBackground extends StatelessWidget {
  final Widget child;

  const GlowingPurpleBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3A0CA3),
                Color(0xFF7209B7),
                Color(0xFF4361EE),
              ],
            ),
          ),
        ),

        // Glow Mesh Effect 1: Center Bottom
        Positioned(
          bottom: -80,
          left: -100,
          right: -100,
          child: Container(
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.purpleAccent.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
                radius: 0.8,
              ),
            ),
          ),
        ),

        // Glow Mesh Effect 2: Mid-left
        Positioned(
          top: 150,
          left: -60,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.blueAccent.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
                radius: 0.6,
              ),
            ),
          ),
        ),

        // Glow Mesh Effect 3: Top-right
        Positioned(
          top: 0,
          right: -50,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.pinkAccent.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
                radius: 0.7,
              ),
            ),
          ),
        ),

        // Content Layer
        child,
      ],
    );
  }
}