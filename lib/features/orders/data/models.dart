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
      shippingTotal:
          double.tryParse(json['shipping_total']?.toString() ?? '0') ?? 0,
      totalAmount:
          double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
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
  final String? area;
  final String? state;
  final String? postalCode;

  Location({
    required this.name,
    required this.address,
    this.phone,
    this.latitude,
    this.longitude,
    this.city,
    this.area,
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
      area: json['area'],
      state: json['state'],
      postalCode: json['postal_code'],
    );
  }

  /// Full address with city, state, postalCode
  String get fullAddress {
    final parts = [address];
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (postalCode != null && postalCode!.isNotEmpty) parts.add(postalCode!);
    return parts.join(', ');
  }

  /// Display address with street and area only (no city)
  String get displayAddress {
    final parts = <String>[];
    if (address.isNotEmpty) parts.add(address);
    if (area != null && area!.isNotEmpty) parts.add(area!);
    return parts.isNotEmpty ? parts.join(', ') : 'No address';
  }

  /// Whether this location has valid GPS coordinates
  bool get hasCoordinates =>
      latitude != null &&
      longitude != null &&
      latitude != 0.0 &&
      longitude != 0.0 &&
      latitude!.abs() <= 90 &&
      longitude!.abs() <= 180;
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
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      assignedAt: json['assigned_at'] != null
          ? DateTime.tryParse(json['assigned_at'])
          : null,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.tryParse(json['accepted_at'])
          : null,
      pickedUpAt: json['picked_up_at'] != null
          ? DateTime.tryParse(json['picked_up_at'])
          : null,
      inTransitAt: json['in_transit_at'] != null
          ? DateTime.tryParse(json['in_transit_at'])
          : null,
      arrivedAt: json['arrived_at'] != null
          ? DateTime.tryParse(json['arrived_at'])
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'])
          : null,
      failedAt: json['failed_at'] != null
          ? DateTime.tryParse(json['failed_at'])
          : null,
      scheduledPickupTime: json['scheduled_pickup_time'] != null
          ? DateTime.tryParse(json['scheduled_pickup_time'])
          : null,
      scheduledDeliveryTime: json['scheduled_delivery_time'] != null
          ? DateTime.tryParse(json['scheduled_delivery_time'])
          : null,
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
  final double? subtotal;
  final double? deliveryFee;
  final String? paymentMethod;
  final String status;
  final String? statusDisplay;
  final int priority;
  final int? customerId;
  final String? customerName;
  final String? customerMobile;
  final String? agentName;
  final String? zoneName;
  final String? deliveryAddress;
  final String? deliveryCity;
  final String? deliveryArea;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double codAmount;
  final DateTime? scheduledDeliveryTime;
  final DateTime createdAt;
  final DateTime? deliveredAt;

  DeliveryOrder({
    required this.id,
    required this.assignmentNumber,
    this.orderNumber,
    this.orderTotal,
    this.subtotal,
    this.deliveryFee,
    this.paymentMethod,
    required this.status,
    this.statusDisplay,
    required this.priority,
    this.customerId,
    this.customerName,
    this.customerMobile,
    this.agentName,
    this.zoneName,
    this.deliveryAddress,
    this.deliveryCity,
    this.deliveryArea,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.pickupLatitude,
    this.pickupLongitude,
    required this.codAmount,
    this.scheduledDeliveryTime,
    required this.createdAt,
    this.deliveredAt,
  });

  bool get hasDeliveryCoordinates =>
      deliveryLatitude != null &&
      deliveryLongitude != null &&
      deliveryLatitude != 0.0 &&
      deliveryLongitude != 0.0 &&
      deliveryLatitude!.abs() <= 90 &&
      deliveryLongitude!.abs() <= 180;

  bool get hasPickupCoordinates =>
      pickupLatitude != null &&
      pickupLongitude != null &&
      pickupLatitude != 0.0 &&
      pickupLongitude != 0.0 &&
      pickupLatitude!.abs() <= 90 &&
      pickupLongitude!.abs() <= 180;

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) {
    // Handle nested payment_breakdown structure (new API format)
    final paymentBreakdown = json['payment_breakdown'] as Map<String, dynamic>?;

    // Try multiple fields for order total
    final orderTotal = double.tryParse(json['order_total']?.toString() ?? '') ??
        double.tryParse(paymentBreakdown?['total']?.toString() ?? '') ??
        double.tryParse(json['total']?.toString() ?? '');

    final subtotal = double.tryParse(json['subtotal']?.toString() ?? '') ??
        double.tryParse(paymentBreakdown?['subtotal']?.toString() ?? '') ??
        double.tryParse(json['order_amount']?.toString() ?? '');

    final deliveryFee = double.tryParse(
            json['delivery_fee']?.toString() ?? '') ??
        double.tryParse(paymentBreakdown?['delivery_fee']?.toString() ?? '') ??
        double.tryParse(json['delivery_charges']?.toString() ?? '');

    // Handle nested customer_info structure
    final customerInfo = json['customer_info'] as Map<String, dynamic>?;
    final customer = json['customer'] as Map<String, dynamic>?;
    final customerId = int.tryParse(
      (json['customer_id'] ?? customerInfo?['id'] ?? customer?['id'])
              ?.toString() ??
          '',
    );
    final customerName = json['customer_name'] ?? customerInfo?['name'];
    final customerMobile = json['customer_mobile'] ??
        customerInfo?['mobile'] ??
        customerInfo?['phone'];

    // Handle nested delivery_info structure
    final deliveryInfo = json['delivery_info'] as Map<String, dynamic>?;
    final deliveryAddress =
        json['delivery_address'] ?? deliveryInfo?['address'];
    final deliveryCity = json['delivery_city'] ?? deliveryInfo?['city'];
    final deliveryArea = json['delivery_area'] ?? deliveryInfo?['area'];
    final zoneName = json['zone_name'] ?? deliveryInfo?['zone'];

    // GPS coordinates for delivery location
    final deliveryLatitude =
        double.tryParse(json['delivery_latitude']?.toString() ?? '') ??
            double.tryParse(deliveryInfo?['latitude']?.toString() ?? '');
    final deliveryLongitude =
        double.tryParse(json['delivery_longitude']?.toString() ?? '') ??
            double.tryParse(deliveryInfo?['longitude']?.toString() ?? '');

    // GPS coordinates for pickup location (store)
    final pickupLatitude =
        double.tryParse(json['pickup_latitude']?.toString() ?? '');
    final pickupLongitude =
        double.tryParse(json['pickup_longitude']?.toString() ?? '');

    // Handle timestamps structure
    final timestamps = json['timestamps'] as Map<String, dynamic>?;
    final createdAtStr = json['created_at'] ?? timestamps?['created_at'];
    final deliveredAtStr = json['delivered_at'] ?? timestamps?['delivered_at'];

    // COD amount from payment_breakdown
    final codAmount = double.tryParse(json['cod_amount']?.toString() ?? '') ??
        (paymentBreakdown?['is_cod'] == true
            ? (double.tryParse(paymentBreakdown?['total']?.toString() ?? '0') ??
                0)
            : 0);

    // Payment method from payment_breakdown
    final paymentMethod =
        json['payment_method'] ?? paymentBreakdown?['payment_method'];

    // Parse scheduled delivery time from various formats
    DateTime? scheduledDeliveryTime;
    if (json['scheduled_date'] != null) {
      // Format: scheduled_date + scheduled_time (from history API)
      final dateStr = json['scheduled_date'] as String;
      final timeStr = json['scheduled_time'] as String? ?? '00:00:00';
      scheduledDeliveryTime = DateTime.tryParse('${dateStr}T$timeStr');
    } else if (json['scheduled_delivery_time'] != null) {
      final schedValue = json['scheduled_delivery_time'] as String;
      // Try parsing as full ISO datetime first
      scheduledDeliveryTime = DateTime.tryParse(schedValue);
      // If failed, it might be time-only (e.g., "07:30:00") - combine with created_at date
      if (scheduledDeliveryTime == null && schedValue.contains(':')) {
        final createdAt = json['created_at'] != null
            ? DateTime.tryParse(json['created_at'])
            : DateTime.now();
        if (createdAt != null) {
          final datePart =
              '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
          scheduledDeliveryTime = DateTime.tryParse('${datePart}T$schedValue');
        }
      }
    }

    return DeliveryOrder(
      id: json['id'],
      assignmentNumber: json['assignment_number'] ?? json['order_number'] ?? '',
      orderNumber: json['order_number'],
      orderTotal: orderTotal,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      paymentMethod: paymentMethod,
      status: json['status'] ?? '',
      statusDisplay: json['status_display'],
      priority: json['priority'] ?? 1,
      customerId: customerId,
      customerName: customerName,
      customerMobile: customerMobile,
      agentName: json['agent_name'],
      zoneName: zoneName,
      deliveryAddress: deliveryAddress,
      deliveryCity: deliveryCity,
      deliveryArea: deliveryArea,
      deliveryLatitude: deliveryLatitude,
      deliveryLongitude: deliveryLongitude,
      pickupLatitude: pickupLatitude,
      pickupLongitude: pickupLongitude,
      codAmount: codAmount,
      scheduledDeliveryTime: scheduledDeliveryTime,
      createdAt: createdAtStr != null
          ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
          : DateTime.now(),
      deliveredAt:
          deliveredAtStr != null ? DateTime.tryParse(deliveredAtStr) : null,
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
    // Parse payment_breakdown for order info
    final paymentBreakdown = json['payment_breakdown'] as Map<String, dynamic>?;
    final items = json['items'] as List<dynamic>?;

    // Build OrderInfo from flat structure
    OrderInfo? orderInfo;
    if (paymentBreakdown != null || items != null) {
      orderInfo = OrderInfo(
        orderNumber: json['order_number'] ?? '',
        status: json['status'] ?? '',
        subtotal:
            double.tryParse(paymentBreakdown?['subtotal']?.toString() ?? '0') ??
                0,
        taxTotal: 0,
        shippingTotal: double.tryParse(
                paymentBreakdown?['delivery_fee']?.toString() ?? '0') ??
            0,
        totalAmount:
            double.tryParse(paymentBreakdown?['total']?.toString() ?? '0') ?? 0,
        paymentMethod: paymentBreakdown?['payment_method'] ?? '',
        paymentStatus: paymentBreakdown?['payment_status'] ?? '',
        items: items?.map((e) => OrderItem.fromJson(e)).toList() ?? [],
      );
    } else if (json['order'] != null) {
      orderInfo = OrderInfo.fromJson(json['order']);
    }

    // Parse customer from customer_info or customer
    Customer? customer;
    final customerInfo = json['customer_info'] as Map<String, dynamic>?;
    if (customerInfo != null) {
      customer = Customer(
        name: customerInfo['name'] ?? '',
        phone: customerInfo['mobile'] ?? customerInfo['phone'] ?? '',
        email: customerInfo['email'],
      );
    } else if (json['customer'] != null) {
      customer = Customer.fromJson(json['customer']);
    }

    // Parse pickup location from business_info or pickup_location
    Location? pickupLocation;
    final businessInfo = json['business_info'] as Map<String, dynamic>?;
    if (businessInfo != null) {
      pickupLocation = Location(
        name: businessInfo['name'] ?? '',
        address: businessInfo['address'] ?? '',
        phone: businessInfo['phone'],
        city: businessInfo['city'],
        latitude: double.tryParse(businessInfo['latitude']?.toString() ?? ''),
        longitude: double.tryParse(businessInfo['longitude']?.toString() ?? ''),
      );
    } else if (json['pickup_location'] != null) {
      pickupLocation = Location.fromJson(json['pickup_location']);
    }

    // Parse delivery location from delivery_info or delivery_location
    Location? deliveryLocation;
    final deliveryInfo = json['delivery_info'] as Map<String, dynamic>?;
    if (deliveryInfo != null) {
      deliveryLocation = Location(
        name: deliveryInfo['zone'] ?? '',
        address: deliveryInfo['address'] ?? '',
        city: deliveryInfo['city'],
        area: deliveryInfo['area'],
        latitude: double.tryParse(deliveryInfo['latitude']?.toString() ?? ''),
        longitude: double.tryParse(deliveryInfo['longitude']?.toString() ?? ''),
      );
    } else if (json['delivery_location'] != null) {
      deliveryLocation = Location.fromJson(json['delivery_location']);
    }

    // Parse timestamps
    final timestampsJson = json['timestamps'] as Map<String, dynamic>?;
    DeliveryTimestamps? timestamps;
    if (timestampsJson != null) {
      timestamps = DeliveryTimestamps(
        createdAt: timestampsJson['created_at'] != null
            ? DateTime.tryParse(timestampsJson['created_at'])
            : null,
        deliveredAt: timestampsJson['delivered_at'] != null
            ? DateTime.tryParse(timestampsJson['delivered_at'])
            : null,
        assignedAt: timestampsJson['assigned_at'] != null
            ? DateTime.tryParse(timestampsJson['assigned_at'])
            : null,
        acceptedAt: timestampsJson['accepted_at'] != null
            ? DateTime.tryParse(timestampsJson['accepted_at'])
            : null,
        pickedUpAt: timestampsJson['picked_up_at'] != null
            ? DateTime.tryParse(timestampsJson['picked_up_at'])
            : null,
        inTransitAt: timestampsJson['in_transit_at'] != null
            ? DateTime.tryParse(timestampsJson['in_transit_at'])
            : null,
        arrivedAt: timestampsJson['arrived_at'] != null
            ? DateTime.tryParse(timestampsJson['arrived_at'])
            : null,
        failedAt: timestampsJson['failed_at'] != null
            ? DateTime.tryParse(timestampsJson['failed_at'])
            : null,
      );
    }

    // Get COD amount from payment_breakdown if available
    final codAmount = double.tryParse(
            paymentBreakdown?['amount_to_collect']?.toString() ?? '') ??
        double.tryParse(json['cod_amount']?.toString() ?? '0') ??
        0;

    final isCodPayment = paymentBreakdown?['is_cod'] == true ||
        paymentBreakdown?['payment_method'] == 'COD';

    return DeliveryOrderDetail(
      id: json['id'],
      assignmentNumber: json['assignment_number'] ?? json['order_number'] ?? '',
      status: json['status'] ?? '',
      priority: json['priority'] ?? 1,
      order: orderInfo,
      customer: customer,
      pickupLocation: pickupLocation,
      deliveryLocation: deliveryLocation,
      timestamps: timestamps,
      distanceKm: double.tryParse(json['distance_km']?.toString() ?? '0') ?? 0,
      deliveryFee: double.tryParse(
              paymentBreakdown?['delivery_fee']?.toString() ??
                  json['delivery_fee']?.toString() ??
                  '0') ??
          0,
      agentCommission:
          double.tryParse(json['agent_commission']?.toString() ?? '0') ?? 0,
      codAmount: isCodPayment
          ? (double.tryParse(paymentBreakdown?['total']?.toString() ?? '0') ??
              codAmount)
          : codAmount,
      codCollected:
          double.tryParse(json['cod_collected']?.toString() ?? '0') ?? 0,
      codStatus: paymentBreakdown?['payment_status'] ??
          json['cod_status'] ??
          'NOT_APPLICABLE',
      deliveryPhoto: json['delivery_photo'],
      signatureImage: json['signature_image'],
      recipientName: json['recipient_name'],
      deliveryNotes: json['delivery_notes'],
      failureReason: json['failure_reason'],
      failureNotes: json['failure_notes'],
      retryCount: json['retry_count'] ?? 0,
      maxRetries: json['max_retries'] ?? 3,
      customerRating:
          double.tryParse(json['customer_rating']?.toString() ?? ''),
      customerFeedback: json['customer_feedback'],
      tipAmount: double.tryParse(json['tip_amount']?.toString() ?? '0') ?? 0,
      statusHistory: (json['status_history'] as List<dynamic>?)
              ?.map((e) => StatusHistory.fromJson(e))
              .toList() ??
          [],
      route: json['route'] != null ? RouteInfo.fromJson(json['route']) : null,
      createdAt: DateTime.tryParse(
              timestampsJson?['created_at'] ?? json['created_at'] ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isCod => order?.paymentMethod == 'COD';
  bool get canRetry => retryCount < maxRetries;
  bool get hasDeliveryCoordinates => deliveryLocation?.hasCoordinates ?? false;
}
