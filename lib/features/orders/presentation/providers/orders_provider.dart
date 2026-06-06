import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/models.dart';

String _extractErrorMessage(dynamic e, String defaultMessage) {
  if (e is DioException) {
    final responseData = e.response?.data;
    if (responseData is Map) {
      return responseData['error'] ?? responseData['message'] ?? defaultMessage;
    }
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Please check your internet.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection.';
    }
  }
  return defaultMessage;
}

String? _responseStatus(Map<String, dynamic> response) {
  final dataMap = response['data'] is Map ? response['data'] as Map : null;
  return (dataMap?['new_status'] ??
          dataMap?['status'] ??
          response['new_status'] ??
          response['status'])
      ?.toString()
      .toUpperCase();
}

String? _responseMessage(Map<String, dynamic> response, String defaultMessage) {
  return (response['error'] ?? response['message'] ?? defaultMessage)
      ?.toString();
}

bool _isExpectedStatusResponse(
  Map<String, dynamic> response,
  String expectedStatus,
) {
  final status = _responseStatus(response);
  return response['success'] != false && status == expectedStatus;
}

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  return OrdersNotifier(ref.read(deliveryServiceProvider));
});

final pendingOrdersProvider =
    StateNotifierProvider<PendingOrdersNotifier, PendingOrdersState>((ref) {
  return PendingOrdersNotifier(ref.read(deliveryServiceProvider));
});

final orderHistoryProvider =
    StateNotifierProvider<OrderHistoryNotifier, OrderHistoryState>((ref) {
  return OrderHistoryNotifier(ref.read(deliveryServiceProvider));
});

final orderDetailProvider =
    StateNotifierProvider.family<OrderDetailNotifier, OrderDetailState, int>(
        (ref, orderId) {
  return OrderDetailNotifier(ref.read(deliveryServiceProvider), orderId);
});

// Orders State
class OrdersState {
  final bool isLoading;
  final List<DeliveryOrder> activeOrders;
  final int completedToday;
  final int pendingCount;
  final String? error;

  OrdersState({
    this.isLoading = false,
    this.activeOrders = const [],
    this.completedToday = 0,
    this.pendingCount = 0,
    this.error,
  });

  OrdersState copyWith({
    bool? isLoading,
    List<DeliveryOrder>? activeOrders,
    int? completedToday,
    int? pendingCount,
    String? error,
  }) {
    return OrdersState(
      isLoading: isLoading ?? this.isLoading,
      activeOrders: activeOrders ?? this.activeOrders,
      completedToday: completedToday ?? this.completedToday,
      pendingCount: pendingCount ?? this.pendingCount,
      error: error,
    );
  }
}

class OrdersNotifier extends StateNotifier<OrdersState> {
  final dynamic _deliveryService;

  OrdersNotifier(this._deliveryService) : super(OrdersState());

  Future<void> loadOrders({String? status, String? date}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _deliveryService.getOrders(status: status, date: date);
      // Handle different API response structures
      List<dynamic> ordersJson = [];
      if (data['active_orders'] != null) {
        ordersJson = data['active_orders'] as List<dynamic>;
      } else if (data['orders'] != null) {
        ordersJson = data['orders'] as List<dynamic>;
      } else if (data is List) {
        ordersJson = data;
      }
      final orders = ordersJson.map((e) => DeliveryOrder.fromJson(e)).toList();
      // Sort by scheduled delivery time (earliest first)
      orders.sort((a, b) {
        final aTime = a.scheduledDeliveryTime;
        final bTime = b.scheduledDeliveryTime;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1; // null times go to the end
        if (bTime == null) return -1;
        return aTime.compareTo(bTime);
      });
      state = state.copyWith(
        isLoading: false,
        activeOrders: orders,
        completedToday:
            data['completed_today'] ?? data['stats']?['completed_today'] ?? 0,
        pendingCount:
            data['pending_count'] ?? data['stats']?['pending_count'] ?? 0,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load orders');
    }
  }

  void clearOrders() {
    state = OrdersState();
  }
}

