import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../orders/data/models.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/models.dart';

const _notificationsStorageKey = 'delivery_notifications';
const _notificationSeenEventsKey = 'delivery_notification_seen_events';
const _maxStoredNotifications = 80;

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final notifier = NotificationsNotifier(ref.read(deliveryServiceProvider));
  notifier.load();
  ref.onDispose(notifier.dispose);
  return notifier;
});

class NotificationsState {
  final bool isLoading;
  final bool isChecking;
  final bool monitorStarted;
  final List<DeliveryNotification> notifications;
  final String? error;
  final DateTime? lastCheckedAt;

  const NotificationsState({
    this.isLoading = false,
    this.isChecking = false,
    this.monitorStarted = false,
    this.notifications = const [],
    this.error,
    this.lastCheckedAt,
  });

  int get unreadCount =>
      notifications.where((notification) => !notification.isRead).length;

  int get importantUnreadCount => notifications
      .where((notification) => !notification.isRead && notification.isImportant)
      .length;

  NotificationsState copyWith({
    bool? isLoading,
    bool? isChecking,
    bool? monitorStarted,
    List<DeliveryNotification>? notifications,
    String? error,
    DateTime? lastCheckedAt,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      isChecking: isChecking ?? this.isChecking,
      monitorStarted: monitorStarted ?? this.monitorStarted,
      notifications: notifications ?? this.notifications,
      error: error,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final dynamic _deliveryService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  Timer? _pollTimer;
  Set<String> _seenEvents = {};

  NotificationsNotifier(this._deliveryService)
      : super(const NotificationsState());

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final rawNotifications =
          await _storage.read(key: _notificationsStorageKey);
      final rawSeenEvents =
          await _storage.read(key: _notificationSeenEventsKey);
      _seenEvents = rawSeenEvents == null || rawSeenEvents.isEmpty
          ? {}
          : rawSeenEvents.split('|').where((item) => item.isNotEmpty).toSet();

      final notifications = DeliveryNotification.decodeList(rawNotifications)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(
        isLoading: false,
        notifications: notifications,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load notifications',
      );
    }
  }

