class DashboardData {
  final DashboardPeriod period;
  final DashboardAgent agent;
  final DeliveryStats deliveryStats;
  final EarningsSummary earnings;
  final CodSummary codSummary;
  final PerformanceMetrics performance;
  final RatingSummary rating;
  final TodaySnapshot todaySnapshot;
  final TrendsData? trends;

  DashboardData({
    required this.period,
    required this.agent,
    required this.deliveryStats,
    required this.earnings,
    required this.codSummary,
    required this.performance,
    required this.rating,
    required this.todaySnapshot,
    this.trends,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      period: DashboardPeriod.fromJson(json['period'] ?? {}),
      agent: DashboardAgent.fromJson(json['agent'] ?? {}),
      deliveryStats: DeliveryStats.fromJson(json['delivery_stats'] ?? {}),
      earnings: EarningsSummary.fromJson(json['earnings'] ?? {}),
      codSummary: CodSummary.fromJson(json['cod_summary'] ?? {}),
      performance: PerformanceMetrics.fromJson(json['performance'] ?? {}),
      rating: RatingSummary.fromJson(json['rating'] ?? {}),
      todaySnapshot: TodaySnapshot.fromJson(json['today_snapshot'] ?? {}),
      trends: json['trends'] != null ? TrendsData.fromJson(json['trends']) : null,
    );
  }
}

class DashboardPeriod {
  final String type;
  final String startDate;
  final String endDate;

  DashboardPeriod({
    required this.type,
    required this.startDate,
    required this.endDate,
  });

  factory DashboardPeriod.fromJson(Map<String, dynamic> json) {
    return DashboardPeriod(
      type: json['type'] ?? 'today',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
    );
  }
}

class DashboardAgent {
  final int id;
  final String name;
  final String code;
  final String phone;
  final String? photo;
  final String status;
  final String statusDisplay;
  final String vehicleType;
  final bool isVerified;
  final bool isActive;

  DashboardAgent({
    required this.id,
    required this.name,
    required this.code,
    required this.phone,
    this.photo,
    required this.status,
    required this.statusDisplay,
    required this.vehicleType,
    required this.isVerified,
    required this.isActive,
  });

  factory DashboardAgent.fromJson(Map<String, dynamic> json) {
    return DashboardAgent(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      phone: json['phone'] ?? '',
      photo: json['photo'],
      status: json['status'] ?? 'OFFLINE',
      statusDisplay: json['status_display'] ?? 'Offline',
      vehicleType: json['vehicle_type'] ?? 'BIKE',
      isVerified: json['is_verified'] ?? false,
      isActive: json['is_active'] ?? false,
    );
  }
}

class DeliveryStats {
  final int totalDeliveries;
  final int successfulDeliveries;
  final int failedDeliveries;
  final int cancelledDeliveries;
  final int returnedDeliveries;
  final double successRate;
  final double failureRate;
  final double cancellationRate;
  final double avgDeliveriesPerDay;

  DeliveryStats({
    required this.totalDeliveries,
    required this.successfulDeliveries,
    required this.failedDeliveries,
    required this.cancelledDeliveries,
    required this.returnedDeliveries,
    required this.successRate,
    required this.failureRate,
    required this.cancellationRate,
    required this.avgDeliveriesPerDay,
  });

  factory DeliveryStats.fromJson(Map<String, dynamic> json) {
    return DeliveryStats(
      totalDeliveries: json['total_deliveries'] ?? 0,
      successfulDeliveries: json['successful_deliveries'] ?? 0,
      failedDeliveries: json['failed_deliveries'] ?? 0,
      cancelledDeliveries: json['cancelled_deliveries'] ?? 0,
      returnedDeliveries: json['returned_deliveries'] ?? 0,
      successRate: _parseDouble(json['success_rate']),
      failureRate: _parseDouble(json['failure_rate']),
      cancellationRate: _parseDouble(json['cancellation_rate']),
      avgDeliveriesPerDay: _parseDouble(json['avg_deliveries_per_day']),
    );
  }
}

class EarningsSummary {
  final double totalEarnings;
  final double commissionEarned;
  final double deliveryFeesEarned;
  final double tipsReceived;
  final double bonuses;
  final double deductions;
  final double netEarnings;
  final double pendingPayout;
  final String? lastPayoutDate;
  final double lastPayoutAmount;

  EarningsSummary({
    required this.totalEarnings,
    required this.commissionEarned,
    required this.deliveryFeesEarned,
    required this.tipsReceived,
    required this.bonuses,
    required this.deductions,
    required this.netEarnings,
    required this.pendingPayout,
    this.lastPayoutDate,
    required this.lastPayoutAmount,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      totalEarnings: _parseDouble(json['total_earnings']),
      commissionEarned: _parseDouble(json['commission_earned']),
      deliveryFeesEarned: _parseDouble(json['delivery_fees_earned']),
      tipsReceived: _parseDouble(json['tips_received']),
      bonuses: _parseDouble(json['bonuses']),
      deductions: _parseDouble(json['deductions']),
      netEarnings: _parseDouble(json['net_earnings']),
      pendingPayout: _parseDouble(json['pending_payout']),
      lastPayoutDate: json['last_payout_date'],
      lastPayoutAmount: _parseDouble(json['last_payout_amount']),
    );
  }
}

