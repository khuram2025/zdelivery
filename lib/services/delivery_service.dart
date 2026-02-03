import 'dart:io';
import '../core/constants/api_constants.dart';
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

  // Orders
  Future<Map<String, dynamic>> getOrders({String? status, String? date}) async {
    final response = await _apiService.get(
      ApiConstants.orders,
      queryParameters: {
        if (status != null) 'status': status,
        if (date != null) 'date': date,
      },
    );
    final responseData = response.data;
    // Handle different API response structures
    if (responseData is Map<String, dynamic>) {
      if (responseData['data'] is Map<String, dynamic>) {
        return responseData['data'];
      } else if (responseData['data'] is List) {
        // If data is directly a list of orders
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
    final List<dynamic> data = response.data['data']?['orders'] ?? response.data['data'] ?? [];
    return data.map((e) => DeliveryOrder.fromJson(e)).toList();
  }

  Future<DeliveryOrderDetail> getOrderDetail(int id) async {
    final response = await _apiService.get(ApiConstants.orderDetail(id));
    return DeliveryOrderDetail.fromJson(response.data['data']);
  }

  Future<Map<String, dynamic>> acceptOrder(int id, {double? latitude, double? longitude}) async {
    final response = await _apiService.post(
      ApiConstants.acceptOrder(id),
      data: {
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> rejectOrder(int id, {required String reason, double? latitude, double? longitude}) async {
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

  Future<Map<String, dynamic>> startTransit(int id, {double? latitude, double? longitude}) async {
    final response = await _apiService.post(
      ApiConstants.inTransitOrder(id),
      data: {
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> markArrived(int id, {double? latitude, double? longitude}) async {
    final response = await _apiService.post(
      ApiConstants.arrivedOrder(id),
      data: {
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> completeDelivery(
    int id, {
    double? latitude,
    double? longitude,
    String? recipientName,
    String? deliveryNotes,
    double? codCollected,
    File? deliveryPhoto,
    File? signatureImage,
  }) async {
    final response = await _apiService.postMultipart(
      ApiConstants.deliverOrder(id),
      data: {
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
        if (recipientName != null) 'recipient_name': recipientName,
        if (deliveryNotes != null) 'delivery_notes': deliveryNotes,
        if (codCollected != null) 'cod_collected': codCollected.toString(),
      },
      file: deliveryPhoto,
      fileField: 'delivery_photo',
      signatureFile: signatureImage,
    );
    return response.data;
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
    String? notes,
  }) async {
    final response = await _apiService.post(
      ApiConstants.updateCustomerLocation(id),
      data: {
        'latitude': latitude,
        'longitude': longitude,
        if (address != null) 'address': address,
        if (notes != null) 'notes': notes,
      },
    );
    return response.data;
  }

  // Earnings & Statistics
  Future<EarningsData> getEarnings({String? period, String? startDate, String? endDate}) async {
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
}
