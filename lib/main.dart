import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/services/session_manager.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: ZDeliveryApp()));
}

class ZDeliveryApp extends StatefulWidget {
  const ZDeliveryApp({super.key});

  @override
  State<ZDeliveryApp> createState() => _ZDeliveryAppState();
}

class _ZDeliveryAppState extends State<ZDeliveryApp> {
  late final StreamSubscription<String> _sessionSubscription;
  final SessionManager _sessionManager = SessionManager();

  @override
  void initState() {
    super.initState();
    // Listen for session expired events
    _sessionSubscription = _sessionManager.onSessionExpired.listen((message) {
      // Navigate to login and clear the stack
      appRouter.go('/login');
    });
  }

  @override
  void dispose() {
    _sessionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ZDelivery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
