import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/static_google_map.dart';
import '../../data/models.dart';

class OrderMapStatusStyle {
  final Color color;
  final double markerHue;
  final IconData icon;
  final String label;

  const OrderMapStatusStyle({
    required this.color,
    this.markerHue = 0,
    required this.icon,
    required this.label,
  });
}

OrderMapStatusStyle orderMapStatusStyle(String status) {
  switch (status.toUpperCase()) {
    case 'PENDING':
      return const OrderMapStatusStyle(
        color: AppColors.warning,
        icon: Icons.pending_actions_outlined,
        label: 'Pending',
      );
    case 'ASSIGNED':
      return const OrderMapStatusStyle(
        color: AppColors.warning,
        icon: Icons.schedule_rounded,
        label: 'Assigned',
      );
    case 'ACCEPTED':
      return const OrderMapStatusStyle(
        color: AppColors.info,
        icon: Icons.task_alt_rounded,
        label: 'Accepted',
      );
    case 'PICKED_UP':
      return const OrderMapStatusStyle(
        color: AppColors.primary,
        icon: Icons.inventory_2_outlined,
        label: 'Picked up',
      );
    case 'IN_TRANSIT':
    case 'OUT_FOR_DELIVERY':
      return const OrderMapStatusStyle(
        color: AppColors.primary,
        icon: Icons.local_shipping_outlined,
        label: 'In transit',
      );
    case 'ARRIVED':
      return const OrderMapStatusStyle(
        color: Color(0xFF8B5CF6),
        icon: Icons.location_on_outlined,
        label: 'Arrived',
      );
    case 'DELIVERED':
      return const OrderMapStatusStyle(
        color: AppColors.success,
        icon: Icons.check_circle_outline,
        label: 'Delivered',
      );
    case 'FAILED':
    case 'CANCELLED':
    case 'RETURNED':
      return const OrderMapStatusStyle(
        color: AppColors.error,
        icon: Icons.error_outline,
        label: 'Failed',
      );
    default:
      return const OrderMapStatusStyle(
        color: AppColors.textSecondary,
        icon: Icons.radio_button_unchecked,
        label: 'Other',
      );
  }
}

String orderMapStaticMarkerColor(String status) {
  switch (status.toUpperCase()) {
    case 'PENDING':
    case 'ASSIGNED':
      return 'orange';
    case 'ACCEPTED':
    case 'PICKED_UP':
    case 'IN_TRANSIT':
    case 'OUT_FOR_DELIVERY':
    case 'ARRIVED':
      return 'blue';
    case 'DELIVERED':
      return 'green';
    case 'FAILED':
    case 'CANCELLED':
    case 'RETURNED':
      return 'red';
    default:
      return 'purple';
  }
}

class OrdersMapView extends StatefulWidget {
  final List<DeliveryOrder> orders;
  final Function(DeliveryOrder) onOrderTapped;

  const OrdersMapView({
    super.key,
    required this.orders,
    required this.onOrderTapped,
  });

  @override
  State<OrdersMapView> createState() => _OrdersMapViewState();
}

class _OrdersMapViewState extends State<OrdersMapView> {
  List<DeliveryOrder> _ordersOnMap = [];

  @override
  void initState() {
    super.initState();
    _buildOrdersOnMap();
  }

