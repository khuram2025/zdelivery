import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../data/models.dart';
import '../providers/customers_provider.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assignedCustomersProvider.notifier).loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(assignedCustomersProvider.notifier).setSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignedCustomersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(assignedCustomersProvider.notifier).loadCustomers(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(assignedCustomersProvider.notifier).loadCustomers(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            _SearchField(
              controller: _searchController,
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 12),
            _FilterBar(selected: state.filter),
            const SizedBox(height: 12),
            _SummaryStrip(
              summary: state.summary,
              customers: state.customers,
              count: state.customers.length,
            ),
            const SizedBox(height: 12),
            if (state.isLoading && state.customers.isEmpty)
              ...List.generate(4, (_) => const _CustomerCardShimmer())
            else if (state.error != null && state.customers.isEmpty)
              _EmptyCustomersState(
                icon: Icons.error_outline_rounded,
                title: 'Unable to Load Customers',
                subtitle: state.error!,
              )
            else if (state.customers.isEmpty)
              const _EmptyCustomersState(
                icon: Icons.people_outline_rounded,
                title: 'No Customers Assigned',
                subtitle:
                    'Customers appear here when orders are assigned to you',
              )
            else
              ...state.customers.map(
                (customer) => _CustomerCard(
                  customer: customer,
                  onTap: () => context.push(
                    '/customers/${customer.id}',
                    extra: customer,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search assigned customers',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Clear',
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  final CustomerPaymentFilter selected;

  const _FilterBar({required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SegmentedButton<CustomerPaymentFilter>(
      segments: const [
        ButtonSegment(
          value: CustomerPaymentFilter.all,
          icon: Icon(Icons.people_alt_outlined),
          label: Text('All'),
        ),
        ButtonSegment(
          value: CustomerPaymentFilter.credit,
          icon: Icon(Icons.credit_card_rounded),
          label: Text('Credit'),
        ),
        ButtonSegment(
          value: CustomerPaymentFilter.cod,
          icon: Icon(Icons.payments_outlined),
          label: Text('COD'),
        ),
      ],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (value) {
        ref.read(assignedCustomersProvider.notifier).setFilter(value.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final AssignedCustomersSummary? summary;
  final List<AssignedCustomer> customers;
  final int count;

  const _SummaryStrip({
    required this.summary,
    required this.customers,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final riskCount =
        customers.where((customer) => customer.hasCustomerRisk).length;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                icon: Icons.groups_2_outlined,
                label: 'Customers',
                value: '${summary?.totalCustomers ?? count}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryTile(
                icon: Icons.warning_amber_rounded,
                label: 'At risk',
                value: '$riskCount',
                valueColor:
                    riskCount > 0 ? AppColors.warning : AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                icon: Icons.receipt_long_outlined,
                label: 'Total',
                value: (summary?.totalAmount ?? 0).compactCurrency,
                valueColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Remaining',
                value: (summary?.totalRemaining ?? 0).compactCurrency,
                valueColor: AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: valueColor ?? AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
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
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final AssignedCustomer customer;
  final VoidCallback onTap;

  const _CustomerCard({
    required this.customer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = customer.wallet.remaining;
    final hasRemaining = remaining > 0;
    final totalAmount = customer.totalAmount == 0
        ? customer.wallet.total
        : customer.totalAmount;
    final riskColor = _riskColor(customer.riskLevel);
    final riskIcon = _riskIcon(customer.riskLevel);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: customer.hasCustomerRisk
              ? riskColor.withValues(alpha: 0.45)
              : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 15,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                customer.mobile.isEmpty
                                    ? 'No mobile'
                                    : customer.mobile,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _RiskPill(
                    label: customer.riskLabel,
                    icon: riskIcon,
                    color: riskColor,
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
              if (customer.hasCustomerRisk) ...[
                const SizedBox(height: 12),
                _RiskBanner(
                  icon: riskIcon,
                  color: riskColor,
                  message: customer.riskSummary,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _AmountTile(
                      label: 'Total',
                      value: totalAmount.compactCurrency,
                      icon: Icons.receipt_long_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AmountTile(
                      label: 'Paid',
                      value: customer.wallet.paid.compactCurrency,
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AmountTile(
                      label: hasRemaining ? 'Credit' : 'Due',
                      value: remaining.compactCurrency,
                      icon: hasRemaining
                          ? Icons.warning_amber_rounded
                          : Icons.verified_outlined,
                      color:
                          hasRemaining ? AppColors.warning : AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      customer.displayLocation,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.local_shipping_outlined,
                    label: '${customer.assignedOrders} orders',
                  ),
                  _InfoChip(
                    icon: Icons.account_balance_wallet_outlined,
                    label:
                        hasRemaining ? 'Collect/verify credit' : 'Wallet clear',
                    color: hasRemaining ? AppColors.warning : AppColors.success,
                  ),
                  if (customer.paymentMethod != null)
                    _InfoChip(
                      icon: customer.paymentMethod == 'CREDIT'
                          ? Icons.credit_card_rounded
                          : Icons.payments_outlined,
                      label: customer.paymentMethod!,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _riskColor(CustomerRiskLevel level) {
  switch (level) {
    case CustomerRiskLevel.clear:
      return AppColors.success;
    case CustomerRiskLevel.watch:
      return AppColors.primary;
    case CustomerRiskLevel.medium:
      return AppColors.warning;
    case CustomerRiskLevel.high:
      return AppColors.error;
    case CustomerRiskLevel.blocked:
      return AppColors.error;
  }
}

IconData _riskIcon(CustomerRiskLevel level) {
  switch (level) {
    case CustomerRiskLevel.clear:
      return Icons.verified_outlined;
    case CustomerRiskLevel.watch:
      return Icons.visibility_outlined;
    case CustomerRiskLevel.medium:
      return Icons.account_balance_wallet_outlined;
    case CustomerRiskLevel.high:
      return Icons.warning_amber_rounded;
    case CustomerRiskLevel.blocked:
      return Icons.block_rounded;
  }
}

class _RiskPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _RiskPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;

  const _RiskBanner({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _AmountTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
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
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCustomersState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyCustomersState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 72),
      child: Column(
        children: [
          Icon(icon, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCardShimmer extends StatelessWidget {
  const _CustomerCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
