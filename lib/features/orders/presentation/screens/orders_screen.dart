import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/order_card.dart';
import '../providers/orders_provider.dart';
import '../widgets/orders_map_view.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isMapView = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ordersProvider.notifier).loadOrders();
      ref.read(orderHistoryProvider.notifier).loadHistory();
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    // Refresh data when switching tabs
    if (_tabController.index == 0) {
      ref.read(ordersProvider.notifier).loadOrders();
    } else {
      // Refresh history for Completed (index 1) and Failed (index 2) tabs
      ref.read(orderHistoryProvider.notifier).loadHistory();
    }
    // Reset to list view when leaving Active tab
    if (_tabController.index != 0 && _isMapView) {
      setState(() => _isMapView = false);
    }
  }

  void _toggleMapView() {
    setState(() => _isMapView = !_isMapView);
  }

  @override
  void dispose() {
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
            onOrderTapped: (order) => context.push('/orders/${order.id}'),
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
    final activeOrders = ordersState.activeOrders.where((o) =>
      !['DELIVERED', 'FAILED', 'CANCELLED', 'RETURNED', 'delivered', 'failed', 'cancelled', 'returned'].contains(o.status)
    ).toList();

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
        itemCount: activeOrders.length,
        itemBuilder: (context, index) {
          final order = activeOrders[index];
          return OrderCard(
            order: order,
            onTap: () => context.push('/orders/${order.id}'),
          );
        },
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
    final orders = isCompleted ? historyState.completedOrders : historyState.failedOrders;

    return Column(
      children: [
        // Filter Bar
        _FilterBar(isCompleted: isCompleted),

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
                      icon: isCompleted ? Icons.check_circle_outline : Icons.error_outline,
                      title: isCompleted ? 'No Completed Orders' : 'No Failed Orders',
                      subtitle: isCompleted
                          ? 'Completed deliveries will appear here'
                          : 'Failed deliveries will appear here',
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(orderHistoryProvider.notifier).loadHistory(),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 100),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return _HistoryOrderCard(order: order, isCompleted: isCompleted);
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
                    onTap: () => ref.read(orderHistoryProvider.notifier).setFilter(HistoryFilter.today),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '7 Days',
                    isSelected: currentFilter == HistoryFilter.week,
                    onTap: () => ref.read(orderHistoryProvider.notifier).setFilter(HistoryFilter.week),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '30 Days',
                    isSelected: currentFilter == HistoryFilter.month,
                    onTap: () => ref.read(orderHistoryProvider.notifier).setFilter(HistoryFilter.month),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'All Time',
                    isSelected: currentFilter == HistoryFilter.all,
                    onTap: () => ref.read(orderHistoryProvider.notifier).setFilter(HistoryFilter.all),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _DateRangeButton(currentFilter: currentFilter),
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

  const _DateRangeButton({required this.currentFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showDateRangePicker(context, ref),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: currentFilter == HistoryFilter.custom ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.calendar_today_outlined,
          size: 18,
          color: currentFilter == HistoryFilter.custom ? Colors.white : AppColors.textSecondary,
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
        start: now.subtract(const Duration(days: 7)),
        end: now,
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
      ref.read(orderHistoryProvider.notifier).setCustomDateRange(picked.start, picked.end);
    }
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

    return GestureDetector(
      onTap: () => context.push('/orders/${order.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Status Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (isCompleted ? AppColors.success : AppColors.error).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.cancel,
                color: isCompleted ? AppColors.success : AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Order Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.orderNumber ?? order.assignmentNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        _getAmountText(order),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isCompleted ? AppColors.success : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          order.customerName ?? 'Customer',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.access_time, size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(displayDate),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
          ],
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