// Pending Orders State
class PendingOrdersState {
  final bool isLoading;
  final List<DeliveryOrder> orders;
  final String? error;

  PendingOrdersState({
    this.isLoading = false,
    this.orders = const [],
    this.error,
  });

  PendingOrdersState copyWith({
    bool? isLoading,
    List<DeliveryOrder>? orders,
    String? error,
  }) {
    return PendingOrdersState(
      isLoading: isLoading ?? this.isLoading,
      orders: orders ?? this.orders,
      error: error,
    );
  }
}

class PendingOrdersNotifier extends StateNotifier<PendingOrdersState> {
  final dynamic _deliveryService;

  PendingOrdersNotifier(this._deliveryService) : super(PendingOrdersState());

  Future<void> loadPendingOrders() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final orders = await _deliveryService.getPendingOrders();
      state = state.copyWith(isLoading: false, orders: orders);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Failed to load pending orders');
    }
  }

  void removeOrder(int orderId) {
    final updatedOrders = state.orders.where((o) => o.id != orderId).toList();
    state = state.copyWith(orders: updatedOrders);
  }
}

// Order History State
enum HistoryFilter { today, week, month, all, custom }

class OrderHistoryState {
  final bool isLoading;
  final List<DeliveryOrder> completedOrders;
  final List<DeliveryOrder> failedOrders;
  final HistoryFilter filter;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? error;

  OrderHistoryState({
    this.isLoading = false,
    this.completedOrders = const [],
    this.failedOrders = const [],
    this.filter = HistoryFilter.today,
    this.startDate,
    this.endDate,
    this.error,
  });

  OrderHistoryState copyWith({
    bool? isLoading,
    List<DeliveryOrder>? completedOrders,
    List<DeliveryOrder>? failedOrders,
    HistoryFilter? filter,
    DateTime? startDate,
    DateTime? endDate,
    String? error,
  }) {
    return OrderHistoryState(
      isLoading: isLoading ?? this.isLoading,
      completedOrders: completedOrders ?? this.completedOrders,
      failedOrders: failedOrders ?? this.failedOrders,
      filter: filter ?? this.filter,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      error: error,
    );
  }
}

class OrderHistoryNotifier extends StateNotifier<OrderHistoryState> {
  final dynamic _deliveryService;

  OrderHistoryNotifier(this._deliveryService) : super(OrderHistoryState());

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  DateTime _historySortDate(DeliveryOrder order) {
    return order.deliveredAt ?? order.scheduledDeliveryTime ?? order.createdAt;
  }

  Future<void> loadHistory(
      {HistoryFilter? filter, DateTime? startDate, DateTime? endDate}) async {
    state = state.copyWith(isLoading: true, error: null);

    final newFilter = filter ?? state.filter;
    DateTime? start = startDate;
    DateTime? end = endDate;
    bool? all;

    // Calculate date range based on filter
    final now = DateTime.now();
    switch (newFilter) {
      case HistoryFilter.today:
        start = now;
        end = now;
        break;
      case HistoryFilter.week:
        start = now.subtract(const Duration(days: 7));
        end = now;
        break;
      case HistoryFilter.month:
        start = DateTime(now.year, now.month - 1, now.day);
        end = now;
        break;
      case HistoryFilter.all:
        all = true;
        break;
      case HistoryFilter.custom:
        start = startDate ?? state.startDate;
        end = endDate ?? state.endDate;
        break;
    }

    try {
      // Load completed and failed orders
      final completed = await _deliveryService.getOrderHistory(
        status: 'DELIVERED',
        startDate: start != null ? _formatDate(start) : null,
        endDate: end != null ? _formatDate(end) : null,
        all: all,
        limit: 50,
      );
      final failed = await _deliveryService.getOrderHistory(
        status: 'FAILED',
        startDate: start != null ? _formatDate(start) : null,
        endDate: end != null ? _formatDate(end) : null,
        all: all,
        limit: 50,
      );
      // Sort history newest first; riders usually need the most recent result.
      completed.sort((DeliveryOrder a, DeliveryOrder b) {
        return _historySortDate(b).compareTo(_historySortDate(a));
      });
      failed.sort((DeliveryOrder a, DeliveryOrder b) {
        return _historySortDate(b).compareTo(_historySortDate(a));
      });

      state = state.copyWith(
        isLoading: false,
        completedOrders: completed,
        failedOrders: failed,
        filter: newFilter,
        startDate: start,
        endDate: end,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e, 'Failed to load order history'),
      );
    }
  }

  void setFilter(HistoryFilter filter) {
    loadHistory(filter: filter);
  }

  void setCustomDateRange(DateTime start, DateTime end) {
    loadHistory(filter: HistoryFilter.custom, startDate: start, endDate: end);
  }
}

