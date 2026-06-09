import '../../orders/data/models.dart';

double _parseDouble(dynamic value) {
  return double.tryParse(value?.toString() ?? '0') ?? 0;
}

int _parseInt(dynamic value) {
  return int.tryParse(value?.toString() ?? '0') ?? 0;
}

DateTime? _parseDate(dynamic value) {
  return value == null ? null : DateTime.tryParse(value.toString());
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

class AssignedCustomersData {
  final List<AssignedCustomer> customers;
  final AssignedCustomersSummary summary;
  final int total;
  final bool hasNext;

  const AssignedCustomersData({
    required this.customers,
    required this.summary,
    required this.total,
    required this.hasNext,
  });

  factory AssignedCustomersData.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']).isNotEmpty ? _asMap(json['data']) : json;
    final pagination = _asMap(data['pagination']);
    final rawCustomers = data['customers'] ??
        data['results'] ??
        data['assigned_customers'] ??
        data['data'] ??
        [];
    final customers = rawCustomers is List
        ? rawCustomers
            .map((item) => AssignedCustomer.fromJson(_asMap(item)))
            .where((customer) => customer.hasIdentity)
            .toList()
        : <AssignedCustomer>[];

    return AssignedCustomersData(
      customers: customers,
      summary: AssignedCustomersSummary.fromJson(
        _asMap(data['summary']).isNotEmpty ? _asMap(data['summary']) : data,
      ),
      total: _parseInt(
        data['total'] ??
            data['count'] ??
            pagination['total_customers'] ??
            pagination['count'] ??
            customers.length,
      ),
      hasNext: data['has_next'] == true || pagination['has_next'] == true,
    );
  }

  factory AssignedCustomersData.fromOrders(List<DeliveryOrder> orders) {
    final grouped = <String, List<DeliveryOrder>>{};
    for (final order in orders) {
      final name = (order.customerName ?? '').trim();
      final mobile = (order.customerMobile ?? '').trim();
      if (name.isEmpty && mobile.isEmpty) continue;
      final key = mobile.isNotEmpty ? mobile : name.toLowerCase();
      grouped.putIfAbsent(key, () => []).add(order);
    }

    final customers = grouped.entries
        .map((entry) => AssignedCustomer.fromOrders(entry.value))
        .toList()
      ..sort((a, b) {
        final aDate = a.lastOrderAt;
        final bDate = b.lastOrderAt;
        if (aDate == null && bDate == null) return a.name.compareTo(b.name);
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

    return AssignedCustomersData(
      customers: customers,
      summary: AssignedCustomersSummary.fromCustomers(customers),
      total: customers.length,
      hasNext: false,
    );
  }
}

class AssignedCustomersSummary {
  final int totalCustomers;
  final int creditCustomers;
  final int codCustomers;
  final double totalAmount;
  final double totalPaid;
  final double totalRemaining;

  const AssignedCustomersSummary({
    required this.totalCustomers,
    required this.creditCustomers,
    required this.codCustomers,
    required this.totalAmount,
    required this.totalPaid,
    required this.totalRemaining,
  });

  factory AssignedCustomersSummary.fromJson(Map<String, dynamic> json) {
    return AssignedCustomersSummary(
      totalCustomers: _parseInt(json['total_customers'] ?? json['total']),
      creditCustomers: _parseInt(json['credit_customers']),
      codCustomers: _parseInt(json['cod_customers']),
      totalAmount: _parseDouble(json['total_amount'] ?? json['order_total']),
      totalPaid: _parseDouble(json['total_paid'] ?? json['paid_amount']),
      totalRemaining:
          _parseDouble(json['total_remaining'] ?? json['remaining_amount']),
    );
  }

  factory AssignedCustomersSummary.fromCustomers(
    List<AssignedCustomer> customers,
  ) {
    return AssignedCustomersSummary(
      totalCustomers: customers.length,
      creditCustomers: customers.where((customer) => customer.hasCredit).length,
      codCustomers: customers.where((customer) => customer.hasCod).length,
      totalAmount:
          customers.fold(0, (sum, customer) => sum + customer.totalAmount),
      totalPaid:
          customers.fold(0, (sum, customer) => sum + customer.wallet.paid),
      totalRemaining: customers.fold(
        0,
        (sum, customer) => sum + customer.wallet.remaining,
      ),
    );
  }
}

class AssignedCustomer {
  final int id;
  final String name;
  final String mobile;
  final String? email;
  final String? address;
  final String? city;
  final String? area;
  final double? latitude;
  final double? longitude;
  final int assignedOrders;
  final int activeOrders;
  final int deliveredOrders;
  final int failedOrders;
  final DateTime? lastOrderAt;
  final CustomerWallet wallet;
  final double totalAmount;
  final String? lastOrderNumber;
  final String? paymentMethod;
  final List<String> paymentMethods;
  final double creditAmount;
  final double codAmount;
  final double codDue;

  const AssignedCustomer({
    required this.id,
    required this.name,
    required this.mobile,
    this.email,
    this.address,
    this.city,
    this.area,
    this.latitude,
    this.longitude,
    required this.assignedOrders,
    required this.activeOrders,
    required this.deliveredOrders,
    required this.failedOrders,
    this.lastOrderAt,
    required this.wallet,
    required this.totalAmount,
    this.lastOrderNumber,
    this.paymentMethod,
    this.paymentMethods = const [],
    this.creditAmount = 0,
    this.codAmount = 0,
    this.codDue = 0,
  });

  bool get hasIdentity => name.isNotEmpty || mobile.isNotEmpty;
  bool get hasCredit =>
      creditAmount > 0 ||
      paymentMethods.contains('CREDIT') ||
      paymentMethod == 'CREDIT';
  bool get hasCod =>
      codAmount > 0 ||
      codDue > 0 ||
      paymentMethods.contains('COD') ||
      paymentMethod == 'COD';
  bool get hasCustomerRisk => riskLevel != CustomerRiskLevel.clear;
  CustomerRiskLevel get riskLevel {
    if (wallet.isOverLimit) return CustomerRiskLevel.blocked;
    if (wallet.remaining > 0 && paymentMethod == 'CREDIT') {
      return CustomerRiskLevel.high;
    }
    if (wallet.remaining > 0 ||
        wallet.availableCredit <= 0 && wallet.creditLimit > 0) {
      return CustomerRiskLevel.medium;
    }
    if (paymentMethod == 'CREDIT') return CustomerRiskLevel.watch;
    return CustomerRiskLevel.clear;
  }

  String get riskLabel {
    switch (riskLevel) {
      case CustomerRiskLevel.clear:
        return 'Clear';
      case CustomerRiskLevel.watch:
        return 'Credit watch';
      case CustomerRiskLevel.medium:
        return paymentMethod == 'COD' ? 'COD due' : 'Balance due';
      case CustomerRiskLevel.high:
        return 'Credit due';
      case CustomerRiskLevel.blocked:
        return 'Over limit';
    }
  }

  String get riskSummary {
    switch (riskLevel) {
      case CustomerRiskLevel.clear:
        return 'No outstanding balance on assigned orders.';
      case CustomerRiskLevel.watch:
        return 'Credit order. Confirm customer status before delivery.';
      case CustomerRiskLevel.medium:
        return 'Verify or collect ${_formatRs(wallet.remaining)} before closing delivery.';
      case CustomerRiskLevel.high:
        return 'Credit customer owes ${_formatRs(wallet.remaining)}. Confirm billing before handover.';
      case CustomerRiskLevel.blocked:
        return 'Outstanding balance exceeds credit limit.';
    }
  }

  bool get hasLocation =>
      latitude != null &&
      longitude != null &&
      latitude != 0.0 &&
      longitude != 0.0 &&
      latitude!.abs() <= 90 &&
      longitude!.abs() <= 180;

  String get displayName => name.isNotEmpty ? name : 'Customer';

  String get displayLocation {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (area != null && area!.isNotEmpty) parts.add(area!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    return parts.isEmpty ? 'No location saved' : parts.join(', ');
  }

  factory AssignedCustomer.fromJson(Map<String, dynamic> json) {
    final customer = _asMap(json['customer']);
    final customerInfo = _asMap(json['customer_info']);
    final deliveryInfo = _asMap(json['delivery_info']);
    final location = _asMap(json['location']);
    final wallet = CustomerWallet.fromJson(
      _asMap(json['wallet']).isNotEmpty
          ? _asMap(json['wallet'])
          : _asMap(json['credit_info']).isNotEmpty
              ? _asMap(json['credit_info'])
              : json,
    );
    final lifetimeSales = _asMap(json['lifetime_sales']);
    final periodSales = _asMap(json['period_sales']);
    final rawPaymentMethods =
        json['payment_methods'] ?? json['payment_types'] ?? [];
    final paymentMethods = rawPaymentMethods is List
        ? rawPaymentMethods
            .map((method) => method.toString().toUpperCase())
            .where((method) => method.isNotEmpty)
            .toSet()
            .toList()
        : <String>[];
    final paymentMethod = json['payment_method']?.toString().toUpperCase();
    if (paymentMethod != null &&
        paymentMethod.isNotEmpty &&
        !paymentMethods.contains(paymentMethod)) {
      paymentMethods.add(paymentMethod);
    }
    final totalAmount = _parseDouble(
      json['total_amount'] ??
          json['order_total'] ??
          json['total'] ??
          json['amount'] ??
          lifetimeSales['total_amount'] ??
          periodSales['total_amount'] ??
          wallet.total,
    );

    final name = (json['name'] ??
            json['customer_name'] ??
            customer['name'] ??
            customerInfo['name'] ??
            '')
        .toString();
    final mobile = (json['mobile'] ??
            json['mobile_number'] ??
            json['customer_mobile'] ??
            customer['mobile'] ??
            customer['mobile_number'] ??
            customer['phone'] ??
            customerInfo['mobile'] ??
            customerInfo['phone'] ??
            '')
        .toString();

    return AssignedCustomer(
      id: _parseInt(
        json['id'] ??
            json['customer_id'] ??
            customer['id'] ??
            customerInfo['id'] ??
            _stableCustomerId(name, mobile),
      ),
      name: name,
      mobile: mobile,
      email: (json['email'] ?? customer['email'] ?? customerInfo['email'])
          ?.toString(),
      address: (json['address'] ??
              json['street_address'] ??
              json['delivery_address'] ??
              deliveryInfo['address'] ??
              location['address'] ??
              location['street_address'])
          ?.toString(),
      city: (json['city'] ?? json['delivery_city'] ?? deliveryInfo['city'])
          ?.toString(),
      area: (json['area'] ?? json['delivery_area'] ?? deliveryInfo['area'])
          ?.toString(),
      latitude: _parseNullableDouble(
        json['latitude'] ??
            json['delivery_latitude'] ??
            deliveryInfo['latitude'],
      ),
      longitude: _parseNullableDouble(
        json['longitude'] ??
            json['delivery_longitude'] ??
            deliveryInfo['longitude'],
      ),
      assignedOrders:
          _parseInt(json['assigned_orders'] ?? json['order_count'] ?? 0),
      activeOrders: _parseInt(json['active_orders']),
      deliveredOrders: _parseInt(json['delivered_orders']),
      failedOrders: _parseInt(json['failed_orders']),
      lastOrderAt: _parseDate(
        json['last_order_at'] ?? json['delivered_at'] ?? json['created_at'],
      ),
      wallet: wallet,
      totalAmount: totalAmount,
      lastOrderNumber:
          (json['last_order_number'] ?? json['order_number'])?.toString(),
      paymentMethod: paymentMethod,
      paymentMethods: paymentMethods,
      creditAmount: _parseDouble(
        json['credit_amount'] ??
            json['credit_due'] ??
            json['credit_total'] ??
            json['credit_remaining'],
      ),
      codAmount: _parseDouble(
        json['cod_amount'] ?? json['cod_total'] ?? json['cod_collected'],
      ),
      codDue: _parseDouble(
        json['cod_due'] ??
            json['cod_to_collect'] ??
            json['cod_pending'] ??
            json['cod_remaining'],
      ),
    );
  }

  factory AssignedCustomer.fromOrders(List<DeliveryOrder> orders) {
    final sorted = [...orders]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final latest = sorted.first;
    final paymentMethods = orders
        .map((order) => order.paymentMethod?.toUpperCase() ?? '')
        .where((method) => method.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final creditAmount = orders
        .where((order) => order.paymentMethod == 'CREDIT')
        .fold(0.0, (sum, order) => sum + (order.orderTotal ?? order.codAmount));
    final codAmount = orders
        .where((order) => order.paymentMethod == 'COD')
        .fold(0.0, (sum, order) => sum + (order.orderTotal ?? order.codAmount));
    final codDue = orders
        .where((order) =>
            order.paymentMethod == 'COD' &&
            !order.status.toUpperCase().contains('DELIVERED'))
        .fold(0.0, (sum, order) => sum + (order.orderTotal ?? order.codAmount));
    final totalRemaining = orders
        .where((order) =>
            order.paymentMethod == 'CREDIT' ||
            (order.paymentMethod == 'COD' &&
                !order.status.toUpperCase().contains('DELIVERED')))
        .fold(0.0, (sum, order) => sum + (order.orderTotal ?? order.codAmount));
    final totalPaid = orders
        .where((order) =>
            order.status.toUpperCase() == 'DELIVERED' &&
            order.paymentMethod != 'CREDIT')
        .fold(0.0, (sum, order) => sum + (order.orderTotal ?? order.codAmount));
    final totalAmount = orders.fold(
      0.0,
      (sum, order) => sum + (order.orderTotal ?? order.codAmount),
    );

    return AssignedCustomer(
      id: latest.customerId ??
          _stableCustomerId(
              latest.customerName ?? '', latest.customerMobile ?? ''),
      name: latest.customerName ?? '',
      mobile: latest.customerMobile ?? '',
      address: latest.deliveryAddress,
      city: latest.deliveryCity,
      area: latest.deliveryArea,
      latitude: latest.deliveryLatitude,
      longitude: latest.deliveryLongitude,
      assignedOrders: orders.length,
      activeOrders: orders
          .where((order) => ![
                'DELIVERED',
                'FAILED',
                'CANCELLED',
                'RETURNED',
              ].contains(order.status.toUpperCase()))
          .length,
      deliveredOrders: orders
          .where((order) => order.status.toUpperCase() == 'DELIVERED')
          .length,
      failedOrders: orders
          .where((order) => order.status.toUpperCase() == 'FAILED')
          .length,
      lastOrderAt: latest.deliveredAt ??
          latest.scheduledDeliveryTime ??
          latest.createdAt,
      wallet: CustomerWallet(
        paid: totalPaid,
        remaining: totalRemaining,
        balance: totalRemaining,
        creditLimit: 0,
        availableCredit: 0,
        total: totalAmount,
      ),
      totalAmount: totalAmount,
      lastOrderNumber: latest.orderNumber ?? latest.assignmentNumber,
      paymentMethod: latest.paymentMethod?.toUpperCase(),
      paymentMethods: paymentMethods,
      creditAmount: creditAmount,
      codAmount: codAmount,
      codDue: codDue,
    );
  }
}

enum CustomerRiskLevel { clear, watch, medium, high, blocked }

class CustomerWallet {
  final double total;
  final double paid;
  final double remaining;
  final double balance;
  final double creditLimit;
  final double availableCredit;

  const CustomerWallet({
    required this.total,
    required this.paid,
    required this.remaining,
    required this.balance,
    required this.creditLimit,
    required this.availableCredit,
  });

  bool get hasRemaining => remaining > 0;
  bool get hasCreditLimit => creditLimit > 0;
  bool get isOverLimit => hasCreditLimit && remaining > creditLimit;
  double get creditUsedPercent {
    if (!hasCreditLimit) return 0;
    return (remaining / creditLimit).clamp(0, 1).toDouble();
  }

  factory CustomerWallet.fromJson(Map<String, dynamic> json) {
    final currentBalance =
        _parseDouble(json['current_balance'] ?? json['balance']);
    final remaining = _parseDouble(
      json['remaining'] ??
          json['remaining_amount'] ??
          json['outstanding'] ??
          json['outstanding_balance'] ??
          currentBalance,
    );
    final creditLimit = _parseDouble(json['credit_limit']);
    final paid =
        _parseDouble(json['paid'] ?? json['paid_amount'] ?? json['total_paid']);
    final total = _parseDouble(json['total'] ??
        json['total_amount'] ??
        json['order_total'] ??
        json['wallet_total']);
    return CustomerWallet(
      total: total == 0 ? paid + remaining : total,
      paid: paid,
      remaining: remaining,
      balance: currentBalance == 0 ? remaining : currentBalance,
      creditLimit: creditLimit,
      availableCredit: _parseDouble(json['available_credit']),
    );
  }
}

class CustomerDeliveryDetail {
  final AssignedCustomer customer;
  final List<CustomerOrderHistoryItem> orderHistory;
  final String? notes;

  const CustomerDeliveryDetail({
    required this.customer,
    required this.orderHistory,
    this.notes,
  });

  factory CustomerDeliveryDetail.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']).isNotEmpty ? _asMap(json['data']) : json;
    final customerJson =
        _asMap(data['customer']).isNotEmpty ? _asMap(data['customer']) : data;
    final rawHistory =
        data['order_history'] ?? data['orders'] ?? data['recent_orders'] ?? [];

    return CustomerDeliveryDetail(
      customer: AssignedCustomer.fromJson(customerJson),
      orderHistory: rawHistory is List
          ? rawHistory
              .map((item) => CustomerOrderHistoryItem.fromJson(_asMap(item)))
              .toList()
          : [],
      notes: data['notes']?.toString(),
    );
  }

  factory CustomerDeliveryDetail.fromCustomerAndOrders(
    AssignedCustomer customer,
    List<DeliveryOrder> orders,
  ) {
    final history = orders
        .where((order) {
          final sameMobile = customer.mobile.isNotEmpty &&
              order.customerMobile == customer.mobile;
          final sameName =
              customer.mobile.isEmpty && order.customerName == customer.name;
          return sameMobile || sameName;
        })
        .map(CustomerOrderHistoryItem.fromOrder)
        .toList()
      ..sort((a, b) {
        final aDate = a.deliveredAt ?? a.createdAt;
        final bDate = b.deliveredAt ?? b.createdAt;
        return bDate.compareTo(aDate);
      });

    return CustomerDeliveryDetail(customer: customer, orderHistory: history);
  }
}

class CustomerOrderHistoryItem {
  final int id;
  final String orderNumber;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final double total;
  final double paid;
  final double remaining;
  final DateTime createdAt;
  final DateTime? deliveredAt;

  const CustomerOrderHistoryItem({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.total,
    required this.paid,
    required this.remaining,
    required this.createdAt,
    this.deliveredAt,
  });

  factory CustomerOrderHistoryItem.fromJson(Map<String, dynamic> json) {
    final payment = _asMap(json['payment_breakdown']);
    final total = _parseDouble(
      json['total'] ??
          json['order_total'] ??
          json['total_amount'] ??
          payment['total'],
    );
    final remaining = _parseDouble(
      json['remaining'] ??
          json['remaining_amount'] ??
          json['outstanding'] ??
          (json['payment_method'] == 'CREDIT' ? total : 0),
    );
    return CustomerOrderHistoryItem(
      id: _parseInt(json['id'] ?? json['order_id']),
      orderNumber: (json['order_number'] ??
              json['sale_number'] ??
              json['assignment_number'] ??
              '')
          .toString(),
      status: (json['status'] ?? '').toString(),
      paymentMethod: (json['payment_method'] ?? payment['payment_method'] ?? '')
          .toString(),
      paymentStatus: (json['payment_status'] ?? payment['payment_status'] ?? '')
          .toString(),
      total: total,
      paid: _parseDouble(json['paid'] ?? json['paid_amount']),
      remaining: remaining,
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      deliveredAt: _parseDate(json['delivered_at']),
    );
  }

  factory CustomerOrderHistoryItem.fromOrder(DeliveryOrder order) {
    final total = order.orderTotal ?? order.codAmount;
    final isRemaining = order.paymentMethod == 'CREDIT' ||
        (order.paymentMethod == 'COD' &&
            order.status.toUpperCase() != 'DELIVERED');
    return CustomerOrderHistoryItem(
      id: order.id,
      orderNumber: order.orderNumber ?? order.assignmentNumber,
      status: order.status,
      paymentMethod: order.paymentMethod ?? '',
      paymentStatus: isRemaining ? 'PENDING' : 'PAID',
      total: total,
      paid: isRemaining ? 0 : total,
      remaining: isRemaining ? total : 0,
      createdAt: order.createdAt,
      deliveredAt: order.deliveredAt,
    );
  }
}

double? _parseNullableDouble(dynamic value) {
  if (value == null || value.toString().isEmpty) return null;
  return double.tryParse(value.toString());
}

int _stableCustomerId(String name, String mobile) {
  final source = (mobile.isNotEmpty ? mobile : name).trim().toLowerCase();
  var hash = 0;
  for (final codeUnit in source.codeUnits) {
    hash = (hash * 31 + codeUnit) & 0x7fffffff;
  }
  return hash == 0 ? 1 : hash;
}

String _formatRs(double amount) {
  return 'Rs ${amount.toStringAsFixed(0)}';
}
