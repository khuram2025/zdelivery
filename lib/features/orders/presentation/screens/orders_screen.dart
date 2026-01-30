import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/order_card.dart';
import '../providers/orders_provider.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ordersProvider.notifier).loadOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);

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
          IconButton(
            icon: const Icon(Icons.pending_actions_outlined),
            onPressed: () => context.push('/orders/pending'),
            tooltip: 'Pending Orders',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OrdersList(
            orders: ordersState.activeOrders.where((o) =>
              !['DELIVERED', 'FAILED', 'CANCELLED', 'RETURNED'].contains(o.status)
            ).toList(),
            isLoading: ordersState.isLoading,
            emptyTitle: 'No Active Orders',
            emptySubtitle: 'Your active deliveries will appear here',
          ),
          _OrdersList(
            orders: ordersState.activeOrders.where((o) => o.status == 'DELIVERED').toList(),
            isLoading: ordersState.isLoading,
            emptyTitle: 'No Completed Orders',
            emptySubtitle: 'Completed deliveries will appear here',
          ),
          _OrdersList(
            orders: ordersState.activeOrders.where((o) =>
              ['FAILED', 'CANCELLED', 'RETURNED'].contains(o.status)
            ).toList(),
            isLoading: ordersState.isLoading,
            emptyTitle: 'No Failed Orders',
            emptySubtitle: 'Failed deliveries will appear here',
          ),
        ],
      ),
    );
  }
}

class _OrdersList extends ConsumerWidget {
  final List orders;
  final bool isLoading;
  final String emptyTitle;
  final String emptySubtitle;

  const _OrdersList({
    required this.orders,
    required this.isLoading,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: 5,
        itemBuilder: (context, index) => const OrderCardShimmer(),
      );
    }

    if (orders.isEmpty) {
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
                child: const Icon(
                  Icons.local_shipping_outlined,
                  size: 48,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                emptySubtitle,
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

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(ordersProvider.notifier).loadOrders();
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return OrderCard(
            order: order,
            onTap: () => context.push('/orders/${order.id}'),
          );
        },
      ),
    );
  }
}
