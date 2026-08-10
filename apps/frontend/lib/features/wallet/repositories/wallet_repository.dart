import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/wallet_model.dart';

/// Persistent local repository for wallet data.
///
/// Wallets are stored on-device as JSON so user-created wallets survive:
/// - leaving the Wallet page
/// - rebuilding the widget tree
/// - closing and reopening the app
///
/// This intentionally contains no hard-coded demo wallets. A fresh install
/// starts empty and the user creates the real wallet data.
abstract interface class WalletRepository {
  Future<List<WalletModel>> getWallets();

  Future<WalletModel> getWallet(String id);

  Future<WalletModel> createWallet(WalletModel wallet);

  Future<WalletModel> updateWallet(WalletModel wallet);

  Future<void> deleteWallet(String id);
}

class LocalWalletRepository implements WalletRepository {
  static const String _storageKey = 'nexora.wallets.v1';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<List<WalletModel>> getWallets() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.trim().isEmpty) {
      return <WalletModel>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('Format wallet lokal tidak valid.');
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => WalletModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false);
    } catch (error) {
      throw StateError('Data wallet lokal rusak: $error');
    }
  }

  @override
  Future<WalletModel> getWallet(String id) async {
    final wallets = await getWallets();

    for (final wallet in wallets) {
      if (wallet.id == id) return wallet;
    }

    throw StateError('Wallet dengan id "$id" tidak ditemukan.');
  }

  @override
  Future<WalletModel> createWallet(WalletModel wallet) async {
    final wallets = await getWallets();

    if (wallets.any((item) => item.id == wallet.id)) {
      throw StateError('Wallet dengan id "${wallet.id}" sudah ada.');
    }

    final updated = List<WalletModel>.from(wallets)..add(wallet);
    await _save(updated);
    return wallet;
  }

  @override
  Future<WalletModel> updateWallet(WalletModel wallet) async {
    final wallets = await getWallets();
    final index = wallets.indexWhere((item) => item.id == wallet.id);

    if (index == -1) {
      throw StateError('Wallet dengan id "${wallet.id}" tidak ditemukan.');
    }

    final updated = List<WalletModel>.from(wallets);
    updated[index] = wallet;
    await _save(updated);
    return wallet;
  }

  @override
  Future<void> deleteWallet(String id) async {
    final wallets = await getWallets();
    final updated = List<WalletModel>.from(wallets)
      ..removeWhere((wallet) => wallet.id == id);

    if (updated.length == wallets.length) {
      throw StateError('Wallet dengan id "$id" tidak ditemukan.');
    }

    await _save(updated);
  }

  Future<void> _save(List<WalletModel> wallets) async {
    final prefs = await _prefs;
    final encoded = jsonEncode(
      wallets.map((wallet) => wallet.toJson()).toList(growable: false),
    );

    final saved = await prefs.setString(_storageKey, encoded);
    if (!saved) {
      throw StateError('Gagal menyimpan data wallet ke penyimpanan lokal.');
    }
  }
}
