import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'token_store.dart';

class ApiClient {
  ApiClient({
    http.Client? client,
    TokenStore? tokenStore,
    Duration timeout = const Duration(seconds: 20),
  })  : _client = client ?? http.Client(),
        _tokenStore = tokenStore ?? TokenStore(),
        _timeout = timeout;

  final http.Client _client;
  final TokenStore _tokenStore;
  final Duration _timeout;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) =>
      _send('GET', path, query: query);

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) =>
      _send('POST', path, body: body, idempotencyKey: idempotencyKey);

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) =>
      _send('PUT', path, body: body);

  Future<Map<String, dynamic>> delete(String path) => _send('DELETE', path);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) async {
    final token = await _tokenStore.read();
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
      headers['Idempotency-Key'] = idempotencyKey;
    }

    final uri = ApiConfig.endpoint(path, query);
    late http.Response response;

    try {
      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: headers).timeout(_timeout);
        case 'POST':
          response = await _client
              .post(uri, headers: headers, body: jsonEncode(body ?? const {}))
              .timeout(_timeout);
        case 'PUT':
          response = await _client
              .put(uri, headers: headers, body: jsonEncode(body ?? const {}))
              .timeout(_timeout);
        case 'DELETE':
          response = await _client.delete(uri, headers: headers).timeout(_timeout);
        default:
          throw StateError('Unsupported HTTP method: $method');
      }
    } on TimeoutException {
      throw const ApiException(
        statusCode: 0,
        code: 'NETWORK_TIMEOUT',
        message: 'The server took too long to respond.',
      );
    } on http.ClientException catch (error) {
      throw ApiException(
        statusCode: 0,
        code: 'NETWORK_ERROR',
        message: error.message,
      );
    }

    final payload = _decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (payload is! Map<String, dynamic>) {
        throw ApiException(
          statusCode: response.statusCode,
          code: 'INVALID_RESPONSE',
          message: 'The server returned an invalid response.',
        );
      }
      return payload;
    }

    if (response.statusCode == 401) {
      await _tokenStore.clear();
    }

    throw _toException(response.statusCode, payload);
  }

  dynamic _decode(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  ApiException _toException(int statusCode, dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final error = payload['error'];
      if (error is Map<String, dynamic>) {
        return ApiException(
          statusCode: statusCode,
          code: error['code']?.toString() ?? 'API_ERROR',
          message: error['message']?.toString() ?? 'The request failed.',
          fields: _parseFields(error['fields']),
        );
      }

      final errors = payload['errors'];
      if (errors is Map) {
        return ApiException(
          statusCode: statusCode,
          code: statusCode == 422 ? 'VALIDATION_ERROR' : 'API_ERROR',
          message: payload['message']?.toString() ?? 'The request failed.',
          fields: _parseFields(errors),
        );
      }

      return ApiException(
        statusCode: statusCode,
        code: payload['code']?.toString() ?? 'API_ERROR',
        message: payload['message']?.toString() ?? 'The request failed.',
      );
    }

    return ApiException(
      statusCode: statusCode,
      code: 'HTTP_$statusCode',
      message: 'The server returned HTTP $statusCode.',
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

  void dispose() => _client.close();
}
