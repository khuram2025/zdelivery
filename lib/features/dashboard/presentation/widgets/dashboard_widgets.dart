import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../data/models.dart';

class HomeWorkPanel extends StatelessWidget {
  final DashboardData data;
  final MobileDeliverySummary? summary;
  final String periodLabel;
  final int pendingCount;
  final VoidCallback onPendingTap;
  final VoidCallback onOrdersTap;
  final VoidCallback onCustomersTap;

  const HomeWorkPanel({
    super.key,
    required this.data,
    required this.summary,
    required this.periodLabel,
    required this.pendingCount,
    required this.onPendingTap,
    required this.onOrdersTap,
    required this.onCustomersTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeOrders =
        summary?.workload.activeOrders ?? data.todaySnapshot.deliveriesPending;
    final delivered =
        summary?.completion.delivered ?? data.todaySnapshot.deliveriesCompleted;
    final failed =
        summary?.completion.failed ?? data.deliveryStats.failedDeliveries;
    final customerCount = (summary?.codCustomers.length ?? 0) +
        (summary?.creditCustomers.length ?? 0);

    return _DashboardPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      periodLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      periodLabel == 'Today'
                          ? 'Assigned delivery workload'
                          : 'Assigned workload for selected period',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _InlineStatus(
                value: '$activeOrders',
                label: 'active',
                color: activeOrders > 0 ? AppColors.warning : AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HomeMetricTile(
                  label: 'Pending',
                  value: '$pendingCount',
                  icon: Icons.pending_actions_rounded,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HomeMetricTile(
                  label: 'Delivered',
                  value: '$delivered',
                  icon: Icons.task_alt_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HomeMetricTile(
                  label: 'Failed',
                  value: '$failed',
                  icon: Icons.cancel_outlined,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _HomeActionButton(
                  icon: Icons.inventory_2_outlined,
                  label: 'Pending',
                  onTap: onPendingTap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HomeActionButton(
                  icon: Icons.list_alt_rounded,
                  label: 'Orders',
                  onTap: onOrdersTap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HomeActionButton(
                  icon: Icons.people_alt_outlined,
                  label: customerCount > 0
                      ? 'Customers $customerCount'
                      : 'Customers',
                  onTap: onCustomersTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HomeMoneyPanel extends StatelessWidget {
  final EarningsSummary earnings;
  final CodSummary codSummary;
  final MobileDeliverySummary? summary;

  const HomeMoneyPanel({
    super.key,
    required this.earnings,
    required this.codSummary,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final codToCollect =
        summary?.payments.codToCollect.amount ?? codSummary.codPending;
    final codCollected =
        summary?.payments.codCollected.amount ?? codSummary.codCollected;
    final creditAmount = summary?.payments.creditDelivered.amount ?? 0;

    return _DashboardPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: _PanelTitle(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Money',
                  subtitle: 'Cash, credit, and earnings',
                ),
              ),
              Text(
                earnings.netEarnings.currency,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AmountRowTile(
                  label: 'COD to collect',
                  value: codToCollect.currency,
                  icon: Icons.payments_outlined,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AmountRowTile(
                  label: 'COD collected',
                  value: codCollected.currency,
                  icon: Icons.price_check_outlined,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _AmountRowTile(
                  label: 'Credit delivered',
                  value: creditAmount.currency,
                  icon: Icons.credit_card_rounded,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AmountRowTile(
                  label: 'Pending payout',
                  value: earnings.pendingPayout.currency,
                  icon: Icons.schedule_rounded,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HomePerformancePanel extends StatelessWidget {
  final DeliveryStats stats;
  final MobileDeliverySummary? summary;
  final PerformanceMetrics performance;
  final RatingSummary rating;

  const HomePerformancePanel({
    super.key,
    required this.stats,
    required this.summary,
    required this.performance,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final delivered =
        summary?.completion.delivered ?? stats.successfulDeliveries;
    final failed = summary?.completion.failed ?? stats.failedDeliveries;
    final cancelled =
        summary?.completion.cancelled ?? stats.cancelledDeliveries;
    final totalDeliveries = summary != null
        ? delivered + failed + cancelled
        : stats.totalDeliveries;
    final successRate = (summary?.completion.successRate ?? stats.successRate)
        .clamp(0, 100)
        .toDouble();

    return _DashboardPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(
            icon: Icons.speed_outlined,
            title: 'Performance',
            subtitle: 'Delivery quality indicators',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HomeMetricTile(
                  label: 'Success rate',
                  value: '${successRate.toStringAsFixed(1)}%',
                  icon: Icons.verified_outlined,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HomeMetricTile(
                  label: 'Avg time',
                  value: '${performance.avgDeliveryTimeMinutes} min',
                  icon: Icons.timer_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HomeMetricTile(
                  label: 'Rating',
                  value: rating.averageRating.toStringAsFixed(1),
                  icon: Icons.star_rounded,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: successRate / 100,
              minHeight: 7,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation(AppColors.success),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$delivered successful of $totalDeliveries total deliveries',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _DashboardPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _PanelTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PanelTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InlineStatus extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _InlineStatus({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _HomeMetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 18),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRowTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _AmountRowTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HomeActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 17),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Today's Quick Stats Card
class TodayStatsCard extends StatelessWidget {
  final TodaySnapshot snapshot;

  const TodayStatsCard({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF1A4FD6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Overview",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${snapshot.hoursOnline.toStringAsFixed(1)}h online',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _QuickStatItem(
                  icon: Icons.check_circle_outline,
                  value: '${snapshot.deliveriesCompleted}',
                  label: 'Completed',
                ),
              ),
              _VerticalDivider(),
              Expanded(
                child: _QuickStatItem(
                  icon: Icons.pending_outlined,
                  value: '${snapshot.deliveriesPending}',
                  label: 'Pending',
                ),
              ),
              _VerticalDivider(),
              Expanded(
                child: _QuickStatItem(
                  icon: Icons.account_balance_wallet_outlined,
                  value: snapshot.earningsToday.currency,
                  label: 'Earned',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _QuickStatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(180),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: 1,
      color: Colors.white.withAlpha(50),
    );
  }
}

// Delivery Stats Card
class DeliveryStatsCard extends StatelessWidget {
  final DeliveryStats stats;

  const DeliveryStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Delivery Statistics',
      icon: Icons.local_shipping_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  value: '${stats.totalDeliveries}',
                  label: 'Total',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  value: '${stats.successfulDeliveries}',
                  label: 'Success',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  value: '${stats.failedDeliveries}',
                  label: 'Failed',
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Success Rate Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Success Rate',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${stats.successRate.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: stats.successRate / 100,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: const AlwaysStoppedAnimation(AppColors.success),
                  minHeight: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Additional Stats Row
          Row(
            children: [
              _MiniStat(
                label: 'Cancelled',
                value: '${stats.cancelledDeliveries}',
                color: AppColors.warning,
              ),
              const SizedBox(width: 16),
              _MiniStat(
                label: 'Returned',
                value: '${stats.returnedDeliveries}',
                color: AppColors.info,
              ),
              const SizedBox(width: 16),
              _MiniStat(
                label: 'Avg/Day',
                value: stats.avgDeliveriesPerDay.toStringAsFixed(1),
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatBox({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Earnings Card
class EarningsCard extends StatelessWidget {
  final EarningsSummary earnings;

  const EarningsCard({super.key, required this.earnings});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Earnings',
      icon: Icons.account_balance_wallet_outlined,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          earnings.netEarnings.currency,
          style: const TextStyle(
            color: AppColors.success,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      child: Column(
        children: [
          _EarningsRow(
            label: 'Commission',
            value: earnings.commissionEarned.currency,
            icon: Icons.percent,
          ),
          _EarningsRow(
            label: 'Delivery Fees',
            value: earnings.deliveryFeesEarned.currency,
            icon: Icons.local_shipping_outlined,
          ),
          _EarningsRow(
            label: 'Tips',
            value: earnings.tipsReceived.currency,
            icon: Icons.volunteer_activism_outlined,
          ),
          if (earnings.bonuses > 0)
            _EarningsRow(
              label: 'Bonuses',
              value: '+${earnings.bonuses.currency}',
              icon: Icons.card_giftcard_outlined,
              valueColor: AppColors.success,
            ),
          if (earnings.deductions > 0)
            _EarningsRow(
              label: 'Deductions',
              value: '-${earnings.deductions.currency}',
              icon: Icons.remove_circle_outline,
              valueColor: AppColors.error,
            ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pending Payout',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    earnings.pendingPayout.currency,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              if (earnings.lastPayoutDate != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Last Payout',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    Text(
                      earnings.lastPayoutAmount.currency,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EarningsRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _EarningsRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// COD Summary Card
class CodSummaryCard extends StatelessWidget {
  final CodSummary codSummary;

  const CodSummaryCard({super.key, required this.codSummary});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'COD Summary',
      icon: Icons.payments_outlined,
      trailing: Text(
        '${codSummary.totalCodOrders} orders',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _CodStatItem(
                  label: 'Collected',
                  value: codSummary.codCollected.currency,
                  color: AppColors.success,
                  icon: Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CodStatItem(
                  label: 'Submitted',
                  value: codSummary.codSubmitted.currency,
                  color: AppColors.info,
                  icon: Icons.arrow_upward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CodStatItem(
                  label: 'Pending',
                  value: codSummary.codPending.currency,
                  color: AppColors.warning,
                  icon: Icons.schedule,
                ),
              ),
            ],
          ),
          if (codSummary.codPending > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.warning, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You have ${codSummary.codPending.currency} pending COD to submit',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CodStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _CodStatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class MobileSummaryCard extends StatelessWidget {
  final MobileDeliverySummary summary;

  const MobileSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Delivery Summary',
      icon: Icons.analytics_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: 'Active',
                  value: '${summary.workload.activeOrders}',
                  color: AppColors.primary,
                  icon: Icons.local_shipping_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryStat(
                  label: 'Delivered',
                  value: '${summary.completion.delivered}',
                  color: AppColors.success,
                  icon: Icons.task_alt,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryStat(
                  label: 'Failed',
                  value: '${summary.completion.failed}',
                  color: AppColors.error,
                  icon: Icons.cancel_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: 'COD Due',
                  value: summary.payments.codToCollect.amount.currency,
                  color: AppColors.warning,
                  icon: Icons.payments_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryStat(
                  label: 'COD Done',
                  value: summary.payments.codCollected.amount.currency,
                  color: AppColors.success,
                  icon: Icons.price_check_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryStat(
                  label: 'Credit',
                  value: summary.payments.creditDelivered.amount.currency,
                  color: AppColors.info,
                  icon: Icons.credit_card,
                ),
              ),
            ],
          ),
          if (summary.failedReasons.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...summary.failedReasons.entries.map((entry) {
              final label = FailureReason.displayNames[entry.key] ??
                  entry.key.toLowerCase().replaceAll('_', ' ').capitalizeWords;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.report_problem_outlined,
                        size: 16, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                    Text(
                      '${entry.value}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class SummaryCustomerLists extends StatelessWidget {
  final MobileDeliverySummary summary;

  const SummaryCustomerLists({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary.codCustomers.isEmpty && summary.creditCustomers.isEmpty) {
      return const SizedBox.shrink();
    }

    return _DashboardCard(
      title: 'Customer Payments',
      icon: Icons.people_outline,
      child: Column(
        children: [
          if (summary.codCustomers.isNotEmpty)
            _CustomerGroup(
              title: 'COD Customers',
              color: AppColors.warning,
              customers: summary.codCustomers,
            ),
          if (summary.codCustomers.isNotEmpty &&
              summary.creditCustomers.isNotEmpty)
            const Divider(height: 24),
          if (summary.creditCustomers.isNotEmpty)
            _CustomerGroup(
              title: 'Credit Customers',
              color: AppColors.info,
              customers: summary.creditCustomers,
            ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CustomerGroup extends StatelessWidget {
  final String title;
  final Color color;
  final List<SummaryCustomer> customers;

  const _CustomerGroup({
    required this.title,
    required this.color,
    required this.customers,
  });

  @override
  Widget build(BuildContext context) {
    final visibleCustomers = customers.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person_pin_circle_outlined, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            Text(
              '${customers.length}',
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...visibleCustomers
            .map((customer) => _CustomerPaymentRow(customer: customer)),
        if (customers.length > visibleCustomers.length)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+${customers.length - visibleCustomers.length} more',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
          ),
      ],
    );
  }
}

class _CustomerPaymentRow extends StatelessWidget {
  final SummaryCustomer customer;

  const _CustomerPaymentRow({required this.customer});

  @override
  Widget build(BuildContext context) {
    final title = customer.customerName.isNotEmpty
        ? customer.customerName
        : customer.orderNumber;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  customer.customerMobile.isNotEmpty
                      ? customer.customerMobile
                      : customer.orderNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            customer.amount.currency,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// Performance Card
class PerformanceCard extends StatelessWidget {
  final PerformanceMetrics performance;

  const PerformanceCard({super.key, required this.performance});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Performance',
      icon: Icons.speed_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _PerformanceMetricItem(
                  icon: Icons.timer_outlined,
                  value: '${performance.avgDeliveryTimeMinutes}',
                  unit: 'min',
                  label: 'Avg Time',
                ),
              ),
              Expanded(
                child: _PerformanceMetricItem(
                  icon: Icons.route_outlined,
                  value: performance.totalDistanceKm.toStringAsFixed(1),
                  unit: 'km',
                  label: 'Distance',
                ),
              ),
              Expanded(
                child: _PerformanceMetricItem(
                  icon: Icons.check_circle_outline,
                  value: performance.onTimeDeliveryRate.toStringAsFixed(0),
                  unit: '%',
                  label: 'On-Time',
                  valueColor: performance.onTimeDeliveryRate >= 90
                      ? AppColors.success
                      : performance.onTimeDeliveryRate >= 75
                          ? AppColors.warning
                          : AppColors.error,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              if (performance.peakHour != null)
                Expanded(
                  child: _InfoChip(
                    icon: Icons.access_time,
                    label: 'Peak Hour',
                    value: performance.peakHour!,
                  ),
                ),
              if (performance.busiestDay != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoChip(
                    icon: Icons.calendar_today,
                    label: 'Busiest Day',
                    value: performance.busiestDay!,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PerformanceMetricItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;
  final Color? valueColor;

  const _PerformanceMetricItem({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textTertiary, size: 22),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
              TextSpan(
                text: unit,
                style: TextStyle(
                  fontSize: 13,
                  color: valueColor ?? AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Rating Card
class RatingCard extends StatelessWidget {
  final RatingSummary rating;

  const RatingCard({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Rating & Reviews',
      icon: Icons.star_outline,
      child: Column(
        children: [
          Row(
            children: [
              // Rating Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star,
                            color: AppColors.warning, size: 28),
                        const SizedBox(width: 4),
                        Text(
                          rating.averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${rating.totalReviews} reviews',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Rating Bars
              Expanded(
                child: Column(
                  children: [
                    _RatingBar(
                        stars: 5,
                        count: rating.fiveStar,
                        total: rating.totalReviews),
                    _RatingBar(
                        stars: 4,
                        count: rating.fourStar,
                        total: rating.totalReviews),
                    _RatingBar(
                        stars: 3,
                        count: rating.threeStar,
                        total: rating.totalReviews),
                    _RatingBar(
                        stars: 2,
                        count: rating.twoStar,
                        total: rating.totalReviews),
                    _RatingBar(
                        stars: 1,
                        count: rating.oneStar,
                        total: rating.totalReviews),
                  ],
                ),
              ),
            ],
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
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 10, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: const AlwaysStoppedAnimation(AppColors.warning),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 24,
            child: Text(
              '$count',
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textTertiary),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// Base Dashboard Card
class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  final Widget child;

  const _DashboardCard({
    required this.title,
    required this.icon,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
