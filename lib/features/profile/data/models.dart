class AgentProfile {
  final int id;
  final String agentCode;
  final String name;
  final String phoneNumber;
  final String alternatePhone;
  final String? profilePhoto;
  final String vehicleType;
  final String vehicleNumber;
  final String status;
  final int totalDeliveries;
  final int successfulDeliveries;
  final double averageRating;
  final int totalRatings;
  final double earningsBalance;
  final double totalEarnings;
  final bool isVerified;

  AgentProfile({
    required this.id,
    required this.agentCode,
    required this.name,
    required this.phoneNumber,
    required this.alternatePhone,
    this.profilePhoto,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.status,
    required this.totalDeliveries,
    required this.successfulDeliveries,
    required this.averageRating,
    required this.totalRatings,
    required this.earningsBalance,
    required this.totalEarnings,
    required this.isVerified,
  });

  factory AgentProfile.fromJson(Map<String, dynamic> json) {
    return AgentProfile(
      id: json['id'] ?? 0,
      agentCode: json['agent_code'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      alternatePhone: json['alternate_phone'] ?? '',
      profilePhoto: json['profile_photo'],
      vehicleType: json['vehicle_type'] ?? 'BIKE',
      vehicleNumber: json['vehicle_number'] ?? '',
      status: json['status'] ?? 'OFFLINE',
      totalDeliveries: json['total_deliveries'] ?? 0,
      successfulDeliveries: json['successful_deliveries'] ?? 0,
      averageRating: double.tryParse(json['average_rating']?.toString() ?? '0') ?? 0,
      totalRatings: json['total_ratings'] ?? 0,
      earningsBalance: double.tryParse(json['earnings_balance']?.toString() ?? '0') ?? 0,
      totalEarnings: double.tryParse(json['total_earnings']?.toString() ?? '0') ?? 0,
      isVerified: json['is_verified'] ?? false,
    );
  }

  double get successRate {
    if (totalDeliveries == 0) return 0;
    return (successfulDeliveries / totalDeliveries) * 100;
  }
}
