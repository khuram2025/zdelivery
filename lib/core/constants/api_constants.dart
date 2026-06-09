class ApiConstants {
  // Primary endpoint (DNS). Preferred whenever it resolves.
  static const String primaryBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://zayyrah.com/api/v1',
  );

  // Secondary endpoint (direct IP). Used only when the DNS host can't be
  // resolved/reached. Must point at the SAME backend as [primaryBaseUrl].
  // static const String fallbackBaseUrl = 'http://54.166.200.11:8001/api/v1';
  static const String fallbackBaseUrl = String.fromEnvironment(
    'API_FALLBACK_BASE_URL',
    defaultValue: 'http://54.209.158.254:8004/api/v1',
  );

  /// Endpoints in preference order: DNS first, IP fallback second.
  static const List<String> baseUrls = [primaryBaseUrl, fallbackBaseUrl];

  /// Backwards-compatible default (the primary/DNS endpoint).
  static const String baseUrl = primaryBaseUrl;

  // Auth endpoints (as per auth.md)
  static const String login = '/delivery/auth/login/';
  static const String refreshToken = '/delivery/auth/refresh/';
  static const String register = '/delivery/auth/register/';
  static const String logout = '/delivery/auth/logout/';
  static const String forgotPassword = '/delivery/auth/forgot-password/';
  static const String verifyOtp = '/delivery/auth/verify-otp/';
  static const String resetPassword = '/delivery/auth/reset-password/';
  static const String changePassword = '/delivery/auth/change-password/';

  // Agent
  static const String agentProfile = '/delivery/agents/profile/';
  static const String agentStatus = '/delivery/agents/status/';
  static const String agentLocation = '/delivery/agents/location/';
  static const String agentEarnings = '/delivery/agents/earnings/';
  static const String agentStatistics = '/delivery/agents/statistics/';
  static const String agentDashboard = '/delivery/agents/dashboard/';

  // Orders — recommended mobile contract (/delivery/mobile/*)
  static const String orders = '/delivery/mobile/orders/';
  static const String pendingOrders = '/delivery/orders/pending/';
  static const String orderHistory = '/delivery/mobile/history/';
  static const String mobileSummary = '/delivery/mobile/summary/';
  static const String assignedCustomers = '/delivery/mobile/customers/';

  static String orderDetail(int id) => '/delivery/mobile/orders/$id/';
  static String assignedCustomerDetail(int id) =>
      '/delivery/mobile/customers/$id/';
  static String orderStatus(int id) => '/delivery/mobile/orders/$id/status/';
  static String completeOrder(int id) =>
      '/delivery/mobile/orders/$id/complete/';
  static String failOrder(int id) => '/delivery/mobile/orders/$id/fail/';
  static String updateCustomerLocation(int id) =>
      '/delivery/mobile/orders/$id/update-customer-location/';

  // Legacy endpoints — kept for accept/reject/pickup which have no mobile equivalent yet
  static String acceptOrder(int id) => '/delivery/orders/$id/accept/';
  static String rejectOrder(int id) => '/delivery/orders/$id/reject/';
  static String pickupOrder(int id) => '/delivery/orders/$id/pickup/';
  static String codCollect(int id) => '/delivery/orders/$id/cod-collect/';
}
