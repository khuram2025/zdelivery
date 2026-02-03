import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for connectivity state
final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
  return ConnectivityNotifier();
});

class ConnectivityState {
  final bool isConnected;
  final bool isInitialized;

  const ConnectivityState({
    this.isConnected = true,
    this.isInitialized = false,
  });

  ConnectivityState copyWith({
    bool? isConnected,
    bool? isInitialized,
  }) {
    return ConnectivityState(
      isConnected: isConnected ?? this.isConnected,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  ConnectivityNotifier() : super(const ConnectivityState()) {
    _init();
  }

  Future<void> _init() async {
    // Check initial connectivity
    final result = await Connectivity().checkConnectivity();
    state = state.copyWith(
      isConnected: _isConnected(result),
      isInitialized: true,
    );

    // Listen to connectivity changes
    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      state = state.copyWith(isConnected: _isConnected(result));
    });
  }

  bool _isConnected(List<ConnectivityResult> result) {
    return result.isNotEmpty && !result.contains(ConnectivityResult.none);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
