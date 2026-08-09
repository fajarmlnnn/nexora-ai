import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../finance/state/financial_transaction_store.dart';
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

final dashboardSummaryProvider = Provider<DashboardSummary>((ref) {
  final transactions = ref.watch(financialTransactionsProvider);

  return DashboardSummary(
    totalBalance: transactions.currentBalance,
    monthlyIncome: transactions.monthlyIncome,
    monthlyExpense: transactions.monthlyExpense,
    monthlyBudget: FinancialTransactionStore.monthlyBudget,
    budgetUsed: transactions.monthlyExpense,
    currency: 'IDR',
    lastUpdated: DateTime.now(),
  );
});

final recentTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final transactions = ref.watch(financialTransactionsProvider);
  final sorted = [...transactions]
    ..sort((a, b) => b.date.compareTo(a.date));
  return sorted;
});

final budgetItemsProvider = FutureProvider<List<BudgetItem>>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getBudgetItems();
});

final dashboardProvider = Provider<DashboardData>((ref) {
  final summary = ref.watch(dashboardSummaryProvider);
  final budgets = ref.watch(budgetItemsProvider).valueOrNull ?? const <BudgetItem>[];
  final transactions = ref.watch(recentTransactionsProvider);

  return DashboardData(
    summary: summary,
    budgetItems: budgets,
    transactions: transactions,
  );
});

final aiInsightProvider = FutureProvider<AIInsight>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getAIInsight();
});
