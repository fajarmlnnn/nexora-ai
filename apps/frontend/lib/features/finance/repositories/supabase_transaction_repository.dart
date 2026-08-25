import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../dashboard/models/transaction_model.dart';
import 'transaction_repository.dart';

class SupabaseTransactionRepository implements TransactionRepository {
  SupabaseTransactionRepository({SupabaseClient? client})
      : _client = client ?? NexoraSupabase.client;

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User belum terautentikasi.');
    }
    return user.id;
  }

  @override
  Future<List<TransactionModel>> getTransactions({
    String? walletId,
    TransactionType? type,
    TransactionCategory? category,
    String? search,
    DateTime? from,
    DateTime? to,
    int limit = 100,
    int offset = 0,
  }) async {
    final safeLimit = limit.clamp(1, 100);
    final safeOffset = offset < 0 ? 0 : offset;

    dynamic query = _client
        .from('transactions')
        .select()
        .eq('user_id', _userId);

    if (walletId != null && walletId.trim().isNotEmpty) {
      final id = walletId.trim();
      query = query.or(
        'wallet_id.eq.$id,source_wallet_id.eq.$id,destination_wallet_id.eq.$id',
      );
    }
    if (type != null) query = query.eq('type', type.name);
    if (category != null) query = query.eq('category', category.name);
    if (search != null && search.trim().isNotEmpty) {
      final escaped = _escapeIlike(search.trim());
      query = query.ilike('description', '%$escaped%');
    }
    if (from != null) {
      query = query.gte('occurred_at', from.toUtc().toIso8601String());
    }
    if (to != null) {
      query = query.lte('occurred_at', to.toUtc().toIso8601String());
    }

    final rows = await query
        .order('occurred_at', ascending: false)
        .order('created_at', ascending: false)
        .range(safeOffset, safeOffset + safeLimit - 1);

    return (rows as List)
        .map<TransactionModel>(
          (row) => _fromRow(Map<String, dynamic>.from(row as Map)),
        )
        .toList(growable: false);
  }

  @override
  Future<TransactionModel> createTransaction(
    TransactionModel transaction, {
    String? idempotencyKey,
  }) async {
    _validate(transaction);
    final key = (idempotencyKey ?? transaction.id).trim();
    if (key.isEmpty) throw ArgumentError('Idempotency key transaksi wajib diisi.');

    final payload = <String, dynamic>{
      'p_id': _transactionIdForInsert(transaction.id),
      'p_type': transaction.type.name,
      'p_amount': transaction.amount.toStringAsFixed(2),
      'p_category': transaction.category.name,
      'p_description': transaction.title.trim(),
      'p_occurred_at': transaction.date.toUtc().toIso8601String(),
      'p_idempotency_key': key,
      'p_metadata': {
        if (transaction.note != null && transaction.note!.trim().isNotEmpty)
          'note': transaction.note!.trim(),
      },
      'p_wallet_id': transaction.isTransfer ? null : transaction.walletId,
      'p_source_wallet_id':
          transaction.isTransfer ? transaction.sourceAccount : null,
      'p_destination_wallet_id':
          transaction.isTransfer ? transaction.destinationAccount : null,
    };

    try {
      final row = await _client
          .rpc('nexora_create_transaction', params: payload)
          .select()
          .single();

      return _fromRow(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error) {
      // The RPC deliberately rejects reuse of an idempotency key with a
      // different transaction. Keep the database error boundary intact while
      // exposing the repository contract expected by the Flutter domain layer.
      if (error.code == 'P0001' &&
          error.message.contains(
            'Idempotency key already belongs to a different transaction',
          )) {
        throw StateError(
          'Idempotency key sudah digunakan untuk transaksi yang berbeda.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<TransactionModel> updateTransaction(
    TransactionModel transaction,
  ) async {
    _validate(transaction);
    if (transaction.id.trim().isEmpty) {
      throw ArgumentError('ID transaksi wajib diisi.');
    }
    if (!_isUuid(transaction.id)) {
      throw ArgumentError('ID transaksi tidak valid untuk Supabase.');
    }

    final payload = <String, dynamic>{
      'p_transaction_id': transaction.id,
      'p_type': transaction.type.name,
      'p_amount': transaction.amount.toStringAsFixed(2),
      'p_category': transaction.category.name,
      'p_description': transaction.title.trim(),
      'p_occurred_at': transaction.date.toUtc().toIso8601String(),
      'p_metadata': {
        if (transaction.note != null && transaction.note!.trim().isNotEmpty)
          'note': transaction.note!.trim(),
      },
      'p_wallet_id': transaction.isTransfer ? null : transaction.walletId,
      'p_source_wallet_id':
          transaction.isTransfer ? transaction.sourceAccount : null,
      'p_destination_wallet_id':
          transaction.isTransfer ? transaction.destinationAccount : null,
    };

    final row = await _client
        .rpc('nexora_update_transaction', params: payload)
        .select()
        .single();

    return _fromRow(Map<String, dynamic>.from(row));
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('ID transaksi wajib diisi.');
    }
    if (!_isUuid(trimmed)) {
      throw ArgumentError('ID transaksi tidak valid untuk Supabase.');
    }

    await _client.rpc(
      'nexora_delete_transaction',
      params: {'p_transaction_id': trimmed},
    );
  }

  TransactionModel _fromRow(Map<String, dynamic> row) {
    final metadata = row['metadata'];
    final metadataMap = metadata is Map
        ? Map<String, dynamic>.from(metadata)
        : const <String, dynamic>{};

    return TransactionModel(
      id: row['id'].toString(),
      title: row['description']?.toString().trim().isNotEmpty == true
          ? row['description'].toString()
          : _defaultTitle(row['type']?.toString()),
      amount: _number(row['amount']),
      type: _transactionType(row['type']?.toString()),
      category: _transactionCategory(row['category']?.toString()),
      date: _parseDate(row['occurred_at']),
      createdAt: _parseOptionalDate(row['created_at']),
      note: metadataMap['note']?.toString(),
      walletId: row['wallet_id']?.toString(),
      sourceAccount: row['source_wallet_id']?.toString(),
      destinationAccount: row['destination_wallet_id']?.toString(),
    );
  }

  TransactionType _transactionType(String? value) {
    switch (value) {
      case 'income':
        return TransactionType.income;
      case 'transfer':
        return TransactionType.transfer;
      case 'expense':
      default:
        return TransactionType.expense;
    }
  }

  TransactionCategory _transactionCategory(String? value) {
    for (final category in TransactionCategory.values) {
      if (category.name == value) return category;
    }
    return TransactionCategory.other;
  }

  DateTime _parseDate(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return (parsed ?? DateTime.now().toUtc()).toLocal();
  }

  DateTime? _parseOptionalDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  double _number(dynamic value) =>
      value is num ? value.toDouble() : double.parse(value.toString());

  String _defaultTitle(String? type) {
    switch (type) {
      case 'income':
        return 'Pemasukan';
      case 'transfer':
        return 'Transfer antar wallet';
      default:
        return 'Pengeluaran';
    }
  }

  String _escapeIlike(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    ).hasMatch(value.trim());
  }

  String _transactionIdForInsert(String value) {
    final trimmed = value.trim();
    return _isUuid(trimmed) ? trimmed : _generateUuidV4();
  }

  String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  void _validate(TransactionModel transaction) {
    if (transaction.id.trim().isEmpty) {
      throw ArgumentError('ID transaksi wajib diisi.');
    }
    if (!transaction.amount.isFinite || transaction.amount <= 0) {
      throw ArgumentError('Nominal transaksi harus lebih besar dari nol.');
    }
    if (transaction.title.trim().isEmpty) {
      throw ArgumentError('Nama transaksi wajib diisi.');
    }
    if (transaction.isTransfer) {
      final source = transaction.sourceAccount?.trim();
      final destination = transaction.destinationAccount?.trim();
      if (source == null || source.isEmpty) {
        throw ArgumentError('Wallet sumber transfer wajib diisi.');
      }
      if (destination == null || destination.isEmpty) {
        throw ArgumentError('Wallet tujuan transfer wajib diisi.');
      }
      if (source == destination) {
        throw ArgumentError('Wallet sumber dan tujuan transfer harus berbeda.');
      }
    } else if (transaction.walletId?.trim().isNotEmpty != true) {
      throw ArgumentError('Wallet transaksi wajib diisi.');
    }
  }
}
