import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models.dart';
import '../providers/earnings_provider.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(earningsProvider.notifier).loadEarnings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final earningsState = ref.watch(earningsProvider);
    final earnings = earningsState.earnings;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Earnings'),
        elevation: 0,
      ),
      body: earningsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : earningsState.error != null
              ? _ErrorState(
                  error: earningsState.error!,
                  onRetry: () => ref.read(earningsProvider.notifier).loadEarnings(),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(earningsProvider.notifier).loadEarnings(
                        period: earningsState.selectedPeriod,
                      ),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Period Filter
                        _PeriodSelector(
                          selectedPeriod: earningsState.selectedPeriod,
                          onChanged: (period) => ref.read(earningsProvider.notifier).changePeriod(period),
                        ),

                        // Main Earnings Card
                        _EarningsCard(earnings: earnings),

                        // Quick Stats Row
                        _QuickStats(earnings: earnings),

                        // Earnings Breakdown
                        _EarningsBreakdown(earnings: earnings),

                        // Payout Summary
                        _PayoutSummary(earnings: earnings),

                        // Recent Transactions
                        _TransactionsSection(transactions: earnings?.transactions ?? []),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
    );
  }
}

// Error State
class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 40, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// Period Selector
class _PeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final ValueChanged<String> onChanged;

  const _PeriodSelector({required this.selectedPeriod, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _PeriodChip(label: 'Today', value: 'today', selected: selectedPeriod, onTap: onChanged),
          const SizedBox(width: 8),
          _PeriodChip(label: 'This Week', value: 'week', selected: selectedPeriod, onTap: onChanged),
          const SizedBox(width: 8),
          _PeriodChip(label: 'This Month', value: 'month', selected: selectedPeriod, onTap: onChanged),
          const SizedBox(width: 8),
          _PeriodChip(label: 'All Time', value: 'all', selected: selectedPeriod, onTap: onChanged),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;

  const _PeriodChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// Main Earnings Card
class _EarningsCard extends StatelessWidget {
  final EarningsData? earnings;

  const _EarningsCard({this.earnings});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(50),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Total Earnings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Earnings',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(earnings?.summary.totalEarnings ?? 0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              // Deliveries Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${earnings?.deliveriesCount ?? 0}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Deliveries',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Divider
          Container(
            height: 1,
            color: Colors.white.withAlpha(30),
          ),
          const SizedBox(height: 12),
          // Bottom Stats
          Row(
            children: [
              Expanded(
                child: _CardStat(
                  icon: Icons.trending_up,
                  label: 'Avg/Delivery',
                  value: _formatCurrency(earnings?.averagePerDelivery ?? 0),
                ),
              ),
              Container(width: 1, height: 35, color: Colors.white.withAlpha(30)),
              Expanded(
                child: _CardStat(
                  icon: Icons.schedule,
                  label: 'Pending',
                  value: _formatCurrency(earnings?.summary.pendingPayout ?? 0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000) {
      return 'Rs ${NumberFormat('#,##0').format(amount)}';
    }
    return 'Rs ${amount.toStringAsFixed(0)}';
  }
}

class _CardStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CardStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white60, size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ],
    );
  }
}

// Quick Stats
class _QuickStats extends StatelessWidget {
  final EarningsData? earnings;

  const _QuickStats({this.earnings});

  @override
  Widget build(BuildContext context) {
    final commission = earnings?.summary.deliveryCommission ?? 0;
    final tips = earnings?.summary.tips ?? 0;
    final total = earnings?.summary.totalEarnings ?? 0;

    // Calculate percentages
    final commissionPct = total > 0 ? (commission / total * 100).toStringAsFixed(0) : '0';
    final tipsPct = total > 0 ? (tips / total * 100).toStringAsFixed(0) : '0';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: _QuickStatCard(
              icon: Icons.delivery_dining,
              label: 'Commission',
              value: _formatCurrency(commission),
              subtext: '$commissionPct% of total',
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickStatCard(
              icon: Icons.favorite,
              label: 'Tips',
              value: _formatCurrency(tips),
              subtext: '$tipsPct% of total',
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return 'Rs ${amount.toStringAsFixed(0)}';
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtext;
  final Color color;

  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtext,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text(subtext, style: TextStyle(fontSize: 10, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Earnings Breakdown
class _EarningsBreakdown extends StatelessWidget {
  final EarningsData? earnings;

  const _EarningsBreakdown({this.earnings});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: _BreakdownItem(
              icon: Icons.card_giftcard,
              label: 'Bonuses',
              amount: earnings?.summary.bonuses ?? 0,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _BreakdownItem(
              icon: Icons.remove_circle_outline,
              label: 'Deductions',
              amount: earnings?.summary.deductions ?? 0,
              color: AppColors.error,
              isNegative: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final Color color;
  final bool isNegative;

  const _BreakdownItem({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          Text(
            '${isNegative && amount > 0 ? '-' : ''}Rs ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isNegative && amount > 0 ? AppColors.error : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// Payout Summary
class _PayoutSummary extends StatelessWidget {
  final EarningsData? earnings;

  const _PayoutSummary({this.earnings});

  @override
  Widget build(BuildContext context) {
    final pending = earnings?.summary.pendingPayout ?? 0;
    final paid = earnings?.summary.paidAmount ?? 0;
    final total = pending + paid;
    final paidPercentage = total > 0 ? paid / total : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payout Status',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: pending > 0 ? AppColors.warning.withAlpha(25) : AppColors.success.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  pending > 0 ? 'Pending' : 'All Paid',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: pending > 0 ? AppColors.warning : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: paidPercentage,
              backgroundColor: AppColors.warning.withAlpha(50),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PayoutItem(
                  label: 'Pending',
                  amount: pending,
                  color: AppColors.warning,
                ),
              ),
              Container(width: 1, height: 30, color: AppColors.border),
              Expanded(
                child: _PayoutItem(
                  label: 'Paid',
                  amount: paid,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayoutItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _PayoutItem({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Rs ${amount.toStringAsFixed(0)}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

// Transactions Section
class _TransactionsSection extends StatelessWidget {
  final List<EarningTransaction> transactions;

  const _TransactionsSection({required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              if (transactions.length > 5)
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'See All',
                    style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),
        ),
        if (transactions.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 36, color: AppColors.textTertiary),
                  const SizedBox(height: 8),
                  const Text(
                    'No transactions yet',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: transactions.length.clamp(0, 10),
              separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) {
                return _TransactionItem(transaction: transactions[index]);
              },
            ),
          ),
      ],
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final EarningTransaction transaction;

  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isPositive = transaction.earningType != 'PENALTY';
    final dateFormat = DateFormat('dd MMM, hh:mm a');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (isPositive ? AppColors.success : AppColors.error).withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getIcon(transaction.earningType),
              color: isPositive ? AppColors.success : AppColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.typeDisplayName,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.assignmentNumber ?? dateFormat.format(transaction.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : '-'}Rs ${transaction.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isPositive ? AppColors.success : AppColors.error,
                ),
              ),
              if (transaction.isPaid)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Paid',
                    style: TextStyle(fontSize: 9, color: AppColors.success, fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'DELIVERY':
        return Icons.local_shipping_outlined;
      case 'TIP':
        return Icons.favorite_outline;
      case 'BONUS':
        return Icons.card_giftcard_outlined;
      case 'PENALTY':
        return Icons.warning_amber_outlined;
      case 'ADJUSTMENT':
        return Icons.tune;
      default:
        return Icons.attach_money;
    }
  }
}
