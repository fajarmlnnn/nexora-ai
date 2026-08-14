import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/budget/controllers/budget_controller.dart';
import 'package:frontend/features/dashboard/models/budget_item.dart';
import 'package:frontend/features/dashboard/models/transaction_model.dart';

void main() {
  test('budget identity changes do not change spending category', () {
    const budget = BudgetItem(
      id: 'budget-unique-001',
      name: 'Makan Bulanan',
      category: TransactionCategory.food,
      spent: 0,
      limit: 500000,
      color: Color(0xFF35D07F),
    );

    expect(budgetCategoryForItem(budget), TransactionCategory.food);
  });
}
