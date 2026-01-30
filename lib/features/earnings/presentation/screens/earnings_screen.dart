import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
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
      ),
      body: earningsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(earningsProvider.notifier).loadEarnings(
                      period: earningsState.selectedPeriod,
                    );
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Period Selector
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _PeriodChip(
                            label: 'Today',
                            isSelected: earningsState.selectedPeriod == 'today',
                            onTap: () => ref.read(earningsProvider.notifier).changePeriod('today'),
                          ),
                          const SizedBox(width: 8),
                          _PeriodChip(
                            label: 'Week',
                            isSelected: earningsState.selectedPeriod == 'week',
                            onTap: () => ref.read(earningsProvider.notifier).changePeriod('week'),
                          ),
                          const SizedBox(width: 8),
                          _PeriodChip(
                            label: 'Month',
                            isSelected: earningsState.selectedPeriod == 'month',
                            onTap: () => ref.read(earningsProvider.notifier).changePeriod('month'),
                          ),
                        ],
                      ),
                    ),

                    // Earnings Summary Card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Total Earnings',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            earnings?.summary.totalEarnings.currency ?? 'Rs 0',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _SummaryItem(
                                label: 'Deliveries',
                                value: '${earnings?.deliveriesCount ?? 0}',
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.white24,
                              ),
                              _SummaryItem(
                                label: 'Average',
                                value: earnings?.averagePerDelivery.currency ?? 'Rs 0',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Breakdown Cards
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _BreakdownCard(
                              icon: Icons.local_shipping_outlined,
                              label: 'Commission',
                              amount: earnings?.summary.deliveryCommission ?? 0,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _BreakdownCard(
                              icon: Icons.volunteer_activism_outlined,
                              label: 'Tips',
                              amount: earnings?.summary.tips ?? 0,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _BreakdownCard(
                              icon: Icons.card_giftcard_outlined,
                              label: 'Bonuses',
                              amount: earnings?.summary.bonuses ?? 0,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _BreakdownCard(
                              icon: Icons.remove_circle_outline,
                              label: 'Deductions',
                              amount: earnings?.summary.deductions ?? 0,
                              color: AppColors.error,
                              isNegative: true,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Payout Info
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payout Summary',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _PayoutRow(
                                label: 'Pending Payout',
                                amount: earnings?.summary.pendingPayout ?? 0,
                                color: AppColors.warning,
                              ),
                              const SizedBox(height: 12),
                              _PayoutRow(
                                label: 'Already Paid',
                                amount: earnings?.summary.paidAmount ?? 0,
                                color: AppColors.success,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Transactions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Transactions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                    ),

                    if (earnings?.transactions.isEmpty ?? true)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No transactions yet',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: earnings!.transactions.length.clamp(0, 10),
                        itemBuilder: (context, index) {
                          final transaction = earnings.transactions[index];
                          return _TransactionItem(transaction: transaction);
                        },
                      ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final Color color;
  final bool isNegative;

  const _BreakdownCard({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                if (isNegative && amount > 0)
                  const Text('-', style: TextStyle(color: AppColors.error)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              amount.currency,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isNegative && amount > 0 ? AppColors.error : AppColors.textPrimary,
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
    );
  }
}

class _PayoutRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _PayoutRow({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          amount.currency,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final dynamic transaction;

  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isPositive = transaction.earningType != 'PENALTY';

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (isPositive ? AppColors.success : AppColors.error).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPositive ? Icons.arrow_downward : Icons.arrow_upward,
          color: isPositive ? AppColors.success : AppColors.error,
          size: 20,
        ),
      ),
      title: Text(
        transaction.typeDisplayName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        transaction.description,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '${isPositive ? '+' : '-'}${transaction.amount.currency}',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isPositive ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }
}
