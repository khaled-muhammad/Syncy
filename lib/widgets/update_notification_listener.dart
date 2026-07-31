import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncy/services/update_service.dart';

class UpdateNotificationListener extends StatefulWidget {
  final Widget child;

  const UpdateNotificationListener({super.key, required this.child});

  @override
  State<UpdateNotificationListener> createState() =>
      _UpdateNotificationListenerState();
}

class _UpdateNotificationListenerState
    extends State<UpdateNotificationListener> {
  Worker? _worker;
  String? _presentedVersion;
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    final service = Get.find<UpdateService>();
    _worker = ever<ReleaseUpdate?>(service.availableUpdate, (update) {
      if (update != null) _schedule(update);
    });
    final initial = service.availableUpdate.value;
    if (initial != null) _schedule(initial);
  }

  void _schedule(ReleaseUpdate update) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_present(update));
    });
  }

  Future<void> _present(ReleaseUpdate update) async {
    if (_showing || _presentedVersion == update.version) return;
    _showing = true;
    _presentedVersion = update.version;
    try {
      await Get.dialog<void>(
        AlertDialog(
          icon: const Icon(Icons.system_update_rounded, size: 36),
          title: Text('Syncy ${update.version} is available'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You have ${Get.find<UpdateService>().currentVersion.value}. '
                'Download the signed ${Theme.of(context).platform == TargetPlatform.windows ? 'Windows ZIP' : 'Android APK'} from GitHub.',
              ),
              if (update.notes.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  update.notes.trim(),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('Later')),
            FilledButton.icon(
              onPressed: () async {
                Get.back();
                final opened = await Get.find<UpdateService>().openDownload(
                  update,
                );
                if (!opened) {
                  Get.snackbar(
                    'Could not open download',
                    'Visit the Syncy GitHub releases page.',
                  );
                }
              },
              icon: const Icon(Icons.download_rounded),
              label: const Text('Download'),
            ),
          ],
        ),
      );
    } finally {
      _showing = false;
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