// Order Detail State
class OrderDetailState {
  final bool isLoading;
  final bool isActionLoading;
  final DeliveryOrderDetail? order;
  final String? error;
  final String? actionError;

  OrderDetailState({
    this.isLoading = false,
    this.isActionLoading = false,
    this.order,
    this.error,
    this.actionError,
  });

  OrderDetailState copyWith({
    bool? isLoading,
    bool? isActionLoading,
    DeliveryOrderDetail? order,
    String? error,
    String? actionError,
  }) {
    return OrderDetailState(
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      order: order ?? this.order,
      error: error,
      actionError: actionError,
    );
  }
}

class OrderDetailNotifier extends StateNotifier<OrderDetailState> {
  final dynamic _deliveryService;
  final int orderId;

  OrderDetailNotifier(this._deliveryService, this.orderId)
      : super(OrderDetailState());

  Future<void> loadOrderDetail() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final order = await _deliveryService.getOrderDetail(orderId);
      state = state.copyWith(isLoading: false, order: order);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Failed to load order details');
    }
  }

  Future<bool> acceptOrder({double? latitude, double? longitude}) async {
    if (state.isActionLoading) return false;
    state = state.copyWith(isActionLoading: true, actionError: null);
    try {
      await _deliveryService.acceptOrder(orderId,
          latitude: latitude, longitude: longitude);
      await loadOrderDetail();
      state = state.copyWith(isActionLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
          isActionLoading: false,
          actionError: _extractErrorMessage(e, 'Failed to accept order'));
      return false;
    }
  }

  Future<bool> rejectOrder(String reason,
      {double? latitude, double? longitude}) async {
    if (state.isActionLoading) return false;
    state = state.copyWith(isActionLoading: true, actionError: null);
    try {
      await _deliveryService.rejectOrder(orderId,
          reason: reason, latitude: latitude, longitude: longitude);
      state = state.copyWith(isActionLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
          isActionLoading: false,
          actionError: _extractErrorMessage(e, 'Failed to reject order'));
      return false;
    }
  }

  Future<bool> pickupOrder(
      {double? latitude, double? longitude, String? notes, File? photo}) async {
    if (state.isActionLoading) return false;
    state = state.copyWith(isActionLoading: true, actionError: null);
    try {
      await _deliveryService.pickupOrder(orderId,
          latitude: latitude, longitude: longitude, notes: notes, photo: photo);
      await loadOrderDetail();
      state = state.copyWith(isActionLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
          isActionLoading: false,
          actionError: _extractErrorMessage(e, 'Failed to pickup order'));
      return false;
    }
  }

  Future<bool> startTransit({double? latitude, double? longitude}) async {
    if (state.isActionLoading) return false;
    state = state.copyWith(isActionLoading: true, actionError: null);
    try {
      final response = await _deliveryService.startTransit(orderId,
          latitude: latitude, longitude: longitude);
      if (!_isExpectedStatusResponse(response, 'OUT_FOR_DELIVERY')) {
        state = state.copyWith(
          isActionLoading: false,
          actionError: _responseMessage(
              response, 'Order did not transition to OUT_FOR_DELIVERY'),
        );
        await loadOrderDetail();
        return false;
      }
      await loadOrderDetail();
      state = state.copyWith(isActionLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
          isActionLoading: false,
          actionError: _extractErrorMessage(e, 'Failed to start delivery'));
      return false;
    }
  }

  Future<bool> markArrived({double? latitude, double? longitude}) async {
    if (state.isActionLoading) return false;
    state = state.copyWith(isActionLoading: true, actionError: null);
    try {
      final response = await _deliveryService.markArrived(orderId,
          latitude: latitude, longitude: longitude);
      if (!_isExpectedStatusResponse(response, 'ARRIVED')) {
        state = state.copyWith(
          isActionLoading: false,
          actionError:
              _responseMessage(response, 'Order did not transition to ARRIVED'),
        );
        await loadOrderDetail();
        return false;
      }
      await loadOrderDetail();
      state = state.copyWith(isActionLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
          isActionLoading: false,
          actionError: _extractErrorMessage(e, 'Failed to mark as arrived'));
      return false;
    }
  }

  Future<bool> completeDelivery({
    double? latitude,
    double? longitude,
    String? recipientName,
    String? deliveryNotes,
    double? codCollected,
    File? deliveryPhoto,
    File? signatureImage,
  }) async {
    if (state.isActionLoading) return false;
    state = state.copyWith(isActionLoading: true, actionError: null);

    final currentStatus = state.order?.status.toUpperCase() ?? '';

    // Auto-chain intermediate transitions. Each step is its own try/catch so
    // we can surface which step the backend rejected.
    // Flow: PICKED_UP -> IN_TRANSIT -> ARRIVED -> DELIVERED
    if (currentStatus == 'PICKED_UP') {
      try {
        final response = await _deliveryService.startTransit(orderId,
            latitude: latitude, longitude: longitude);
        if (!_isExpectedStatusResponse(response, 'OUT_FOR_DELIVERY')) {
          state = state.copyWith(
            isActionLoading: false,
            actionError: _responseMessage(
                response, 'Order did not transition to OUT_FOR_DELIVERY'),
          );
          await loadOrderDetail();
          return false;
        }
      } catch (e) {
        state = state.copyWith(
            isActionLoading: false,
            actionError: _extractErrorMessage(
                e, 'Failed to start delivery (in-transit step)'));
        return false;
      }
      try {
        final response = await _deliveryService.markArrived(orderId,
            latitude: latitude, longitude: longitude);
        if (!_isExpectedStatusResponse(response, 'ARRIVED')) {
          state = state.copyWith(
            isActionLoading: false,
            actionError: _responseMessage(
                response, 'Order did not transition to ARRIVED'),
          );
          await loadOrderDetail();
          return false;
        }
      } catch (e) {
        state = state.copyWith(
            isActionLoading: false,
            actionError: _extractErrorMessage(e, 'Failed to mark arrived'));
        return false;
      }
    } else if (currentStatus == 'IN_TRANSIT' ||
        currentStatus == 'OUT_FOR_DELIVERY') {
      try {
        final response = await _deliveryService.markArrived(orderId,
            latitude: latitude, longitude: longitude);
        if (!_isExpectedStatusResponse(response, 'ARRIVED')) {
          state = state.copyWith(
            isActionLoading: false,
            actionError: _responseMessage(
                response, 'Order did not transition to ARRIVED'),
          );
          await loadOrderDetail();
          return false;
        }
      } catch (e) {
        state = state.copyWith(
            isActionLoading: false,
            actionError: _extractErrorMessage(e, 'Failed to mark arrived'));
        return false;
      }
    }

    // Final /deliver/ call — inspect response body, don't trust 2xx alone.
    try {
      final response = await _deliveryService.completeDelivery(
        orderId,
        latitude: latitude,
        longitude: longitude,
        recipientName: recipientName,
        deliveryNotes: deliveryNotes,
        codCollected: codCollected,
        deliveryPhoto: deliveryPhoto,
        signatureImage: signatureImage,
      );
      if (!_isExpectedStatusResponse(response, 'DELIVERED')) {
        final returnedStatus = _responseStatus(response);
        state = state.copyWith(
          isActionLoading: false,
          actionError: _responseMessage(
            response,
            'Order did not transition to DELIVERED (got ${returnedStatus ?? 'unknown'})',
          ),
        );
        await loadOrderDetail();
        return false;
      }
      await loadOrderDetail();
      state = state.copyWith(isActionLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
          isActionLoading: false,
          actionError: _extractErrorMessage(e, 'Failed to complete delivery'));
      return false;
    }
  }

  Future<bool> failDelivery({
    required String failureReason,
    String? failureNotes,
    double? latitude,
    double? longitude,
  }) async {
    if (state.isActionLoading) return false;
    state = state.copyWith(isActionLoading: true, actionError: null);

    final currentStatus = state.order?.status.toUpperCase() ?? '';

    // Auto-chain intermediate transitions, surfacing whichever step the
    // backend rejects. Flow: PICKED_UP -> IN_TRANSIT -> ARRIVED -> FAILED
    if (currentStatus == 'PICKED_UP') {
      try {
        final response = await _deliveryService.startTransit(orderId,
            latitude: latitude, longitude: longitude);
        if (!_isExpectedStatusResponse(response, 'OUT_FOR_DELIVERY')) {
          state = state.copyWith(
            isActionLoading: false,
            actionError: _responseMessage(
                response, 'Order did not transition to OUT_FOR_DELIVERY'),
          );
          await loadOrderDetail();
          return false;
        }
      } catch (e) {
        state = state.copyWith(
            isActionLoading: false,
            actionError: _extractErrorMessage(
                e, 'Failed to start delivery (in-transit step)'));
        return false;
      }
      try {
        final response = await _deliveryService.markArrived(orderId,
            latitude: latitude, longitude: longitude);
        if (!_isExpectedStatusResponse(response, 'ARRIVED')) {
          state = state.copyWith(
            isActionLoading: false,
            actionError: _responseMessage(
                response, 'Order did not transition to ARRIVED'),
          );
          await loadOrderDetail();
          return false;
        }
      } catch (e) {
        state = state.copyWith(
            isActionLoading: false,
            actionError: _extractErrorMessage(e, 'Failed to mark arrived'));
        return false;
      }
    } else if (currentStatus == 'IN_TRANSIT' ||
        currentStatus == 'OUT_FOR_DELIVERY') {
      try {
        final response = await _deliveryService.markArrived(orderId,
            latitude: latitude, longitude: longitude);
        if (!_isExpectedStatusResponse(response, 'ARRIVED')) {
          state = state.copyWith(
            isActionLoading: false,
            actionError: _responseMessage(
                response, 'Order did not transition to ARRIVED'),
          );
          await loadOrderDetail();
          return false;
        }
      } catch (e) {
        state = state.copyWith(
            isActionLoading: false,
            actionError: _extractErrorMessage(e, 'Failed to mark arrived'));
        return false;
      }
    }

    try {
      final response = await _deliveryService.failDelivery(
        orderId,
        failureReason: failureReason,
        failureNotes: failureNotes,
        latitude: latitude,
        longitude: longitude,
      );
      if (!_isExpectedStatusResponse(response, 'FAILED')) {
        final returnedStatus = _responseStatus(response);
        state = state.copyWith(
          isActionLoading: false,
          actionError: _responseMessage(
            response,
            'Order did not transition to FAILED (got ${returnedStatus ?? 'unknown'})',
          ),
        );
        await loadOrderDetail();
        return false;
      }
      await loadOrderDetail();
      state = state.copyWith(isActionLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
          isActionLoading: false,
          actionError:
              _extractErrorMessage(e, 'Failed to mark delivery as failed'));
      return false;
    }
  }

  Future<bool> updateCustomerLocation({
    required double latitude,
    required double longitude,
    String? address,
    String? notes,
  }) async {
    if (state.isActionLoading) return false;
    state = state.copyWith(isActionLoading: true, actionError: null);
    try {
      await _deliveryService.updateCustomerLocation(
        orderId,
        latitude: latitude,
        longitude: longitude,
        address: address,
        notes: notes,
      );
      await loadOrderDetail();
      state = state.copyWith(isActionLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
          isActionLoading: false,
          actionError:
              _extractErrorMessage(e, 'Failed to update customer location'));
      return false;
    }
  }
}
