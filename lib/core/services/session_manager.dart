import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import 'navigation_service.dart';

/// Manages session expiration and logout globally
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Stream controller for session expired events
  final _sessionExpiredController = StreamController<String>.broadcast();
  Stream<String> get onSessionExpired => _sessionExpiredController.stream;

  bool _isHandlingExpiration = false;

  /// Call this when token refresh fails (session expired)
  Future<void> handleSessionExpired({String message = 'Session expired. Please login again.'}) async {
    // Prevent multiple simultaneous handling
    if (_isHandlingExpiration) return;
    _isHandlingExpiration = true;

    try {
      // Clear stored tokens
      await _storage.delete(key: AppConstants.accessTokenKey);
      await _storage.delete(key: AppConstants.refreshTokenKey);
      await _storage.delete(key: AppConstants.userDataKey);

      // Notify listeners
      _sessionExpiredController.add(message);

      // Show message and navigate to login
      final context = NavigationService.context;
      if (context != null && context.mounted) {
        // Show snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.logout, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      // Reset flag after a delay to prevent rapid repeated calls
      Future.delayed(const Duration(seconds: 2), () {
        _isHandlingExpiration = false;
      });
    }
  }

  void dispose() {
    _sessionExpiredController.close();
  }
}
