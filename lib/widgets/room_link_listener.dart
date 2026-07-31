import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncy/bottomsheets/join_room_bottom_sheet.dart';
import 'package:syncy/controllers/room_controller.dart';
import 'package:syncy/services/room_link_service.dart';
import 'package:syncy/widgets/adaptive_sheet.dart';

class RoomLinkListener extends StatefulWidget {
  final Widget child;

  const RoomLinkListener({super.key, required this.child});

  @override
  State<RoomLinkListener> createState() => _RoomLinkListenerState();
}

class _RoomLinkListenerState extends State<RoomLinkListener> {
  Worker? _worker;
  bool _presenting = false;

  @override
  void initState() {
    super.initState();
    final service = Get.find<RoomLinkService>();
    _worker = ever<String?>(service.pendingRoomReference, (reference) {
      if (reference != null) _schedulePresentation(reference);
    });

    final initialReference = service.pendingRoomReference.value;
    if (initialReference != null) _schedulePresentation(initialReference);
  }

  void _schedulePresentation(String reference) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_present(reference));
    });
  }

  Future<void> _present(String reference) async {
    if (_presenting) return;

    final linkService = Get.find<RoomLinkService>();
    final roomController = Get.find<RoomController>();
    linkService.consume(reference);

    if (roomController.room.value.id.isNotEmpty) {
      Get.snackbar(
        'Room invite received',
        'Leave your current room before opening another invite.',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    _presenting = true;
    try {
      await showAdaptiveSheet(
        JoinRoomBottomSheet(initialRoomReference: reference),
      );
    } finally {
      _presenting = false;
      final nextReference = linkService.pendingRoomReference.value;
      if (nextReference != null) _schedulePresentation(nextReference);
    }
  }

  @override
  void dispose() {
    _worker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
