import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:syncy/controllers/settings_controller.dart';
import 'package:syncy/routes/app_routes.dart';
import 'package:syncy/services/update_service.dart';
import 'package:syncy/widgets/native_purple_mesh_background.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final updates = Get.find<UpdateService>();
    return NativePurpleMeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
                leading: Icon(Iconsax.crown_1_bold, color: Colors.amber),
                title: const Text(
                  'Subscription Plans',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Upgrade to unlock premium features'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Get.toNamed(Routes.PLANS),
              ),
              const Divider(),
              Obx(
                () => ListTile(
                  leading: const Icon(Icons.system_update_rounded),
                  title: Text(
                    updates.availableUpdate.value == null
                        ? 'Check for updates'
                        : 'Download Syncy ${updates.availableUpdate.value!.version}',
                  ),
                  subtitle: Text(
                    updates.statusMessage.value.isEmpty
                        ? 'Installed version ${updates.currentVersion.value}'
                        : updates.statusMessage.value,
                  ),
                  trailing: updates.isChecking.value
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  onTap: updates.isChecking.value
                      ? null
                      : () async {
                          final available = updates.availableUpdate.value;
                          if (available != null) {
                            await updates.openDownload(available);
                            return;
                          }
                          final update = await updates.check(force: true);
                          if (update == null) {
                            Get.snackbar(
                              'Update check',
                              updates.statusMessage.value,
                            );
                          }
                        },
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                subtitle: Obx(
                  () => Text('Version ${updates.currentVersion.value}'),
                ),
                onTap: () {
                  // Show about dialog or navigate to about page
                  Get.dialog(
                    AlertDialog(
                      title: const Text('About Syncy'),
                      content: Text(
                        'Syncy - The Ultimate Cross-Platform Media Sync & Watch Party App\n\n'
                        'Built with 💜 by passionate developers\n\n'
                        'Version ${updates.currentVersion.value}',
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
      ),
    );
  }
}
