import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/order_card.dart';
import '../providers/orders_provider.dart';
import '../widgets/orders_map_view.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  bool _isMapView = false;
  int _lastHandledTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ordersProvider.notifier).loadOrders();
      ref.read(orderHistoryProvider.notifier).loadHistory();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshCurrentTab();
    }
  }

  void _refreshCurrentTab() {
    if (_tabController.index == 0) {
      ref.read(ordersProvider.notifier).loadOrders();
    } else {
      ref.read(orderHistoryProvider.notifier).loadHistory();
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final currentIndex = _tabController.index;
    final changedTab = currentIndex != _lastHandledTabIndex;
    _lastHandledTabIndex = currentIndex;

    if (changedTab || (currentIndex != 0 && _isMapView)) {
      setState(() {
        if (currentIndex != 0) {
          _isMapView = false;
        }
      });
    }

    // Refresh data when switching tabs
    if (currentIndex == 0) {
      ref.read(ordersProvider.notifier).loadOrders();
    } else {
      // Refresh history for Completed (index 1) and Failed (index 2) tabs
      ref.read(orderHistoryProvider.notifier).loadHistory();
    }
  }

  void _toggleMapView() {
    setState(() => _isMapView = !_isMapView);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Failed'),
          ],
        ),
        actions: [
          // Map/List toggle - only show on Active tab
          if (_tabController.index == 0)
            IconButton(
              icon: Icon(_isMapView ? Icons.list : Icons.map_outlined),
              onPressed: _toggleMapView,
              tooltip: _isMapView ? 'List View' : 'Map View',
            ),
          IconButton(
            icon: const Icon(Icons.pending_actions_outlined),
            onPressed: () => context.push('/orders/pending'),
            tooltip: 'Pending Orders',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        physics: _isMapView ? const NeverScrollableScrollPhysics() : null,
        children: [
          _ActiveOrdersTab(
            isMapView: _isMapView,
            onOrderTapped: (order) async {
              await context.push('/orders/${order.id}');
              _refreshCurrentTab();
            },
          ),
          const _HistoryTab(isCompleted: true),
          const _HistoryTab(isCompleted: false),
        ],
      ),
    );
  }
}

// Active Orders Tab
class _ActiveOrdersTab extends ConsumerWidget {
  final bool isMapView;
  final Function(dynamic order) onOrderTapped;

  const _ActiveOrdersTab({
    this.isMapView = false,
    required this.onOrderTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(ordersProvider);
    final activeOrders = ordersState.activeOrders
        .where((o) => ![
              'DELIVERED',
              'FAILED',
              'CANCELLED',
              'RETURNED',
              'delivered',
              'failed',
              'cancelled',
              'returned'
            ].contains(o.status))
        .toList();

    if (ordersState.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: 3,
        itemBuilder: (context, index) => const OrderCardShimmer(),
      );
    }

    if (activeOrders.isEmpty) {
      return _EmptyState(
        icon: Icons.local_shipping_outlined,
        title: 'No Active Orders',
        subtitle: 'Your active deliveries will appear here',
      );
    }

    // Map View
    if (isMapView) {
      return OrdersMapView(
        orders: activeOrders,
        onOrderTapped: onOrderTapped,
      );
    }

    // List View
    return RefreshIndicator(
      onRefresh: () => ref.read(ordersProvider.notifier).loadOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: activeOrders.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _ActiveOrdersSummary(orders: activeOrders);
          }
          final order = activeOrders[index - 1];
          return OrderCard(
            order: order,
            onTap: () => onOrderTapped(order),
          );
        },
      ),
    );
  }
}

class _ActiveOrdersSummary extends StatelessWidget {
  final List<dynamic> orders;

  const _ActiveOrdersSummary({required this.orders});

