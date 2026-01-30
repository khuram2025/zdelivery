import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../providers/auth_provider.dart';

enum ForgotPasswordStep { enterMobile, verifyOtp, resetPassword }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  ForgotPasswordStep _currentStep = ForgotPasswordStep.enterMobile;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _mobileNumber = '';

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  Future<void> _requestOtp() async {
    if (_formKey.currentState?.validate() ?? false) {
      _mobileNumber = _mobileController.text.trim();
      final response = await ref.read(authStateProvider.notifier).forgotPassword(_mobileNumber);

      if (response != null && mounted) {
        setState(() {
          _currentStep = ForgotPasswordStep.verifyOtp;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await ref.read(authStateProvider.notifier).verifyOtp(
            _mobileNumber,
            _otpController.text.trim(),
          );

      if (success && mounted) {
        setState(() {
          _currentStep = ForgotPasswordStep.resetPassword;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await ref.read(authStateProvider.notifier).resetPassword(
            mobileNumber: _mobileNumber,
            otpCode: _otpController.text.trim(),
            newPassword: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successful!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/home');
      }
    }
  }

  void _goBack() {
    if (_currentStep == ForgotPasswordStep.enterMobile) {
      context.pop();
    } else {
      setState(() {
        if (_currentStep == ForgotPasswordStep.resetPassword) {
          _currentStep = ForgotPasswordStep.verifyOtp;
        } else {
          _currentStep = ForgotPasswordStep.enterMobile;
        }
      });
      ref.read(authStateProvider.notifier).clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress Indicator
                  _buildProgressIndicator(),
                  const SizedBox(height: 32),

                  // Step Content
                  _buildStepContent(authState),

                  const SizedBox(height: 24),

                  // Error Message
                  if (authState.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              authState.error!,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Action Button
                  CustomButton(
                    text: _getButtonText(),
                    onPressed: _getButtonAction(),
                    isLoading: authState.isLoading,
                  ),

                  if (_currentStep == ForgotPasswordStep.verifyOtp) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: authState.isLoading
                          ? null
                          : () async {
                              await ref
                                  .read(authStateProvider.notifier)
                                  .forgotPassword(_mobileNumber);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('OTP resent successfully'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            },
                      child: const Text('Resend OTP'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        _buildProgressStep(1, 'Mobile', _currentStep.index >= 0),
        Expanded(
          child: Container(
            height: 2,
            color: _currentStep.index >= 1
                ? AppColors.primary
                : AppColors.textTertiary.withOpacity(0.3),
          ),
        ),
        _buildProgressStep(2, 'Verify', _currentStep.index >= 1),
        Expanded(
          child: Container(
            height: 2,
            color: _currentStep.index >= 2
                ? AppColors.primary
                : AppColors.textTertiary.withOpacity(0.3),
          ),
        ),
        _buildProgressStep(3, 'Reset', _currentStep.index >= 2),
      ],
    );
  }

  Widget _buildProgressStep(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.textTertiary.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textTertiary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppColors.primary : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent(AuthState authState) {
    switch (_currentStep) {
      case ForgotPasswordStep.enterMobile:
        return _buildEnterMobileStep();
      case ForgotPasswordStep.verifyOtp:
        return _buildVerifyOtpStep();
      case ForgotPasswordStep.resetPassword:
        return _buildResetPasswordStep();
    }
  }

  Widget _buildEnterMobileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.phone_android,
          size: 48,
          color: AppColors.primary,
        ),
        const SizedBox(height: 16),
        const Text(
          'Enter your mobile number',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'We will send you an OTP to verify your identity',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          decoration: const InputDecoration(
            labelText: 'Mobile Number',
            hintText: '03XXXXXXXXX',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your mobile number';
            }
            if (value.length < 10) {
              return 'Please enter a valid mobile number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildVerifyOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.sms_outlined,
          size: 48,
          color: AppColors.primary,
        ),
        const SizedBox(height: 16),
        const Text(
          'Enter verification code',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 6-digit code sent to $_mobileNumber',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          decoration: const InputDecoration(
            labelText: 'OTP Code',
            hintText: '------',
            prefixIcon: Icon(Icons.pin_outlined),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the OTP';
            }
            if (value.length != 6) {
              return 'OTP must be 6 digits';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildResetPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.lock_reset,
          size: 48,
          color: AppColors.primary,
        ),
        const SizedBox(height: 16),
        const Text(
          'Create new password',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your new password must be different from previously used passwords',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'New Password',
            hintText: 'Min 8 chars with uppercase, lowercase & number',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          validator: _validatePassword,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            hintText: 'Re-enter your password',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  String _getTitle() {
    switch (_currentStep) {
      case ForgotPasswordStep.enterMobile:
        return 'Forgot Password';
      case ForgotPasswordStep.verifyOtp:
        return 'Verify OTP';
      case ForgotPasswordStep.resetPassword:
        return 'Reset Password';
    }
  }

  String _getButtonText() {
    switch (_currentStep) {
      case ForgotPasswordStep.enterMobile:
        return 'Send OTP';
      case ForgotPasswordStep.verifyOtp:
        return 'Verify';
      case ForgotPasswordStep.resetPassword:
        return 'Reset Password';
    }
  }

  VoidCallback _getButtonAction() {
    switch (_currentStep) {
      case ForgotPasswordStep.enterMobile:
        return _requestOtp;
      case ForgotPasswordStep.verifyOtp:
        return _verifyOtp;
      case ForgotPasswordStep.resetPassword:
        return _resetPassword;
    }
  }
}
