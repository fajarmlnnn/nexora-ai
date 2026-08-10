import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../finance/state/financial_transaction_store.dart';
import '../../wallet/controllers/wallet_controller.dart';
import '../models/ai_insight.dart';
import '../models/budget_item.dart';
import '../models/dashboard_data.dart';
import '../models/dashboard_summary.dart';
import '../models/transaction_model.dart';
import '../repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return const DashboardRepository();
});

final financialTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  return ref.watch(financialTransactionStoreProvider);
});

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final transactions = ref.watch(financialTransactionsProvider);
  final totalBalance = ref.watch(totalWalletBalanceProvider);

  return DashboardSummary(
    totalBalance: totalBalance,
    monthlyIncome: transactions.monthlyIncome,
    monthlyExpense: transactions.monthlyExpense,
    monthlyBudget: 0,
    budgetUsed: 0,
    currency: 'IDR',
    lastUpdated: DateTime.now(),
  );
});

final recentTransactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final transactions = ref.watch(financialTransactionsProvider);
  final sorted = [...transactions]
    ..sort((a, b) => b.date.compareTo(a.date));
  return sorted;
});

final budgetItemsProvider = FutureProvider<List<BudgetItem>>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getBudgetItems();
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
  final currentMonth = transactions.where((item) =>
      item.date.year == now.year && item.date.month == now.month);
  final previousMonthDate = DateTime(now.year, now.month - 1);
  final previousMonth = transactions.where((item) =>
      item.date.year == previousMonthDate.year &&
      item.date.month == previousMonthDate.month);

  final currentExpense = currentMonth.fold<double>(
    0,
    (sum, item) => sum + (item.isExpense ? item.amount : 0),
  );
  final previousExpense = previousMonth.fold<double>(
    0,
    (sum, item) => sum + (item.isExpense ? item.amount : 0),
  );
  final currentIncome = currentMonth.fold<double>(
    0,
    (sum, item) => sum + (item.isIncome ? item.amount : 0),
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
      message: 'Belum ada pengeluaran bulan ini. Insight perbandingan akan tersedia setelah data pengeluaran tercatat.',
      level: InsightLevel.positive,
    );
  }

  return const AIInsight(
    title: 'Nexora AI Insight',
    message: 'Belum cukup data historis untuk membuat perbandingan. Lanjutkan pencatatan transaksi agar insight semakin akurat.',
    level: InsightLevel.positive,
  );
}
