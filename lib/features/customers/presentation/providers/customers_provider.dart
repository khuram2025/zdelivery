import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/models.dart';

String _extractErrorMessage(dynamic e, String defaultMessage) {
  if (e is DioException) {
    final responseData = e.response?.data;
    if (responseData is Map) {
      return (responseData['error'] ??
              responseData['message'] ??
              defaultMessage)
          .toString();
    }
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Please check your internet.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection.';
    }
  }
  return defaultMessage;
}

enum CustomerPaymentFilter { all, credit, cod }

extension CustomerPaymentFilterQuery on CustomerPaymentFilter {
  String? get queryValue {
    switch (this) {
      case CustomerPaymentFilter.all:
        return null;
      case CustomerPaymentFilter.credit:
        return 'credit';
      case CustomerPaymentFilter.cod:
        return 'cod';
    }
  }
}

final assignedCustomersProvider =
    StateNotifierProvider<AssignedCustomersNotifier, AssignedCustomersState>(
        (ref) {
  return AssignedCustomersNotifier(ref.read(deliveryServiceProvider));
});

final customerDetailProvider = StateNotifierProvider.family<
    CustomerDetailNotifier,
    CustomerDetailState,
    CustomerDetailRequest>((ref, request) {
  return CustomerDetailNotifier(ref.read(deliveryServiceProvider), request);
});

@immutable
class CustomerDetailRequest {
  final int customerId;
  final AssignedCustomer? initialCustomer;

  const CustomerDetailRequest({
    required this.customerId,
    this.initialCustomer,
  });

  @override
  bool operator ==(Object other) {
    return other is CustomerDetailRequest &&
        other.customerId == customerId &&
        other.initialCustomer?.id == initialCustomer?.id;
  }

  @override
  int get hashCode => Object.hash(customerId, initialCustomer?.id);
}

class AssignedCustomersState {
  final bool isLoading;
  final List<AssignedCustomer> customers;
  final AssignedCustomersSummary? summary;
  final CustomerPaymentFilter filter;
  final String search;
  final String? error;

  const AssignedCustomersState({
    this.isLoading = false,
    this.customers = const [],
    this.summary,
    this.filter = CustomerPaymentFilter.all,
    this.search = '',
    this.error,
  });

  AssignedCustomersState copyWith({
    bool? isLoading,
    List<AssignedCustomer>? customers,
    AssignedCustomersSummary? summary,
    CustomerPaymentFilter? filter,
    String? search,
    String? error,
  }) {
    return AssignedCustomersState(
      isLoading: isLoading ?? this.isLoading,
      customers: customers ?? this.customers,
      summary: summary ?? this.summary,
      filter: filter ?? this.filter,
      search: search ?? this.search,
      error: error,
    );
  }
}

class AssignedCustomersNotifier extends StateNotifier<AssignedCustomersState> {
  final dynamic _deliveryService;

  AssignedCustomersNotifier(this._deliveryService)
      : super(const AssignedCustomersState());

  Future<void> loadCustomers({
    String? search,
    CustomerPaymentFilter? filter,
  }) async {
    final nextSearch = search ?? state.search;
    final nextFilter = filter ?? state.filter;
    state = state.copyWith(
      isLoading: true,
      search: nextSearch,
      filter: nextFilter,
      error: null,
    );

    try {
      final data = await _deliveryService.getAssignedCustomers(
        search: nextSearch.trim().isEmpty ? null : nextSearch.trim(),
        paymentType: nextFilter.queryValue,
      );
      state = state.copyWith(
        isLoading: false,
        customers: data.customers,
        summary: data.summary,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e, 'Failed to load customers'),
      );
    }
  }

  void setFilter(CustomerPaymentFilter filter) {
    loadCustomers(filter: filter);
  }

  void setSearch(String search) {
    loadCustomers(search: search);
  }
}

class CustomerDetailState {
  final bool isLoading;
  final CustomerDeliveryDetail? detail;
  final String? error;

  const CustomerDetailState({
    this.isLoading = false,
    this.detail,
    this.error,
  });

  CustomerDetailState copyWith({
    bool? isLoading,
    CustomerDeliveryDetail? detail,
    String? error,
  }) {
    return CustomerDetailState(
      isLoading: isLoading ?? this.isLoading,
      detail: detail ?? this.detail,
      error: error,
    );
  }
}

class CustomerDetailNotifier extends StateNotifier<CustomerDetailState> {
  final dynamic _deliveryService;
  final CustomerDetailRequest request;

  CustomerDetailNotifier(this._deliveryService, this.request)
      : super(CustomerDetailState(
          detail: request.initialCustomer == null
              ? null
              : CustomerDeliveryDetail(
                  customer: request.initialCustomer!,
                  orderHistory: const [],
                ),
        ));

  Future<void> loadCustomerDetail() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final detail = await _deliveryService.getAssignedCustomerDetail(
        request.customerId,
        initialCustomer: request.initialCustomer,
      );
      state = state.copyWith(isLoading: false, detail: detail);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e, 'Failed to load customer details'),
      );
    }
  }
}
