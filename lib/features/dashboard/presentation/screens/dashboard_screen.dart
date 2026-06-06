import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../data/models.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_widgets.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).loadDashboard();
      ref.read(profileProvider.notifier).loadProfile();
      ref.read(ordersProvider.notifier).loadOrders();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(dashboardProvider.notifier).loadDashboard(),
      ref.read(ordersProvider.notifier).loadOrders(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final profileState = ref.watch(profileProvider);
    final ordersState = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            // App Bar with Agent Info
            _DashboardAppBar(
              profile: profileState.profile,
              onStatusTap: () => _showStatusSheet(context),
              onMenuTap: () => _openDrawer(context),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.pending_actions_rounded,
                        title: 'Pending Orders',
                        count: ordersState.pendingCount,
                        color: AppColors.warning,
                        onTap: () => context.push('/orders/pending'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.bar_chart_rounded,
                        title: 'Statistics',
                        color: AppColors.info,
                        onTap: () => context.push('/statistics'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Filter Chips
            SliverToBoxAdapter(
              child: _PeriodFilterBar(
                currentFilter: dashboardState.filter,
                onFilterChanged: (filter) {
                  ref.read(dashboardProvider.notifier).setFilter(filter);
                },
                onCustomDateTap: () => _showDateRangePicker(context),
              ),
            ),

            // Dashboard Content
            if (dashboardState.isLoading && dashboardState.data == null)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (dashboardState.error != null &&
                dashboardState.data == null)
              SliverFillRemaining(
                child: _ErrorState(
                  error: dashboardState.error!,
                  onRetry: () =>
                      ref.read(dashboardProvider.notifier).loadDashboard(),
                ),
              )
            else if (dashboardState.data != null)
              _DashboardContent(
                data: dashboardState.data!,
                summary: dashboardState.summary,
              )
            else
              const SliverFillRemaining(
                child: Center(child: Text('No data available')),
              ),
          ],
        ),
      ),
    );
  }

  void _showStatusSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _StatusSheet(),
    );
  }

  void _openDrawer(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }

  void _showDateRangePicker(BuildContext context) async {
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
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(dashboardProvider.notifier).setCustomDateRange(
            picked.start,
            picked.end,
          );
    }
  }
}

// Dashboard App Bar
class _DashboardAppBar extends ConsumerWidget {
  final dynamic profile;
  final VoidCallback onStatusTap;
  final VoidCallback onMenuTap;

  const _DashboardAppBar({
    this.profile,
    required this.onStatusTap,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline =
        profile?.status == 'AVAILABLE' || profile?.status == 'BUSY';
    final unreadCount = ref.watch(
      notificationsProvider.select((state) => state.unreadCount),
    );

    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, Color(0xFF1A4FD6)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Profile Photo
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withAlpha(100), width: 2),
                        ),
                        child: profile?.profilePhoto != null
                            ? ClipOval(
                                child: Image.network(
                                  profile!.profilePhoto!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.person,
                                    color: Colors.white70,
                                    size: 28,
                                  ),
                                ),
                              )
                            : const Icon(Icons.person,
                                color: Colors.white70, size: 28),
                      ),
                      const SizedBox(width: 14),
                      // Name & Code
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?.name ?? 'Loading...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              profile?.agentCode ?? '',
                              style: TextStyle(
                                color: Colors.white.withAlpha(180),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status Badge
                      GestureDetector(
                        onTap: onStatusTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? AppColors.success
                                : Colors.white.withAlpha(50),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color:
                                      isOnline ? Colors.white : Colors.white70,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isOnline ? 'Online' : 'Offline',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
      actions: [
        IconButton(
          icon: _NotificationIconBadge(count: unreadCount),
          onPressed: () => context.push('/notifications'),
        ),
      ],
    );
  }
}

class _NotificationIconBadge extends StatelessWidget {
  final int count;

