import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:syncy/services/lan/lan_host_service.dart';
import 'package:syncy/widgets/native_purple_mesh_background.dart';

/// Desktop screen for pairing a phone: shows the one-time code, the manual
/// address fallback, and the list of already-paired phones.
class PcPairingScreen extends StatelessWidget {
  const PcPairingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final host = LanHostService.to;

    return NativePurpleMeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Pair a phone'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: Get.back,
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Obx(() {
                if (!host.isRunning.value) {
                  return const _HostOffline();
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'On your phone, open Syncy → Connect to a PC, pick this '
                      'computer, and enter this code.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, height: 1.4),
                    ),
                    const SizedBox(height: 28),
                    _CodeCard(code: host.code.value),
                    const SizedBox(height: 14),
                    TextButton.icon(
                      onPressed: host.refreshCode,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('New code'),
                    ),
                    const SizedBox(height: 20),
                    _AddressHint(
                      ip: host.lanIp.value,
                      port: host.port.value,
                    ),
                    const SizedBox(height: 28),
                    _PairedDevices(host: host),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    // Space the digits so the code is easy to read aloud / type.
    final spaced = code.split('').join(' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B00EA), Color(0xFFCD34E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: .4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Text(
        spaced,
        style: const TextStyle(
          fontSize: 44,
          fontWeight: FontWeight.w800,
          letterSpacing: 4,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _AddressHint extends StatelessWidget {
  const _AddressHint({required this.ip, required this.port});
  final String? ip;
  final int port;

  @override
  Widget build(BuildContext context) {
    if (ip == null || port == 0) {
      return const Text(
        'No local network address found. Connect this PC to Wi-Fi or Ethernet.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.orangeAccent, fontSize: 12.5),
      );
    }
    final address = '$ip:$port';
    return Column(
      children: [
        const Text(
          "If your phone can't find this PC automatically, enter its address:",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 12.5, height: 1.4),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => Clipboard.setData(ClipboardData(text: address)),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  address,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.copy_rounded, size: 14, color: Colors.white38),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PairedDevices extends StatelessWidget {
  const _PairedDevices({required this.host});
  final LanHostService host;

  @override
  Widget build(BuildContext context) {
    final devices = host.pairedDevices();
    if (devices.isEmpty) {
      return const Text(
        'No phones paired yet.',
        style: TextStyle(color: Colors.white38, fontSize: 12.5),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Paired phones',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 8),
        for (final d in devices)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.smartphone_rounded, color: Colors.white54),
            title: Text(d['deviceName']?.toString() ?? 'Phone'),
            trailing: TextButton(
              onPressed: () async {
                await host.revoke(d['deviceId']?.toString() ?? '');
                // Rebuild via a lightweight navigation refresh.
                (context as Element).markNeedsBuild();
              },
              child: const Text(
                'Revoke',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
      ],
    );
  }
}

class _HostOffline extends StatelessWidget {
  const _HostOffline();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.wifi_off_rounded, size: 48, color: Colors.white24),
        SizedBox(height: 14),
        Text(
          'The LAN host could not start.\n'
          'Check that a firewall is not blocking Syncy.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white60, height: 1.4),
        ),
      ],
    );
  }
}
