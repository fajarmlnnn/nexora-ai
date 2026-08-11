import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../budget/controllers/budget_controller.dart';
import '../../finance/state/financial_transaction_store.dart';
import '../../wallet/controllers/wallet_controller.dart';
import '../models/ai_insight.dart';
import '../models/dashboard_data.dart';
import '../models/dashboard_summary.dart';
import '../models/transaction_model.dart';

export '../../budget/controllers/budget_controller.dart' show budgetItemsProvider;

final financialTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  return ref.watch(financialTransactionStoreProvider);
});

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final transactions = ref.watch(financialTransactionsProvider);
  final totalBalance = ref.watch(totalWalletBalanceProvider);
  final balanceTrend = _buildBalanceTrend(transactions, totalBalance);

  return DashboardSummary(
    totalBalance: totalBalance,
    monthlyIncome: transactions.monthlyIncome,
    monthlyExpense: transactions.monthlyExpense,
    monthlyBudget: ref.watch(totalBudgetLimitProvider),
    budgetUsed: ref.watch(totalBudgetSpentProvider),
    currency: 'IDR',
    lastUpdated: DateTime.now(),
    previousBalance: balanceTrend.previousBalance,
    balanceChangePercent: balanceTrend.changePercent,
    balanceTrendPoints: balanceTrend.points,
  );
});

final recentTransactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final transactions = ref.watch(financialTransactionsProvider);
  final sorted = [...transactions]
    ..sort((a, b) => b.date.compareTo(a.date));
  return sorted;
});

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final summary = await ref.watch(dashboardSummaryProvider.future);
  final budgets = await ref.watch(budgetItemsProvider.future);
  final transactions = await ref.watch(recentTransactionsProvider.future);

  return DashboardData(
    summary: summary,
    budgetItems: budgets,
    transactions: transactions,
  );
});

final aiInsightProvider = Provider<AIInsight>((ref) {
  final transactions = ref.watch(financialTransactionsProvider);
  return _buildRealDataInsight(transactions);
});

AIInsight _buildRealDataInsight(List<TransactionModel> transactions) {
  if (transactions.isEmpty) {
    return const AIInsight(
      title: 'Nexora AI Insight',
      message: 'Belum ada transaksi. Tambahkan transaksi untuk mendapatkan insight berdasarkan data keuanganmu.',
      level: InsightLevel.positive,
    );
  }

  final now = DateTime.now();
  final currentMonth = transactions.where(
    (item) => item.date.year == now.year && item.date.month == now.month,
  );
  final previousMonthDate = DateTime(now.year, now.month - 1);
  final previousMonth = transactions.where(
    (item) =>
        item.date.year == previousMonthDate.year &&
        item.date.month == previousMonthDate.month,
  );

  final currentExpense = currentMonth.fold<double>(
    0.0,
    (sum, item) => sum + (item.isExpense ? item.amount : 0.0),
  );
  final previousExpense = previousMonth.fold<double>(
    0.0,
    (sum, item) => sum + (item.isExpense ? item.amount : 0.0),
  );
  final currentIncome = currentMonth.fold<double>(
    0.0,
    (sum, item) => sum + (item.isIncome ? item.amount : 0.0),
  );

  if (previousExpense > 0) {
    final change = ((currentExpense - previousExpense) / previousExpense) * 100;
    final direction = change >= 0 ? 'naik' : 'turun';
    final absoluteChange = change.abs().toStringAsFixed(1);
    return AIInsight(
      title: 'Nexora AI Insight',
      message:
          'Pengeluaran bulan ini $direction $absoluteChange% dibanding bulan lalu berdasarkan transaksi yang tercatat.',
      level: change > 0 ? InsightLevel.warning : InsightLevel.positive,
    );
  }

  if (currentIncome > 0 && currentExpense == 0) {
    return const AIInsight(
      title: 'Nexora AI Insight',
      message:
          'Belum ada pengeluaran bulan ini. Insight perbandingan akan tersedia setelah data pengeluaran tercatat.',
      level: InsightLevel.positive,
    );
  }

  return const AIInsight(
    title: 'Nexora AI Insight',
    message:
        'Belum cukup data historis untuk membuat perbandingan. Lanjutkan pencatatan transaksi agar insight semakin akurat.',
    level: InsightLevel.positive,
  );
}

_BalanceTrend _buildBalanceTrend(
  List<TransactionModel> transactions,
  double currentBalance,
) {
  final now = DateTime.now();
  final currentMonthTransactions = transactions
      .where(
        (item) => item.date.year == now.year && item.date.month == now.month,
      )
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  final currentMonthIncome = currentMonthTransactions.fold<double>(
    0.0,
    (sum, item) => sum + (item.isIncome ? item.amount : 0.0),
  );
  final currentMonthExpense = currentMonthTransactions.fold<double>(
    0.0,
    (sum, item) => sum + (item.isExpense ? item.amount : 0.0),
  );

  final previousBalance = currentBalance - currentMonthIncome + currentMonthExpense;
  final changePercent = previousBalance <= 0
      ? 0.0
      : ((currentBalance - previousBalance) / previousBalance) * 100;

  final dailyDeltas = <int, double>{};
  for (final transaction in currentMonthTransactions) {
    final delta = transaction.isIncome
        ? transaction.amount
        : transaction.isExpense
            ? -transaction.amount
            : 0.0;
    dailyDeltas[transaction.date.day] =
        (dailyDeltas[transaction.date.day] ?? 0.0) + delta;
  }

  var balance = previousBalance;
  final points = <double>[];
  final dayCount = now.day < 2 ? 2 : now.day;
  for (var day = 1; day <= dayCount; day++) {
    balance += dailyDeltas[day] ?? 0.0;
    points.add(balance);
  }

  if (points.length == 1) {
    points.add(points.first);
  }

  return _BalanceTrend(
    previousBalance: previousBalance,
    changePercent: changePercent,
    points: List<double>.unmodifiable(points),
  );
}

class _BalanceTrend {
  const _BalanceTrend({
    required this.previousBalance,
    required this.changePercent,
    required this.points,
  });

  final double previousBalance;
  final double changePercent;
  final List<double> points;
}
