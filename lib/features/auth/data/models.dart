class Agent {
  final int id;
  final String agentCode;
  final String name;
  final String mobileNumber;
  final String? email;
  final String? phoneNumber;
  final String? alternatePhone;
  final String? profilePhoto;
  final String vehicleType;
  final String? vehicleNumber;
  final String status;
  final int totalDeliveries;
  final int successfulDeliveries;
  final String averageRating;
  final int totalRatings;
  final String earningsBalance;
  final bool isActive;
  final bool isVerified;
  final String? businessName;
  final String dateJoined;

  Agent({
    required this.id,
    required this.agentCode,
    required this.name,
    required this.mobileNumber,
    this.email,
    this.phoneNumber,
    this.alternatePhone,
    this.profilePhoto,
    required this.vehicleType,
    this.vehicleNumber,
    required this.status,
    required this.totalDeliveries,
    required this.successfulDeliveries,
    required this.averageRating,
    required this.totalRatings,
    required this.earningsBalance,
    required this.isActive,
    required this.isVerified,
    this.businessName,
    required this.dateJoined,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] ?? 0,
      agentCode: json['agent_code'] ?? '',
      name: json['name'] ?? '',
      mobileNumber: json['mobile_number'] ?? '',
      email: json['email'],
      phoneNumber: json['phone_number'],
      alternatePhone: json['alternate_phone'],
      profilePhoto: json['profile_photo'],
      vehicleType: json['vehicle_type'] ?? 'BIKE',
      vehicleNumber: json['vehicle_number'],
      status: json['status'] ?? 'OFFLINE',
      totalDeliveries: json['total_deliveries'] ?? 0,
      successfulDeliveries: json['successful_deliveries'] ?? 0,
      averageRating: json['average_rating'] ?? '0.00',
      totalRatings: json['total_ratings'] ?? 0,
      earningsBalance: json['earnings_balance'] ?? '0.00',
      isActive: json['is_active'] ?? false,
      isVerified: json['is_verified'] ?? false,
      businessName: json['business_name'],
      dateJoined: json['date_joined'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agent_code': agentCode,
      'name': name,
      'mobile_number': mobileNumber,
      'email': email,
      'phone_number': phoneNumber,
      'alternate_phone': alternatePhone,
      'profile_photo': profilePhoto,
      'vehicle_type': vehicleType,
      'vehicle_number': vehicleNumber,
      'status': status,
      'total_deliveries': totalDeliveries,
      'successful_deliveries': successfulDeliveries,
      'average_rating': averageRating,
      'total_ratings': totalRatings,
      'earnings_balance': earningsBalance,
      'is_active': isActive,
      'is_verified': isVerified,
      'business_name': businessName,
      'date_joined': dateJoined,
    };
  }
}

class AuthTokens {
  final String access;
  final String refresh;

  AuthTokens({required this.access, required this.refresh});

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      access: json['access'] ?? '',
      refresh: json['refresh'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access': access,
      'refresh': refresh,
    };
  }
}

class AuthResponse {
  final bool success;
  final String message;
  final Agent? agent;
  final AuthTokens? tokens;
  final bool isVerified;
  final Map<String, dynamic>? errors;

  AuthResponse({
    required this.success,
    required this.message,
    this.agent,
    this.tokens,
    this.isVerified = false,
    this.errors,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    // agent.md: tokens are at root level, agent data is directly in 'data'
    // Check for tokens at root level first (agent.md format), then inside data (auth.md format)
    AuthTokens? tokens;
    if (json['tokens'] != null) {
      tokens = AuthTokens.fromJson(json['tokens']);
    } else if (data != null && data['tokens'] != null) {
      tokens = AuthTokens.fromJson(data['tokens']);
    }

    // Agent data: check if data contains agent fields directly (agent.md) or nested (auth.md)
    Agent? agent;
    if (data != null) {
      if (data['agent'] != null) {
        // auth.md format: data.agent
        agent = Agent.fromJson(data['agent']);
      } else if (data['id'] != null) {
        // agent.md format: data contains agent fields directly
        agent = Agent.fromJson(data);
      }
    }

    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      agent: agent,
      tokens: tokens,
      isVerified: data?['is_verified'] ?? json['is_verified'] ?? false,
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }
}

class ForgotPasswordResponse {
  final bool success;
  final String message;
  final String? mobileNumber;
  final String? expiresAt;
  final int? otpLength;
  final Map<String, dynamic>? errors;

  ForgotPasswordResponse({
    required this.success,
    required this.message,
    this.mobileNumber,
    this.expiresAt,
    this.otpLength,
    this.errors,
  });

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return ForgotPasswordResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      mobileNumber: data?['mobile_number'],
      expiresAt: data?['expires_at'],
      otpLength: data?['otp_length'],
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }
}

class VerifyOtpResponse {
  final bool success;
  final String message;
  final String? mobileNumber;
  final bool verified;
  final Map<String, dynamic>? errors;

  VerifyOtpResponse({
    required this.success,
    required this.message,
    this.mobileNumber,
    this.verified = false,
    this.errors,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return VerifyOtpResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      mobileNumber: data?['mobile_number'],
      verified: data?['verified'] ?? false,
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }
}

class VehicleType {
  static const String bike = 'BIKE';
  static const String bicycle = 'BICYCLE';
  static const String car = 'CAR';
  static const String van = 'VAN';
  static const String truck = 'TRUCK';
  static const String walk = 'WALK';

  static List<String> get all => [bike, bicycle, car, van, truck, walk];

  static String displayName(String type) {
    switch (type) {
      case bike:
        return 'Bike';
      case bicycle:
        return 'Bicycle';
      case car:
        return 'Car';
      case van:
        return 'Van';
      case truck:
        return 'Truck';
      case walk:
        return 'Walk';
      default:
        return type;
    }
  }
}
