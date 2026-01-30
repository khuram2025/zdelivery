import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/models.dart';

final earningsProvider = StateNotifierProvider<EarningsNotifier, EarningsState>((ref) {
  return EarningsNotifier(ref.read(deliveryServiceProvider));
});

final statisticsProvider = StateNotifierProvider<StatisticsNotifier, StatisticsState>((ref) {
  return StatisticsNotifier(ref.read(deliveryServiceProvider));
});

// Earnings State
class EarningsState {
  final bool isLoading;
  final EarningsData? earnings;
  final String selectedPeriod;
  final String? error;

  EarningsState({
    this.isLoading = false,
    this.earnings,
    this.selectedPeriod = 'today',
    this.error,
  });

  EarningsState copyWith({
    bool? isLoading,
    EarningsData? earnings,
    String? selectedPeriod,
    String? error,
  }) {
    return EarningsState(
      isLoading: isLoading ?? this.isLoading,
      earnings: earnings ?? this.earnings,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      error: error,
    );
  }
}

class EarningsNotifier extends StateNotifier<EarningsState> {
  final dynamic _deliveryService;

  EarningsNotifier(this._deliveryService) : super(EarningsState());

  Future<void> loadEarnings({String period = 'today'}) async {
    state = state.copyWith(isLoading: true, error: null, selectedPeriod: period);
    try {
      final earnings = await _deliveryService.getEarnings(period: period);
      state = state.copyWith(isLoading: false, earnings: earnings);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load earnings');
    }
  }

  void changePeriod(String period) {
    loadEarnings(period: period);
  }
}

// Statistics State
class StatisticsState {
  final bool isLoading;
  final StatisticsData? statistics;
  final String? error;

  StatisticsState({
    this.isLoading = false,
    this.statistics,
    this.error,
  });

  StatisticsState copyWith({
    bool? isLoading,
    StatisticsData? statistics,
    String? error,
  }) {
    return StatisticsState(
      isLoading: isLoading ?? this.isLoading,
      statistics: statistics ?? this.statistics,
      error: error,
    );
  }
}

class StatisticsNotifier extends StateNotifier<StatisticsState> {
  final dynamic _deliveryService;

  StatisticsNotifier(this._deliveryService) : super(StatisticsState());

  Future<void> loadStatistics() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final statistics = await _deliveryService.getStatistics();
      state = state.copyWith(isLoading: false, statistics: statistics);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load statistics');
    }
  }
}
