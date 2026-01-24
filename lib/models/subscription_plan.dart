class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double monthlyPrice;
  final double yearlyPrice;
  final String currency;
  final List<PlanFeature> features;
  final bool isPopular;
  final String gradientStartColor;
  final String gradientEndColor;
  final String badgeText;
  final PlanLimits limits;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    this.currency = 'USD',
    required this.features,
    this.isPopular = false,
    required this.gradientStartColor,
    required this.gradientEndColor,
    this.badgeText = '',
    required this.limits,
  });

  String get monthlyPriceString => monthlyPrice == 0 ? 'Free' : '\$${monthlyPrice.toStringAsFixed(2)}/month';
  String get yearlyPriceString => yearlyPrice == 0 ? 'Free Forever' : '\$${yearlyPrice.toStringAsFixed(2)}/year';
  String get yearlySavings => yearlyPrice > 0 ? 'Save \$${((monthlyPrice * 12) - yearlyPrice).toStringAsFixed(2)}' : '';
}

class PlanFeature {
  final String title;
  final String? subtitle;
  final bool included;
  final bool highlighted;

  const PlanFeature({
    required this.title,
    this.subtitle,
    this.included = true,
    this.highlighted = false,
  });
}

class PlanLimits {
  final int maxRooms;
  final int maxUsersPerRoom;
  final int maxSessionDurationMinutes;
  final String syncQuality;
  final bool unlimitedSessions;
  final bool cloudStorage;
  final bool prioritySupport;
  final bool customBranding;
  final bool analytics;
  final bool screenSharing;

  const PlanLimits({
    required this.maxRooms,
    required this.maxUsersPerRoom,
    required this.maxSessionDurationMinutes,
    required this.syncQuality,
    this.unlimitedSessions = false,
    this.cloudStorage = false,
    this.prioritySupport = false,
    this.customBranding = false,
    this.analytics = false,
    this.screenSharing = false,
  });
}

class SubscriptionPlans {
  static const List<SubscriptionPlan> allPlans = [
    SubscriptionPlan(
      id: 'free',
      name: 'Starter',
      description: 'Perfect for casual watch parties with friends',
      monthlyPrice: 0,
      yearlyPrice: 0,
      gradientStartColor: '#667eea',
      gradientEndColor: '#764ba2',
      badgeText: 'Get Started',
      limits: PlanLimits(
        maxRooms: 2,
        maxUsersPerRoom: 4,
        maxSessionDurationMinutes: 60,
        syncQuality: 'Standard HD',
      ),
      features: [
        PlanFeature(title: 'Up to 2 simultaneous rooms'),
        PlanFeature(title: '4 users per room'),
        PlanFeature(title: 'Standard HD sync quality'),
        PlanFeature(title: '1 hour session limit'),
        PlanFeature(title: 'Basic media formats (MP4, MOV)'),
        PlanFeature(title: 'Smart search'),
        PlanFeature(title: 'Real-time synchronization'),
        PlanFeature(title: 'Beautiful UI with dark theme'),
      ],
    ),
    SubscriptionPlan(
      id: 'pro',
      name: 'Pro',
      description: 'For regular streamers and content creators',
      monthlyPrice: 4.99,
      yearlyPrice: 49.99,
      isPopular: true,
      gradientStartColor: '#8E2DE2',
      gradientEndColor: '#4A00E0',
      badgeText: 'Most Popular',
      limits: PlanLimits(
        maxRooms: 10,
        maxUsersPerRoom: 25,
        maxSessionDurationMinutes: -1, // unlimited
        syncQuality: 'Full HD',
        unlimitedSessions: true,
        prioritySupport: true,
      ),
      features: [
        PlanFeature(title: 'Up to 10 simultaneous rooms'),
        PlanFeature(title: '25 users per room'),
        PlanFeature(title: 'Full HD sync quality', highlighted: true),
        PlanFeature(title: 'Unlimited session duration', highlighted: true),
        PlanFeature(title: 'All media formats support'),
        PlanFeature(title: 'Advanced AI-powered search'),
        PlanFeature(title: 'Subtitle support with custom timing'),
        PlanFeature(title: 'Room history and recordings'),
        PlanFeature(title: 'Priority sync servers'),
        PlanFeature(title: 'Email support'),
      ],
    ),
    SubscriptionPlan(
      id: 'premium',
      name: 'Premium',
      description: 'For power users and large communities',
      monthlyPrice: 9.99,
      yearlyPrice: 99.99,
      gradientStartColor: '#FF6B6B',
      gradientEndColor: '#FF8E53',
      badgeText: 'Best Value',
      limits: PlanLimits(
        maxRooms: -1, // unlimited
        maxUsersPerRoom: 100,
        maxSessionDurationMinutes: -1, // unlimited
        syncQuality: '4K Ultra HD',
        unlimitedSessions: true,
        cloudStorage: true,
        prioritySupport: true,
        customBranding: true,
        analytics: true,
        screenSharing: true,
      ),
      features: [
        PlanFeature(title: 'Unlimited rooms'),
        PlanFeature(title: '100 users per room'),
        PlanFeature(title: '4K Ultra HD sync quality', highlighted: true),
        PlanFeature(title: 'Sub-second latency optimization', highlighted: true),
        PlanFeature(title: 'Screen sharing capabilities', highlighted: true),
        PlanFeature(title: 'Group chat during watch parties'),
        PlanFeature(title: 'Custom room branding'),
        PlanFeature(title: 'Advanced moderation tools'),
        PlanFeature(title: 'Room analytics and insights'),
        PlanFeature(title: 'Cloud storage integration'),
        PlanFeature(title: 'Custom video filters'),
        PlanFeature(title: 'Priority 24/7 support'),
        PlanFeature(title: 'API access for integrations'),
      ],
    ),
  ];

  static SubscriptionPlan get freePlan => allPlans[0];
  static SubscriptionPlan get proPlan => allPlans[1];
  static SubscriptionPlan get premiumPlan => allPlans[2];
}

