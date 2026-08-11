import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/models/transaction_model.dart';
import 'financial_transaction_store.dart';

class FinancialAnalyticsSnapshot {
  const FinancialAnalyticsSnapshot({
    required this.start,
    required this.end,
    required this.income,
    required this.expense,
    required this.transferIn,
    required this.transferOut,
    required this.expenseByCategory,
    required this.transactionCount,
  });

  final DateTime start;
  final DateTime end;
  final double income;
  final double expense;
  final double transferIn;
  final double transferOut;
  final Map<TransactionCategory, double> expenseByCategory;
  final int transactionCount;

  double get netCashflow => income - expense;
  double get savingsRate => income <= 0 ? 0 : netCashflow / income;
  double get transferNet => transferIn - transferOut;

  MapEntry<TransactionCategory, double>? get topExpenseCategory {
    if (expenseByCategory.isEmpty) return null;
    return expenseByCategory.entries.reduce(
      (current, next) => next.value > current.value ? next : current,
    );
  }
}

/// Builds a consistent financial snapshot from the single transaction store.
/// Internal transfers are deliberately excluded from income/expense metrics.
final financialAnalyticsProvider = Provider<FinancialAnalyticsSnapshot>((ref) {
  final transactions = ref.watch(financialTransactionStoreProvider);
  final now = DateTime.now();
  return buildFinancialAnalytics(
    transactions,
    DateTime(now.year, now.month),
    DateTime(now.year, now.month + 1),
  );
});

/// Analytics for an arbitrary half-open date range: [start, end).
FinancialAnalyticsSnapshot buildFinancialAnalytics(
  List<TransactionModel> transactions,
  DateTime start,
  DateTime end,
) {
  var income = 0.0;
  var expense = 0.0;
  var transferIn = 0.0;
  var transferOut = 0.0;
  final expenseByCategory = <TransactionCategory, double>{};
  var transactionCount = 0;

  for (final transaction in transactions) {
    if (transaction.date.isBefore(start) || !transaction.date.isBefore(end)) {
      continue;
    }

    transactionCount++;

    if (transaction.isIncome) {
      income += transaction.amount;
      continue;
    }

    if (transaction.isExpense) {
      expense += transaction.amount;
      expenseByCategory[transaction.category] =
          (expenseByCategory[transaction.category] ?? 0) + transaction.amount;
      continue;
    }

    if (transaction.isTransfer) {
      if (transaction.destinationAccount != null) {
        transferIn += transaction.amount;
      }
      if (transaction.sourceAccount != null) {
        transferOut += transaction.amount;
      }
    }
  }

  return FinancialAnalyticsSnapshot(
    start: start,
    end: end,
    income: income,
    expense: expense,
    transferIn: transferIn,
    transferOut: transferOut,
    expenseByCategory: Map.unmodifiable(expenseByCategory),
    transactionCount: transactionCount,
  );
}

FinancialAnalyticsSnapshot buildPreviousMonthAnalytics(
  List<TransactionModel> transactions,
) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month - 1);
  final end = DateTime(now.year, now.month);
  return buildFinancialAnalytics(transactions, start, end);
}

final previousMonthFinancialAnalyticsProvider =
    Provider<FinancialAnalyticsSnapshot>((ref) {
  final transactions = ref.watch(financialTransactionStoreProvider);
  return buildPreviousMonthAnalytics(transactions);
});

final monthlyIncomeChangeProvider = Provider<double>((ref) {
  final current = ref.watch(financialAnalyticsProvider);
  final previous = ref.watch(previousMonthFinancialAnalyticsProvider);
  if (previous.income <= 0) return 0;
  return ((current.income - previous.income) / previous.income) * 100;
});

final monthlyExpenseChangeProvider = Provider<double>((ref) {
  final current = ref.watch(financialAnalyticsProvider);
  final previous = ref.watch(previousMonthFinancialAnalyticsProvider);
  if (previous.expense <= 0) return 0;
  return ((current.expense - previous.expense) / previous.expense) * 100;
});
