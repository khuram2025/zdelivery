import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/models.dart';

enum DashboardPeriodFilter { today, yesterday, week, month, all, custom }

class DashboardState {
  final bool isLoading;
  final DashboardData? data;
  final DashboardPeriodFilter filter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final String? error;

  DashboardState({
    this.isLoading = false,
    this.data,
    this.filter = DashboardPeriodFilter.today,
    this.customStartDate,
    this.customEndDate,
    this.error,
  });

  DashboardState copyWith({
    bool? isLoading,
    DashboardData? data,
    DashboardPeriodFilter? filter,
    DateTime? customStartDate,
    DateTime? customEndDate,
    String? error,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      filter: filter ?? this.filter,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      error: error,
    );
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref.read(deliveryServiceProvider));
});

class DashboardNotifier extends StateNotifier<DashboardState> {
  final dynamic _deliveryService;

  DashboardNotifier(this._deliveryService) : super(DashboardState());

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getPeriodString(DashboardPeriodFilter filter) {
    switch (filter) {
      case DashboardPeriodFilter.today:
        return 'today';
      case DashboardPeriodFilter.yesterday:
        return 'yesterday';
      case DashboardPeriodFilter.week:
        return 'week';
      case DashboardPeriodFilter.month:
        return 'month';
      case DashboardPeriodFilter.all:
        return 'all';
      case DashboardPeriodFilter.custom:
        return 'custom';
    }
  }

  Future<void> loadDashboard({DashboardPeriodFilter? filter}) async {
    final newFilter = filter ?? state.filter;
    state = state.copyWith(isLoading: true, error: null, filter: newFilter);

    try {
      String? startDate;
      String? endDate;

      if (newFilter == DashboardPeriodFilter.custom &&
          state.customStartDate != null &&
          state.customEndDate != null) {
        startDate = _formatDate(state.customStartDate!);
        endDate = _formatDate(state.customEndDate!);
      }

      final data = await _deliveryService.getDashboard(
        period: _getPeriodString(newFilter),
        startDate: startDate,
        endDate: endDate,
      );

      state = state.copyWith(isLoading: false, data: data);
    } on DioException catch (e) {
      String errorMessage = 'Failed to load dashboard';
      if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection';
      } else if (e.response?.data != null && e.response!.data is Map) {
        errorMessage = e.response!.data['message'] ?? errorMessage;
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load dashboard');
    }
  }

  void setFilter(DashboardPeriodFilter filter) {
    loadDashboard(filter: filter);
  }

  void setCustomDateRange(DateTime start, DateTime end) {
    state = state.copyWith(
      customStartDate: start,
      customEndDate: end,
    );
    loadDashboard(filter: DashboardPeriodFilter.custom);
  }
}
