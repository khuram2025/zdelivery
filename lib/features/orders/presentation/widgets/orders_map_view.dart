import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models.dart';

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
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {};
  DeliveryOrder? _selectedOrder;

  // Default camera position (will be updated based on orders)
  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(31.4504, 73.1350), // Default to Jhang, Pakistan
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _buildMarkers();
  }

  @override
  void didUpdateWidget(OrdersMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orders != widget.orders) {
      _buildMarkers();
    }
  }

  void _buildMarkers() {
    final markers = <Marker>{};
    final ordersWithCoords = widget.orders.where((o) => o.hasDeliveryCoordinates).toList();

    if (ordersWithCoords.isEmpty) {
      setState(() => _markers = markers);
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

    for (final order in ordersToShow) {
      markers.add(
        Marker(
          markerId: MarkerId('delivery_${order.id}'),
          position: LatLng(order.deliveryLatitude!, order.deliveryLongitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(_getMarkerHue(order.status)),
          infoWindow: InfoWindow(
            title: order.orderNumber ?? order.assignmentNumber,
            snippet: '${order.customerName ?? 'Customer'} - ${order.status}',
          ),
          onTap: () {
            setState(() => _selectedOrder = order);
          },
        ),
      );
    }

    setState(() => _markers = markers);
    _fitBounds();
  }

  double _getMarkerHue(String status) {
    switch (status.toUpperCase()) {
      case 'ASSIGNED':
        return BitmapDescriptor.hueOrange;
      case 'ACCEPTED':
        return BitmapDescriptor.hueBlue;
      case 'PICKED_UP':
      case 'IN_TRANSIT':
      case 'OUT_FOR_DELIVERY':
        return BitmapDescriptor.hueCyan;
      case 'ARRIVED':
        return BitmapDescriptor.hueViolet;
      case 'DELIVERED':
        return BitmapDescriptor.hueGreen;
      case 'FAILED':
        return BitmapDescriptor.hueRed;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  Future<void> _fitBounds() async {
    if (_markers.isEmpty) return;

    final controller = await _controller.future;

    if (_markers.length == 1) {
      final marker = _markers.first;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(marker.position, 15),
      );
    } else {
      double minLat = double.infinity;
      double maxLat = -double.infinity;
      double minLng = double.infinity;
      double maxLng = -double.infinity;

      for (final marker in _markers) {
        if (marker.position.latitude < minLat) minLat = marker.position.latitude;
        if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
        if (marker.position.longitude < minLng) minLng = marker.position.longitude;
        if (marker.position.longitude > maxLng) maxLng = marker.position.longitude;
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 60),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersWithCoordinates = widget.orders.where((o) => o.hasDeliveryCoordinates).toList();

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

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _defaultPosition,
          markers: _markers,
          onMapCreated: (controller) {
            _controller.complete(controller);
            _fitBounds();
          },
          onTap: (_) {
            setState(() => _selectedOrder = null);
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
        ),
        // Legend
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_markers.length} Orders',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                _legendItem(Colors.orange, 'Assigned'),
                _legendItem(Colors.blue, 'Accepted'),
                _legendItem(Colors.cyan, 'In Transit'),
                _legendItem(Colors.green, 'Delivered'),
              ],
            ),
          ),
        ),
        // Selected Order Card
        if (_selectedOrder != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _OrderCard(
              order: _selectedOrder!,
              onTap: () => widget.onOrderTapped(_selectedOrder!),
              onClose: () => setState(() => _selectedOrder = null),
            ),
          ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final DeliveryOrder order;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderNumber ?? order.assignmentNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.customerName ?? 'Customer',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.deliveryAddress ?? 'No address',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order.status,
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (order.orderTotal != null)
                    Text(
                      'Rs ${order.orderTotal!.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ASSIGNED':
        return Colors.orange;
      case 'ACCEPTED':
        return AppColors.info;
      case 'PICKED_UP':
      case 'IN_TRANSIT':
      case 'OUT_FOR_DELIVERY':
        return AppColors.primary;
      case 'ARRIVED':
        return Colors.purple;
      case 'DELIVERED':
        return AppColors.success;
      case 'FAILED':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}
