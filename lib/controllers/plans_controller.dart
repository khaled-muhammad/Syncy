import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncy/models/subscription_plan.dart';

class PlansController extends GetxController {
  // Current billing period toggle
  var isYearlyBilling = false.obs;
  
  // Current selected plan (starts with free)
  var selectedPlanId = 'free'.obs;
  
  // Loading states
  var isUpgrading = false.obs;
  var isChangingPlan = false.obs;

  // Get all available plans
  List<SubscriptionPlan> get allPlans => SubscriptionPlans.allPlans;
  
  // Get current user's plan
  SubscriptionPlan get currentPlan => allPlans.firstWhere(
    (plan) => plan.id == selectedPlanId.value,
    orElse: () => SubscriptionPlans.freePlan,
  );

  // Toggle between monthly and yearly billing
  void toggleBillingPeriod() {
    isYearlyBilling.value = !isYearlyBilling.value;
  }

  // Select a plan for comparison or upgrade
  void selectPlan(String planId) {
    selectedPlanId.value = planId;
  }

  // Check if a plan is currently active
  bool isPlanActive(String planId) {
    return selectedPlanId.value == planId;
  }

  // Check if user can upgrade to a specific plan
  bool canUpgradeTo(String planId) {
    final currentIndex = allPlans.indexWhere((p) => p.id == selectedPlanId.value);
    final targetIndex = allPlans.indexWhere((p) => p.id == planId);
    return targetIndex > currentIndex;
  }

  // Check if user can downgrade to a specific plan
  bool canDowngradeTo(String planId) {
    final currentIndex = allPlans.indexWhere((p) => p.id == selectedPlanId.value);
    final targetIndex = allPlans.indexWhere((p) => p.id == planId);
    return targetIndex < currentIndex;
  }

  // Get price for a plan based on billing period
  String getPlanPrice(SubscriptionPlan plan) {
    if (plan.monthlyPrice == 0) return 'Free';
    
    if (isYearlyBilling.value) {
      return plan.yearlyPriceString;
    } else {
      return plan.monthlyPriceString;
    }
  }

  // Get billing period suffix
  String getBillingPeriod() {
    return isYearlyBilling.value ? '/year' : '/month';
  }

  // Upgrade to a specific plan
  Future<void> upgradeToPlan(String planId) async {
    if (isUpgrading.value || planId == selectedPlanId.value) return;

    isUpgrading.value = true;

    try {
      // Simulate API call for plan upgrade
      await Future.delayed(const Duration(seconds: 2));
      
      // TODO: Implement actual payment processing integration
      // - Integrate with payment provider (Stripe, RevenueCat, etc.)
      // - Handle payment success/failure
      // - Update user subscription status
      
      selectedPlanId.value = planId;
      
      Get.snackbar(
        'Success! 🎉',
        'Welcome to ${allPlans.firstWhere((p) => p.id == planId).name}!',
        backgroundColor: const Color(0xFF4CAF50),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      
      // Navigate back after successful upgrade
      Get.back();
      
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to upgrade plan. Please try again.',
        backgroundColor: const Color(0xFFFF5722),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isUpgrading.value = false;
    }
  }

  // Cancel subscription (downgrade to free)
  Future<void> cancelSubscription() async {
    if (isChangingPlan.value || selectedPlanId.value == 'free') return;

    isChangingPlan.value = true;

    try {
      // Simulate API call for subscription cancellation
      await Future.delayed(const Duration(seconds: 1));
      
      // TODO: Implement actual subscription cancellation
      // - Cancel recurring payments
      // - Set plan to expire at end of billing cycle
      // - Update user status
      
      selectedPlanId.value = 'free';
      
      Get.snackbar(
        'Subscription Cancelled',
        'Your subscription will remain active until the end of your billing period.',
        backgroundColor: const Color(0xFFFF9800),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to cancel subscription. Please try again.',
        backgroundColor: const Color(0xFFFF5722),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isChangingPlan.value = false;
    }
  }

  // Get plan recommendation based on usage (placeholder logic)
  String getRecommendedPlanId() {
    // TODO: Implement logic based on user's actual usage patterns
    // - Room creation frequency
    // - Average session duration
    // - Number of participants
    // - Feature usage
    
    return 'pro'; // Default recommendation
  }

  // Check if plan has specific feature
  bool planHasFeature(String planId, String featureName) {
    final plan = allPlans.firstWhere(
      (p) => p.id == planId,
      orElse: () => SubscriptionPlans.freePlan,
    );
    
    return plan.features.any(
      (feature) => feature.title.toLowerCase().contains(featureName.toLowerCase())
    );
  }

  // Get plan benefits comparison
  Map<String, List<bool>> getFeatureComparison() {
    final features = <String, List<bool>>{};
    
    // Extract all unique features
    final allFeatures = <String>{};
    for (final plan in allPlans) {
      for (final feature in plan.features) {
        allFeatures.add(feature.title);
      }
    }
    
    // Create comparison matrix
    for (final featureName in allFeatures) {
      features[featureName] = allPlans.map(
        (plan) => plan.features.any((f) => f.title == featureName)
      ).toList();
    }
    
    return features;
  }

  @override
  void onInit() {
    super.onInit();
    // TODO: Load current user's subscription status from backend
    // selectedPlanId.value = getCurrentUserPlan();
  }
}
