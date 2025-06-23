import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  final isLoading = false.obs;
  final userName = 'John Doe'.obs;
  final email = 'john.doe@example.com'.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }

  void loadUserProfile() {
    isLoading.value = true;
    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      // In a real app, fetch user data from API or local storage
      userName.value = 'John Doe';
      email.value = 'john.doe@example.com';
      isLoading.value = false;
    });
  }

  void editProfile() {
    Get.dialog(
      AlertDialog(
        title: const Text('Edit Profile'),
        content: const Text(
          'Profile editing functionality will be implemented here.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  void viewSyncHistory() {
    Get.dialog(
      AlertDialog(
        title: const Text('Sync History'),
        content: const Text('Sync history will be displayed here.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  void logout() {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              // Implement logout logic
              Get.offAllNamed('/home');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
