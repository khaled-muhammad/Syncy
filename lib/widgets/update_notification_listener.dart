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
                '${update.canInstallDirectly ? 'Syncy will download, verify, and install' : 'Download'} the signed '
                '${Theme.of(context).platform == TargetPlatform.windows ? 'Windows update' : 'Android APK'} from GitHub.',
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
                await runUpdateFlow(update);
              },
              icon: const Icon(Icons.download_rounded),
              label: Text(
                update.canInstallDirectly ? 'Update now' : 'Download',
              ),
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

Future<void> runUpdateFlow(ReleaseUpdate update) async {
  final service = Get.find<UpdateService>();
  final direct = service.directInstallEnabled(update);
  final future = service.install(update);
  if (direct) {
    unawaited(
      Get.dialog<void>(
        const _UpdateProgressDialog(),
        barrierDismissible: false,
      ),
    );
  }
  final outcome = await future;
  if (Get.isDialogOpen == true && direct) Get.back();
  switch (outcome) {
    case UpdateInstallOutcome.permissionRequested:
      Get.snackbar(
        'One permission needed',
        'Allow Syncy to install updates. Android will continue automatically.',
        duration: const Duration(seconds: 6),
      );
    case UpdateInstallOutcome.failed:
      Get.snackbar('Update failed', service.statusMessage.value);
    case UpdateInstallOutcome.cancelled:
      Get.snackbar('Update cancelled', 'No changes were made.');
    case UpdateInstallOutcome.launched:
    case UpdateInstallOutcome.browserOpened:
      break;
  }
}

class _UpdateProgressDialog extends StatelessWidget {
  const _UpdateProgressDialog();

  @override
  Widget build(BuildContext context) {
    final service = Get.find<UpdateService>();
    return Obx(
      () => AlertDialog(
        icon: const Icon(Icons.system_update_rounded, size: 34),
        title: const Text('Updating Syncy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value:
                  service.downloadProgress.value > 0 &&
                      service.downloadProgress.value < 1
                  ? service.downloadProgress.value
                  : null,
            ),
            const SizedBox(height: 14),
            Text(
              service.statusMessage.value,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            if (service.downloadProgress.value > 0 &&
                service.downloadProgress.value < 1) ...[
              const SizedBox(height: 6),
              Text(
                '${(service.downloadProgress.value * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: service.canCancelUpdate.value
                ? service.cancelInstall
                : null,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
