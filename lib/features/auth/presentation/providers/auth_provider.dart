import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/api_service.dart';
import '../../../../services/auth_service.dart';
import '../../data/models.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(apiServiceProvider));
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final Agent? agent;
  final String? error;
  final String? successMessage;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.agent,
    this.error,
    this.successMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    Agent? agent,
    String? error,
    String? successMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      agent: agent ?? this.agent,
      error: error,
      successMessage: successMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState());

  // Check auth status on app start
  Future<void> checkAuthStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      final agent = await _authService.getCurrentAgent();
      state = state.copyWith(isAuthenticated: true, agent: agent);
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Clear success message
  void clearSuccessMessage() {
    state = state.copyWith(successMessage: null);
  }

  // Login
  Future<bool> login(String mobileNumber, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.login(mobileNumber, password);

      // agent.md: Login returns tokens but not agent profile
      // Agent profile should be fetched separately via /delivery/agents/profile/
      if (response.success && response.tokens != null) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          agent: response.agent, // May be null for agent.md format, profile loaded separately
        );
        return true;
      } else {
        String errorMessage = response.message;
        if (response.errors != null) {
          final errors = response.errors!;
          if (errors['non_field_errors'] != null) {
            errorMessage = (errors['non_field_errors'] as List).first;
          }
        }
        state = state.copyWith(isLoading: false, error: errorMessage);
        return false;
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _authService.parseErrorResponse(e),
      );
      return false;
    } catch (e) {
      print('Login exception: $e'); // Debug log
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Register
  Future<bool> register({
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
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.register(
        mobileNumber: mobileNumber,
        password: password,
        passwordConfirm: passwordConfirm,
        name: name,
        email: email,
        alternatePhone: alternatePhone,
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
        businessCode: businessCode,
      );

      // Registration may return tokens without full agent profile
      if (response.success && response.tokens != null) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          agent: response.agent,
          successMessage: response.message,
        );
        return true;
      } else {
        String errorMessage = response.message;
        if (response.errors != null) {
          final messages = <String>[];
          response.errors!.forEach((key, value) {
            if (value is List) {
              messages.addAll(value.map((e) => e.toString()));
            } else {
              messages.add(value.toString());
            }
          });
          if (messages.isNotEmpty) {
            errorMessage = messages.join('\n');
          }
        }
        state = state.copyWith(isLoading: false, error: errorMessage);
        return false;
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _authService.parseErrorResponse(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred. Please try again.',
      );
      return false;
    }
  }

  // Forgot Password
  Future<ForgotPasswordResponse?> forgotPassword(String mobileNumber) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.forgotPassword(mobileNumber);

      if (response.success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: response.message,
        );
        return response;
      } else {
        String errorMessage = response.message;
        if (response.errors != null) {
          final messages = <String>[];
          response.errors!.forEach((key, value) {
            if (value is List) {
              messages.addAll(value.map((e) => e.toString()));
            } else {
              messages.add(value.toString());
            }
          });
          if (messages.isNotEmpty) {
            errorMessage = messages.join('\n');
          }
        }
        state = state.copyWith(isLoading: false, error: errorMessage);
        return null;
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _authService.parseErrorResponse(e),
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred. Please try again.',
      );
      return null;
    }
  }

  // Verify OTP
  Future<bool> verifyOtp(String mobileNumber, String otpCode) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.verifyOtp(mobileNumber, otpCode);

      if (response.success && response.verified) {
        state = state.copyWith(
          isLoading: false,
          successMessage: response.message,
        );
        return true;
      } else {
        String errorMessage = response.message;
        if (response.errors != null) {
          final messages = <String>[];
          response.errors!.forEach((key, value) {
            if (value is List) {
              messages.addAll(value.map((e) => e.toString()));
            } else {
              messages.add(value.toString());
            }
          });
          if (messages.isNotEmpty) {
            errorMessage = messages.join('\n');
          }
        }
        state = state.copyWith(isLoading: false, error: errorMessage);
        return false;
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _authService.parseErrorResponse(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred. Please try again.',
      );
      return false;
    }
  }

  // Reset Password
  Future<bool> resetPassword({
    required String mobileNumber,
    required String otpCode,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.resetPassword(
        mobileNumber: mobileNumber,
        otpCode: otpCode,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      // Reset password may auto-login with tokens but without full agent profile
      if (response.success && response.tokens != null) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          agent: response.agent,
          successMessage: response.message,
        );
        return true;
      } else if (response.success) {
        // Password reset successful but no auto-login
        state = state.copyWith(
          isLoading: false,
          successMessage: response.message,
        );
        return true;
      } else {
        String errorMessage = response.message;
        if (response.errors != null) {
          final messages = <String>[];
          response.errors!.forEach((key, value) {
            if (value is List) {
              messages.addAll(value.map((e) => e.toString()));
            } else {
              messages.add(value.toString());
            }
          });
          if (messages.isNotEmpty) {
            errorMessage = messages.join('\n');
          }
        }
        state = state.copyWith(isLoading: false, error: errorMessage);
        return false;
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _authService.parseErrorResponse(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred. Please try again.',
      );
      return false;
    }
  }

  // Change Password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (response.success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: response.message,
        );
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: response.message);
        return false;
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _authService.parseErrorResponse(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred. Please try again.',
      );
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    state = AuthState();
  }

  // Update agent in state
  void updateAgent(Agent agent) {
    state = state.copyWith(agent: agent);
  }
}
