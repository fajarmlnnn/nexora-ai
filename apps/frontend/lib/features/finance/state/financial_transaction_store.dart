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
  FinancialTransactionStore() : super(_seedTransactions);

  static const openingBalance = 12553000.0;
  static const monthlyBudget = 5000000.0;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      state = decoded
          .map((item) => TransactionModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false);
    } catch (_) {
      // Corrupt local data must never prevent the app from opening.
      state = _seedTransactions;
    }
  }

  Future<void> add(TransactionModel transaction) async {
    state = [transaction, ...state];
    await _persist();
  }

  Future<void> delete(String id) async {
    state = state.where((transaction) => transaction.id != id).toList(growable: false);
    await _persist();
  }

  Future<void> replace(TransactionModel transaction) async {
    state = [
      for (final item in state) item.id == transaction.id ? transaction : item,
    ];
    await _persist();
  }

  Future<void> clearAndRestoreDemoData() async {
    state = _seedTransactions;
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(state.map((transaction) => transaction.toJson()).toList()),
    );
  }

  static final _seedTransactions = <TransactionModel>[
    TransactionModel(
      id: 'seed-salary-may',
      title: 'Gaji Bulan Mei',
      amount: 15000000,
      type: TransactionType.income,
      category: TransactionCategory.salary,
      date: DateTime.now(),
    ),
    TransactionModel(
      id: 'seed-lunch',
      title: 'Makan Siang',
      amount: 35000,
      type: TransactionType.expense,
      category: TransactionCategory.food,
      date: DateTime.now(),
    ),
    TransactionModel(
      id: 'seed-coffee',
      title: 'Kopi',
      amount: 18000,
      type: TransactionType.expense,
      category: TransactionCategory.shopping,
      date: DateTime.now(),
    ),
  ];
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

  double get netCashflow => totalIncome - totalExpense;

  double get currentBalance =>
      FinancialTransactionStore.openingBalance + netCashflow;

  double get monthlyIncome => _inCurrentMonth((item) => item.isIncome);

  double get monthlyExpense => _inCurrentMonth((item) => item.isExpense);

  double _inCurrentMonth(bool Function(TransactionModel) predicate) {
    final now = DateTime.now();
    return fold<double>(
      0,
      (sum, item) => sum +
          (item.date.year == now.year &&
                  item.date.month == now.month &&
                  predicate(item)
              ? item.amount
              : 0),
    );
  }
}
