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
    final row = await _client
        .from('wallets')
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();

    if (row == null) {
      throw StateError('Wallet dengan id "$id" tidak ditemukan.');
    }
    return _fromRow(row);
  }

  @override
  Future<WalletModel> createWallet(WalletModel wallet) async {
    // Balance is a derived financial value. It must never be accepted from
    // an untrusted Flutter client. Opening funds should be recorded as an
    // income transaction so the database trigger remains the single source
    // of truth for balance changes.
    final row = await _client
        .from('wallets')
        .insert({
          'id': wallet.id,
          'user_id': _userId,
          'name': wallet.name,
          'bank_name': wallet.bankName.isEmpty ? null : wallet.bankName,
          'account_number':
              wallet.accountNumber.isEmpty ? null : wallet.accountNumber,
          'type': wallet.type.name,
          'balance': 0,
          'minimum_balance': wallet.minimumBalance,
          'color': _colorToHex(wallet.color),
          'is_primary': wallet.isPrimary,
          'is_hidden': wallet.isHidden,
        })
        .select()
        .single();

    return _fromRow(row);
  }

  @override
  Future<WalletModel> updateWallet(WalletModel wallet) async {
    final row = await _client
        .from('wallets')
        .update({
          'name': wallet.name,
          'bank_name': wallet.bankName.isEmpty ? null : wallet.bankName,
          'account_number':
              wallet.accountNumber.isEmpty ? null : wallet.accountNumber,
          'type': wallet.type.name,
          'minimum_balance': wallet.minimumBalance,
          'color': _colorToHex(wallet.color),
          'is_primary': wallet.isPrimary,
          'is_hidden': wallet.isHidden,
        })
        .eq('id', wallet.id)
        .eq('user_id', _userId)
        .select()
        .maybeSingle();

    if (row == null) {
      throw StateError('Wallet dengan id "${wallet.id}" tidak ditemukan.');
    }
    return _fromRow(row);
  }

  @override
  Future<void> deleteWallet(String id) async {
    await _client
        .from('wallets')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
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