class CodSummary {
  final int totalCodOrders;
  final double codCollected;
  final double codSubmitted;
  final double codPending;
  final String? codDueDate;

  CodSummary({
    required this.totalCodOrders,
    required this.codCollected,
    required this.codSubmitted,
    required this.codPending,
    this.codDueDate,
  });

  factory CodSummary.fromJson(Map<String, dynamic> json) {
    return CodSummary(
      totalCodOrders: json['total_cod_orders'] ?? 0,
      codCollected: _parseDouble(json['cod_collected']),
      codSubmitted: _parseDouble(json['cod_submitted']),
      codPending: _parseDouble(json['cod_pending']),
      codDueDate: json['cod_due_date'],
    );
  }
}

class PerformanceMetrics {
  final int avgDeliveryTimeMinutes;
  final double totalDistanceKm;
  final double avgDistancePerDeliveryKm;
  final double onTimeDeliveryRate;
  final int lateDeliveries;
  final String? peakHour;
  final String? busiestDay;

  PerformanceMetrics({
    required this.avgDeliveryTimeMinutes,
    required this.totalDistanceKm,
    required this.avgDistancePerDeliveryKm,
    required this.onTimeDeliveryRate,
    required this.lateDeliveries,
    this.peakHour,
    this.busiestDay,
  });

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      avgDeliveryTimeMinutes: json['avg_delivery_time_minutes'] ?? 0,
      totalDistanceKm: _parseDouble(json['total_distance_km']),
      avgDistancePerDeliveryKm: _parseDouble(json['avg_distance_per_delivery_km']),
      onTimeDeliveryRate: _parseDouble(json['on_time_delivery_rate']),
      lateDeliveries: json['late_deliveries'] ?? 0,
      peakHour: json['peak_hour'],
      busiestDay: json['busiest_day'],
    );
  }
}

class RatingSummary {
  final double averageRating;
  final int totalReviews;
  final int fiveStar;
  final int fourStar;
  final int threeStar;
  final int twoStar;
  final int oneStar;
  final List<ReviewItem> recentReviews;

  RatingSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.fiveStar,
    required this.fourStar,
    required this.threeStar,
    required this.twoStar,
    required this.oneStar,
    required this.recentReviews,
  });

  factory RatingSummary.fromJson(Map<String, dynamic> json) {
    return RatingSummary(
      averageRating: _parseDouble(json['average_rating']),
      totalReviews: json['total_reviews'] ?? 0,
      fiveStar: json['five_star'] ?? 0,
      fourStar: json['four_star'] ?? 0,
      threeStar: json['three_star'] ?? 0,
      twoStar: json['two_star'] ?? 0,
      oneStar: json['one_star'] ?? 0,
      recentReviews: (json['recent_reviews'] as List<dynamic>?)
              ?.map((e) => ReviewItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ReviewItem {
  final int rating;
  final String? comment;
  final String date;

  ReviewItem({
    required this.rating,
    this.comment,
    required this.date,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      date: json['date'] ?? '',
    );
  }
}

class TodaySnapshot {
  final int deliveriesCompleted;
  final int deliveriesPending;
  final double earningsToday;
  final double codCollectedToday;
  final double hoursOnline;

  TodaySnapshot({
    required this.deliveriesCompleted,
    required this.deliveriesPending,
    required this.earningsToday,
    required this.codCollectedToday,
    required this.hoursOnline,
  });

  factory TodaySnapshot.fromJson(Map<String, dynamic> json) {
    return TodaySnapshot(
      deliveriesCompleted: json['deliveries_completed'] ?? 0,
      deliveriesPending: json['deliveries_pending'] ?? 0,
      earningsToday: _parseDouble(json['earnings_today']),
      codCollectedToday: _parseDouble(json['cod_collected_today']),
      hoursOnline: _parseDouble(json['hours_online']),
    );
  }
}

class TrendsData {
  final List<TrendPoint> deliveriesTrend;
  final List<TrendPoint> earningsTrend;

  TrendsData({
    required this.deliveriesTrend,
    required this.earningsTrend,
  });

  factory TrendsData.fromJson(Map<String, dynamic> json) {
    return TrendsData(
      deliveriesTrend: (json['deliveries_trend'] as List<dynamic>?)
              ?.map((e) => TrendPoint.fromJson(e, isCount: true))
              .toList() ??
          [],
      earningsTrend: (json['earnings_trend'] as List<dynamic>?)
              ?.map((e) => TrendPoint.fromJson(e, isCount: false))
              .toList() ??
          [],
    );
  }
}

class TrendPoint {
  final String date;
  final double value;

  TrendPoint({required this.date, required this.value});

  factory TrendPoint.fromJson(Map<String, dynamic> json, {bool isCount = true}) {
    return TrendPoint(
      date: json['date'] ?? '',
      value: isCount
          ? (json['count'] ?? 0).toDouble()
          : _parseDouble(json['amount']),
    );
  }
}

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
