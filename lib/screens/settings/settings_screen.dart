import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncy/controllers/settings_controller.dart';

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
          ],
        ),
      ),
    );
  }
}
