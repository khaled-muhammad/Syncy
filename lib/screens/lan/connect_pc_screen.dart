import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:syncy/controllers/lan_controller.dart';
import 'package:syncy/models/lan_device.dart';
import 'package:syncy/screens/lan/pc_library_screen.dart';
import 'package:syncy/services/lan/lan_client_service.dart';
import 'package:syncy/widgets/native_purple_mesh_background.dart';

/// Phone screen: find a PC on the LAN and pair with its one-time code.
class ConnectPcScreen extends StatelessWidget {
  const ConnectPcScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Reuse the controller if we've been here before, so returning to this
    // screen doesn't spin up a second discovery/controller.
    final controller = Get.isRegistered<LanController>()
        ? Get.find<LanController>()
        : Get.put(LanController());

    return NativePurpleMeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Connect to a PC'),
          actions: [
            Obx(
              () => controller.isScanning.value
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: controller.refresh,
                    ),
            ),
          ],
        ),
        body: Obx(() {
          if (!controller.ready.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final devices = controller.devices;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Make sure your phone and PC are on the same Wi-Fi. On the PC, '
                'open Syncy → Pair a phone.',
                style: TextStyle(color: Colors.white60, height: 1.4),
              ),
              const SizedBox(height: 16),
              if (devices.isEmpty && !controller.isScanning.value)
                const _NoDevices(),
              for (final device in devices)
                _DeviceTile(controller: controller, device: device),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _manualEntry(context, controller),
                icon: const Icon(Icons.keyboard_rounded, size: 18),
                label: const Text('Enter PC address manually'),
              ),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _manualEntry(
    BuildContext context,
    LanController controller,
  ) async {
    final hostCtrl = TextEditingController();
    final portCtrl = TextEditingController(text: '8770');
    final proceed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xFF1A0E2E),
        title: const Text('Enter PC address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: hostCtrl,
              decoration: const InputDecoration(
                labelText: 'IP address',
                hintText: '192.168.1.42',
              ),
            ),
            TextField(
              controller: portCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Port'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          TextButton(onPressed: () => Get.back(result: true), child: const Text('Find')),
        ],
      ),
    );
    if (proceed != true) return;

    final device = await controller.probe(
      hostCtrl.text.trim(),
      int.tryParse(portCtrl.text.trim()) ?? 8770,
    );
    if (device == null) {
      Get.snackbar('Not found', 'No Syncy PC answered at that address.');
      return;
    }
    if (context.mounted) _startPairing(controller, device);
  }

  void _startPairing(LanController controller, LanDevice device) {
    if (device.isPaired) {
      controller.openLibrary(device);
      Get.to(() => const PcLibraryScreen());
      return;
    }
    _CodeSheet.show(controller, device);
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.controller, required this.device});
  final LanController controller;
  final LanDevice device;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: .06),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.desktop_windows_rounded, color: Colors.white70),
        title: Text(device.name),
        subtitle: Text(
          device.isPaired ? 'Paired · ${device.host}' : device.host,
          style: TextStyle(
            color: device.isPaired ? Colors.greenAccent : Colors.white38,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          device.isPaired ? Icons.arrow_forward_ios_rounded : Icons.link_rounded,
          size: 16,
        ),
        onTap: () {
          if (device.isPaired) {
            controller.openLibrary(device);
            Get.to(() => const PcLibraryScreen());
          } else {
            _CodeSheet.show(controller, device);
          }
        },
      ),
    );
  }
}

class _NoDevices extends StatelessWidget {
  const _NoDevices();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.wifi_find_rounded, size: 44, color: Colors.white24),
          SizedBox(height: 12),
          Text(
            'No PCs found yet.\nPull the refresh button, or enter the address manually.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet that collects the 6-digit code and pairs.
class _CodeSheet extends StatefulWidget {
  const _CodeSheet({required this.controller, required this.device});
  final LanController controller;
  final LanDevice device;

  static void show(LanController controller, LanDevice device) {
    Get.bottomSheet(
      _CodeSheet(controller: controller, device: device),
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A0E2E),
    );
  }

  @override
  State<_CodeSheet> createState() => _CodeSheetState();
}

class _CodeSheetState extends State<_CodeSheet> {
  final _codeCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final paired = await widget.controller.pair(
        widget.device,
        _codeCtrl.text.trim(),
      );
      if (!mounted) return;
      Get.back(); // close sheet
      widget.controller.openLibrary(paired);
      Get.to(() => const PcLibraryScreen());
    } on LanUnauthorized {
      setState(() => _error = 'Incorrect or expired code.');
    } catch (_) {
      setState(() => _error = "Couldn't reach the PC. Try again.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 22,
        bottom: MediaQuery.of(context).viewInsets.bottom + 22,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Pair with ${widget.device.name}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter the 6-digit code shown on the PC.',
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _codeCtrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 28, letterSpacing: 8),
            decoration: InputDecoration(
              counterText: '',
              errorText: _error,
              hintText: '••••••',
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _busy ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.purpleAccent.withValues(alpha: .35),
                foregroundColor: Colors.white,
              ),
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Pair'),
            ),
          ),
        ],
      ),
    );
  }
}
