import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/budget/controllers/budget_controller.dart';
import 'package:frontend/features/dashboard/models/budget_item.dart';
import 'package:frontend/features/dashboard/models/transaction_model.dart';

void main() {
  test('budget category is independent from budget database id', () {
    const budget = BudgetItem(
      id: 'budget-1734029912345',
      name: 'Makan Harian',
      category: TransactionCategory.food,
      spent: 0,
      limit: 100000,
      color: Color(0xFF35D07F),
    );

    expect(budgetCategoryForItem(budget), TransactionCategory.food);
  });

  test('custom budget id cannot silently change the explicit category', () {
    const budget = BudgetItem(
      id: 'food',
      name: 'Budget Custom',
      category: TransactionCategory.bills,
      spent: 0,
      limit: 100000,
      color: Color(0xFF7C8CFF),
    );

    expect(budgetCategoryForItem(budget), TransactionCategory.bills);
  });

  test('localized display names do not override an explicit category', () {
    const budget = BudgetItem(
      id: 'budget-custom',
      name: 'Tagihan',
      category: TransactionCategory.food,
      spent: 0,
      limit: 100000,
      color: Color(0xFF35D07F),
    );

    expect(budgetCategoryForItem(budget), TransactionCategory.food);
  });

  test('over-budget state uses the real spent amount and preserves negative remaining', () {
    const budget = BudgetItem(
      id: 'budget-food',
      name: 'Makan',
      category: TransactionCategory.food,
      spent: 125000,
      limit: 100000,
      color: Color(0xFF35D07F),
    );

    expect(budget.isOverBudget, isTrue);
    expect(budget.remaining, -25000);
    expect(budget.progress, 1);
  });
}
