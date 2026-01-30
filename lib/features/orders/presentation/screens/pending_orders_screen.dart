import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/order_card.dart';
import '../providers/orders_provider.dart';

class PendingOrdersScreen extends ConsumerStatefulWidget {
  const PendingOrdersScreen({super.key});

  @override
  ConsumerState<PendingOrdersScreen> createState() => _PendingOrdersScreenState();
}

class _PendingOrdersScreenState extends ConsumerState<PendingOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pendingOrdersProvider.notifier).loadPendingOrders();
    });
  }

  void _showRejectDialog(int orderId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RejectOrderSheet(orderId: orderId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingState = ref.watch(pendingOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pending Orders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: pendingState.isLoading
          ? ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: 3,
              itemBuilder: (context, index) => const OrderCardShimmer(),
            )
          : pendingState.orders.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Pending Orders',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'New orders will appear here when assigned to you',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(pendingOrdersProvider.notifier).loadPendingOrders();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: pendingState.orders.length,
                    itemBuilder: (context, index) {
                      final order = pendingState.orders[index];
                      return OrderCard(
                        order: order,
                        showActions: true,
                        onTap: () => context.push('/orders/${order.id}'),
                        onAccept: () async {
                          final notifier = ref.read(orderDetailProvider(order.id).notifier);
                          final success = await notifier.acceptOrder();
                          if (success) {
                            ref.read(pendingOrdersProvider.notifier).removeOrder(order.id);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Order accepted successfully'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          }
                        },
                        onReject: () => _showRejectDialog(order.id),
                      );
                    },
                  ),
                ),
    );
  }
}

class _RejectOrderSheet extends ConsumerStatefulWidget {
  final int orderId;

  const _RejectOrderSheet({required this.orderId});

  @override
  ConsumerState<_RejectOrderSheet> createState() => _RejectOrderSheetState();
}

class _RejectOrderSheetState extends ConsumerState<_RejectOrderSheet> {
  String? _selectedReason;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  final _reasons = [
    'Too far from current location',
    'Vehicle issue',
    'Personal emergency',
    'Already have too many orders',
    'Other',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _rejectOrder() async {
    if (_selectedReason == null) return;

    setState(() => _isLoading = true);

    final reason = _selectedReason == 'Other' ? _notesController.text : _selectedReason!;
    final notifier = ref.read(orderDetailProvider(widget.orderId).notifier);
    final success = await notifier.rejectOrder(reason);

    setState(() => _isLoading = false);

    if (success && mounted) {
      ref.read(pendingOrdersProvider.notifier).removeOrder(widget.orderId);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order rejected'),
          backgroundColor: AppColors.textSecondary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Reject Order',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please select a reason for rejecting this order',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ...(_reasons.map((reason) => RadioListTile<String>(
                    title: Text(reason),
                    value: reason,
                    groupValue: _selectedReason,
                    onChanged: (value) {
                      setState(() => _selectedReason = value);
                    },
                    contentPadding: EdgeInsets.zero,
                  ))),
              if (_selectedReason == 'Other') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Please provide more details...',
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedReason != null && !_isLoading
                          ? _rejectOrder
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text('Reject Order'),
                    ),
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
