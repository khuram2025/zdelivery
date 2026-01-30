import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/app_constants.dart';

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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
          if (error.response?.statusCode == 401) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              final retryResponse = await _retry(error.requestOptions);
              return handler.resolve(retryResponse);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '${ApiConstants.baseUrl}${ApiConstants.refreshToken}',
        data: {'refresh_token': refreshToken}, // auth.md uses 'refresh_token' key
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // auth.md: access token is in data.access
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
}
