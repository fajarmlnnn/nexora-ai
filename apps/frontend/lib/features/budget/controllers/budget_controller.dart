import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/models/budget_item.dart';
import '../../dashboard/models/transaction_model.dart';
import '../../finance/state/financial_transaction_store.dart';
import '../repositories/budget_repository.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return LocalBudgetRepository();
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
    try {
      await _repository.createBudget(budget);
      await _reload();
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue<List<BudgetItem>>.error(error, stackTrace).copyWithPrevious(state);
      return false;
    }
  }

  Future<bool> updateBudget(BudgetItem budget) async {
    try {
      await _repository.updateBudget(budget);
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
    return [
      for (final budget in budgets)
        budget.copyWith(
          spent: transactions
              .where((transaction) =>
                  transaction.isExpense &&
                  transaction.date.year == now.year &&
                  transaction.date.month == now.month &&
                  transaction.category.name == budget.id)
              .fold<double>(0, (sum, transaction) => sum + transaction.amount),
        ),
    ];
  }
}

final totalBudgetLimitProvider = Provider<double>((ref) {
  final budgets = ref.watch(budgetItemsProvider).valueOrNull ?? const <BudgetItem>[];
  return budgets.fold<double>(0, (sum, budget) => sum + budget.limit);
});

final totalBudgetSpentProvider = Provider<double>((ref) {
  final budgets = ref.watch(budgetItemsProvider).valueOrNull ?? const <BudgetItem>[];
  return budgets.fold<double>(0, (sum, budget) => sum + budget.spent);
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
