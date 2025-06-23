import 'dart:ui';
import 'package:flutter/material.dart';

class NavItem {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  NavItem({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
}

class FloatingBottomBar extends StatelessWidget {
  final List<NavItem> navItems;
  final int activeIndex;

  const FloatingBottomBar({
    super.key,
    required this.navItems,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.08),
            border: Border.all(color: Colors.white.withValues(alpha:0.15)),
            borderRadius: BorderRadius.circular(64),
          ),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(navItems.length, (index) {
              final isActive = index == activeIndex;
              final item = navItems[index];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: AnimatedCrossFade(
                  firstChild: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(60, 60),
                    ),
                    onPressed: item.onPressed,
                    icon: Icon(item.icon),
                  ),
                  secondChild: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF5B00EA),
                          Color.fromARGB(255, 130, 9, 229),
                          Color(0xFFCD34E8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: [0.0, 0.5, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(60, 60),
                      ),
                      onPressed: item.onPressed,
                      icon: Icon(item.icon, size: 30),
                      label: FittedBox(child: Text(item.label)),
                    ),
                  ),
                  crossFadeState: isActive
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}