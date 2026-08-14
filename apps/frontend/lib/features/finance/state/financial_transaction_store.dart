import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/models/transaction_model.dart';
import '../repositories/supabase_transaction_repository.dart';
import '../repositories/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return SupabaseTransactionRepository();
});

final financialTransactionStoreProvider =
    StateNotifierProvider<FinancialTransactionStore, List<TransactionModel>>(
  (ref) => FinancialTransactionStore(ref.read(transactionRepositoryProvider))..load(),
);

class FinancialTransactionStore extends StateNotifier<List<TransactionModel>> {
  FinancialTransactionStore(this._repository) : super(const []);

  static const _pageSize = 100;
  static const _maxPages = 50;

  final TransactionRepository _repository;
  int _loadGeneration = 0;
  Object? _lastLoadError;

  bool get hasLoadError => _lastLoadError != null;
  Object? get lastLoadError => _lastLoadError;

  /// Loads the authoritative remote transaction list.
  ///
  /// A failed refresh must NEVER replace known-good financial data with an
  /// empty list. This is especially important for pull-to-refresh: a
  /// temporary network/session failure is not the same thing as "no data".
  /// A generation token also prevents an older concurrent request from
  /// overwriting a newer successful response.
  Future<void> load() async {
    final generation = ++_loadGeneration;

    try {
      final loaded = await _loadAllTransactions();
      if (generation != _loadGeneration || !mounted) return;

      state = loaded;
      _lastLoadError = null;
    } catch (error) {
      if (generation != _loadGeneration || !mounted) return;

      _lastLoadError = error;
      // Intentionally preserve the previous state.
      // [] means "there are no transactions"; it must never mean
      // "the refresh request failed".
    }
  }

  Future<List<TransactionModel>> _loadAllTransactions() async {
    final all = <TransactionModel>[];

    for (var page = 0; page < _maxPages; page++) {
      final batch = await _repository.getTransactions(
        limit: _pageSize,
        offset: page * _pageSize,
      );
      all.addAll(batch);

      if (batch.length < _pageSize) {
        break;
      }
    }

    return List<TransactionModel>.unmodifiable(all);
  }

  Future<void> reload() => load();

  Future<void> add(TransactionModel transaction) async {
    _validateTransaction(transaction);

    final created = await _repository.createTransaction(
      transaction,
      idempotencyKey: transaction.id,
    );

    if (state.any((item) => item.id == created.id)) {
      return;
    }

    state = [created, ...state];
    _lastLoadError = null;
  }

  /// Records an internal wallet transfer. The database applies both wallet
  /// balance changes atomically; this store only submits the transaction.
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

    await _repository.deleteTransaction(trimmedId);
    state = state
        .where((transaction) => transaction.id != trimmedId)
        .toList(growable: false);
  }

  Future<void> replace(TransactionModel transaction) async {
    _validateTransaction(transaction);

    final updated = await _repository.updateTransaction(transaction);
    final index = state.indexWhere((item) => item.id == updated.id);
    if (index == -1) {
      state = [updated, ...state];
      return;
    }

    final next = [...state];
    next[index] = updated;
    state = next;
  }

  /// Reloads the remote source. This intentionally does not delete remote
  /// financial data; clearing a local cache must never erase real finances.
  Future<void> clearAndRestoreDemoData() async {
    await load();
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
