import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/models.dart';

final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  return OrdersNotifier(ref.read(deliveryServiceProvider));
});

final pendingOrdersProvider = StateNotifierProvider<PendingOrdersNotifier, PendingOrdersState>((ref) {
  return PendingOrdersNotifier(ref.read(deliveryServiceProvider));
});

final orderDetailProvider = StateNotifierProvider.family<OrderDetailNotifier, OrderDetailState, int>((ref, orderId) {
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
      final List<dynamic> ordersJson = data['active_orders'] ?? [];
      final orders = ordersJson.map((e) => DeliveryOrder.fromJson(e)).toList();
      state = state.copyWith(
        isLoading: false,
        activeOrders: orders,
        completedToday: data['completed_today'] ?? 0,
        pendingCount: data['pending_count'] ?? 0,
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
      state = state.copyWith(isLoading: false, error: 'Failed to load pending orders');
    }
  }

  void removeOrder(int orderId) {
    final updatedOrders = state.orders.where((o) => o.id != orderId).toList();
    state = state.copyWith(orders: updatedOrders);
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

  OrderDetailNotifier(this._deliveryService, this.orderId) : super(OrderDetailState());

  Future<void> loadOrderDetail() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final order = await _deliveryService.getOrderDetail(orderId);
      state = state.copyWith(isLoading: false, order: order);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load order details');
    }
  }

  Future<bool> acceptOrder({double? latitude, double? longitude}) async {
    state = state.copyWith(isActionLoading: true, actionError: null);
    try {
      await _deliveryService.acceptOrder(orderId, latitude: latitude, longitude: longitude);
      await loadOrderDetail();
      state = state.copyWith(isActionLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isActionLoading: false, actionError: 'Failed to accept order');
      return false;
    }
  }

  Future<bool> rejectOrder(String reason, {double? latitude, double? longitude}) async {
    state = state.copyWith(isActionLoading: true, actionError: null);
    try {
      await _deliveryService.rejectOrder(orderId, reason: reason, latitude: latitude, longitude: longitude);
      state = state.copyWith(isActionLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isActionLoading: false, actionError: 'Failed to reject order');
      return false;
    }
  }

  Future<bool> pickupOrder({double? latitude, double? longitude, String? notes, File? photo}) async {
    state = state.copyWith(isActionLoading: true, actionError: null);
    try {
      await _deliveryService.pickupOrder(orderId, latitude: latitude, longitude: longitude, notes: notes, photo: photo);
      await loadOrderDetail();
      state = state.copyWith(isActionLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isActionLoading: false, actionError: 'Failed to pickup order');
      return false;
    }
  }

  Future<bool> startTransit({double? latitude, double? longitude}) async {
    state = state.copyWith(isActionLoading: true, actionError: null);
    try {
      await _deliveryService.startTransit(orderId, latitude: latitude, longitude: longitude);
      await loadOrderDetail();
      state = state.copyWith(isActionLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isActionLoading: false, actionError: 'Failed to start transit');
      return false;
    }
  }

  Future<bool> markArrived({double? latitude, double? longitude}) async {
    state = state.copyWith(isActionLoading: true, actionError: null);
    try {
      await _deliveryService.markArrived(orderId, latitude: latitude, longitude: longitude);
      await loadOrderDetail();
      state = state.copyWith(isActionLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isActionLoading: false, actionError: 'Failed to mark as arrived');
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
    state = state.copyWith(isActionLoading: true, actionError: null);
    try {
      await _deliveryService.completeDelivery(
        orderId,
        latitude: latitude,
        longitude: longitude,
        recipientName: recipientName,
        deliveryNotes: deliveryNotes,
        codCollected: codCollected,
        deliveryPhoto: deliveryPhoto,
        signatureImage: signatureImage,
      );
      await loadOrderDetail();
      state = state.copyWith(isActionLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isActionLoading: false, actionError: 'Failed to complete delivery');
      return false;
    }
  }

  Future<bool> failDelivery({
    required String failureReason,
    String? failureNotes,
    double? latitude,
    double? longitude,
  }) async {
    state = state.copyWith(isActionLoading: true, actionError: null);
    try {
      await _deliveryService.failDelivery(
        orderId,
        failureReason: failureReason,
        failureNotes: failureNotes,
        latitude: latitude,
        longitude: longitude,
      );
      await loadOrderDetail();
      state = state.copyWith(isActionLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isActionLoading: false, actionError: 'Failed to mark delivery as failed');
      return false;
    }
  }
}
