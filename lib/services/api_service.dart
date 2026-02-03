import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/app_constants.dart';
import '../core/services/session_manager.dart';

/// Custom exception for network errors
class NetworkException implements Exception {
  final String message;
  final bool isOffline;

  NetworkException(this.message, {this.isOffline = false});

  @override
  String toString() => message;
}

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final SessionManager _sessionManager = SessionManager();

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: AppConstants.accessTokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle network errors
          if (_isNetworkError(error)) {
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                error: NetworkException(
                  'No internet connection. Please check your network.',
                  isOffline: true,
                ),
                type: DioExceptionType.connectionError,
              ),
            );
          }

          // Handle 401 Unauthorized
          if (error.response?.statusCode == 401) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry the request with new token
              final retryResponse = await _retry(error.requestOptions);
              return handler.resolve(retryResponse);
            } else {
              // Token refresh failed - session expired
              await _sessionManager.handleSessionExpired();
              return handler.reject(
                DioException(
                  requestOptions: error.requestOptions,
                  error: AuthException('Session expired. Please login again.'),
                  type: DioExceptionType.badResponse,
                  response: error.response,
                ),
              );
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  bool _isNetworkError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.error is SocketException;
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '${ApiConstants.baseUrl}${ApiConstants.refreshToken}',
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['data']?['access'] ?? response.data['access'];
        if (newAccessToken != null) {
          await _storage.write(key: AppConstants.accessTokenKey, value: newAccessToken);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $token',
      },
    );
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  // GET request
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  // POST request
  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  // PATCH request
  Future<Response> patch(String path, {dynamic data}) async {
    return await _dio.patch(path, data: data);
  }

  // POST with multipart
  Future<Response> postMultipart(
    String path, {
    required Map<String, dynamic> data,
    File? file,
    String? fileField,
    File? signatureFile,
  }) async {
    final formData = FormData();

    data.forEach((key, value) {
      if (value != null) {
        formData.fields.add(MapEntry(key, value.toString()));
      }
    });

    if (file != null && fileField != null) {
      formData.files.add(
        MapEntry(
          fileField,
          await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
        ),
      );
    }

    if (signatureFile != null) {
      formData.files.add(
        MapEntry(
          'signature_image',
          await MultipartFile.fromFile(signatureFile.path, filename: 'signature.png'),
        ),
      );
    }

    return await _dio.post(
      path,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  // PATCH with multipart
  Future<Response> patchMultipart(
    String path, {
    required Map<String, dynamic> data,
    File? file,
    String? fileField,
  }) async {
    final formData = FormData();

    data.forEach((key, value) {
      if (value != null) {
        formData.fields.add(MapEntry(key, value.toString()));
      }
    });

    if (file != null && fileField != null) {
      formData.files.add(
        MapEntry(
          fileField,
          await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
        ),
      );
    }

    return await _dio.patch(
      path,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  /// Helper to check if error is a network error
  static bool isNetworkError(Object error) {
    if (error is DioException) {
      return error.error is NetworkException ||
          error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout;
    }
    return false;
  }

  /// Helper to check if error is an auth error
  static bool isAuthError(Object error) {
    if (error is DioException) {
      return error.error is AuthException || error.response?.statusCode == 401;
    }
    return false;
  }

  /// Get user-friendly error message from exception
  static String getErrorMessage(Object error) {
    if (error is DioException) {
      if (error.error is NetworkException) {
        return (error.error as NetworkException).message;
      }
      if (error.error is AuthException) {
        return (error.error as AuthException).message;
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return 'No internet connection. Please check your network.';
      }
      if (error.response?.data != null && error.response!.data is Map) {
        final data = error.response!.data as Map;
        if (data['message'] != null) {
          return data['message'].toString();
        }
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
