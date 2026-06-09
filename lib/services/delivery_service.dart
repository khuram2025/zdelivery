import 'dart:io';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../features/customers/data/models.dart';
import '../features/dashboard/data/models.dart';
import '../features/orders/data/models.dart';
import '../features/profile/data/models.dart';
import '../features/earnings/data/models.dart';
import 'api_service.dart';

class DeliveryService {
  final ApiService _apiService;

  DeliveryService(this._apiService);

  // Profile
  Future<AgentProfile> getProfile() async {
    final response = await _apiService.get(ApiConstants.agentProfile);
    return AgentProfile.fromJson(response.data['data']);
  }

  Future<AgentProfile> updateProfile({
    String? phoneNumber,
    String? alternatePhone,
    String? vehicleNumber,
    File? profilePhoto,
  }) async {
    final data = <String, dynamic>{};
    if (phoneNumber != null) data['phone_number'] = phoneNumber;
    if (alternatePhone != null) data['alternate_phone'] = alternatePhone;
    if (vehicleNumber != null) data['vehicle_number'] = vehicleNumber;

    final response = await _apiService.patchMultipart(
      ApiConstants.agentProfile,
      data: data,
      file: profilePhoto,
      fileField: 'profile_photo',
    );
    return AgentProfile.fromJson(response.data['data']);
  }

  Future<Map<String, dynamic>> updateStatus({
    required String status,
    double? latitude,
    double? longitude,
  }) async {
    final response = await _apiService.patch(
      ApiConstants.agentStatus,
      data: {
        'status': status,
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
      },
    );
    return response.data;
  }

  Future<void> sendLocation({
    int? assignmentId,
    required List<Map<String, dynamic>> locations,
  }) async {
    await _apiService.post(
      ApiConstants.agentLocation,
      data: {
        if (assignmentId != null) 'assignment_id': assignmentId,
        'locations': locations,
      },
    );
  }

  // Orders — uses recommended /delivery/mobile/orders/?type=active contract
  Future<Map<String, dynamic>> getOrders({String? status, String? date}) async {
    final response = await _apiService.get(
      ApiConstants.orders,
      queryParameters: {
        'type': 'active',
        if (status != null) 'status': status,
        if (date != null) 'date': date,
      },
    );
    final responseData = response.data;
    if (responseData is Map<String, dynamic>) {
      if (responseData['data'] is Map<String, dynamic>) {
        return responseData['data'];
      } else if (responseData['data'] is List) {
        return {'orders': responseData['data']};
      }
      return responseData;
    }
    return {'orders': []};
  }

  Future<List<DeliveryOrder>> getPendingOrders() async {
    final response = await _apiService.get(ApiConstants.pendingOrders);
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((e) => DeliveryOrder.fromJson(e)).toList();
  }

  Future<List<DeliveryOrder>> getOrderHistory({
    String? status,
    String? startDate,
    String? endDate,
    String? startTime,
    String? endTime,
    bool? all,
    int? limit,
  }) async {
    final response = await _apiService.get(
      ApiConstants.orderHistory,
      queryParameters: {
        if (status != null) 'status': status,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (startTime != null) 'start_time': startTime,
        if (endTime != null) 'end_time': endTime,
        if (all != null) 'all': all.toString(),
        if (limit != null) 'limit': limit.toString(),
      },
    );
    final List<dynamic> data =
        response.data['data']?['orders'] ?? response.data['data'] ?? [];
    final List<DeliveryOrder> orders =
        data.map((e) => DeliveryOrder.fromJson(e)).toList();
    return orders;
  }

  Future<DeliveryOrderDetail> getOrderDetail(int id) async {
    final response = await _apiService.get(ApiConstants.orderDetail(id));
    return DeliveryOrderDetail.fromJson(response.data['data']);
  }

