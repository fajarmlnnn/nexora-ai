import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase, SupabaseClient;

import '../../../core/network/api_exception.dart';
import '../../finance/state/financial_analytics_provider.dart';

class AiGatewayHealth {
  const AiGatewayHealth({
    required this.configured,
    required this.reachable,
    required this.message,
  });

  final bool configured;
  final bool reachable;
  final String message;

  bool get ready => configured && reachable;
}

class AiApiService {
  AiApiService({
    SupabaseClient? supabase,
    Dio? dio,
    String? baseUrl,
  })  : _supabaseOverride = supabase,
        _dio = dio ?? Dio(),
        _baseUrl = _normalizeBaseUrl(
          baseUrl ?? const String.fromEnvironment('NEXORA_API_BASE_URL'),
        );

  final SupabaseClient? _supabaseOverride;
  final Dio _dio;
  final String _baseUrl;

  SupabaseClient get _supabase => _supabaseOverride ?? Supabase.instance.client;

  bool get isConfigured => _baseUrl.isNotEmpty;

  /// Accept either the complete API root (`.../api/v1`) or the backend host.
  static String _normalizeBaseUrl(String raw) {
    final value = raw.trim().replaceFirst(RegExp(r'/+$'), '');
    if (value.isEmpty) return '';
    if (value.endsWith('/api/v1')) return value;
    if (value.endsWith('/api')) return '$value/v1';
    return '$value/api/v1';
  }

  Future<AiGatewayHealth> health() async {
    if (_baseUrl.isEmpty) {
      return const AiGatewayHealth(
        configured: false,
        reachable: false,
        message: 'Server AI belum dikonfigurasi',
      );
    }

    final session = _supabase.auth.currentSession;
    if (session == null) {
      return const AiGatewayHealth(
        configured: true,
        reachable: false,
        message: 'Sesi login tidak ditemukan. Silakan masuk kembali.',
      );
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/ai/health',
        options: Options(
          headers: {'Authorization': 'Bearer ${session.accessToken}'},
          responseType: ResponseType.json,
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      final success = response.data?['success'] == true;
      if (success) {
        return const AiGatewayHealth(
          configured: true,
          reachable: true,
          message: 'Gateway AI siap',
        );
      }
      return const AiGatewayHealth(
        configured: true,
        reachable: false,
        message: 'Gateway AI belum siap',
      );
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 503) {
        return const AiGatewayHealth(
          configured: true,
          reachable: false,
          message: 'Penyedia AI belum tersedia',
        );
      }
      return const AiGatewayHealth(
        configured: true,
        reachable: false,
        message: 'Tidak bisa terhubung ke server AI',
      );
    } catch (_) {
      return const AiGatewayHealth(
        configured: true,
        reachable: false,
        message: 'Tidak bisa terhubung ke server AI',
      );
    }
  }

  Future<String> chat({
    required List<AiChatMessage> messages,
    required FinancialAnalyticsSnapshot analytics,
  }) async {
    if (_baseUrl.isEmpty) {
      throw const ApiException(
        statusCode: 0,
        code: 'API_BASE_URL_MISSING',
        message: 'Server AI belum dikonfigurasi pada aplikasi ini.',
      );
    }

    var session = _supabase.auth.currentSession;
    if (session == null) {
      throw const ApiException(
        statusCode: 401,
        code: 'UNAUTHENTICATED',
        message: 'Sesi login tidak ditemukan. Silakan login kembali.',
      );
    }

    try {
      return await _send(session.accessToken, messages, analytics);
    } on ApiException catch (error) {
      if (error.statusCode != 401) rethrow;

      final refreshed = await _supabase.auth.refreshSession();
      session = refreshed.session;
      if (session == null) {
        throw const ApiException(
          statusCode: 401,
          code: 'UNAUTHENTICATED',
          message: 'Sesi login sudah kedaluwarsa. Silakan login kembali.',
        );
      }

      return _send(session.accessToken, messages, analytics);
    }
  }

