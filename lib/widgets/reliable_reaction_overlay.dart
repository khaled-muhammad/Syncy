import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncy/controllers/room_controller.dart';
import 'package:syncy/models/room.dart';

class ReactionOverlay extends StatelessWidget {
  const ReactionOverlay({super.key, this.bottomInset = 72, this.controller});

  final double bottomInset;
  final RoomController? controller;

  @override
  Widget build(BuildContext context) {
    final roomController = controller ?? Get.find<RoomController>();
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) => Obx(
          () => Stack(
            clipBehavior: Clip.none,
            children: roomController.floatingReactions
                .map(
                  (reaction) => _FloatingReaction(
                    key: ValueKey(reaction['id']),
                    emoji: reaction['emoji'] ?? '❤️',
                    availableWidth: constraints.maxWidth,
                    bottomInset: bottomInset,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _FloatingReaction extends StatefulWidget {
  const _FloatingReaction({
    super.key,
    required this.emoji,
    required this.availableWidth,
    required this.bottomInset,
  });

  final String emoji;
  final double availableWidth;
  final double bottomInset;

  @override
  State<_FloatingReaction> createState() => _FloatingReactionState();
}

class _FloatingReactionState extends State<_FloatingReaction>
    with SingleTickerProviderStateMixin {
  late final double _horizontalOffset = Random().nextDouble() * .68 + .16;
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..forward();
  late final Animation<double> _fade = CurvedAnimation(
    parent: _animation,
    curve: const Interval(.62, 1, curve: Curves.easeOut),
  ).drive(Tween(begin: 1, end: 0));
  late final Animation<double> _rise = CurvedAnimation(
    parent: _animation,
    curve: Curves.easeOutCubic,
  ).drive(Tween(begin: 0, end: 210));
  late final Animation<double> _scale = CurvedAnimation(
    parent: _animation,
    curve: Curves.elasticOut,
  ).drive(Tween(begin: .35, end: 1));

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Positioned(
        left:
            (widget.availableWidth - 48).clamp(0, double.infinity) *
            _horizontalOffset,
        bottom: widget.bottomInset + _rise.value,
        child: Opacity(
          opacity: _fade.value,
          child: Transform.scale(scale: _scale.value, child: child),
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .22),
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Text(widget.emoji, style: const TextStyle(fontSize: 36)),
        ),
      ),
    );
  }
}

class ReactionBar extends StatelessWidget {
  const ReactionBar({super.key, this.onReactionSent, this.controller});

  final VoidCallback? onReactionSent;
  final RoomController? controller;

  static const friendsReactions = ['😂', '🔥', '😮', '👏', '👍', '🎉'];
  static const coupleReactions = ['❤️', '😘', '🥰', '💋', '🌹', '🫶'];

  @override
  Widget build(BuildContext context) {
    final roomController = controller ?? Get.find<RoomController>();
    return Obx(() {
      final reactions = roomController.room.value.mode == RoomMode.couple
          ? coupleReactions
          : friendsReactions;
      return Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF120C20).withValues(alpha: .88),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: .12)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: reactions
                .map(
                  (emoji) => Semantics(
                    button: true,
                    label: 'Send $emoji reaction',
                    child: InkResponse(
                      radius: 23,
                      onTap: () {
                        roomController.sendReaction(emoji);
                        onReactionSent?.call();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      );
    });
  }
}