  const _NotificationIconBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications_outlined, color: Colors.white),
        if (count > 0)
          Positioned(
            right: -4,
            top: -5,
            child: Container(
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Period Filter Bar
class _PeriodFilterBar extends StatelessWidget {
  final DashboardPeriodFilter currentFilter;
  final Function(DashboardPeriodFilter) onFilterChanged;
  final VoidCallback onCustomDateTap;

  const _PeriodFilterBar({
    required this.currentFilter,
    required this.onFilterChanged,
    required this.onCustomDateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'Today',
              isSelected: currentFilter == DashboardPeriodFilter.today,
              onTap: () => onFilterChanged(DashboardPeriodFilter.today),
            ),
            _FilterChip(
              label: 'Yesterday',
              isSelected: currentFilter == DashboardPeriodFilter.yesterday,
              onTap: () => onFilterChanged(DashboardPeriodFilter.yesterday),
            ),
            _FilterChip(
              label: '7 Days',
              isSelected: currentFilter == DashboardPeriodFilter.week,
              onTap: () => onFilterChanged(DashboardPeriodFilter.week),
            ),
            _FilterChip(
              label: '30 Days',
              isSelected: currentFilter == DashboardPeriodFilter.month,
              onTap: () => onFilterChanged(DashboardPeriodFilter.month),
            ),
            _FilterChip(
              label: 'All Time',
              isSelected: currentFilter == DashboardPeriodFilter.all,
              onTap: () => onFilterChanged(DashboardPeriodFilter.all),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onCustomDateTap,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: currentFilter == DashboardPeriodFilter.custom
                      ? AppColors.primary
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.date_range,
                  size: 20,
                  color: currentFilter == DashboardPeriodFilter.custom
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
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
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// Dashboard Content
class _DashboardContent extends StatelessWidget {
  final DashboardData data;
  final MobileDeliverySummary? summary;

  const _DashboardContent({
    required this.data,
    this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Today's Quick Stats
          TodayStatsCard(snapshot: data.todaySnapshot),
          const SizedBox(height: 16),

          if (summary != null) ...[
            MobileSummaryCard(summary: summary!),
            const SizedBox(height: 16),
            SummaryCustomerLists(summary: summary!),
            const SizedBox(height: 16),
          ],

          // Delivery Stats
          DeliveryStatsCard(stats: data.deliveryStats),
          const SizedBox(height: 16),

          // Earnings Card
          EarningsCard(earnings: data.earnings),
          const SizedBox(height: 16),

          // COD Summary
          CodSummaryCard(codSummary: data.codSummary),
          const SizedBox(height: 16),

          // Performance Metrics
          PerformanceCard(performance: data.performance),
          const SizedBox(height: 16),

          // Rating Card
          RatingCard(rating: data.rating),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

// Error State
class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              error,
              style:
                  const TextStyle(fontSize: 16, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// Status Sheet
class _StatusSheet extends ConsumerWidget {
  const _StatusSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final currentStatus = profileState.profile?.status ?? 'OFFLINE';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Update Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _StatusOption(
            label: 'Available',
            subtitle: 'Ready to receive orders',
            icon: Icons.check_circle,
            color: AppColors.success,
            isSelected: currentStatus == 'AVAILABLE',
            onTap: () {
              ref.read(profileProvider.notifier).updateStatus('AVAILABLE');
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 12),
          _StatusOption(
            label: 'Busy',
            subtitle: 'Currently on delivery',
            icon: Icons.local_shipping,
            color: AppColors.warning,
            isSelected: currentStatus == 'BUSY',
            onTap: () {
              ref.read(profileProvider.notifier).updateStatus('BUSY');
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 12),
          _StatusOption(
            label: 'Offline',
            subtitle: 'Not accepting orders',
            icon: Icons.power_settings_new,
            color: AppColors.textTertiary,
            isSelected: currentStatus == 'OFFLINE',
            onTap: () {
              ref.read(profileProvider.notifier).updateStatus('OFFLINE');
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(25) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}

// Quick Action Card
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int? count;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (count != null)
                      Text(
                        '$count pending',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
