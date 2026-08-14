import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/api_exception.dart';
import '../../finance/state/financial_analytics_provider.dart';

class AiApiService {
  AiApiService({
    SupabaseClient? supabase,
    Dio? dio,
    String? baseUrl,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _dio = dio ?? Dio(),
        _baseUrl = (baseUrl ?? const String.fromEnvironment('NEXORA_API_BASE_URL')).replaceAll(RegExp(r'/$'), '');

  final SupabaseClient _supabase;
  final Dio _dio;
  final String _baseUrl;

  Future<String> chat({
    required List<AiChatMessage> messages,
    required FinancialAnalyticsSnapshot analytics,
  }) async {
    if (_baseUrl.isEmpty) {
      throw const ApiException(
        code: 'API_BASE_URL_MISSING',
        message: 'Server AI belum dikonfigurasi pada aplikasi ini.',
      );
    }

    var session = _supabase.auth.currentSession;
    if (session == null) {
      throw const ApiException(
        code: 'UNAUTHENTICATED',
        message: 'Sesi login tidak ditemukan. Silakan login kembali.',
        statusCode: 401,
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
          code: 'UNAUTHENTICATED',
          message: 'Sesi login sudah kedaluwarsa. Silakan login kembali.',
          statusCode: 401,
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
            'period_start': analytics.periodStart.toIso8601String().split('T').first,
            'period_end': analytics.periodEnd.toIso8601String().split('T').first,
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
          code: 'AI_INVALID_RESPONSE',
          message: 'AI mengirim respons yang tidak valid.',
        );
      }
      return content.trim();
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401) {
        throw const ApiException(
          code: 'UNAUTHENTICATED',
          message: 'Sesi login perlu diperbarui.',
          statusCode: 401,
        );
      }
      if (status == 429) {
        throw const ApiException(
          code: 'RATE_LIMITED',
          message: 'Terlalu banyak permintaan. Tunggu sebentar lalu coba lagi.',
          statusCode: 429,
        );
      }
      if (status == 503) {
        throw const ApiException(
          code: 'AI_UNAVAILABLE',
          message: 'Nexora AI sedang tidak tersedia. Coba lagi sebentar.',
          statusCode: 503,
        );
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        throw const ApiException(
          code: 'AI_TIMEOUT',
          message: 'Respons AI terlalu lama. Periksa koneksi lalu coba lagi.',
        );
      }
      throw const ApiException(
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
