class EarningsSummary {
  final double totalEarnings;
  final double deliveryCommission;
  final double tips;
  final double bonuses;
  final double deductions;
  final double pendingPayout;
  final double paidAmount;

  EarningsSummary({
    required this.totalEarnings,
    required this.deliveryCommission,
    required this.tips,
    required this.bonuses,
    required this.deductions,
    required this.pendingPayout,
    required this.paidAmount,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      totalEarnings: double.tryParse(json['total_earnings']?.toString() ?? '0') ?? 0,
      deliveryCommission: double.tryParse(json['delivery_commission']?.toString() ?? '0') ?? 0,
      tips: double.tryParse(json['tips']?.toString() ?? '0') ?? 0,
      bonuses: double.tryParse(json['bonuses']?.toString() ?? '0') ?? 0,
      deductions: double.tryParse(json['deductions']?.toString() ?? '0') ?? 0,
      pendingPayout: double.tryParse(json['pending_payout']?.toString() ?? '0') ?? 0,
      paidAmount: double.tryParse(json['paid_amount']?.toString() ?? '0') ?? 0,
    );
  }
}

class EarningTransaction {
  final int id;
  final String? assignmentNumber;
  final String earningType;
  final double amount;
  final String description;
  final bool isPaid;
  final DateTime createdAt;

  EarningTransaction({
    required this.id,
    this.assignmentNumber,
    required this.earningType,
    required this.amount,
    required this.description,
    required this.isPaid,
    required this.createdAt,
  });

  factory EarningTransaction.fromJson(Map<String, dynamic> json) {
    return EarningTransaction(
      id: json['id'],
      assignmentNumber: json['assignment_number'],
      earningType: json['earning_type'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      description: json['description'] ?? '',
      isPaid: json['is_paid'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get typeDisplayName {
    switch (earningType) {
      case 'DELIVERY':
        return 'Delivery';
      case 'TIP':
        return 'Tip';
      case 'BONUS':
        return 'Bonus';
      case 'PENALTY':
        return 'Penalty';
      case 'ADJUSTMENT':
        return 'Adjustment';
      default:
        return earningType;
    }
  }
}

class EarningsData {
  final EarningsSummary summary;
  final int deliveriesCount;
  final double averagePerDelivery;
  final List<EarningTransaction> transactions;

  EarningsData({
    required this.summary,
    required this.deliveriesCount,
    required this.averagePerDelivery,
    required this.transactions,
  });

  factory EarningsData.fromJson(Map<String, dynamic> json) {
    return EarningsData(
      summary: EarningsSummary.fromJson(json['summary'] ?? {}),
      deliveriesCount: json['deliveries_count'] ?? 0,
      averagePerDelivery: double.tryParse(json['average_per_delivery']?.toString() ?? '0') ?? 0,
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((e) => EarningTransaction.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class PerformanceStats {
  final int totalDeliveries;
  final int successfulDeliveries;
  final int failedDeliveries;
  final double successRate;
  final double averageRating;
  final int totalRatings;
  final double onTimeRate;

  PerformanceStats({
    required this.totalDeliveries,
    required this.successfulDeliveries,
    required this.failedDeliveries,
    required this.successRate,
    required this.averageRating,
    required this.totalRatings,
    required this.onTimeRate,
  });

  factory PerformanceStats.fromJson(Map<String, dynamic> json) {
    return PerformanceStats(
      totalDeliveries: json['total_deliveries'] ?? 0,
      successfulDeliveries: json['successful_deliveries'] ?? 0,
      failedDeliveries: json['failed_deliveries'] ?? 0,
      successRate: double.tryParse(json['success_rate']?.toString() ?? '0') ?? 0,
      averageRating: double.tryParse(json['average_rating']?.toString() ?? '0') ?? 0,
      totalRatings: json['total_ratings'] ?? 0,
      onTimeRate: double.tryParse(json['on_time_rate']?.toString() ?? '0') ?? 0,
    );
  }
}

class TodayStats {
  final int deliveriesCompleted;
  final double earnings;
  final int hoursOnline;
  final double distanceCoveredKm;

  TodayStats({
    required this.deliveriesCompleted,
    required this.earnings,
    required this.hoursOnline,
    required this.distanceCoveredKm,
  });

  factory TodayStats.fromJson(Map<String, dynamic> json) {
    return TodayStats(
      deliveriesCompleted: json['deliveries_completed'] ?? 0,
      earnings: double.tryParse(json['earnings']?.toString() ?? '0') ?? 0,
      hoursOnline: json['hours_online'] ?? 0,
      distanceCoveredKm: double.tryParse(json['distance_covered_km']?.toString() ?? '0') ?? 0,
    );
  }
}

class WeekStats {
  final int deliveriesCompleted;
  final double earnings;
  final double averagePerDay;

  WeekStats({
    required this.deliveriesCompleted,
    required this.earnings,
    required this.averagePerDay,
  });

  factory WeekStats.fromJson(Map<String, dynamic> json) {
    return WeekStats(
      deliveriesCompleted: json['deliveries_completed'] ?? 0,
      earnings: double.tryParse(json['earnings']?.toString() ?? '0') ?? 0,
      averagePerDay: double.tryParse(json['average_per_day']?.toString() ?? '0') ?? 0,
    );
  }
}

class RatingBreakdown {
  final int oneStar;
  final int twoStar;
  final int threeStar;
  final int fourStar;
  final int fiveStar;

  RatingBreakdown({
    required this.oneStar,
    required this.twoStar,
    required this.threeStar,
    required this.fourStar,
    required this.fiveStar,
  });

  factory RatingBreakdown.fromJson(Map<String, dynamic> json) {
    return RatingBreakdown(
      oneStar: json['1_star'] ?? 0,
      twoStar: json['2_star'] ?? 0,
      threeStar: json['3_star'] ?? 0,
      fourStar: json['4_star'] ?? 0,
      fiveStar: json['5_star'] ?? 0,
    );
  }

  int get total => oneStar + twoStar + threeStar + fourStar + fiveStar;
}

class StatisticsData {
  final PerformanceStats performance;
  final TodayStats today;
  final WeekStats thisWeek;
  final RatingBreakdown ratingBreakdown;

  StatisticsData({
    required this.performance,
    required this.today,
    required this.thisWeek,
    required this.ratingBreakdown,
  });

  factory StatisticsData.fromJson(Map<String, dynamic> json) {
    return StatisticsData(
      performance: PerformanceStats.fromJson(json['performance'] ?? {}),
      today: TodayStats.fromJson(json['today'] ?? {}),
      thisWeek: WeekStats.fromJson(json['this_week'] ?? {}),
      ratingBreakdown: RatingBreakdown.fromJson(json['rating_breakdown'] ?? {}),
    );
  }
}
