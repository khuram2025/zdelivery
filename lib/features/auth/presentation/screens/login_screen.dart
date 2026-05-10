import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _localError;
  Timer? _timeoutTimer;
  int _timeoutSeconds = 0;
  bool _showSlowWarning = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startTimeoutTimer() {
    _timeoutSeconds = 0;
    _showSlowWarning = false;
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _timeoutSeconds++;
      if (_timeoutSeconds == 10) {
        setState(() => _showSlowWarning = true);
      }
      if (_timeoutSeconds >= 30) {
        timer.cancel();
        // Force stop loading after 30s
        ref.read(authStateProvider.notifier).clearError();
        setState(() {
          _localError = 'Connection timed out. Please check:\n'
              '- Your internet connection is working\n'
              '- Try switching between WiFi and Mobile Data\n'
              '- Restart the app and try again';
          _showSlowWarning = false;
        });
      }
    });
  }

  void _stopTimeoutTimer() {
    _timeoutTimer?.cancel();
    _showSlowWarning = false;
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _localError = null;
        _showSlowWarning = false;
      });

      _startTimeoutTimer();

      try {
        final success = await ref.read(authStateProvider.notifier).login(
              _mobileController.text.trim(),
              _passwordController.text,
            );

        _stopTimeoutTimer();

        if (success && mounted) {
          context.go('/home');
        }
      } on SocketException catch (_) {
        _stopTimeoutTimer();
        if (mounted) {
          setState(() {
            _localError = 'Cannot reach server. Please check your internet connection.';
          });
        }
      } on TimeoutException catch (_) {
        _stopTimeoutTimer();
        if (mounted) {
          setState(() {
            _localError = 'Server is not responding. Please try again later.';
          });
        }
      } catch (e) {
        _stopTimeoutTimer();
        if (mounted) {
          setState(() {
            _localError = 'Unexpected error: ${e.runtimeType}\nPlease screenshot this and report.';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final displayError = _localError ?? authState.error;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),

                  // Logo/Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Sign in to continue delivering',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // Mobile Number Field
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

                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        context.push('/forgot-password');
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Slow connection warning
                  if (_showSlowWarning && authState.isLoading)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.wifi_find, color: AppColors.warning),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Taking longer than usual...\nPlease check your internet connection.',
                              style: TextStyle(color: AppColors.warning, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Error Message
                  if (displayError != null && !authState.isLoading)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              displayError,
                              style: const TextStyle(color: AppColors.error, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Login Button
                  CustomButton(
                    text: 'Sign In',
                    onPressed: authState.isLoading ? null : _login,
                    isLoading: authState.isLoading,
                  ),

                  const SizedBox(height: 24),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.push('/register');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
