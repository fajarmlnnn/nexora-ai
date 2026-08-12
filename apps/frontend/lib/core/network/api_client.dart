import 'dart:async';

import 'package:dio/dio.dart';

import 'api_config.dart';
import 'api_exception.dart';
import 'token_store.dart';

class ApiClient {
  ApiClient({
    Dio? dio,
    TokenStore? tokenStore,
    Duration timeout = const Duration(seconds: 20),
  })  : _dio = dio ?? Dio(),
        _tokenStore = tokenStore ?? TokenStore() {
    _dio.options = _dio.options.copyWith(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: timeout,
      receiveTimeout: timeout,
      sendTimeout: timeout,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      validateStatus: (status) => status != null && status >= 200 && status < 300,
    );
  }

  final Dio _dio;
  final TokenStore _tokenStore;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) =>
      _send(() => _dio.get(path, queryParameters: query));

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) =>
      _send(
        () => _dio.post(
          path,
          data: body ?? const <String, dynamic>{},
          options: Options(
            headers: idempotencyKey == null
                ? null
                : {'Idempotency-Key': idempotencyKey},
          ),
        ),
      );

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) =>
      _send(() => _dio.put(path, data: body ?? const <String, dynamic>{}));

  Future<Map<String, dynamic>> delete(String path) => _send(() => _dio.delete(path));

  Future<Map<String, dynamic>> _send(Future<Response<dynamic>> Function() request) async {
    final token = await _tokenStore.read();
    final previousAuthorization = _dio.options.headers['Authorization'];

    if (token != null && token.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }

    try {
      final response = await request();
      final payload = _asMap(response.data);
      if (payload == null) {
        throw ApiException(
          statusCode: response.statusCode ?? 0,
          code: 'INVALID_RESPONSE',
          message: 'The server returned an invalid response.',
        );
      }
      return payload;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode == 401) {
        await _tokenStore.clear();
      }
      throw _toException(statusCode, error.response?.data, error);
    } finally {
      if (previousAuthorization == null) {
        _dio.options.headers.remove('Authorization');
      } else {
        _dio.options.headers['Authorization'] = previousAuthorization;
      }
    }
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  ApiException _toException(int statusCode, dynamic payload, DioException error) {
    final map = _asMap(payload);
    final apiError = _asMap(map?['error']);
    final errors = map?['errors'];

    if (apiError != null) {
      return ApiException(
        statusCode: statusCode,
        code: apiError['code']?.toString() ?? 'API_ERROR',
        message: apiError['message']?.toString() ?? 'The request failed.',
        fields: _parseFields(apiError['fields']),
      );
    }

    if (errors is Map) {
      return ApiException(
        statusCode: statusCode,
        code: statusCode == 422 ? 'VALIDATION_ERROR' : 'API_ERROR',
        message: map?['message']?.toString() ?? 'The request failed.',
        fields: _parseFields(errors),
      );
    }

    if (statusCode == 0) {
      final code = error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout
          ? 'NETWORK_TIMEOUT'
          : 'NETWORK_ERROR';
      return ApiException(
        statusCode: 0,
        code: code,
        message: error.message ?? 'Unable to reach the server.',
      );
    }

    return ApiException(
      statusCode: statusCode,
      code: map?['code']?.toString() ?? 'HTTP_$statusCode',
      message: map?['message']?.toString() ?? 'The request failed.',
    );
  }

  Map<String, List<String>> _parseFields(dynamic value) {
    if (value is! Map) return const {};
    return value.map(
      (key, value) => MapEntry(
        key.toString(),
        value is List
            ? value.map((item) => item.toString()).toList(growable: false)
            : [value.toString()],
      ),
    );
  }

  void dispose() => _dio.close(force: true);
}
