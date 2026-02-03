import 'package:flutter/material.dart';

/// Global navigation service for navigating from anywhere in the app
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navigatorKey.currentState;

  static BuildContext? get context => navigatorKey.currentContext;

  static void navigateTo(String routeName) {
    navigator?.pushNamed(routeName);
  }

  static void navigateToAndClearStack(String routeName) {
    navigator?.pushNamedAndRemoveUntil(routeName, (route) => false);
  }

  static void goBack() {
    navigator?.pop();
  }
}
