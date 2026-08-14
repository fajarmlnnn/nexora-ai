import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/budget/controllers/budget_controller.dart';
import 'package:frontend/features/dashboard/models/budget_item.dart';
import 'package:frontend/features/dashboard/models/transaction_model.dart';

group('BudgetItem', () {
  test('defaults category to other for backward compatibility', () {
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

  test('copyWith preserves category and JSON round trip', () {
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

  test('over budget and progress are safely bounded', () {
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
});

group('budgetCategoryForItem', () {
  test('uses explicit category instead of budget id', () {
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

  test('custom budget without a known category safely maps to other', () {
    const budget = BudgetItem(
      id: 'custom-budget-1',
      name: 'My custom budget',
      spent: 0,
      limit: 100,
      color: Color(0xFF000000),
    );

    expect(budgetCategoryForItem(budget), TransactionCategory.other);
  });
});
