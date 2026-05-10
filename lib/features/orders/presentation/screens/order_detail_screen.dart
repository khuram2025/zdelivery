import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/custom_button.dart';
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
  Timer? _autoBackTimer;
  bool _autoBackScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderDetailProvider(widget.orderId).notifier).loadOrderDetail();
    });
  }

  @override
  void dispose() {
    _autoBackTimer?.cancel();
    super.dispose();
  }

  void _scheduleAutoBack() {
    if (_autoBackScheduled) return;
    _autoBackScheduled = true;
    _autoBackTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        context.pop();
      }
    });
  }

  void _callCustomer(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openNavigation(
      {String? url,
      double? latitude,
      double? longitude,
      String? address}) async {
    // Build the destination string
    String? destination;
    if (latitude != null && longitude != null) {
      destination = '$latitude,$longitude';
    } else if (address != null && address.isNotEmpty) {
      destination = address;
    }

    if (url == null && destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No navigation address available')),
      );
      return;
    }

    // Try multiple URL schemes in order of preference
    final urlsToTry = <Uri>[];

    if (url != null && url.isNotEmpty) {
      urlsToTry.add(Uri.parse(url));
    }

    if (destination != null) {
      final encodedDest = Uri.encodeComponent(destination);
      // Google Maps URL (works on most devices)
      urlsToTry.add(Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$encodedDest'));
      // Geo URI scheme (Android native)
      urlsToTry.add(Uri.parse('geo:0,0?q=$encodedDest'));
      // Google Maps with directions
      urlsToTry.add(Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$encodedDest&travelmode=driving'));
    }

    for (final uri in urlsToTry) {
      try {
        final launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (launched) {
          return; // Successfully launched
        }
      } catch (e) {
        // Try next URL
        continue;
      }
    }

    // If all attempts failed
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not open maps. Please install Google Maps.')),
      );
    }
  }

  void _showUpdateLocationDialog(DeliveryOrderDetail order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UpdateLocationSheet(
        orderId: order.id,
        currentAddress: order.deliveryLocation?.fullAddress,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderDetailProvider(widget.orderId));
    final order = state.order;
    final showActionButton =
        order != null && !_isCompletedOrFailed(order.status);

    // Auto-navigate back when order is completed or failed
    if (order != null && _isCompletedOrFailed(order.status)) {
      _scheduleAutoBack();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(order?.order?.orderNumber ?? 'Order Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      bottomNavigationBar: showActionButton
          ? _ActionBottomSheet(
              order: order,
              isLoading: state.isActionLoading,
            )
          : null,
      body: Stack(
        children: [
          _buildBody(state, order),
          // Auto-back countdown banner
          if (order != null && _isCompletedOrFailed(order.status))
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                color: order.status.toLowerCase().contains('delivered')
                    ? AppColors.success
                    : AppColors.error,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Returning to orders in 5 seconds...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Text(
                        'Go Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isCompletedOrFailed(String status) {
    return [
      'delivered',
      'DELIVERED',
      'failed',
      'FAILED',
      'cancelled',
      'CANCELLED'
    ].contains(status);
  }

  Widget _buildBody(OrderDetailState state, DeliveryOrderDetail? order) {
    // Show loading
    if (state.isLoading && order == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error
    if (state.error != null && order == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                state.error!,
                style: const TextStyle(
                    fontSize: 16, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(orderDetailProvider(widget.orderId).notifier)
                      .loadOrderDetail();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Show content
    if (order == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(orderDetailProvider(widget.orderId).notifier)
            .loadOrderDetail();
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
              onNavigate: () => _openNavigation(
                url: order.route?.navigationUrl,
                latitude: order.deliveryLocation?.latitude,
                longitude: order.deliveryLocation?.longitude,
                address: order.deliveryLocation?.fullAddress,
              ),
              onUpdateLocation: () => _showUpdateLocationDialog(order),
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
        color: order.status.statusColor.withValues(alpha: 0.1),
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
              _InfoRow('Est. Duration',
                  '${order.route!.estimatedDurationMinutes} mins'),
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
  final VoidCallback onUpdateLocation;

  const _LocationsCard({
    required this.order,
    required this.onCallCustomer,
    required this.onNavigate,
    required this.onUpdateLocation,
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
                        color: AppColors.info.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.store,
                          color: AppColors.info, size: 20),
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
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on,
                      color: AppColors.success, size: 20),
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
                      if (order.hasDeliveryCoordinates)
                        Text(
                          order.deliveryLocation?.displayAddress ?? '-',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        )
                      else
                        const Text(
                          'No location',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.error,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (order.hasDeliveryCoordinates) ...[
              // Action Buttons - shown when location exists
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
              const SizedBox(height: 12),
              // Update Location Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onUpdateLocation,
                  icon: const Icon(Icons.my_location, size: 18),
                  label: const Text('Update Customer Location'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else ...[
              // Add Location Button - shown when no GPS location
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onUpdateLocation,
                  icon: const Icon(Icons.add_location_alt, size: 18),
                  label: const Text('Add Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
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
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
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

  // Get the correct COD amount (total order amount including delivery)
  double get _amountToCollect {
    if (order.codAmount > 0) {
      return order.codAmount;
    }
    return order.order?.totalAmount ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final amount = _amountToCollect;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.payments_outlined, color: AppColors.success),
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
                    'Collect ${amount.currency}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              amount.currency,
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

    // Check if order is ready for completion (after pickup)
    final isReadyForCompletion = order.status == DeliveryStatus.pickedUp ||
        order.status == DeliveryStatus.inTransit ||
        order.status == DeliveryStatus.outForDelivery ||
        order.status == DeliveryStatus.arrived;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isReadyForCompletion) ...[
              // Simplified flow: After pickup, show Complete/Fail options directly
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
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: isLoading
                    ? null
                    : () => _handleAction(context, ref, order.status),
                child: CustomButton(
                  text: actionInfo['text'],
                  onPressed: () => _handleAction(context, ref, order.status),
                  isLoading: isLoading,
                  icon: actionInfo['icon'],
                  backgroundColor: actionInfo['color'],
                  width: double.infinity,
                ),
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
          'text': 'Start Delivery',
          'icon': Icons.local_shipping_outlined,
          'color': AppColors.primary,
        };
      case DeliveryStatus.accepted:
        return {
          'text': 'Start Delivery',
          'icon': Icons.local_shipping_outlined,
          'color': AppColors.primary,
        };
      // After pickup, go directly to Complete Delivery (simplified flow)
      case DeliveryStatus.pickedUp:
      case DeliveryStatus.inTransit:
      case DeliveryStatus.outForDelivery:
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

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, String status) async {
    final notifier = ref.read(orderDetailProvider(order.id).notifier);
    bool success = false;

    switch (status) {
      case DeliveryStatus.assigned:
        success = await notifier.startTransit();
        break;
      case DeliveryStatus.accepted:
        success = await notifier.startTransit();
        break;
      case DeliveryStatus.pickedUp:
        success = await notifier.startTransit();
        break;
      case DeliveryStatus.inTransit:
        success = await notifier.markArrived();
        break;
    }

    if (context.mounted && !success) {
      // Show error only on failure
      final state = ref.read(orderDetailProvider(order.id));
      final errorMessage =
          state.actionError ?? 'Action failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
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
  ConsumerState<_CompleteDeliverySheet> createState() =>
      _CompleteDeliverySheetState();
}

class _CompleteDeliverySheetState
    extends ConsumerState<_CompleteDeliverySheet> {
  final _recipientController = TextEditingController();
  final _notesController = TextEditingController();
  final _codController = TextEditingController();
  File? _deliveryPhoto;
  bool _isLoading = false;

  // Get the correct COD amount (total order amount including delivery)
  double get _codAmountToCollect {
    // Use codAmount if it's set, otherwise use order total
    if (widget.order.codAmount > 0) {
      return widget.order.codAmount;
    }
    return widget.order.order?.totalAmount ?? 0;
  }

  @override
  void initState() {
    super.initState();
    if (widget.order.isCod) {
      _codController.text = _codAmountToCollect.toStringAsFixed(0);
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
      final expectedAmount = _codAmountToCollect;
      if (codCollected == null || codCollected < expectedAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Collected amount must be at least ${expectedAmount.currency}'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
    }

    final notifier = ref.read(orderDetailProvider(widget.order.id).notifier);
    final success = await notifier.completeDelivery(
      recipientName: _recipientController.text.isNotEmpty
          ? _recipientController.text
          : null,
      deliveryNotes:
          _notesController.text.isNotEmpty ? _notesController.text : null,
      codCollected: codCollected,
      deliveryPhoto: _deliveryPhoto,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context);
      if (!success) {
        final state = ref.read(orderDetailProvider(widget.order.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.actionError ?? 'Failed to complete delivery'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
              const SizedBox(height: 16),
              // Payment Method Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.order.isCod
                      ? AppColors.warning.withValues(alpha: 0.1)
                      : AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.order.isCod
                        ? AppColors.warning.withValues(alpha: 0.3)
                        : AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.order.isCod
                          ? Icons.payments_outlined
                          : Icons.credit_card,
                      color: widget.order.isCod
                          ? AppColors.warning
                          : AppColors.success,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment: ${widget.order.order?.paymentMethod ?? 'N/A'}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: widget.order.isCod
                                  ? AppColors.warning
                                  : AppColors.success,
                            ),
                          ),
                          Text(
                            widget.order.isCod
                                ? 'Collect ${_codAmountToCollect.currency} from customer'
                                : 'No cash collection needed',
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
              const SizedBox(height: 20),
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
                            Icon(Icons.camera_alt_outlined,
                                size: 32, color: AppColors.textTertiary),
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
                  readOnly: true, // Auto-filled, no need to edit
                  decoration: InputDecoration(
                    labelText: 'COD Amount to Collect',
                    prefixText: 'Rs ',
                    suffixIcon: const Icon(Icons.lock_outline, size: 18),
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
      failureNotes:
          _notesController.text.isNotEmpty ? _notesController.text : null,
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
              ...FailureReason.displayNames.entries
                  .map((entry) => RadioListTile<String>(
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

class _UpdateLocationSheet extends ConsumerStatefulWidget {
  final int orderId;
  final String? currentAddress;

  const _UpdateLocationSheet({
    required this.orderId,
    this.currentAddress,
  });

  @override
  ConsumerState<_UpdateLocationSheet> createState() =>
      _UpdateLocationSheetState();
}

class _UpdateLocationSheetState extends ConsumerState<_UpdateLocationSheet> {
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _isUpdating = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    // Auto-fetch location immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are disabled. Please enable GPS.';
          _isLoadingLocation = false;
        });
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permission denied';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError =
              'Location permissions are permanently denied. Please enable in settings.';
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Failed to get location: ${e.toString()}';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _updateLocation() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please get your current location first')),
      );
      return;
    }

    setState(() => _isUpdating = true);

    final notifier = ref.read(orderDetailProvider(widget.orderId).notifier);
    final success = await notifier.updateCustomerLocation(
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      address:
          _addressController.text.isNotEmpty ? _addressController.text : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    setState(() => _isUpdating = false);

    if (mounted) {
      Navigator.pop(context); // Always close the sheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Customer location updated successfully!'
              : (ref.read(orderDetailProvider(widget.orderId)).actionError ??
                  'Failed to update location')),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
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
                'Update Customer Location',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use your current GPS location to update the delivery address',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              // Map Preview / Location Status
              if (_isLoadingLocation)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text(
                        'Getting your location...',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_currentPosition != null)
                Column(
                  children: [
                    // Google Maps Preview with pin overlay
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              zoom: 17,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId('current_location'),
                                position: LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                ),
                                infoWindow: const InfoWindow(
                                    title: 'Customer Location'),
                              ),
                            },
                            myLocationEnabled: false,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                            scrollGesturesEnabled: false,
                            zoomGesturesEnabled: false,
                            rotateGesturesEnabled: false,
                            tiltGesturesEnabled: false,
                          ),
                          // Center pin overlay (always visible on top of map)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 36),
                              child: Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 48,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Shadow dot under pin
                          Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 12),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          // Location badge overlay
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle,
                                      color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Location Found',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Refresh button overlay
                          Positioned(
                            top: 10,
                            right: 10,
                            child: GestureDetector(
                              onTap: _getCurrentLocation,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.refresh,
                                    size: 18, color: AppColors.primary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Coordinates display
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.gps_fixed,
                              color: AppColors.primary, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                // Error or initial state
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _locationError != null
                            ? Icons.location_off
                            : Icons.location_searching,
                        size: 40,
                        color: _locationError != null
                            ? AppColors.error
                            : AppColors.textTertiary,
                      ),
                      const SizedBox(height: 12),
                      if (_locationError != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            _locationError!,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      OutlinedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.my_location, size: 18),
                        label: const Text('Get Current Location'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_currentPosition != null) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address Description (Optional)',
                    hintText: 'e.g., Near City Park, Gate 2',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Any additional notes...',
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
                    flex: 2,
                    child: CustomButton(
                      text: 'Update Location',
                      onPressed:
                          _currentPosition != null ? _updateLocation : null,
                      isLoading: _isUpdating,
                      icon: Icons.save,
                      backgroundColor: AppColors.primary,
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
