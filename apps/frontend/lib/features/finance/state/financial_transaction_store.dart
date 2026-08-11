import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../dashboard/models/transaction_model.dart';

const _storageKey = 'nexora_financial_transactions_v1';

final financialTransactionStoreProvider =
    StateNotifierProvider<FinancialTransactionStore, List<TransactionModel>>(
  (ref) => FinancialTransactionStore()..load(),
);

class FinancialTransactionStore extends StateNotifier<List<TransactionModel>> {
  FinancialTransactionStore() : super(const []);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final loaded = decoded
          .map(
            (item) => TransactionModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .where((transaction) => !_isLegacyDemo(transaction))
          .toList(growable: false);

      state = loaded;

      if (loaded.length != decoded.length) {
        await _persist();
      }
    } catch (_) {
      state = const [];
      await _persist();
    }
  }

  Future<void> add(TransactionModel transaction) async {
    _validateTransaction(transaction);
    if (state.any((item) => item.id == transaction.id)) {
      throw StateError('Transaksi dengan id "${transaction.id}" sudah ada.');
    }

    final previous = state;
    final next = [transaction, ...previous];
    state = next;

    try {
      await _persist();
    } catch (_) {
      state = previous;
      rethrow;
    }
  }

  /// Records an internal wallet transfer. It never contributes to income,
  /// expense, or net cashflow.
  Future<void> transfer({
    required String sourceWalletId,
    required String destinationWalletId,
    required double amount,
    String title = 'Transfer antar wallet',
    String? note,
  }) async {
    if (sourceWalletId == destinationWalletId) {
      throw ArgumentError('Wallet sumber dan tujuan harus berbeda.');
    }
    if (sourceWalletId.trim().isEmpty || destinationWalletId.trim().isEmpty) {
      throw ArgumentError('Wallet sumber dan tujuan wajib diisi.');
    }
    if (amount <= 0 || !amount.isFinite) {
      throw ArgumentError('Nominal transfer harus lebih besar dari nol.');
    }

    final transaction = TransactionModel(
      id: 'transfer-${DateTime.now().microsecondsSinceEpoch}',
      title: title.trim().isEmpty ? 'Transfer antar wallet' : title.trim(),
      amount: amount,
      type: TransactionType.transfer,
      category: TransactionCategory.other,
      date: DateTime.now(),
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      sourceAccount: sourceWalletId,
      destinationAccount: destinationWalletId,
    );

    await add(transaction);
  }

  Future<void> delete(String id) async {
    final trimmedId = id.trim();
    if (trimmedId.isEmpty) {
      throw ArgumentError('ID transaksi wajib diisi.');
    }

    final previous = state;
    final next = previous
        .where((transaction) => transaction.id != trimmedId)
        .toList(growable: false);
    if (next.length == previous.length) {
      throw StateError('Transaksi dengan id "$trimmedId" tidak ditemukan.');
    }

    state = next;

    try {
      await _persist();
    } catch (_) {
      state = previous;
      rethrow;
    }
  }

  Future<void> replace(TransactionModel transaction) async {
    _validateTransaction(transaction);

    final previous = state;
    final index = previous.indexWhere((item) => item.id == transaction.id);
    if (index == -1) {
      throw StateError('Transaksi dengan id "${transaction.id}" tidak ditemukan.');
    }

    final next = [...previous];
    next[index] = transaction;
    state = next;

    try {
      await _persist();
    } catch (_) {
      state = previous;
      rethrow;
    }
  }

  /// Clears persisted transactions. This method does not restore demo data.
  Future<void> clearAndRestoreDemoData() async {
    final previous = state;
    state = const [];

    try {
      await _persist();
    } catch (_) {
      state = previous;
      rethrow;
    }
  }

  void _validateTransaction(TransactionModel transaction) {
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
      if (transaction.sourceAccount == null || transaction.sourceAccount!.trim().isEmpty) {
        throw ArgumentError('Wallet sumber transfer wajib diisi.');
      }
      if (transaction.destinationAccount == null || transaction.destinationAccount!.trim().isEmpty) {
        throw ArgumentError('Wallet tujuan transfer wajib diisi.');
      }
      if (transaction.sourceAccount == transaction.destinationAccount) {
        throw ArgumentError('Wallet sumber dan tujuan transfer harus berbeda.');
      }
    } else if (transaction.walletId == null || transaction.walletId!.trim().isEmpty) {
      throw ArgumentError('Wallet transaksi wajib diisi.');
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      _storageKey,
      jsonEncode(state.map((transaction) => transaction.toJson()).toList()),
    );
    if (!saved) {
      throw StateError('Gagal menyimpan transaksi ke penyimpanan lokal.');
    }
  }

  bool _isLegacyDemo(TransactionModel transaction) {
    return transaction.id == 'seed-salary-may' ||
        transaction.id == 'seed-lunch' ||
        transaction.id == 'seed-coffee';
  }
}

extension FinancialTransactionCalculations on List<TransactionModel> {
  double get totalIncome => fold<double>(
        0,
        (sum, item) => sum + (item.isIncome ? item.amount : 0),
      );

  double get totalExpense => fold<double>(
        0,
        (sum, item) => sum + (item.isExpense ? item.amount : 0),
      );

  /// Transfers are internal movements and therefore do not change cashflow.
  double get netCashflow => totalIncome - totalExpense;

  double get monthlyIncome => _inCurrentMonth((item) => item.isIncome);

  double get monthlyExpense => _inCurrentMonth((item) => item.isExpense);

  double _inCurrentMonth(bool Function(TransactionModel) predicate) {
    final now = DateTime.now();
    return fold<double>(
      0,
      (sum, item) =>
          sum +
          (item.date.year == now.year &&
                  item.date.month == now.month &&
                  predicate(item)
              ? item.amount
              : 0),
    );
  }
}
