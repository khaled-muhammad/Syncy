import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsController extends GetxController {
  final isDarkMode = false.obs;
  final notificationsEnabled = true.obs;
  final syncFrequency = 'Every 30 minutes'.obs;

  void toggleTheme(bool value) {
    isDarkMode.value = value;
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  void toggleNotifications(bool value) {
    notificationsEnabled.value = value;
    // Implement notification toggling logic
  }

  void changeSyncFrequency() {
    // Show a dialog to select sync frequency
    final options = [
      'Every 15 minutes',
      'Every 30 minutes',
      'Every hour',
      'Every 3 hours',
      'Every 6 hours',
      'Every 12 hours',
      'Once a day',
    ];

    Get.dialog(
      SimpleDialog(
        title: const Text('Select Sync Frequency'),
        children: options
            .map(
              (option) => SimpleDialogOption(
                onPressed: () {
                  syncFrequency.value = option;
                  Get.back();
                },
                child: Text(option),
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  void onInit() {
    super.onInit();
    // Initialize settings from storage
  }
}
