import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final budgets = await _repository.getBudgets();
    final transactions = ref.watch(financialTransactionStoreProvider);
    return _applyTransactions(budgets, transactions);
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
          spent: analytics.expenseByCategory[budgetCategoryForItem(budget)] ?? 0,
        ),
    ];
  }
}

/// Resolves a budget's transaction category.
///
/// Current budgets use their id as the category key (for example `food` or
/// `transport`). The display name is also accepted for human-readable budgets.
/// Unknown values safely fall back to `other`.
TransactionCategory budgetCategoryForItem(BudgetItem budget) {
  final byId = _transactionCategoryFromName(budget.id.trim().toLowerCase());
  if (byId != TransactionCategory.other) return byId;

  return _transactionCategoryFromName(_normalizeCategoryName(budget.name));
}

String _normalizeCategoryName(String value) {
  final normalized = value.trim().toLowerCase();
  const aliases = <String, String>{
    'makanan': 'food',
    'makan': 'food',
    'transportasi': 'transport',
    'belanja': 'shopping',
    'tagihan': 'bills',
    'hiburan': 'entertainment',
    'kesehatan': 'health',
    'pendidikan': 'education',
    'lainnya': 'other',
  };
  return aliases[normalized] ?? normalized;
}

TransactionCategory _transactionCategoryFromName(String value) {
  for (final category in TransactionCategory.values) {
    if (category.name == value) return category;
  }
  return TransactionCategory.other;
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
      return const Color(0xFF35D07F);
    case 'transport':
      return const Color(0xFFFFB84D);
    case 'shopping':
      return const Color(0xFFFF5D6C);
    case 'bills':
      return const Color(0xFF7C8CFF);
    case 'entertainment':
      return const Color(0xFFB77CFF);
    case 'health':
      return const Color(0xFFFF6FAE);
    case 'education':
      return const Color(0xFF55C8FF);
    default:
      return const Color(0xFF9A72FF);
  }
}
