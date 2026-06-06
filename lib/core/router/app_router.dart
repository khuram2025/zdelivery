import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/customers/data/models.dart';
import '../../features/customers/presentation/screens/customer_detail_screen.dart';
import '../../features/customers/presentation/screens/customers_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/earnings/presentation/screens/earnings_screen.dart';
import '../../features/earnings/presentation/screens/statistics_screen.dart';
import '../../features/home/presentation/screens/main_shell.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/orders/presentation/screens/pending_orders_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../services/navigation_service.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: NavigationService.navigatorKey,
  initialLocation: '/',
  routes: [
    // Splash
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),

    // Login
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    // Register
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),

    // Forgot Password
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),

    // Main Shell with Bottom Navigation
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        // Dashboard (Home)
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),

        // Orders
        GoRoute(
          path: '/orders',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: OrdersScreen(),
          ),
        ),

        // Earnings
        GoRoute(
          path: '/earnings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: EarningsScreen(),
          ),
        ),

        // Assigned Customers
        GoRoute(
          path: '/customers',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CustomersScreen(),
          ),
        ),

        // Profile
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfileScreen(),
          ),
        ),
      ],
    ),

    // Pending Orders (full screen)
    GoRoute(
      path: '/orders/pending',
      builder: (context, state) => const PendingOrdersScreen(),
    ),

    // Notifications (full screen)
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),

    // Order Detail (full screen)
    GoRoute(
      path: '/orders/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return OrderDetailScreen(orderId: id);
      },
    ),

    // Statistics (full screen)
    GoRoute(
      path: '/statistics',
      builder: (context, state) => const StatisticsScreen(),
    ),

    // Customer Detail (full screen)
    GoRoute(
      path: '/customers/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        final initialCustomer = state.extra is AssignedCustomer
            ? state.extra as AssignedCustomer
            : null;
        return CustomerDetailScreen(
          customerId: id,
          initialCustomer: initialCustomer,
        );
      },
    ),
  ],
);
