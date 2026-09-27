class SubscriptionUsage {
  final String plan;
  final String planDisplayName;
  final int planPrice;
  final bool isTrial;
  final DateTime? trialEndsAt;
  final bool hasUsedTrial;
  final bool isFounderPlan;
  final int whatsappUsed;
  final int whatsappLimit;
  final int whatsappRemaining;
  final int whatsappPercentage;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final int totalMessagesSent;

  SubscriptionUsage({
    required this.plan,
    required this.planDisplayName,
    required this.planPrice,
    required this.isTrial,
    this.trialEndsAt,
    required this.hasUsedTrial,
    required this.isFounderPlan,
    required this.whatsappUsed,
    required this.whatsappLimit,
    required this.whatsappRemaining,
    required this.whatsappPercentage,
    this.periodStart,
    this.periodEnd,
    required this.totalMessagesSent,
  });

  factory SubscriptionUsage.fromJson(Map<String, dynamic> json) {
    final whatsapp = json['whatsapp'] as Map<String, dynamic>? ?? {};

    return SubscriptionUsage(
      plan: json['plan']?.toString() ?? 'free',
      planDisplayName:
          json['planDisplayName']?.toString() ?? 'Free',
      planPrice: (json['planPrice'] as num?)?.toInt() ?? 0,
      isTrial: json['isTrial'] == true,
      trialEndsAt: json['trialEndsAt'] != null
          ? DateTime.tryParse(json['trialEndsAt'].toString())
          : null,
      hasUsedTrial: json['hasUsedTrial'] == true,
      isFounderPlan: json['isFounderPlan'] == true,
      whatsappUsed: (whatsapp['used'] as num?)?.toInt() ?? 0,
      whatsappLimit: (whatsapp['limit'] as num?)?.toInt() ?? 50,
      whatsappRemaining:
          (whatsapp['remaining'] as num?)?.toInt() ?? 0,
      whatsappPercentage:
          (whatsapp['percentage'] as num?)?.toInt() ?? 0,
      periodStart: json['periodStart'] != null
          ? DateTime.tryParse(json['periodStart'].toString())
          : null,
      periodEnd: json['periodEnd'] != null
          ? DateTime.tryParse(json['periodEnd'].toString())
          : null,
      totalMessagesSent:
          (json['totalMessagesSent'] as num?)?.toInt() ?? 0,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool get hasReachedLimit => whatsappRemaining <= 0;

  bool get isNearLimit => whatsappPercentage >= 80;

  bool get canStartTrial => !hasUsedTrial && !isTrial;
}