  Future<void> startMonitor() async {
    if (state.monitorStarted) return;
    state = state.copyWith(monitorStarted: true);
    await checkNow();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => checkNow(silent: true),
    );
  }

  Future<void> checkNow({bool silent = false}) async {
    if (state.isChecking) return;
    state = state.copyWith(isChecking: !silent, error: null);
    try {
      final generated = <DeliveryNotification>[];

      final pendingOrders = await _safePendingOrders();
      for (final order in pendingOrders) {
        generated.add(_newOrderNotification(order, source: 'pending'));
        generated.addAll(_attentionNotifications(order));
      }

      final activeOrders = await _safeActiveOrders();
      for (final order in activeOrders) {
        generated.addAll(_attentionNotifications(order));
        final stale = _staleOrderNotification(order);
        if (stale != null) generated.add(stale);
      }

      await _addGenerated(generated);
      state = state.copyWith(
        isChecking: false,
        lastCheckedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isChecking: false,
        error: 'Failed to check notifications',
        lastCheckedAt: DateTime.now(),
      );
    }
  }

  Future<List<DeliveryOrder>> _safePendingOrders() async {
    try {
      final orders = await _deliveryService.getPendingOrders();
      return List<DeliveryOrder>.from(orders);
    } catch (_) {
      return [];
    }
  }

  Future<List<DeliveryOrder>> _safeActiveOrders() async {
    try {
      final data = await _deliveryService.getOrders();
      final rawOrders = data['active_orders'] ?? data['orders'] ?? [];
      if (rawOrders is! List) return [];
      return rawOrders
          .map(
              (item) => DeliveryOrder.fromJson(Map<String, dynamic>.from(item)))
          .where((order) => !_isClosedStatus(order.status))
          .toList();
    } catch (_) {
      return [];
    }
  }

  bool _isClosedStatus(String status) {
    return const {
      DeliveryStatus.delivered,
      DeliveryStatus.failed,
      DeliveryStatus.cancelled,
      DeliveryStatus.returned,
    }.contains(status.toUpperCase());
  }

  DeliveryNotification _newOrderNotification(
    DeliveryOrder order, {
    required String source,
  }) {
    return DeliveryNotification(
      id: '$source-new-order-${order.id}',
      type: DeliveryNotificationType.newOrder,
      title: 'New delivery assigned',
      body:
          '${order.orderNumber ?? order.assignmentNumber} for ${order.customerName ?? 'Customer'}',
      route: source == 'pending' ? '/orders/pending' : '/orders/${order.id}',
      orderId: order.id,
      orderNumber: order.orderNumber ?? order.assignmentNumber,
      createdAt: order.createdAt,
      isImportant: true,
    );
  }

  List<DeliveryNotification> _attentionNotifications(DeliveryOrder order) {
    final notifications = <DeliveryNotification>[];
    final orderLabel = order.orderNumber ?? order.assignmentNumber;

    if (!order.hasDeliveryCoordinates) {
      notifications.add(
        DeliveryNotification(
          id: 'missing-location-${order.id}',
          type: DeliveryNotificationType.missingLocation,
          title: 'Customer GPS missing',
          body: '$orderLabel has an address but no precise GPS pin.',
          route: '/orders/${order.id}',
          orderId: order.id,
          orderNumber: orderLabel,
          createdAt: DateTime.now(),
          isImportant: true,
        ),
      );
    }

    if ((order.paymentMethod ?? '').toUpperCase() == 'COD' &&
        (order.orderTotal ?? order.codAmount) > 0) {
      notifications.add(
        DeliveryNotification(
          id: 'cod-${order.id}',
          type: DeliveryNotificationType.codCollection,
          title: 'COD collection needed',
          body: '$orderLabel requires collection of '
              'Rs ${(order.orderTotal ?? order.codAmount).toStringAsFixed(0)}.',
          route: '/orders/${order.id}',
          orderId: order.id,
          orderNumber: orderLabel,
          createdAt: DateTime.now(),
          isImportant: true,
        ),
      );
    }

    if ((order.paymentMethod ?? '').toUpperCase() == 'CREDIT') {
      notifications.add(
        DeliveryNotification(
          id: 'credit-${order.id}',
          type: DeliveryNotificationType.creditOrder,
          title: 'Credit customer order',
          body: '$orderLabel is marked as credit. Verify customer status.',
          route: '/orders/${order.id}',
          orderId: order.id,
          orderNumber: orderLabel,
          createdAt: DateTime.now(),
          isImportant: true,
        ),
      );
    }

    return notifications;
  }

  DeliveryNotification? _staleOrderNotification(DeliveryOrder order) {
    final age = DateTime.now().difference(order.createdAt);
    if (age.inMinutes < 30) return null;
    final status = order.status.toUpperCase();
    if (status == DeliveryStatus.delivered || status == DeliveryStatus.failed) {
      return null;
    }
    final orderLabel = order.orderNumber ?? order.assignmentNumber;
    return DeliveryNotification(
      id: 'stale-${order.id}-$status',
      type: DeliveryNotificationType.staleOrder,
      title: 'Order needs status update',
      body: '$orderLabel has been $status for ${age.inMinutes} minutes.',
      route: '/orders/${order.id}',
      orderId: order.id,
      orderNumber: orderLabel,
      createdAt: DateTime.now(),
      isImportant: true,
    );
  }

  Future<void> _addGenerated(
    List<DeliveryNotification> generated,
  ) async {
    final uniqueGenerated = <String, DeliveryNotification>{};
    for (final notification in generated) {
      uniqueGenerated.putIfAbsent(notification.id, () => notification);
    }

    final newNotifications = uniqueGenerated.values
        .where((notification) => !_seenEvents.contains(notification.id))
        .toList();
    if (newNotifications.isEmpty) return;

    _seenEvents.addAll(newNotifications.map((notification) => notification.id));

    final merged = [...newNotifications, ...state.notifications]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final limited = merged.take(_maxStoredNotifications).toList();
    state = state.copyWith(notifications: limited);
    await _persist(limited);
  }

  Future<void> markRead(String id) async {
    final updated = state.notifications
        .map((notification) => notification.id == id
            ? notification.copyWith(isRead: true)
            : notification)
        .toList();
    state = state.copyWith(notifications: updated);
    await _persist(updated);
  }

  Future<void> markAllRead() async {
    final updated = state.notifications
        .map((notification) => notification.copyWith(isRead: true))
        .toList();
    state = state.copyWith(notifications: updated);
    await _persist(updated);
  }

  Future<void> clearAll() async {
    state = state.copyWith(notifications: []);
    await _storage.delete(key: _notificationsStorageKey);
  }

  Future<void> _persist(List<DeliveryNotification> notifications) async {
    await _storage.write(
      key: _notificationsStorageKey,
      value: DeliveryNotification.encodeList(notifications),
    );
    await _storage.write(
      key: _notificationSeenEventsKey,
      value: _seenEvents.join('|'),
    );
  }
}
