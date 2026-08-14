import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/budget/controllers/budget_controller.dart';
import 'package:frontend/features/dashboard/models/budget_item.dart';
import 'package:frontend/features/dashboard/models/transaction_model.dart';

void main() {
  test('budget category mapping prefers stable category id over display name', () {
    const budget = BudgetItem(
      id: 'food',
      name: 'Makan Harian',
      spent: 0,
      limit: 100000,
      color: Color(0xFF35D07F),
    );

    expect(budgetCategoryForItem(budget), TransactionCategory.food);
  });

  test('localized budget names map to their transaction categories', () {
    const budget = BudgetItem(
      id: 'custom-bills',
      name: 'Tagihan',
      spent: 0,
      limit: 100000,
      color: Color(0xFF7C8CFF),
    );

    expect(budgetCategoryForItem(budget), TransactionCategory.bills);
  });

  test('unknown budget categories safely fall back to other', () {
    const budget = BudgetItem(
      id: 'custom-category',
      name: 'Budget Acak',
      spent: 0,
      limit: 100000,
      color: Color(0xFF9A72FF),
    );

    expect(budgetCategoryForItem(budget), TransactionCategory.other);
  });

  test('over-budget state uses the real spent amount and preserves negative remaining', () {
    const budget = BudgetItem(
      id: 'food',
      name: 'Makan',
      spent: 125000,
      limit: 100000,
      color: Color(0xFF35D07F),
    );

    expect(budget.isOverBudget, isTrue);
    expect(budget.remaining, -25000);
    expect(budget.progress, 1);
  });
}
