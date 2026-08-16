import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase, SupabaseClient;

import '../../../core/network/api_exception.dart';
import '../../finance/state/financial_analytics_provider.dart';

class AiApiService {
  AiApiService({
    SupabaseClient? supabase,
    Dio? dio,
    String? baseUrl,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _dio = dio ?? Dio(),
        _baseUrl = _normalizeBaseUrl(
          baseUrl ?? const String.fromEnvironment('NEXORA_API_BASE_URL'),
        );

  final SupabaseClient _supabase;
  final Dio _dio;
  final String _baseUrl;

  /// Accept either the complete API root (`.../api/v1`) or the backend host.
  ///
  /// This prevents a production build from silently calling `/ai/chat` when
  /// the configured value only contains the backend host. The Laravel route
  /// is registered under `/api/v1/ai/chat`.
  static String _normalizeBaseUrl(String raw) {
    final value = raw.trim().replaceFirst(RegExp(r'/+$'), '');
    if (value.isEmpty) return '';
    if (value.endsWith('/api/v1')) return value;
    if (value.endsWith('/api')) return '$value/v1';
    return '$value/api/v1';
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
            'period_end': analytics.end.toIso8601String().split('T').first,
          },
        },
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 35),
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
      if (status == 401) {
        throw const ApiException(
          statusCode: 401,
          code: 'UNAUTHENTICATED',
          message: 'Sesi login perlu diperbarui.',
        );
      }
      if (status == 403) {
        throw const ApiException(
          statusCode: 403,
          code: 'FORBIDDEN',
          message: 'Akses ke server Nexora ditolak.',
        );
      }
      if (status == 404) {
        throw const ApiException(
          statusCode: 404,
          code: 'API_ENDPOINT_NOT_FOUND',
          message: 'Endpoint server Nexora tidak ditemukan. Periksa konfigurasi API.',
        );
      }
      if (status == 422) {
        throw const ApiException(
          statusCode: 422,
          code: 'INVALID_REQUEST',
          message: 'Data permintaan AI tidak valid.',
        );
      }
      if (status == 429) {
        throw const ApiException(
          statusCode: 429,
          code: 'RATE_LIMITED',
          message: 'Terlalu banyak permintaan. Tunggu sebentar lalu coba lagi.',
        );
      }
      if (status == 503) {
        throw const ApiException(
          statusCode: 503,
          code: 'AI_UNAVAILABLE',
          message: 'Nexora AI sedang tidak tersedia. Coba lagi sebentar.',
        );
      }
      if (status != null && status >= 500) {
        throw const ApiException(
          statusCode: 502,
          code: 'SERVER_ERROR',
          message: 'Server Nexora mengalami masalah. Coba lagi sebentar.',
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
