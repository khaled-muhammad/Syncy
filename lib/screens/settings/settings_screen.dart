import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:syncy/controllers/settings_controller.dart';
import 'package:syncy/routes/app_routes.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: const Text('Dark Mode'),
              trailing: Obx(
                () => Switch(
                  value: controller.isDarkMode.value,
                  onChanged: controller.toggleTheme,
                ),
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Notifications'),
              trailing: Obx(
                () => Switch(
                  value: controller.notificationsEnabled.value,
                  onChanged: controller.toggleNotifications,
                ),
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Sync Frequency'),
              subtitle: Obx(() => Text(controller.syncFrequency.value)),
              onTap: controller.changeSyncFrequency,
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Iconsax.crown_1_bold,
                color: Colors.amber,
              ),
              title: const Text(
                'Subscription Plans',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Upgrade to unlock premium features'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Get.toNamed(Routes.PLANS),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              subtitle: const Text('Version 1.0.0'),
              onTap: () {
                // Show about dialog or navigate to about page
                Get.dialog(
                  AlertDialog(
                    title: const Text('About Syncy'),
                    content: const Text(
                      'Syncy - The Ultimate Cross-Platform Media Sync & Watch Party App\n\n'
                      'Built with 💜 by passionate developers\n\n'
                      'Version 1.0.0',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
