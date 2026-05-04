class UserTrustInsight {
  final int completedTrades;
  final int cancelledTrades;
  final int declinedTrades;
  final int disputedTrades;
  final double? avgResponseHours;
  final double? avgShippingHours;
  final bool isNewAccount;
  final bool profileIncomplete;
  final bool hasInsufficientHistory;

  const UserTrustInsight({
    this.completedTrades = 0,
    this.cancelledTrades = 0,
    this.declinedTrades = 0,
    this.disputedTrades = 0,
    this.avgResponseHours,
    this.avgShippingHours,
    this.isNewAccount = false,
    this.profileIncomplete = false,
    this.hasInsufficientHistory = true,
  });

  factory UserTrustInsight.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserTrustInsight();
    return UserTrustInsight(
      completedTrades: json['completed_trades'] as int? ?? 0,
      cancelledTrades: json['cancelled_trades'] as int? ?? 0,
      declinedTrades: json['declined_trades'] as int? ?? 0,
      disputedTrades: json['disputed_trades'] as int? ?? 0,
      avgResponseHours:
          json['avg_response_hours'] != null
              ? (json['avg_response_hours'] as num).toDouble()
              : null,
      avgShippingHours:
          json['avg_shipping_hours'] != null
              ? (json['avg_shipping_hours'] as num).toDouble()
              : null,
      isNewAccount: json['is_new_account'] as bool? ?? false,
      profileIncomplete: json['profile_incomplete'] as bool? ?? false,
      hasInsufficientHistory: json['has_insufficient_history'] as bool? ?? true,
    );
  }

  bool get hasAnySignal =>
      completedTrades > 0 ||
      cancelledTrades > 0 ||
      declinedTrades > 0 ||
      disputedTrades > 0 ||
      avgResponseHours != null ||
      avgShippingHours != null ||
      isNewAccount ||
      profileIncomplete;
}
