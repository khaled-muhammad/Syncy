import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncy/controllers/room_controller.dart';

class ReactionOverlay extends StatelessWidget {
  const ReactionOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RoomController>();

    return Obx(
      () => Stack(
        children: controller.floatingReactions
            .map(
              (reaction) => _FloatingReaction(
                key: ValueKey(reaction['id']),
                emoji: reaction['emoji'] ?? '❤️',
              ),
            )
            .toList(),
      ),
    );
  }
}

class _FloatingReaction extends StatefulWidget {
  final String emoji;

  const _FloatingReaction({super.key, required this.emoji});

  @override
  State<_FloatingReaction> createState() => _FloatingReactionState();
}

class _FloatingReactionState extends State<_FloatingReaction>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _positionAnimation;
  late double _horizontalOffset;

  @override
  void initState() {
    super.initState();

    final random = Random();
    _horizontalOffset = random.nextDouble() * 0.6 + 0.2; // 0.2 to 0.8

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.5,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 70),
    ]).animate(_controller);

    _positionAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -200),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: screenWidth * _horizontalOffset - 20,
          bottom: 100 - _positionAnimation.value.dy,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Text(widget.emoji, style: const TextStyle(fontSize: 40)),
            ),
          ),
        );
      },
    );
  }
}

class ReactionBar extends StatelessWidget {
  static const List<String> reactions = ['❤️', '😂', '😮', '👍', '🔥', '👏'];

  const ReactionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RoomController>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactions
            .map(
              (emoji) => GestureDetector(
                onTap: () => controller.sendReaction(emoji),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
