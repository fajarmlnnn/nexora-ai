import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_state_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../dashboard/models/budget_item.dart';
import '../../dashboard/models/transaction_model.dart';
import '../../finance/state/financial_analytics_provider.dart';
import '../../finance/state/financial_transaction_store.dart';
import '../repositories/budget_repository.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return SupabaseBudgetRepository();
});

final budgetItemsProvider = AsyncNotifierProvider<BudgetController, List<BudgetItem>>(
  BudgetController.new,
);

class BudgetController extends AsyncNotifier<List<BudgetItem>> {
  BudgetRepository get _repository => ref.read(budgetRepositoryProvider);

  @override
  Future<List<BudgetItem>> build() async {
    ref.watch(currentUserProvider);
    final budgets = await _repository.getBudgets();
    final transactions = ref.watch(financialTransactionStoreProvider);
    return _applyTransactions(budgets, transactions);
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final budgets = await _repository.getBudgets();
      final transactions = ref.read(financialTransactionStoreProvider);
      return _applyTransactions(budgets, transactions);
    });
  }

  Future<bool> addBudget(BudgetItem budget) async {
    if (budget.limit <= 0) return false;
    try {
      await _repository.createBudget(budget.copyWith(spent: 0));
      await _reload();
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue<List<BudgetItem>>.error(error, stackTrace).copyWithPrevious(state);
      return false;
    }
  }

  Future<bool> updateBudget(BudgetItem budget) async {
    if (budget.limit <= 0) return false;
    try {
      await _repository.updateBudget(budget.copyWith(spent: 0));
      await _reload();
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue<List<BudgetItem>>.error(error, stackTrace).copyWithPrevious(state);
      return false;
    }
  }

  Future<bool> deleteBudget(String id) async {
    try {
      await _repository.deleteBudget(id);
      await _reload();
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue<List<BudgetItem>>.error(error, stackTrace).copyWithPrevious(state);
      return false;
    }
  }

  Future<void> _reload() async {
    state = await AsyncValue.guard<List<BudgetItem>>(() async {
      final budgets = await _repository.getBudgets();
      final transactions = ref.read(financialTransactionStoreProvider);
      return _applyTransactions(budgets, transactions);
    });
  }

  List<BudgetItem> _applyTransactions(
    List<BudgetItem> budgets,
    List<TransactionModel> transactions,
  ) {
    final now = DateTime.now();
    final analytics = buildFinancialAnalytics(
      transactions,
      DateTime(now.year, now.month),
      DateTime(now.year, now.month + 1),
    );

    return [
      for (final budget in budgets)
        budget.copyWith(
          spent: analytics.expenseByCategory[budget.category] ?? 0,
        ),
    ];
  }
}

/// Resolves a budget's transaction category.
///
/// New records use the explicit database category. This legacy helper remains
/// only for callers/tests that construct an old BudgetItem without category.
/// It must never infer a category from the budget database id once category is
/// present on the model.
TransactionCategory budgetCategoryForItem(BudgetItem budget) {
  return budget.category;
}

final totalBudgetLimitProvider = Provider<double>((ref) {
  final budgets = ref.watch(budgetItemsProvider).valueOrNull ?? const <BudgetItem>[];
  return budgets.fold<double>(0, (sum, budget) => sum + budget.limit);
});

final totalBudgetSpentProvider = Provider<double>((ref) {
  final budgets = ref.watch(budgetItemsProvider).valueOrNull ?? const <BudgetItem>[];
  return budgets.fold<double>(0, (sum, budget) => sum + budget.spent);
});

final budgetRemainingProvider = Provider<double>((ref) {
  return ref.watch(totalBudgetLimitProvider) - ref.watch(totalBudgetSpentProvider);
});

final overBudgetItemsProvider = Provider<List<BudgetItem>>((ref) {
  final budgets = ref.watch(budgetItemsProvider).valueOrNull ?? const <BudgetItem>[];
  return budgets.where((budget) => budget.isOverBudget).toList(growable: false);
});

final budgetUsageProvider = Provider<double>((ref) {
  final limit = ref.watch(totalBudgetLimitProvider);
  if (limit <= 0) return 0;
  return (ref.watch(totalBudgetSpentProvider) / limit).clamp(0.0, 1.0);
});

Color budgetColorForCategory(String category) {
  switch (category) {
    case 'food':
      return AppColors.success;
    case 'transport':
      return AppColors.warning;
    case 'shopping':
      return AppColors.danger;
    case 'bills':
      return AppColors.info;
    case 'entertainment':
      return AppColors.ai;
    case 'health':
      return AppColors.chart2;
    case 'education':
      return AppColors.chart2;
    default:
      return AppColors.brand;
  }
}
