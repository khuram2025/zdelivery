import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/static_google_map.dart';
import '../../data/models.dart';
import '../providers/customers_provider.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final int customerId;
  final AssignedCustomer? initialCustomer;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
    this.initialCustomer,
  });

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  late final CustomerDetailRequest _request;

  @override
  void initState() {
    super.initState();
    _request = CustomerDetailRequest(
      customerId: widget.customerId,
      initialCustomer: widget.initialCustomer,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerDetailProvider(_request).notifier).loadCustomerDetail();
    });
  }

  Future<void> _callCustomer(String mobile) async {
    if (mobile.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: mobile);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openDirections(AssignedCustomer customer) async {
    if (!customer.hasLocation) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${customer.latitude},${customer.longitude}&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendInvoiceToWhatsApp(
    AssignedCustomer customer,
    CustomerOrderHistoryItem order,
  ) async {
    final phone = _normalizeWhatsAppPhone(customer.mobile);
    if (phone.isEmpty) {
      _showMessage('Customer mobile number is missing');
      return;
    }

    final message = _buildInvoiceMessage(customer, order);
    final uri = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );
    final fallbackUri = Uri.parse(
      'whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(fallbackUri)) {
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
    } else {
      _showMessage('WhatsApp is not available on this device');
    }
  }

  String _normalizeWhatsAppPhone(String mobile) {
    final digits = mobile.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (digits.startsWith('0') && digits.length >= 10) {
      return '92${digits.substring(1)}';
    }
    return digits;
  }

  String _buildInvoiceMessage(
    AssignedCustomer customer,
    CustomerOrderHistoryItem order,
  ) {
    final orderNumber =
        order.orderNumber.isEmpty ? 'Order #${order.id}' : order.orderNumber;
    final remainingLine = order.remaining > 0
        ? 'Remaining: ${order.remaining.currency}'
        : 'Remaining: Rs 0';
    final paidLine = order.paid > 0 ? order.paid.currency : 'Rs 0';
    final paymentMethod =
        order.paymentMethod.isEmpty ? 'N/A' : order.paymentMethod;

    return [
      'Zayyrah Delivery Invoice',
      '',
      'Customer: ${customer.displayName}',
      'Invoice: $orderNumber',
      'Date: ${order.createdAt.formattedDateTime}',
      'Status: ${order.status.statusDisplayName}',
      'Payment: $paymentMethod',
      '',
      'Total: ${order.total.currency}',
      'Paid: $paidLine',
      remainingLine,
      '',
      'Thank you.',
    ].join('\n');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerDetailProvider(_request));
    final detail = state.detail;
    final customer = detail?.customer ?? widget.initialCustomer;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customer Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref
                .read(customerDetailProvider(_request).notifier)
                .loadCustomerDetail(),
          ),
        ],
      ),
      body: customer == null && state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : customer == null
              ? _DetailError(message: state.error ?? 'Customer not found')
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(customerDetailProvider(_request).notifier)
                      .loadCustomerDetail(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    children: [
                      if (state.error != null)
                        _InlineError(message: state.error!),
                      _CustomerHeader(
                        customer: customer,
                        onCall: () => _callCustomer(customer.mobile),
                        onDirections: () => _openDirections(customer),
                      ),
                      const SizedBox(height: 12),
                      _CustomerRiskPanel(customer: customer),
                      const SizedBox(height: 12),
                      _WalletPanel(wallet: customer.wallet),
                      const SizedBox(height: 12),
                      _LocationPanel(customer: customer),
                      const SizedBox(height: 12),
                      _OrderHistoryPanel(
                        customer: customer,
                        orders: detail?.orderHistory ?? const [],
                        isLoading: state.isLoading && detail == null,
                        onOrderTap: (order) => context.push(
                          '/orders/${order.id}',
                        ),
                        onSendInvoice: (order) =>
                            _sendInvoiceToWhatsApp(customer, order),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _CustomerHeader extends StatelessWidget {
  final AssignedCustomer customer;
  final VoidCallback onCall;
  final VoidCallback onDirections;

  const _CustomerHeader({
    required this.customer,
    required this.onCall,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.primary,
                  size: 28,
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
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.mobile.isEmpty ? 'No mobile' : customer.mobile,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _RiskPill(
                label: customer.riskLabel,
                icon: _riskIcon(customer.riskLevel),
                color: _riskColor(customer.riskLevel),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: customer.mobile.isEmpty ? null : onCall,
                  icon: const Icon(Icons.call_outlined),
                  label: const Text('Call'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: customer.hasLocation ? onDirections : null,
                  icon: const Icon(Icons.navigation_outlined),
                  label: const Text('Route'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerRiskPanel extends StatelessWidget {
  final AssignedCustomer customer;

  const _CustomerRiskPanel({required this.customer});

  @override
  Widget build(BuildContext context) {
    final color = _riskColor(customer.riskLevel);
    final icon = _riskIcon(customer.riskLevel);
    final wallet = customer.wallet;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  customer.riskLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (customer.paymentMethod != null)
                _RiskPill(
                  label: customer.paymentMethod!,
                  icon: customer.paymentMethod == 'CREDIT'
                      ? Icons.credit_card_rounded
                      : Icons.payments_outlined,
                  color: color,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            customer.riskSummary,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (wallet.hasCreditLimit) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: wallet.creditUsedPercent,
                minHeight: 8,
                color: color,
                backgroundColor: color.withValues(alpha: 0.14),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${wallet.remaining.currency} used',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${wallet.creditLimit.currency} limit',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WalletPanel extends StatelessWidget {
  final CustomerWallet wallet;

  const _WalletPanel({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final hasRemaining = wallet.remaining > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasRemaining
                    ? Icons.warning_amber_rounded
                    : Icons.verified_outlined,
                color: hasRemaining ? AppColors.warning : AppColors.success,
              ),
              const SizedBox(width: 8),
              Text(
                hasRemaining ? 'Wallet has remaining balance' : 'Wallet clear',
                style: TextStyle(
                  color: hasRemaining ? AppColors.warning : AppColors.success,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MoneyTile(
                  label: 'Total',
                  value: wallet.total.currency,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MoneyTile(
                  label: 'Paid',
                  value: wallet.paid.currency,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MoneyTile(
                  label: 'Remaining',
                  value: wallet.remaining.currency,
                  color: hasRemaining ? AppColors.warning : AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MoneyTile(
                  label: 'Credit Limit',
                  value: wallet.creditLimit.currency,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MoneyTile(
                  label: 'Available',
                  value: wallet.availableCredit.currency,
                ),
              ),
            ],
          ),
        ],
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
          Icon(icon, color: color, size: 13),
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

class _MoneyTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _MoneyTile({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color ?? AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
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
    );
  }
}

class _LocationPanel extends StatelessWidget {
  final AssignedCustomer customer;

  const _LocationPanel({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    customer.displayLocation,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 190,
            width: double.infinity,
            child: customer.hasLocation
                ? StaticGoogleMap(
                    markers: [
                      StaticMapMarker(
                        latitude: customer.latitude!,
                        longitude: customer.longitude!,
                        color: 'blue',
                        label: 'C',
                      ),
                    ],
                    centerLatitude: customer.latitude!,
                    centerLongitude: customer.longitude!,
                    zoom: 15,
                    size: '640x360',
                  )
                : const _NoMapLocation(),
          ),
        ],
      ),
    );
  }
}

class _NoMapLocation extends StatelessWidget {
  const _NoMapLocation();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off_outlined,
              color: AppColors.textTertiary,
              size: 34,
            ),
            SizedBox(height: 8),
            Text(
              'No GPS location saved',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderHistoryPanel extends StatelessWidget {
  final AssignedCustomer customer;
  final List<CustomerOrderHistoryItem> orders;
  final bool isLoading;
  final ValueChanged<CustomerOrderHistoryItem> onOrderTap;
  final ValueChanged<CustomerOrderHistoryItem> onSendInvoice;

  const _OrderHistoryPanel({
    required this.customer,
    required this.orders,
    required this.isLoading,
    required this.onOrderTap,
    required this.onSendInvoice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Order History',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${orders.length}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (orders.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: Text(
                'No order history returned for this customer',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            ...orders.map(
              (order) => _HistoryRow(
                order: order,
                customer: customer,
                onTap: () => onOrderTap(order),
                onSendInvoice: () => onSendInvoice(order),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final CustomerOrderHistoryItem order;
  final AssignedCustomer customer;
  final VoidCallback onTap;
  final VoidCallback onSendInvoice;

  const _HistoryRow({
    required this.order,
    required this.customer,
    required this.onTap,
    required this.onSendInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = order.remaining;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: order.status.statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                order.status.statusIcon,
                color: order.status.statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderNumber.isEmpty
                        ? 'Order #${order.id}'
                        : order.orderNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.status.statusDisplayName} • ${order.createdAt.formattedDateTime}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _HistoryChip(
                        icon: Icons.receipt_long_outlined,
                        label: order.total.compactCurrency,
                      ),
                      _HistoryChip(
                        icon: remaining > 0
                            ? Icons.account_balance_wallet_outlined
                            : Icons.check_circle_outline_rounded,
                        label: remaining > 0
                            ? '${remaining.compactCurrency} remaining'
                            : 'Paid',
                        color: remaining > 0
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                      if (order.paymentMethod.isNotEmpty)
                        _HistoryChip(
                          icon: order.paymentMethod == 'CREDIT'
                              ? Icons.credit_card_rounded
                              : Icons.payments_outlined,
                          label: order.paymentMethod,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                IconButton.filledTonal(
                  onPressed: customer.mobile.isEmpty ? null : onSendInvoice,
                  icon: const Icon(Icons.chat_outlined),
                  tooltip: 'Send invoice on WhatsApp',
                  style: IconButton.styleFrom(
                    foregroundColor: AppColors.success,
                    backgroundColor: AppColors.success.withValues(alpha: 0.1),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Invoice',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _HistoryChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: chipColor, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: chipColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  final String message;

  const _DetailError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.textTertiary,
              size: 60,
            ),
            const SizedBox(height: 14),
            const Text(
              'Customer unavailable',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
