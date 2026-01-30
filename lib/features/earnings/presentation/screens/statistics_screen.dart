import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/earnings_provider.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(statisticsProvider.notifier).loadStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final statisticsState = ref.watch(statisticsProvider);
    final stats = statisticsState.statistics;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: statisticsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(statisticsProvider.notifier).loadStatistics();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Today's Performance
                    const Text(
                      "Today's Performance",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _TodayStatCard(
                            icon: Icons.local_shipping_rounded,
                            value: '${stats?.today.deliveriesCompleted ?? 0}',
                            label: 'Deliveries',
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TodayStatCard(
                            icon: Icons.account_balance_wallet_rounded,
                            value: stats?.today.earnings.currency ?? 'Rs 0',
                            label: 'Earned',
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _TodayStatCard(
                            icon: Icons.access_time_rounded,
                            value: '${stats?.today.hoursOnline ?? 0}h',
                            label: 'Online',
                            color: AppColors.info,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TodayStatCard(
                            icon: Icons.route_rounded,
                            value: '${stats?.today.distanceCoveredKm.toStringAsFixed(1) ?? 0} km',
                            label: 'Distance',
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Performance Overview
                    const Text(
                      'Overall Performance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _PerformanceCircle(
                                  value: stats?.performance.successRate ?? 0,
                                  label: 'Success Rate',
                                  color: AppColors.success,
                                ),
                                _PerformanceCircle(
                                  value: stats?.performance.onTimeRate ?? 0,
                                  label: 'On-Time',
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),
                            _StatRow(
                              label: 'Total Deliveries',
                              value: '${stats?.performance.totalDeliveries ?? 0}',
                            ),
                            _StatRow(
                              label: 'Successful',
                              value: '${stats?.performance.successfulDeliveries ?? 0}',
                              valueColor: AppColors.success,
                            ),
                            _StatRow(
                              label: 'Failed',
                              value: '${stats?.performance.failedDeliveries ?? 0}',
                              valueColor: AppColors.error,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Rating Breakdown
                    const Text(
                      'Rating Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      stats?.performance.averageRating.toStringAsFixed(1) ?? '0.0',
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(
                                        5,
                                        (index) => Icon(
                                          index < (stats?.performance.averageRating.round() ?? 0)
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          color: AppColors.warning,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${stats?.performance.totalRatings ?? 0} reviews',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  child: Column(
                                    children: [
                                      _RatingBar(
                                        stars: 5,
                                        count: stats?.ratingBreakdown.fiveStar ?? 0,
                                        total: stats?.ratingBreakdown.total ?? 1,
                                      ),
                                      _RatingBar(
                                        stars: 4,
                                        count: stats?.ratingBreakdown.fourStar ?? 0,
                                        total: stats?.ratingBreakdown.total ?? 1,
                                      ),
                                      _RatingBar(
                                        stars: 3,
                                        count: stats?.ratingBreakdown.threeStar ?? 0,
                                        total: stats?.ratingBreakdown.total ?? 1,
                                      ),
                                      _RatingBar(
                                        stars: 2,
                                        count: stats?.ratingBreakdown.twoStar ?? 0,
                                        total: stats?.ratingBreakdown.total ?? 1,
                                      ),
                                      _RatingBar(
                                        stars: 1,
                                        count: stats?.ratingBreakdown.oneStar ?? 0,
                                        total: stats?.ratingBreakdown.total ?? 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Weekly Summary
                    const Text(
                      'This Week',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _StatRow(
                              label: 'Deliveries Completed',
                              value: '${stats?.thisWeek.deliveriesCompleted ?? 0}',
                            ),
                            _StatRow(
                              label: 'Total Earnings',
                              value: stats?.thisWeek.earnings.currency ?? 'Rs 0',
                              valueColor: AppColors.success,
                            ),
                            _StatRow(
                              label: 'Daily Average',
                              value: stats?.thisWeek.averagePerDay.currency ?? 'Rs 0',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }
}

class _TodayStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _TodayStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceCircle extends StatelessWidget {
  final double value;
  final String label;
  final Color color;

  const _PerformanceCircle({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: value / 100,
                strokeWidth: 10,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Center(
                child: Text(
                  '${value.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBar extends StatelessWidget {
  final int stars;
  final int count;
  final int total;

  const _RatingBar({
    required this.stars,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? count / total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$stars',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star_rounded, size: 12, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 24,
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
