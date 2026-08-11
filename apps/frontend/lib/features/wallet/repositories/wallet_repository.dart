import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/wallet_model.dart';

abstract interface class WalletRepository {
  Future<List<WalletModel>> getWallets();
  Future<WalletModel> getWallet(String id);
  Future<WalletModel> createWallet(WalletModel wallet);
  Future<WalletModel> updateWallet(WalletModel wallet);
  Future<void> deleteWallet(String id);
}

/// Local persistent wallet repository.
/// A new installation starts with an empty wallet list; there are no
/// hard-coded demo balances or accounts.
class LocalWalletRepository implements WalletRepository {
  static const _storageKey = 'nexora_wallets_v1';

  Future<List<WalletModel>> _read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return <WalletModel>[];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map(
            (item) => WalletModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: true);
    } catch (_) {
      return <WalletModel>[];
    }
  }

  Future<void> _write(List<WalletModel> wallets) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      _storageKey,
      jsonEncode(wallets.map((wallet) => wallet.toJson()).toList()),
    );
    if (!saved) {
      throw StateError('Gagal menyimpan data wallet ke penyimpanan lokal.');
    }
  }

  @override
  Future<List<WalletModel>> getWallets() async {
    return List<WalletModel>.unmodifiable(await _read());
  }

  @override
  Future<WalletModel> getWallet(String id) async {
    final wallets = await _read();
    return _findWallet(wallets, id);
  }

  @override
  Future<WalletModel> createWallet(WalletModel wallet) async {
    final wallets = List<WalletModel>.from(await _read());
    if (wallets.any((item) => item.id == wallet.id)) {
      throw StateError('Wallet dengan id "${wallet.id}" sudah ada.');
    }
    wallets.add(wallet);
    await _write(wallets);
    return wallet;
  }

  @override
  Future<WalletModel> updateWallet(WalletModel wallet) async {
    final wallets = List<WalletModel>.from(await _read());
    final index = wallets.indexWhere((item) => item.id == wallet.id);
    if (index == -1) {
      throw StateError('Wallet dengan id "${wallet.id}" tidak ditemukan.');
    }
    wallets[index] = wallet;
    await _write(wallets);
    return wallet;
  }

  @override
  Future<void> deleteWallet(String id) async {
    final wallets = List<WalletModel>.from(await _read());
    final index = wallets.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw StateError('Wallet dengan id "$id" tidak ditemukan.');
    }
    wallets.removeAt(index);
    await _write(wallets);
  }

  WalletModel _findWallet(List<WalletModel> wallets, String id) {
    for (final wallet in wallets) {
      if (wallet.id == id) return wallet;
    }
    throw StateError('Wallet dengan id "$id" tidak ditemukan.');
  }
}

/// Temporary source-compatible alias during the migration away from demo data.
/// It uses LocalWalletRepository and contains no demo records.
@Deprecated('Use LocalWalletRepository instead.')
class MockWalletRepository extends LocalWalletRepository {}
