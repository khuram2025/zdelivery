import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/app_constants.dart';
import '../features/auth/data/models.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthService(this._apiService);

  // Register a new delivery agent
  Future<AuthResponse> register({
    required String mobileNumber,
    required String password,
    required String passwordConfirm,
    required String name,
    String? email,
    String? alternatePhone,
    String? vehicleType,
    String? vehicleNumber,
    String? businessCode,
  }) async {
    final data = {
      'mobile_number': mobileNumber,
      'password': password,
      'password_confirm': passwordConfirm,
      'name': name,
    };

    if (email != null && email.isNotEmpty) data['email'] = email;
    if (alternatePhone != null && alternatePhone.isNotEmpty) {
      data['alternate_phone'] = alternatePhone;
    }
    if (vehicleType != null) data['vehicle_type'] = vehicleType;
    if (vehicleNumber != null && vehicleNumber.isNotEmpty) {
      data['vehicle_number'] = vehicleNumber;
    }
    if (businessCode != null && businessCode.isNotEmpty) {
      data['business_code'] = businessCode;
    }

    final response = await _apiService.post(ApiConstants.register, data: data);
    final authResponse = AuthResponse.fromJson(response.data);

    if (authResponse.success && authResponse.tokens != null) {
      await _saveAuthData(authResponse);
    }

    return authResponse;
  }

  // Login
  Future<AuthResponse> login(String mobileNumber, String password) async {
    try {
      final response = await _apiService.post(
        ApiConstants.login,
        data: {
          'mobile_number': mobileNumber,
          'password': password,
        },
      );

      print('Login response: ${response.data}'); // Debug log

      final authResponse = AuthResponse.fromJson(response.data);

      if (authResponse.success && authResponse.tokens != null) {
        await _saveAuthData(authResponse);
      }

      return authResponse;
    } catch (e) {
      print('Login error: $e'); // Debug log
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken != null) {
        await _apiService.post(
          ApiConstants.logout,
          data: {'refresh_token': refreshToken}, // auth.md uses 'refresh_token' key
        );
      }
    } catch (e) {
      // Ignore errors during logout API call
    } finally {
      await _clearAuthData();
    }
  }

  // Forgot Password - Request OTP
  Future<ForgotPasswordResponse> forgotPassword(String mobileNumber) async {
    final response = await _apiService.post(
      ApiConstants.forgotPassword,
      data: {'mobile_number': mobileNumber},
    );
    return ForgotPasswordResponse.fromJson(response.data);
  }

  // Verify OTP
  Future<VerifyOtpResponse> verifyOtp(String mobileNumber, String otpCode) async {
    final response = await _apiService.post(
      ApiConstants.verifyOtp,
      data: {
        'mobile_number': mobileNumber,
        'otp_code': otpCode,
      },
    );
    return VerifyOtpResponse.fromJson(response.data);
  }

  // Reset Password
  Future<AuthResponse> resetPassword({
    required String mobileNumber,
    required String otpCode,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _apiService.post(
      ApiConstants.resetPassword,
      data: {
        'mobile_number': mobileNumber,
        'otp_code': otpCode,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
    );

    final authResponse = AuthResponse.fromJson(response.data);

    if (authResponse.success && authResponse.tokens != null) {
      await _saveAuthData(authResponse);
    }

    return authResponse;
  }

  // Refresh Token
  Future<String?> refreshAccessToken() async {
    final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
    if (refreshToken == null) return null;

    try {
      final response = await _apiService.post(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken}, // auth.md uses 'refresh_token' key
      );

      // auth.md: access token is in data.access
      final newAccessToken = response.data['data']?['access'] ?? response.data['access'];
      if (newAccessToken != null) {
        await _storage.write(key: AppConstants.accessTokenKey, value: newAccessToken);
        return newAccessToken;
      }
    } catch (e) {
      // Token refresh failed
    }
    return null;
  }

  // Change Password (authenticated)
  Future<AuthResponse> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _apiService.post(
      ApiConstants.changePassword,
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
    );

    final authResponse = AuthResponse.fromJson(response.data);

    // Update tokens if provided
    if (authResponse.success && authResponse.tokens != null) {
      await _storage.write(
        key: AppConstants.accessTokenKey,
        value: authResponse.tokens!.access,
      );
      await _storage.write(
        key: AppConstants.refreshTokenKey,
        value: authResponse.tokens!.refresh,
      );
    }

    return authResponse;
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    return token != null;
  }

  // Get current agent
  Future<Agent?> getCurrentAgent() async {
    final agentData = await _storage.read(key: AppConstants.userDataKey);
    if (agentData != null) {
      return Agent.fromJson(jsonDecode(agentData));
    }
    return null;
  }

  // Get access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: AppConstants.accessTokenKey);
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: AppConstants.refreshTokenKey);
  }

  // Save auth data
  Future<void> _saveAuthData(AuthResponse authResponse) async {
    if (authResponse.tokens != null) {
      await _storage.write(
        key: AppConstants.accessTokenKey,
        value: authResponse.tokens!.access,
      );
      await _storage.write(
        key: AppConstants.refreshTokenKey,
        value: authResponse.tokens!.refresh,
      );
    }
    if (authResponse.agent != null) {
      await _storage.write(
        key: AppConstants.userDataKey,
        value: jsonEncode(authResponse.agent!.toJson()),
      );
    }
  }

  // Clear auth data
  Future<void> _clearAuthData() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.userDataKey);
  }

  // Update stored agent data
  Future<void> updateStoredAgent(Agent agent) async {
    await _storage.write(
      key: AppConstants.userDataKey,
      value: jsonEncode(agent.toJson()),
    );
  }

  // Parse error response
  String parseErrorResponse(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        if (data['message'] != null) {
          return data['message'];
        }
        if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          final messages = <String>[];
          errors.forEach((key, value) {
            if (value is List) {
              messages.addAll(value.map((e) => e.toString()));
            } else {
              messages.add(value.toString());
            }
          });
          return messages.join('\n');
        }
      }
    }
    return 'An error occurred. Please try again.';
  }
}
