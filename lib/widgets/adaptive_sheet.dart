import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncy/utils/platform_utils.dart';

/// Presents [child] the way the current platform expects.
///
/// A sheet sliding up from the bottom edge reads as native on a phone but as a
/// mistake on a desktop window, where the same content belongs in a centered,
/// width-constrained dialog. Both routes are modal and dismiss identically, so
/// callers — and the sheet bodies themselves — do not need to care which they
/// are in.
Future<T?> showAdaptiveSheet<T>(Widget child, {bool dismissible = true}) {
  if (!isDesktop) {
    return Get.bottomSheet<T>(child, isDismissible: dismissible);
  }

  return Get.dialog<T>(
    Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A0E2E).withValues(alpha: .92),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: .12)),
                ),
                padding: const EdgeInsets.all(8),
                child: SingleChildScrollView(child: child),
              ),
            ),
          ),
        ),
      ),
    ),
    barrierDismissible: dismissible,
    barrierColor: Colors.black.withValues(alpha: .55),
  );
}
