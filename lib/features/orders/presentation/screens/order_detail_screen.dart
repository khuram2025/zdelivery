import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/models.dart';
import '../providers/orders_provider.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderDetailProvider(widget.orderId).notifier).loadOrderDetail();
    });
  }

  void _callCustomer(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openNavigation(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderDetailProvider(widget.orderId));
    final order = state.order;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(order?.order?.orderNumber ?? 'Order Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: LoadingOverlay(
        isLoading: state.isLoading,
        message: 'Loading...',
        child: order == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  await ref.read(orderDetailProvider(widget.orderId).notifier).loadOrderDetail();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Status Header
                      _StatusHeader(order: order),

                      // Order Info Card
                      _OrderInfoCard(order: order),

                      // Customer & Locations
                      _LocationsCard(
                        order: order,
                        onCallCustomer: () => _callCustomer(order.customer?.phone),
                        onNavigate: () => _openNavigation(order.route?.navigationUrl),
                      ),

                      // Order Items
                      if (order.order != null) _OrderItemsCard(orderInfo: order.order!),

                      // COD Info
                      if (order.isCod) _CodCard(order: order),

                      // Timeline
                      _TimelineCard(order: order),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
      ),
      bottomSheet: order != null
          ? _ActionBottomSheet(
              order: order,
              isLoading: state.isActionLoading,
            )
          : null,
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final DeliveryOrderDetail order;

  const _StatusHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: order.status.statusColor.withOpacity(0.1),
      ),
      child: Column(
        children: [
          Icon(
            order.status.statusIcon,
            size: 48,
            color: order.status.statusColor,
          ),
          const SizedBox(height: 12),
          StatusBadge(status: order.status),
          const SizedBox(height: 8),
          Text(
            order.assignmentNumber,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderInfoCard extends StatelessWidget {
  final DeliveryOrderDetail order;

  const _OrderInfoCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (order.priority >= 2)
                  PriorityBadge(priority: order.priority),
              ],
            ),
            const Divider(height: 24),
            _InfoRow('Total Amount', order.order?.totalAmount.currency ?? '-'),
            _InfoRow('Payment', order.order?.paymentMethod ?? '-'),
            _InfoRow('Distance', '${order.distanceKm.toStringAsFixed(1)} km'),
            _InfoRow('Commission', order.agentCommission.currency),
            if (order.route != null)
              _InfoRow('Est. Duration', '${order.route!.estimatedDurationMinutes} mins'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationsCard extends StatelessWidget {
  final DeliveryOrderDetail order;
  final VoidCallback onCallCustomer;
  final VoidCallback onNavigate;

  const _LocationsCard({
    required this.order,
    required this.onCallCustomer,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Route',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // Pickup Location
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.store, color: AppColors.info, size: 20),
                    ),
                    Container(
                      width: 2,
                      height: 40,
                      color: AppColors.border,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pickup',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        order.pickupLocation?.name ?? 'Store',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        order.pickupLocation?.address ?? '-',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Delivery Location
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on, color: AppColors.success, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        order.customer?.name ?? 'Customer',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        order.deliveryLocation?.fullAddress ?? '-',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCallCustomer,
                    icon: const Icon(Icons.phone_outlined, size: 18),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onNavigate,
                    icon: const Icon(Icons.navigation_outlined, size: 18),
                    label: const Text('Navigate'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
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

class _OrderItemsCard extends StatelessWidget {
  final OrderInfo orderInfo;

  const _OrderItemsCard({required this.orderInfo});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: ExpansionTile(
        title: const Text(
          'Order Items',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '${orderInfo.items.length} item(s)',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        children: [
          ...orderInfo.items.map((item) => ListTile(
                title: Text(
                  item.productName,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  'Qty: ${item.quantity} x ${item.unitPrice.currency}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: Text(
                  item.lineTotal.currency,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              )),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _InfoRow('Subtotal', orderInfo.subtotal.currency),
                _InfoRow('Tax', orderInfo.taxTotal.currency),
                _InfoRow('Shipping', orderInfo.shippingTotal.currency),
                const Divider(height: 16),
                _InfoRow('Total', orderInfo.totalAmount.currency),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CodCard extends StatelessWidget {
  final DeliveryOrderDetail order;

  const _CodCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.success.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.payments_outlined, color: AppColors.success),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cash on Delivery',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Collect ${order.codAmount.currency}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              order.codAmount.currency,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final DeliveryOrderDetail order;

  const _TimelineCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: ExpansionTile(
        title: const Text(
          'Timeline',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: order.statusHistory.reversed.map((history) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: history.toStatus.statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          history.toStatus.statusDisplayName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        history.changedAt.formattedTime,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBottomSheet extends ConsumerWidget {
  final DeliveryOrderDetail order;
  final bool isLoading;

  const _ActionBottomSheet({
    required this.order,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionInfo = _getActionInfo(order.status);
    if (actionInfo == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (order.status == DeliveryStatus.arrived) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () => _showFailureDialog(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Mark Failed'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: 'Complete Delivery',
                      onPressed: () => _showCompleteDialog(context, ref),
                      isLoading: isLoading,
                      icon: Icons.check_circle_outline,
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ],
              ),
            ] else
              CustomButton(
                text: actionInfo['text'],
                onPressed: () => _handleAction(context, ref, order.status),
                isLoading: isLoading,
                icon: actionInfo['icon'],
                backgroundColor: actionInfo['color'],
                width: double.infinity,
              ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic>? _getActionInfo(String status) {
    switch (status) {
      case DeliveryStatus.assigned:
        return {
          'text': 'Accept Order',
          'icon': Icons.check_circle_outline,
          'color': AppColors.success,
        };
      case DeliveryStatus.accepted:
        return {
          'text': 'Mark as Picked Up',
          'icon': Icons.inventory_2_outlined,
          'color': AppColors.primary,
        };
      case DeliveryStatus.pickedUp:
        return {
          'text': 'Start Delivery',
          'icon': Icons.local_shipping_outlined,
          'color': AppColors.primary,
        };
      case DeliveryStatus.inTransit:
        return {
          'text': 'Mark as Arrived',
          'icon': Icons.location_on_outlined,
          'color': AppColors.secondary,
        };
      case DeliveryStatus.arrived:
        return {
          'text': 'Complete Delivery',
          'icon': Icons.task_alt,
          'color': AppColors.success,
        };
      default:
        return null;
    }
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref, String status) async {
    final notifier = ref.read(orderDetailProvider(order.id).notifier);
    bool success = false;

    switch (status) {
      case DeliveryStatus.assigned:
        success = await notifier.acceptOrder();
        break;
      case DeliveryStatus.accepted:
        success = await notifier.pickupOrder();
        break;
      case DeliveryStatus.pickedUp:
        success = await notifier.startTransit();
        break;
      case DeliveryStatus.inTransit:
        success = await notifier.markArrived();
        break;
    }

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showCompleteDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CompleteDeliverySheet(order: order),
    );
  }

  void _showFailureDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FailDeliverySheet(orderId: order.id),
    );
  }
}

class _CompleteDeliverySheet extends ConsumerStatefulWidget {
  final DeliveryOrderDetail order;

  const _CompleteDeliverySheet({required this.order});

  @override
  ConsumerState<_CompleteDeliverySheet> createState() => _CompleteDeliverySheetState();
}

class _CompleteDeliverySheetState extends ConsumerState<_CompleteDeliverySheet> {
  final _recipientController = TextEditingController();
  final _notesController = TextEditingController();
  final _codController = TextEditingController();
  File? _deliveryPhoto;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.order.isCod) {
      _codController.text = widget.order.codAmount.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _notesController.dispose();
    _codController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _deliveryPhoto = File(image.path));
    }
  }

  Future<void> _completeDelivery() async {
    setState(() => _isLoading = true);

    double? codCollected;
    if (widget.order.isCod) {
      codCollected = double.tryParse(_codController.text);
      if (codCollected == null || codCollected != widget.order.codAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please collect exact amount: ${widget.order.codAmount.currency}'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
    }

    final notifier = ref.read(orderDetailProvider(widget.order.id).notifier);
    final success = await notifier.completeDelivery(
      recipientName: _recipientController.text.isNotEmpty ? _recipientController.text : null,
      deliveryNotes: _notesController.text.isNotEmpty ? _notesController.text : null,
      codCollected: codCollected,
      deliveryPhoto: _deliveryPhoto,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery completed successfully!'),
          backgroundColor: AppColors.success,
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
                'Complete Delivery',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              // Photo
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: _deliveryPhoto != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_deliveryPhoto!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined, size: 32, color: AppColors.textTertiary),
                            SizedBox(height: 8),
                            Text(
                              'Take Delivery Photo',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _recipientController,
                decoration: const InputDecoration(
                  labelText: 'Recipient Name',
                  hintText: 'Who received the package?',
                ),
              ),
              const SizedBox(height: 16),
              if (widget.order.isCod) ...[
                TextField(
                  controller: _codController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'COD Amount Collected',
                    hintText: 'Enter amount',
                    prefixText: 'Rs ',
                    suffixText: 'Expected: ${widget.order.codAmount.currency}',
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Delivery Notes (Optional)',
                  hintText: 'Any additional notes...',
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Complete Delivery',
                onPressed: _completeDelivery,
                isLoading: _isLoading,
                icon: Icons.check_circle_outline,
                backgroundColor: AppColors.success,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FailDeliverySheet extends ConsumerStatefulWidget {
  final int orderId;

  const _FailDeliverySheet({required this.orderId});

  @override
  ConsumerState<_FailDeliverySheet> createState() => _FailDeliverySheetState();
}

class _FailDeliverySheetState extends ConsumerState<_FailDeliverySheet> {
  String? _selectedReason;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _failDelivery() async {
    if (_selectedReason == null) return;

    setState(() => _isLoading = true);

    final notifier = ref.read(orderDetailProvider(widget.orderId).notifier);
    final success = await notifier.failDelivery(
      failureReason: _selectedReason!,
      failureNotes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery marked as failed'),
          backgroundColor: AppColors.warning,
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
                'Mark as Failed',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please select the reason for failed delivery',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ...FailureReason.displayNames.entries.map((entry) => RadioListTile<String>(
                    title: Text(entry.value),
                    value: entry.key,
                    groupValue: _selectedReason,
                    onChanged: (value) {
                      setState(() => _selectedReason = value);
                    },
                    contentPadding: EdgeInsets.zero,
                  )),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Additional notes (optional)...',
                ),
              ),
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
                    child: CustomButton(
                      text: 'Mark Failed',
                      onPressed: _selectedReason != null ? _failDelivery : null,
                      isLoading: _isLoading,
                      backgroundColor: AppColors.error,
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
