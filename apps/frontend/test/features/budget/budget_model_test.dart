import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/budget/controllers/budget_controller.dart';
import 'package:frontend/features/dashboard/models/budget_item.dart';
import 'package:frontend/features/dashboard/models/transaction_model.dart';

void main() {
  test('BudgetItem defaults category to other', () {
    const budget = BudgetItem(
      id: 'custom-1',
      name: 'Daily spending',
      spent: 25,
      limit: 100,
      color: Color(0xFF000000),
    );

    expect(budget.category, 'other');
    expect(budget.remaining, 75);
    expect(budget.progress, 0.25);
  });

  test('BudgetItem copyWith and JSON round trip preserve category', () {
    const budget = BudgetItem(
      id: 'food-budget',
      name: 'Food',
      spent: 50,
      limit: 200,
      color: Color(0xFF123456),
      category: 'food',
    );

    final copy = budget.copyWith(limit: 300);
    final restored = BudgetItem.fromJson(copy.toJson());

    expect(copy.category, 'food');
    expect(restored.category, 'food');
    expect(restored.limit, 300);
    expect(restored.color, const Color(0xFF123456));
  });

  test('BudgetItem safely clamps progress and detects over budget', () {
    const budget = BudgetItem(
      id: 'bills',
      name: 'Bills',
      spent: 150,
      limit: 100,
      color: Color(0xFF000000),
      category: 'bills',
    );

    expect(budget.isOverBudget, isTrue);
    expect(budget.remaining, -50);
    expect(budget.progress, 1.0);
  });

  test('budget category uses explicit category instead of database id', () {
    const budget = BudgetItem(
      id: 'random-database-id',
      name: 'Food budget',
      spent: 0,
      limit: 100,
      color: Color(0xFF000000),
      category: 'food',
    );

    expect(budgetCategoryForItem(budget), TransactionCategory.food);
  });

  test('legacy category-keyed ids remain supported', () {
    const budget = BudgetItem(
      id: 'transport',
      name: 'Transport',
      spent: 0,
      limit: 100,
      color: Color(0xFF000000),
    );

    expect(budgetCategoryForItem(budget), TransactionCategory.transport);
  });

  test('unknown custom budgets safely map to other', () {
    const budget = BudgetItem(
      id: 'custom-budget-1',
      name: 'My custom budget',
      spent: 0,
      limit: 100,
      color: Color(0xFF000000),
    );

    expect(budgetCategoryForItem(budget), TransactionCategory.other);
  });
}
