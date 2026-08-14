import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../models/wallet_model.dart';
import 'wallet_repository.dart';

class SupabaseWalletRepository implements WalletRepository {
  SupabaseWalletRepository({SupabaseClient? client})
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
  Future<List<WalletModel>> getWallets() async {
    final rows = await _client
        .from('wallets')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<WalletModel> getWallet(String id) async {
    final trimmed = id.trim();
    if (!_isUuid(trimmed)) {
      throw ArgumentError('ID wallet tidak valid untuk Supabase.');
    }

    final row = await _client
        .from('wallets')
        .select()
        .eq('id', trimmed)
        .eq('user_id', _userId)
        .maybeSingle();

    if (row == null) {
      throw StateError('Wallet dengan id "$trimmed" tidak ditemukan.');
    }
    return _fromRow(row);
  }

  @override
  Future<WalletModel> createWallet(WalletModel wallet) async {
    // Wallet IDs are UUIDs in Supabase. Older UI flows may provide a local
    // timestamp-style ID, so let Postgres generate a UUID unless the supplied
    // ID is already a valid UUID.
    final payload = <String, dynamic>{
      'user_id': _userId,
      'name': wallet.name.trim(),
      'bank_name': wallet.bankName.trim().isEmpty ? null : wallet.bankName.trim(),
      'account_number': wallet.accountNumber.trim().isEmpty
          ? null
          : wallet.accountNumber.trim(),
      'type': wallet.type.name,
      // Balance is derived from transactions and is column-protected.
      // A new wallet therefore always starts at the database default (0).
      'minimum_balance': wallet.minimumBalance,
      'color': _colorToHex(wallet.color),
      'is_primary': wallet.isPrimary,
      'is_hidden': wallet.isHidden,
    };

    final suppliedId = wallet.id.trim();
    if (_isUuid(suppliedId)) {
      payload['id'] = suppliedId;
    }

    final row = await _client
        .from('wallets')
        .insert(payload)
        .select()
        .single();

    return _fromRow(row);
  }

  @override
  Future<WalletModel> updateWallet(WalletModel wallet) async {
    final id = wallet.id.trim();
    if (!_isUuid(id)) {
      throw ArgumentError('ID wallet tidak valid untuk Supabase.');
    }

    final row = await _client
        .from('wallets')
        .update({
          'name': wallet.name.trim(),
          'bank_name': wallet.bankName.trim().isEmpty ? null : wallet.bankName.trim(),
          'account_number': wallet.accountNumber.trim().isEmpty
              ? null
              : wallet.accountNumber.trim(),
          'type': wallet.type.name,
          'minimum_balance': wallet.minimumBalance,
          'color': _colorToHex(wallet.color),
          'is_primary': wallet.isPrimary,
          'is_hidden': wallet.isHidden,
        })
        .eq('id', id)
        .eq('user_id', _userId)
        .select()
        .maybeSingle();

    if (row == null) {
      throw StateError('Wallet dengan id "$id" tidak ditemukan.');
    }
    return _fromRow(row);
  }

  @override
  Future<void> deleteWallet(String id) async {
    final trimmed = id.trim();
    if (!_isUuid(trimmed)) {
      throw ArgumentError('ID wallet tidak valid untuk Supabase.');
    }

    // Transactions deliberately use ON DELETE RESTRICT. Never silently erase
    // financial history just because the user removes a wallet.
    final references = await _client
        .from('transactions')
        .select('id')
        .eq('user_id', _userId)
        .or(
          'wallet_id.eq.$trimmed,source_wallet_id.eq.$trimmed,destination_wallet_id.eq.$trimmed',
        )
        .limit(1);

    if (references.isNotEmpty) {
      throw StateError(
        'Wallet tidak bisa dihapus karena masih memiliki transaksi. Hapus atau pindahkan transaksi terlebih dahulu.',
      );
    }

    final deleted = await _client
        .from('wallets')
        .delete()
        .eq('id', trimmed)
        .eq('user_id', _userId)
        .select('id');

    if (deleted.isEmpty) {
      throw StateError('Wallet tidak ditemukan atau gagal dihapus.');
    }
  }

  WalletModel _fromRow(Map<String, dynamic> row) {
    return WalletModel(
      id: row['id'] as String,
      name: row['name'] as String,
      bankName: row['bank_name'] as String? ?? '',
      accountNumber: row['account_number'] as String? ?? '',
      balance: _number(row['balance']),
      type: _walletType(row['type']?.toString()),
      color: _colorFromDb(row['color']),
      isPrimary: row['is_primary'] as bool? ?? false,
      isHidden: row['is_hidden'] as bool? ?? false,
      minimumBalance: _number(row['minimum_balance']),
    );
  }

  WalletType _walletType(String? value) {
    switch (value) {
      case 'bank':
        return WalletType.bank;
      case 'ewallet':
        return WalletType.ewallet;
      case 'investment':
        return WalletType.investment;
      case 'cash':
      default:
        return WalletType.cash;
    }
  }

  double _number(dynamic value) => value is num ? value.toDouble() : 0;

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    ).hasMatch(value.trim());
  }

  Color _colorFromDb(dynamic value) {
    if (value is int) return Color(value);
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return const Color(0xFF2563EB);
    final normalized = raw.replaceFirst('#', '');
    final hex = normalized.length == 6 ? 'FF$normalized' : normalized;
    final parsed = int.tryParse(hex, radix: 16);
    return parsed == null ? const Color(0xFF2563EB) : Color(parsed);
  }

  String _colorToHex(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
}