  Future<String> _send(
    String accessToken,
    List<AiChatMessage> messages,
    FinancialAnalyticsSnapshot analytics,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_baseUrl/ai/chat',
        data: {
          'messages': messages.map((message) => message.toJson()).toList(),
          'financial_context': {
            'income': analytics.income,
            'expense': analytics.expense,
            'net_cashflow': analytics.netCashflow,
            'savings_rate': analytics.savingsRate,
            if (analytics.topExpenseCategory != null)
              'top_expense_category': analytics.topExpenseCategory!.key.name,
            if (analytics.topExpenseCategory != null)
              'top_expense_value': analytics.topExpenseCategory!.value,
            'period_start': analytics.start.toIso8601String().split('T').first,
            'period_end': analytics.endInclusive.toIso8601String().split('T').first,
          },
        },
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 25),
        ),
      );

      final data = response.data;
      final content = data?['data']?['message']?['content'];
      if (content is! String || content.trim().isEmpty) {
        throw const ApiException(
          statusCode: 502,
          code: 'AI_INVALID_RESPONSE',
          message: 'AI mengirim respons yang tidak valid.',
        );
      }
      return content.trim();
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      final gatewayError = _gatewayError(error.response?.data);
      final serverCode = gatewayError?['code'] as String?;
      final serverMessage = gatewayError?['message'] as String?;

      if (status == 401) {
        throw ApiException(
          statusCode: 401,
          code: serverCode ?? 'UNAUTHENTICATED',
          message: serverMessage ?? 'Sesi login perlu diperbarui.',
        );
      }
      if (status == 403) {
        throw ApiException(
          statusCode: 403,
          code: serverCode ?? 'FORBIDDEN',
          message: serverMessage ?? 'Akses ke server Nexora ditolak.',
        );
      }
      if (status == 404) {
        throw ApiException(
          statusCode: 404,
          code: serverCode ?? 'API_ENDPOINT_NOT_FOUND',
          message: serverMessage ?? 'Endpoint server Nexora tidak ditemukan. Periksa konfigurasi API.',
        );
      }
      if (status == 422) {
        throw ApiException(
          statusCode: 422,
          code: serverCode ?? 'INVALID_REQUEST',
          message: serverMessage ?? 'Data permintaan AI tidak valid.',
        );
      }
      if (status == 429) {
        throw ApiException(
          statusCode: 429,
          code: serverCode ?? 'RATE_LIMITED',
          message: serverMessage ?? 'Terlalu banyak permintaan. Tunggu sebentar lalu coba lagi.',
        );
      }
      if (status == 503) {
        throw ApiException(
          statusCode: 503,
          code: serverCode ?? 'AI_UNAVAILABLE',
          message: serverMessage ?? 'Nexora AI sedang tidak tersedia. Coba lagi sebentar.',
        );
      }
      if (status != null && status >= 500) {
        throw ApiException(
          statusCode: status,
          code: serverCode ?? 'SERVER_ERROR',
          message: serverMessage ?? 'Server Nexora mengalami masalah. Coba lagi sebentar.',
        );
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        throw const ApiException(
          statusCode: 0,
          code: 'AI_TIMEOUT',
          message: 'Respons AI terlalu lama. Periksa koneksi lalu coba lagi.',
        );
      }
      throw const ApiException(
        statusCode: 0,
        code: 'NETWORK_ERROR',
        message: 'Tidak bisa terhubung ke server Nexora.',
      );
    }
  }

  Map<String, dynamic>? _gatewayError(dynamic payload) {
    if (payload is! Map) return null;
    final error = payload['error'];
    if (error is! Map) return null;
    return Map<String, dynamic>.from(error);
  }
}

class AiChatMessage {
  const AiChatMessage({required this.role, required this.content});

  final String role;
  final String content;

  Map<String, String> toJson() => {
        'role': role,
        'content': content,
      };
}