  @override
  void didUpdateWidget(OrdersMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orders != widget.orders) {
      _buildOrdersOnMap();
    }
  }

  void _buildOrdersOnMap() {
    final ordersWithCoords =
        widget.orders.where((o) => o.hasDeliveryCoordinates).toList();

    if (ordersWithCoords.isEmpty) {
      setState(() => _ordersOnMap = []);
      return;
    }

    // Find the most common region (cluster orders by proximity)
    // Use the first order as reference point, filter orders within ~500km
    final referenceOrder = ordersWithCoords.first;
    final refLat = referenceOrder.deliveryLatitude!;
    final refLng = referenceOrder.deliveryLongitude!;

    // Filter orders within reasonable distance (~5 degrees ≈ 500km)
    final nearbyOrders = ordersWithCoords.where((order) {
      final latDiff = (order.deliveryLatitude! - refLat).abs();
      final lngDiff = (order.deliveryLongitude! - refLng).abs();
      return latDiff < 5 && lngDiff < 5;
    }).toList();

    // Use nearby orders if most orders are in one region, otherwise show all
    final ordersToShow = nearbyOrders.length >= ordersWithCoords.length / 2
        ? nearbyOrders
        : ordersWithCoords;

    setState(() => _ordersOnMap = ordersToShow);
  }

  @override
  Widget build(BuildContext context) {
    final ordersWithCoordinates =
        widget.orders.where((o) => o.hasDeliveryCoordinates).toList();

    if (ordersWithCoordinates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'No orders with location data',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Orders will appear on the map when\nthey have GPS coordinates',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    final markers = _ordersOnMap.map(_staticMarkerForOrder).toList();

    return Stack(
      children: [
        StaticGoogleMap(
          markers: markers,
          centerLatitude: markers.length == 1 ? markers.first.latitude : null,
          centerLongitude: markers.length == 1 ? markers.first.longitude : null,
          zoom: 14,
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: _MapLegend(
            orders: ordersWithCoordinates,
            markerCount: _ordersOnMap.length,
          ),
        ),
        Positioned(
          right: 16,
          top: 120,
          child: _StaticMapBadge(
            icon: Icons.map_rounded,
            label: 'Preview',
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: _MapOrderStrip(
            orders: _ordersOnMap,
            onOrderTapped: widget.onOrderTapped,
          ),
        ),
      ],
    );
  }

  StaticMapMarker _staticMarkerForOrder(DeliveryOrder order) {
    final style = orderMapStatusStyle(order.status);
    return StaticMapMarker(
      latitude: order.deliveryLatitude!,
      longitude: order.deliveryLongitude!,
      color: orderMapStaticMarkerColor(order.status),
      label: style.label.substring(0, 1).toUpperCase(),
    );
  }
}

class _StaticMapBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StaticMapBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapOrderStrip extends StatelessWidget {
  final List<DeliveryOrder> orders;
  final Function(DeliveryOrder) onOrderTapped;

  const _MapOrderStrip({
    required this.orders,
    required this.onOrderTapped,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final order = orders[index];
          return _MapOrderStripCard(
            order: order,
            onTap: () => onOrderTapped(order),
          );
        },
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  final List<DeliveryOrder> orders;
  final int markerCount;

  const _MapLegend({
    required this.orders,
    required this.markerCount,
  });

  @override
  Widget build(BuildContext context) {
    final statusCounts = <String, _LegendStatus>{};
    for (final order in orders) {
      final style = orderMapStatusStyle(order.status);
      final current = statusCounts[style.label];
      statusCounts[style.label] = _LegendStatus(
        style: style,
        count: (current?.count ?? 0) + 1,
      );
    }

    final entries = statusCounts.values.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$markerCount orders on map',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: entries.map((entry) {
              return _MapStatusChip(
                color: entry.style.color,
                icon: entry.style.icon,
                label: '${entry.style.label} ${entry.count}',
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _LegendStatus {
  final OrderMapStatusStyle style;
  final int count;

  const _LegendStatus({
    required this.style,
    required this.count,
  });

  String get key => style.label;
}

class _MapStatusChip extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _MapStatusChip({
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
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

class _MapOrderStripCard extends StatelessWidget {
  final DeliveryOrder order;
  final VoidCallback onTap;

  const _MapOrderStripCard({
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = orderMapStatusStyle(order.status);

    return Container(
      width: 276,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: style.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(style.icon, color: style.color, size: 18),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      order.customerName ?? 'Customer',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded,
                      color: AppColors.textTertiary),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.receipt_long_outlined,
                      size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      order.orderNumber ?? order.assignmentNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (order.orderTotal != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Rs ${order.orderTotal!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                order.displayDeliveryAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: order.hasDeliveryAddress
                      ? AppColors.textSecondary
                      : AppColors.error,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