  Future<AssignedCustomersData> getAssignedCustomers({
    String? search,
    String? paymentType,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConstants.assignedCustomers,
        queryParameters: {
          if (search != null) 'search': search,
          if (paymentType != null) 'payment_type': paymentType,
        },
      );
      final data = AssignedCustomersData.fromJson(response.data);
      return _filterAssignedCustomersFallback(
        data,
        search: search,
        paymentType: paymentType,
      );
    } on DioException catch (e) {
      if (!_canUseCustomerFallback(e)) rethrow;
      final fallback = await _getAssignedCustomersFromOrders();
      return _filterAssignedCustomersFallback(
        fallback,
        search: search,
        paymentType: paymentType,
      );
    }
  }

  Future<CustomerDeliveryDetail> getAssignedCustomerDetail(
    int id, {
    AssignedCustomer? initialCustomer,
  }) async {
    try {
      final response =
          await _apiService.get(ApiConstants.assignedCustomerDetail(id));
      return CustomerDeliveryDetail.fromJson(response.data);
    } on DioException catch (e) {
      if (!_canUseCustomerFallback(e)) rethrow;
      final orders = await _getAssignedOrderSnapshot();
      var customer = initialCustomer;
      if (customer == null) {
        for (final item in AssignedCustomersData.fromOrders(orders).customers) {
          if (item.id == id) {
            customer = item;
            break;
          }
        }
      }
      if (customer == null) rethrow;
      return CustomerDeliveryDetail.fromCustomerAndOrders(customer, orders);
    }
  }

  Future<Map<String, dynamic>> acceptOrder(int id,
      {double? latitude, double? longitude}) async {
    final response = await _apiService.post(
      ApiConstants.acceptOrder(id),
      data: {
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> rejectOrder(int id,
      {required String reason, double? latitude, double? longitude}) async {
    final response = await _apiService.post(
      ApiConstants.rejectOrder(id),
      data: {
        'reason': reason,
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> pickupOrder(
    int id, {
    double? latitude,
    double? longitude,
    String? notes,
    File? photo,
  }) async {
    final response = await _apiService.postMultipart(
      ApiConstants.pickupOrder(id),
      data: {
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
        if (notes != null) 'notes': notes,
      },
      file: photo,
      fileField: 'photo',
    );
    return response.data;
  }

  // Unified status update via /delivery/mobile/orders/{id}/status/
  Future<Map<String, dynamic>> updateOrderStatus(
    int id, {
    required String status,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    final response = await _apiService.post(
      ApiConstants.orderStatus(id),
      data: {
        'status': status,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (notes != null) 'notes': notes,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> startTransit(int id,
          {double? latitude, double? longitude}) =>
      updateOrderStatus(id,
          status: 'OUT_FOR_DELIVERY', latitude: latitude, longitude: longitude);

  Future<Map<String, dynamic>> markArrived(int id,
          {double? latitude, double? longitude}) =>
      updateOrderStatus(id,
          status: 'ARRIVED', latitude: latitude, longitude: longitude);

  Future<Map<String, dynamic>> completeDelivery(
    int id, {
    double? latitude,
    double? longitude,
    String? recipientName,
    String? deliveryNotes,
    double? codCollected,
    File? deliveryPhoto,
    File? signatureImage,
    DateTime? deliveredAt,
  }) async {
    final deliveryTimestamp = (deliveredAt ?? DateTime.now()).toUtc();
    final payload = {
      'delivered_at': deliveryTimestamp.toIso8601String(),
      if (latitude != null) 'latitude': latitude.toString(),
      if (longitude != null) 'longitude': longitude.toString(),
      if (recipientName != null) 'recipient_name': recipientName,
      if (deliveryNotes != null) 'delivery_notes': deliveryNotes,
      if (codCollected != null)
        'collected_amount': codCollected.toStringAsFixed(2),
    };

    if (deliveryPhoto == null && signatureImage == null) {
      final response = await _apiService.post(
        ApiConstants.completeOrder(id),
        data: payload,
      );
      return response.data;
    }

    try {
      final response = await _apiService.postMultipart(
        ApiConstants.completeOrder(id),
        data: payload,
        file: deliveryPhoto,
        fileField: 'delivery_photo',
        signatureFile: signatureImage,
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode != 415) rethrow;
      final response = await _apiService.post(
        ApiConstants.completeOrder(id),
        data: payload,
      );
      return response.data;
    }
  }

  Future<Map<String, dynamic>> failDelivery(
    int id, {
    required String failureReason,
    String? failureNotes,
    double? latitude,
    double? longitude,
  }) async {
    final response = await _apiService.post(
      ApiConstants.failOrder(id),
      data: {
        'failure_reason': failureReason,
        if (failureNotes != null) 'failure_notes': failureNotes,
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> collectCod(
    int id, {
    required double amountCollected,
    String? paymentMethod,
    String? notes,
  }) async {
    final response = await _apiService.post(
      ApiConstants.codCollect(id),
      data: {
        'amount_collected': amountCollected.toString(),
        if (paymentMethod != null) 'payment_method': paymentMethod,
        if (notes != null) 'notes': notes,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateCustomerLocation(
    int id, {
    required double latitude,
    required double longitude,
    String? address,
    String? city,
    String? area,
    String? notes,
  }) async {
    final response = await _apiService.post(
      ApiConstants.updateCustomerLocation(id),
      data: {
        'latitude': latitude,
        'longitude': longitude,
        if (address != null) ...{
          'address': address,
          'street_address': address,
        },
        if (city != null) 'city': city,
        if (area != null) 'area': area,
        if (notes != null) 'notes': notes,
      },
    );
    return response.data;
  }

  // Earnings & Statistics
  Future<EarningsData> getEarnings(
      {String? period, String? startDate, String? endDate}) async {
    final response = await _apiService.get(
      ApiConstants.agentEarnings,
      queryParameters: {
        if (period != null) 'period': period,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      },
    );
    return EarningsData.fromJson(response.data['data']);
  }

  Future<StatisticsData> getStatistics() async {
    final response = await _apiService.get(ApiConstants.agentStatistics);
    return StatisticsData.fromJson(response.data['data']);
  }

  // Dashboard
  Future<DashboardData> getDashboard({
    String? period,
    String? startDate,
    String? endDate,
  }) async {
    final response = await _apiService.get(
      ApiConstants.agentDashboard,
      queryParameters: {
        if (period != null) 'period': period,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      },
    );
    return DashboardData.fromJson(response.data['data']);
  }

  Future<MobileDeliverySummary> getMobileSummary({
    String? date,
    String? startDate,
    String? endDate,
  }) async {
    final response = await _apiService.get(
      ApiConstants.mobileSummary,
      queryParameters: {
        if (date != null) 'date': date,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      },
    );
    return MobileDeliverySummary.fromJson(response.data['data']);
  }

  bool _canUseCustomerFallback(DioException e) {
    return e.response?.statusCode == 404 || e.response?.statusCode == 405;
  }

  Future<AssignedCustomersData> _getAssignedCustomersFromOrders() async {
    return AssignedCustomersData.fromOrders(await _getAssignedOrderSnapshot());
  }

  Future<List<DeliveryOrder>> _getAssignedOrderSnapshot() async {
    final activeData = await getOrders();
    final activeJson =
        activeData['active_orders'] ?? activeData['orders'] ?? <dynamic>[];
    final activeOrders = activeJson is List
        ? activeJson.map((item) => DeliveryOrder.fromJson(item)).toList()
        : <DeliveryOrder>[];

    final deliveredOrders = await getOrderHistory(
      status: 'DELIVERED',
      all: true,
      limit: 100,
    );
    final failedOrders = await getOrderHistory(
      status: 'FAILED',
      all: true,
      limit: 100,
    );

    return [...activeOrders, ...deliveredOrders, ...failedOrders];
  }

  AssignedCustomersData _filterAssignedCustomersFallback(
    AssignedCustomersData data, {
    String? search,
    String? paymentType,
  }) {
    var customers = data.customers;
    final normalizedSearch = search?.trim().toLowerCase();
    if (normalizedSearch != null && normalizedSearch.isNotEmpty) {
      customers = customers.where((customer) {
        return customer.name.toLowerCase().contains(normalizedSearch) ||
            customer.mobile.toLowerCase().contains(normalizedSearch) ||
            customer.displayLocation.toLowerCase().contains(normalizedSearch);
      }).toList();
    }
    if (paymentType == 'credit') {
      customers = customers.where((customer) => customer.hasCredit).toList();
    } else if (paymentType == 'cod') {
      customers = customers.where((customer) => customer.hasCod).toList();
    }
    _sortAssignedCustomers(customers, paymentType: paymentType);
    return AssignedCustomersData(
      customers: customers,
      summary: AssignedCustomersSummary.fromCustomers(customers),
      total: customers.length,
      hasNext: false,
    );
  }

  void _sortAssignedCustomers(
    List<AssignedCustomer> customers, {
    String? paymentType,
  }) {
    customers.sort((a, b) {
      if (paymentType == 'credit') {
        final creditCompare = b.creditAmount.compareTo(a.creditAmount);
        if (creditCompare != 0) return creditCompare;
        final remainingCompare =
            b.wallet.remaining.compareTo(a.wallet.remaining);
        if (remainingCompare != 0) return remainingCompare;
      } else if (paymentType == 'cod') {
        final codDueCompare = b.codDue.compareTo(a.codDue);
        if (codDueCompare != 0) return codDueCompare;
        final codCompare = b.codAmount.compareTo(a.codAmount);
        if (codCompare != 0) return codCompare;
      } else {
        final riskCompare = b.wallet.remaining.compareTo(a.wallet.remaining);
        if (riskCompare != 0) return riskCompare;
        final activeCompare = b.activeOrders.compareTo(a.activeOrders);
        if (activeCompare != 0) return activeCompare;
      }

      final aDate = a.lastOrderAt;
      final bDate = b.lastOrderAt;
      if (aDate == null && bDate == null) return a.name.compareTo(b.name);
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
  }
}
