class OrderItem {
  final String productName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  OrderItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productName: json['product_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0,
      lineTotal: double.tryParse(json['line_total']?.toString() ?? '0') ?? 0,
    );
  }
}

class OrderInfo {
  final String orderNumber;
  final String status;
  final double subtotal;
  final double taxTotal;
  final double shippingTotal;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String? customerNotes;
  final List<OrderItem> items;

  OrderInfo({
    required this.orderNumber,
    required this.status,
    required this.subtotal,
    required this.taxTotal,
    required this.shippingTotal,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.customerNotes,
    required this.items,
  });

  factory OrderInfo.fromJson(Map<String, dynamic> json) {
    return OrderInfo(
      orderNumber: json['order_number'] ?? '',
      status: json['status'] ?? '',
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0,
      taxTotal: double.tryParse(json['tax_total']?.toString() ?? '0') ?? 0,
      shippingTotal: double.tryParse(json['shipping_total']?.toString() ?? '0') ?? 0,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      paymentMethod: json['payment_method'] ?? '',
      paymentStatus: json['payment_status'] ?? '',
      customerNotes: json['customer_notes'],
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class Customer {
  final String name;
  final String phone;
  final String? email;

  Customer({
    required this.name,
    required this.phone,
    this.email,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
    );
  }
}

class Location {
  final String name;
  final String address;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? state;
  final String? postalCode;

  Location({
    required this.name,
    required this.address,
    this.phone,
    this.latitude,
    this.longitude,
    this.city,
    this.state,
    this.postalCode,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'],
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      city: json['city'],
      state: json['state'],
      postalCode: json['postal_code'],
    );
  }

  String get fullAddress {
    final parts = [address];
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (postalCode != null && postalCode!.isNotEmpty) parts.add(postalCode!);
    return parts.join(', ');
  }
}

class DeliveryTimestamps {
  final DateTime? createdAt;
  final DateTime? assignedAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? inTransitAt;
  final DateTime? arrivedAt;
  final DateTime? deliveredAt;
  final DateTime? failedAt;
  final DateTime? scheduledPickupTime;
  final DateTime? scheduledDeliveryTime;

  DeliveryTimestamps({
    this.createdAt,
    this.assignedAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.inTransitAt,
    this.arrivedAt,
    this.deliveredAt,
    this.failedAt,
    this.scheduledPickupTime,
    this.scheduledDeliveryTime,
  });

  factory DeliveryTimestamps.fromJson(Map<String, dynamic> json) {
    return DeliveryTimestamps(
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      assignedAt: json['assigned_at'] != null ? DateTime.tryParse(json['assigned_at']) : null,
      acceptedAt: json['accepted_at'] != null ? DateTime.tryParse(json['accepted_at']) : null,
      pickedUpAt: json['picked_up_at'] != null ? DateTime.tryParse(json['picked_up_at']) : null,
      inTransitAt: json['in_transit_at'] != null ? DateTime.tryParse(json['in_transit_at']) : null,
      arrivedAt: json['arrived_at'] != null ? DateTime.tryParse(json['arrived_at']) : null,
      deliveredAt: json['delivered_at'] != null ? DateTime.tryParse(json['delivered_at']) : null,
      failedAt: json['failed_at'] != null ? DateTime.tryParse(json['failed_at']) : null,
      scheduledPickupTime: json['scheduled_pickup_time'] != null ? DateTime.tryParse(json['scheduled_pickup_time']) : null,
      scheduledDeliveryTime: json['scheduled_delivery_time'] != null ? DateTime.tryParse(json['scheduled_delivery_time']) : null,
    );
  }
}

class StatusHistory {
  final String fromStatus;
  final String toStatus;
  final DateTime changedAt;
  final String? notes;

  StatusHistory({
    required this.fromStatus,
    required this.toStatus,
    required this.changedAt,
    this.notes,
  });

  factory StatusHistory.fromJson(Map<String, dynamic> json) {
    return StatusHistory(
      fromStatus: json['from_status'] ?? '',
      toStatus: json['to_status'] ?? '',
      changedAt: DateTime.parse(json['changed_at']),
      notes: json['notes'],
    );
  }
}

class RouteInfo {
  final double distanceKm;
  final int estimatedDurationMinutes;
  final String? navigationUrl;

  RouteInfo({
    required this.distanceKm,
    required this.estimatedDurationMinutes,
    this.navigationUrl,
  });

  factory RouteInfo.fromJson(Map<String, dynamic> json) {
    return RouteInfo(
      distanceKm: double.tryParse(json['distance_km']?.toString() ?? '0') ?? 0,
      estimatedDurationMinutes: json['estimated_duration_minutes'] ?? 0,
      navigationUrl: json['navigation_url'],
    );
  }
}

class DeliveryOrder {
  final int id;
  final String assignmentNumber;
  final String? orderNumber;
  final double? orderTotal;
  final String? paymentMethod;
  final String status;
  final int priority;
  final String? customerName;
  final String? agentName;
  final String? zoneName;
  final String? deliveryAddress;
  final double codAmount;
  final DateTime? scheduledDeliveryTime;
  final DateTime createdAt;

  DeliveryOrder({
    required this.id,
    required this.assignmentNumber,
    this.orderNumber,
    this.orderTotal,
    this.paymentMethod,
    required this.status,
    required this.priority,
    this.customerName,
    this.agentName,
    this.zoneName,
    this.deliveryAddress,
    required this.codAmount,
    this.scheduledDeliveryTime,
    required this.createdAt,
  });

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) {
    return DeliveryOrder(
      id: json['id'],
      assignmentNumber: json['assignment_number'] ?? '',
      orderNumber: json['order_number'],
      orderTotal: double.tryParse(json['order_total']?.toString() ?? '0'),
      paymentMethod: json['payment_method'],
      status: json['status'] ?? '',
      priority: json['priority'] ?? 1,
      customerName: json['customer_name'],
      agentName: json['agent_name'],
      zoneName: json['zone_name'],
      deliveryAddress: json['delivery_address'],
      codAmount: double.tryParse(json['cod_amount']?.toString() ?? '0') ?? 0,
      scheduledDeliveryTime: json['scheduled_delivery_time'] != null
          ? DateTime.tryParse(json['scheduled_delivery_time'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get isCod => paymentMethod == 'COD';
  bool get isHighPriority => priority >= 2;
}

class DeliveryOrderDetail {
  final int id;
  final String assignmentNumber;
  final String status;
  final int priority;
  final OrderInfo? order;
  final Customer? customer;
  final Location? pickupLocation;
  final Location? deliveryLocation;
  final DeliveryTimestamps? timestamps;
  final double distanceKm;
  final double deliveryFee;
  final double agentCommission;
  final double codAmount;
  final double codCollected;
  final String codStatus;
  final String? deliveryPhoto;
  final String? signatureImage;
  final String? recipientName;
  final String? deliveryNotes;
  final String? failureReason;
  final String? failureNotes;
  final int retryCount;
  final int maxRetries;
  final double? customerRating;
  final String? customerFeedback;
  final double tipAmount;
  final List<StatusHistory> statusHistory;
  final RouteInfo? route;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeliveryOrderDetail({
    required this.id,
    required this.assignmentNumber,
    required this.status,
    required this.priority,
    this.order,
    this.customer,
    this.pickupLocation,
    this.deliveryLocation,
    this.timestamps,
    required this.distanceKm,
    required this.deliveryFee,
    required this.agentCommission,
    required this.codAmount,
    required this.codCollected,
    required this.codStatus,
    this.deliveryPhoto,
    this.signatureImage,
    this.recipientName,
    this.deliveryNotes,
    this.failureReason,
    this.failureNotes,
    required this.retryCount,
    required this.maxRetries,
    this.customerRating,
    this.customerFeedback,
    required this.tipAmount,
    required this.statusHistory,
    this.route,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeliveryOrderDetail.fromJson(Map<String, dynamic> json) {
    return DeliveryOrderDetail(
      id: json['id'],
      assignmentNumber: json['assignment_number'] ?? '',
      status: json['status'] ?? '',
      priority: json['priority'] ?? 1,
      order: json['order'] != null ? OrderInfo.fromJson(json['order']) : null,
      customer: json['customer'] != null ? Customer.fromJson(json['customer']) : null,
      pickupLocation: json['pickup_location'] != null
          ? Location.fromJson(json['pickup_location'])
          : null,
      deliveryLocation: json['delivery_location'] != null
          ? Location.fromJson(json['delivery_location'])
          : null,
      timestamps: json['timestamps'] != null
          ? DeliveryTimestamps.fromJson(json['timestamps'])
          : null,
      distanceKm: double.tryParse(json['distance_km']?.toString() ?? '0') ?? 0,
      deliveryFee: double.tryParse(json['delivery_fee']?.toString() ?? '0') ?? 0,
      agentCommission: double.tryParse(json['agent_commission']?.toString() ?? '0') ?? 0,
      codAmount: double.tryParse(json['cod_amount']?.toString() ?? '0') ?? 0,
      codCollected: double.tryParse(json['cod_collected']?.toString() ?? '0') ?? 0,
      codStatus: json['cod_status'] ?? 'NOT_APPLICABLE',
      deliveryPhoto: json['delivery_photo'],
      signatureImage: json['signature_image'],
      recipientName: json['recipient_name'],
      deliveryNotes: json['delivery_notes'],
      failureReason: json['failure_reason'],
      failureNotes: json['failure_notes'],
      retryCount: json['retry_count'] ?? 0,
      maxRetries: json['max_retries'] ?? 3,
      customerRating: double.tryParse(json['customer_rating']?.toString() ?? ''),
      customerFeedback: json['customer_feedback'],
      tipAmount: double.tryParse(json['tip_amount']?.toString() ?? '0') ?? 0,
      statusHistory: (json['status_history'] as List<dynamic>?)
              ?.map((e) => StatusHistory.fromJson(e))
              .toList() ??
          [],
      route: json['route'] != null ? RouteInfo.fromJson(json['route']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  bool get isCod => order?.paymentMethod == 'COD';
  bool get canRetry => retryCount < maxRetries;
}
