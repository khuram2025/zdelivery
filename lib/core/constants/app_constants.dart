class AppConstants {
  static const String appName = 'ZDelivery';
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
}

class AgentStatus {
  static const String available = 'AVAILABLE';
  static const String busy = 'BUSY';
  static const String offline = 'OFFLINE';
  static const String onBreak = 'ON_BREAK';
}

class DeliveryStatus {
  static const String pending = 'PENDING';
  static const String assigned = 'ASSIGNED';
  static const String accepted = 'ACCEPTED';
  static const String rejected = 'REJECTED';
  static const String pickedUp = 'PICKED_UP';
  static const String inTransit = 'IN_TRANSIT';
  static const String outForDelivery = 'OUT_FOR_DELIVERY';
  static const String arrived = 'ARRIVED';
  static const String delivered = 'DELIVERED';
  static const String failed = 'FAILED';
  static const String returned = 'RETURNED';
  static const String cancelled = 'CANCELLED';
}

class FailureReason {
  static const String customerUnavailable = 'CUSTOMER_UNAVAILABLE';
  static const String wrongAddress = 'WRONG_ADDRESS';
  static const String customerRefused = 'CUSTOMER_REFUSED';
  static const String damagedGoods = 'DAMAGED_GOODS';
  static const String paymentIssue = 'PAYMENT_ISSUE';
  static const String weather = 'WEATHER';
  static const String vehicleIssue = 'VEHICLE_ISSUE';
  static const String other = 'OTHER';

  static Map<String, String> get displayNames => {
        customerUnavailable: 'Customer Not Available',
        wrongAddress: 'Wrong/Incomplete Address',
        customerRefused: 'Customer Refused',
        damagedGoods: 'Goods Damaged',
        paymentIssue: 'Payment Issue (COD)',
        weather: 'Bad Weather',
        vehicleIssue: 'Vehicle Breakdown',
        other: 'Other',
      };
}