  @override
  Widget build(BuildContext context) {
    final gpsCount =
        orders.where((o) => o.hasDeliveryCoordinates == true).length;
    final codDue = orders.fold<double>(
      0,
      (total, order) {
        final amount = order.isCod == true ? order.codAmount : 0;
        return total + (amount as num).toDouble();
      },
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: _SummaryTile(
              icon: Icons.local_shipping_outlined,
              label: 'Active',
              value: orders.length.toString(),
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryTile(
              icon: Icons.gps_fixed,
              label: 'GPS',
              value: '$gpsCount/${orders.length}',
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryTile(
              icon: Icons.payments_outlined,
              label: 'COD due',
              value: codDue.currency,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// History Tab (Completed / Failed)
class _HistoryTab extends ConsumerWidget {
  final bool isCompleted;

  const _HistoryTab({required this.isCompleted});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(orderHistoryProvider);
    final orders =
        isCompleted ? historyState.completedOrders : historyState.failedOrders;

    return Column(
      children: [
        // Filter Bar
        _FilterBar(isCompleted: isCompleted),
        if (historyState.error != null)
          _HistoryErrorBanner(message: historyState.error!),

        // Orders List
        Expanded(
          child: historyState.isLoading
              ? ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: 3,
                  itemBuilder: (context, index) => const OrderCardShimmer(),
                )
              : orders.isEmpty
                  ? _EmptyState(
                      icon: isCompleted
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      title: isCompleted
                          ? 'No Completed Orders'
                          : 'No Failed Orders',
                      subtitle: isCompleted
                          ? 'Completed deliveries will appear here'
                          : 'Failed deliveries will appear here',
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(orderHistoryProvider.notifier).loadHistory(),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 100),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return _HistoryOrderCard(
                              order: order, isCompleted: isCompleted);
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

// Filter Bar
class _FilterBar extends ConsumerWidget {
  final bool isCompleted;

  const _FilterBar({required this.isCompleted});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(orderHistoryProvider);
    final currentFilter = historyState.filter;
    final customLabel = historyState.startDate != null &&
            historyState.endDate != null &&
            currentFilter == HistoryFilter.custom
        ? '${DateFormat('dd MMM').format(historyState.startDate!)} - ${DateFormat('dd MMM').format(historyState.endDate!)}'
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Today',
                    isSelected: currentFilter == HistoryFilter.today,
                    onTap: () => ref
                        .read(orderHistoryProvider.notifier)
                        .setFilter(HistoryFilter.today),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '7 Days',
                    isSelected: currentFilter == HistoryFilter.week,
                    onTap: () => ref
                        .read(orderHistoryProvider.notifier)
                        .setFilter(HistoryFilter.week),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '30 Days',
                    isSelected: currentFilter == HistoryFilter.month,
                    onTap: () => ref
                        .read(orderHistoryProvider.notifier)
                        .setFilter(HistoryFilter.month),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'All Time',
                    isSelected: currentFilter == HistoryFilter.all,
                    onTap: () => ref
                        .read(orderHistoryProvider.notifier)
                        .setFilter(HistoryFilter.all),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _DateRangeButton(
            currentFilter: currentFilter,
            label: customLabel,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _DateRangeButton extends ConsumerWidget {
  final HistoryFilter currentFilter;
  final String? label;

  const _DateRangeButton({required this.currentFilter, this.label});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = currentFilter == HistoryFilter.custom;
    return GestureDetector(
      onTap: () => _showDateRangePicker(context, ref),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label == null ? 8 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label!,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDateRangePicker(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: ref.read(orderHistoryProvider).startDate ??
            now.subtract(const Duration(days: 7)),
        end: ref.read(orderHistoryProvider).endDate ?? now,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref
          .read(orderHistoryProvider.notifier)
          .setCustomDateRange(picked.start, picked.end);
    }
  }
}

class _HistoryErrorBanner extends StatelessWidget {
  final String message;

  const _HistoryErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// History Order Card - Compact design
class _HistoryOrderCard extends StatelessWidget {
  final dynamic order;
  final bool isCompleted;

  const _HistoryOrderCard({required this.order, required this.isCompleted});

  String _getAmountText(dynamic order) {
    final orderTotal = order.orderTotal;
    final codAmount = order.codAmount;

    if (orderTotal != null && orderTotal > 0) {
      return 'Rs ${orderTotal.toStringAsFixed(0)}';
    }
    if (codAmount > 0) {
      return 'Rs ${codAmount.toStringAsFixed(0)}';
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM, hh:mm a');
    // Show delivered_at for completed orders, created_at for failed
    final displayDate = isCompleted && order.deliveredAt != null
        ? order.deliveredAt
        : order.createdAt;
    final address = order.displayDeliveryAddress;

    return Semantics(
      button: true,
      label: 'View order ${order.orderNumber ?? order.assignmentNumber}',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => context.push('/orders/${order.id}'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (isCompleted
                                  ? AppColors.success
                                  : AppColors.error)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isCompleted ? Icons.check_circle : Icons.cancel,
                          color:
                              isCompleted ? AppColors.success : AppColors.error,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.orderNumber ?? order.assignmentNumber,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              order.customerName ?? 'Customer',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _getAmountText(order),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: isCompleted
                                  ? AppColors.success
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            dateFormat.format(displayDate),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      IconButton.filledTonal(
                        onPressed: () => context.push('/orders/${order.id}'),
                        tooltip: 'View order details',
                        icon: const Icon(Icons.chevron_right_rounded),
                        style: IconButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.08),
                          fixedSize: const Size(34, 34),
                          minimumSize: const Size(34, 34),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        order.hasDeliveryCoordinates
                            ? Icons.location_on_outlined
                            : Icons.map_outlined,
                        size: 15,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: order.hasDeliveryAddress
                                ? AppColors.textSecondary
                                : AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Empty State
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
