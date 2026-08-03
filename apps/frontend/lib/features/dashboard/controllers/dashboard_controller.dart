import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_summary.dart';
import '../models/transaction_model.dart';
import '../repositories/dashboard_repository.dart';
import '../models/budget_item.dart';
import '../models/dashboard_data.dart';
import '../models/ai_insight.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return const DashboardRepository();
});

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getDashboardSummary();
});

final recentTransactionsProvider = FutureProvider<List<TransactionModel>>((
  ref,
) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getRecentTransactions();
});

final budgetItemsProvider = FutureProvider<List<BudgetItem>>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getBudgetItems();
});

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);

  return repository.getDashboardData();
});

final aiInsightProvider = FutureProvider<AIInsight>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);

  return repository.getAIInsight();
});
