import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:syncy/controllers/plans_controller.dart';
import 'package:syncy/models/subscription_plan.dart';
import 'package:syncy/widgets/custom_button.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PlansController controller = Get.find<PlansController>();

    return Stack(
      children: [
        // Background with blur effect
        const Opacity(
          opacity: 0.3,
          child: BlurHash(
            hash: "^2701,bB6rW-Sbj[SpW,sHa{WmjuW~W,sHj[a#fQwmWlfOo4Wma}R~f9o3jujwfPn:aya^fRa_fOSZfSn.fPfRfOssa_Wnjua^a|W*jvjsfRa#",
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text(
              'Choose Your Plan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Get.back(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header section
                _buildHeader(context),
                const SizedBox(height: 24),
                
                // Billing toggle
                _buildBillingToggle(controller),
                const SizedBox(height: 32),
                
                // Plans grid
                _buildPlansGrid(controller),
                const SizedBox(height: 24),
                
                // Features comparison
                _buildFeaturesComparison(controller),
                const SizedBox(height: 32),
                
                // FAQ or additional info
                _buildAdditionalInfo(),
                const SizedBox(height: 80), // Bottom padding
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha: 0.2),
            Colors.blue.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.crown_1_bold,
            size: 48,
            color: Colors.amber,
          ),
          const SizedBox(height: 16),
          const Text(
            'Unlock the Full Syncy Experience',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the perfect plan for your watch party needs',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingToggle(PlansController controller) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToggleOption(
              'Monthly',
              !controller.isYearlyBilling.value,
              () => controller.isYearlyBilling.value = false,
            ),
            _buildToggleOption(
              'Yearly (Save up to 20%)',
              controller.isYearlyBilling.value,
              () => controller.isYearlyBilling.value = true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPlansGrid(PlansController controller) {
    return Obx(
      () => Column(
        children: controller.allPlans
            .map((plan) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildPlanCard(plan, controller),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, PlansController controller) {
    final isCurrentPlan = controller.isPlanActive(plan.id);
    final canUpgrade = controller.canUpgradeTo(plan.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Stack(
        children: [
          // Popular badge
          if (plan.isPopular)
            Positioned(
              top: -8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    plan.badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),

          // Main card
          Container(
            margin: EdgeInsets.only(top: plan.isPopular ? 16 : 0),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _hexToColor(plan.gradientStartColor).withValues(alpha: 0.3),
                  _hexToColor(plan.gradientEndColor).withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCurrentPlan
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.2),
                width: isCurrentPlan ? 2 : 1,
              ),
              boxShadow: [
                if (plan.isPopular)
                  BoxShadow(
                    color: _hexToColor(plan.gradientStartColor).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plan.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    if (isCurrentPlan)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Text(
                          'Current',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Price
                Obx(() {
                  final billing = controller.getBillingPeriod();
                  
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (plan.monthlyPrice == 0)
                        const Text(
                          'Free',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      else ...[
                        Text(
                          '\$${controller.isYearlyBilling.value ? plan.yearlyPrice.toStringAsFixed(2) : plan.monthlyPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          billing,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  );
                }),

                // Yearly savings
                if (plan.monthlyPrice > 0)
                  Obx(() {
                    if (controller.isYearlyBilling.value && plan.yearlySavings.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          plan.yearlySavings,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),

                const SizedBox(height: 24),

                // Features
                ...plan.features.take(6).map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            feature.included ? Icons.check_circle : Icons.cancel,
                            size: 16,
                            color: feature.included ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature.title,
                              style: TextStyle(
                                color: feature.highlighted
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.8),
                                fontWeight: feature.highlighted
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),

                if (plan.features.length > 6)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '+ ${plan.features.length - 6} more features',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Action button
                Obx(() => SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: isCurrentPlan
                            ? 'Current Plan'
                            : canUpgrade
                                ? 'Upgrade to ${plan.name}'
                                : plan.monthlyPrice == 0
                                    ? 'Downgrade to Free'
                                    : 'Select ${plan.name}',
                        onPressed: isCurrentPlan || controller.isUpgrading.value
                            ? null
                            : () => _handlePlanSelection(plan, controller),
                        gradient: isCurrentPlan
                            ? null
                            : LinearGradient(
                                colors: [
                                  _hexToColor(plan.gradientStartColor),
                                  _hexToColor(plan.gradientEndColor),
                                ],
                              ),
                        isLoading: controller.isUpgrading.value,
                        backgroundColor: isCurrentPlan ? Colors.grey : null,
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesComparison(PlansController controller) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Compare Features',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildComparisonRow('Max Rooms', ['2', '10', 'Unlimited']),
          _buildComparisonRow('Users per Room', ['4', '25', '100']),
          _buildComparisonRow('Session Duration', ['1 hour', 'Unlimited', 'Unlimited']),
          _buildComparisonRow('Sync Quality', ['Standard HD', 'Full HD', '4K Ultra HD']),
          _buildComparisonRow('Priority Support', ['❌', '✅', '✅']),
          _buildComparisonRow('Screen Sharing', ['❌', '❌', '✅']),
          _buildComparisonRow('Custom Branding', ['❌', '❌', '✅']),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String feature, List<String> values) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ),
          ...values.map((value) => Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildFAQItem(
            'Can I change my plan anytime?',
            'Yes! You can upgrade or downgrade your plan at any time. Changes take effect immediately.',
          ),
          _buildFAQItem(
            'What payment methods do you accept?',
            'We accept all major credit cards, PayPal, and Apple Pay for your convenience.',
          ),
          _buildFAQItem(
            'Is there a free trial?',
            'All paid plans come with a 7-day free trial. Cancel anytime during the trial period.',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _handlePlanSelection(SubscriptionPlan plan, PlansController controller) {
    if (plan.id == 'free') {
      // Handle downgrade to free
      _showDowngradeConfirmation(controller);
    } else {
      // Handle upgrade to paid plan
      controller.upgradeToPlan(plan.id);
    }
  }

  void _showDowngradeConfirmation(PlansController controller) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirm Downgrade',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to downgrade to the free plan? You\'ll lose access to premium features.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.cancelSubscription();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Confirm Downgrade'),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}
