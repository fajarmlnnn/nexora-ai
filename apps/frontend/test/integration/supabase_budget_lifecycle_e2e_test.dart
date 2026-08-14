import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

import 'package:frontend/core/supabase/supabase_config.dart';
import 'package:frontend/features/budget/repositories/budget_repository.dart';
import 'package:frontend/features/dashboard/models/budget_item.dart';
import 'package:frontend/features/dashboard/models/transaction_model.dart';
import 'package:frontend/features/finance/state/financial_analytics_provider.dart';

void main() {
  const email = String.fromEnvironment('NEXORA_E2E_EMAIL');
  const password = String.fromEnvironment('NEXORA_E2E_PASSWORD');
  final configured = SupabaseConfig.isConfigured && email.isNotEmpty && password.isNotEmpty;

  test(
    'Budget lifecycle persists limits and derives spending without counting transfers',
    () async {
      final client = SupabaseClient(
        SupabaseConfig.url,
        SupabaseConfig.publishableKey,
      );
      await client.auth.signInWithPassword(email: email, password: password);
      final user = client.auth.currentUser;
      if (user == null) throw StateError('E2E authentication failed.');

      final repository = SupabaseBudgetRepository(client: client);
      const budgetId = 'budget-e2e-food';
      var created = false;

      try {
        await client
            .from('budgets')
            .delete()
            .eq('id', budgetId)
            .eq('user_id', user.id);

        final budget = await repository.createBudget(
          const BudgetItem(
            id: budgetId,
            name: 'Makan E2E',
            category: TransactionCategory.food,
            spent: 999999,
            limit: 100000,
            color: Color(0xFF35D07F),
          ),
        );
        created = true;

        expect(budget.category, TransactionCategory.food);
        expect(budget.spent, 0);
        final stored = await client
            .from('budgets')
            .select('id, name, category, budget_limit, color')
            .eq('id', budgetId)
            .eq('user_id', user.id)
            .single();
        expect((stored['budget_limit'] as num).toDouble(), 100000);
        expect(stored['name'], 'Makan E2E');
        expect(stored['category'], 'food');

        final transactions = <TransactionModel>[
          TransactionModel(
            id: 'budget-fixture-expense',
            title: 'E2E budget food expense',
            amount: 75000,
            type: TransactionType.expense,
            category: TransactionCategory.food,
            date: DateTime.now(),
          ),
          TransactionModel(
            id: 'budget-fixture-transfer',
            title: 'E2E budget transfer',
            amount: 500000,
            type: TransactionType.transfer,
            category: TransactionCategory.food,
            date: DateTime.now(),
            sourceAccount: 'wallet-source',
            destinationAccount: 'wallet-destination',
          ),
        ];

        final now = DateTime.now();
        final analytics = buildFinancialAnalytics(
          transactions,
          DateTime(now.year, now.month),
          DateTime(now.year, now.month + 1),
        );
        expect(analytics.expenseByCategory[TransactionCategory.food], 75000);
        expect(analytics.expense, 75000);
        expect(analytics.transferOut, 500000);
        expect(analytics.transferIn, 500000);
        expect(analytics.transactionCount, 2);

        final reloaded = await repository.getBudgets();
        expect(reloaded.singleWhere((item) => item.id == budgetId).spent, 0);
        expect(reloaded.singleWhere((item) => item.id == budgetId).category, TransactionCategory.food);

        final updated = await repository.updateBudget(
          budget.copyWith(limit: 120000, spent: 777777),
        );
        expect(updated.limit, 120000);
        expect(updated.spent, 0);
        expect(updated.category, TransactionCategory.food);

        final afterUpdate = await repository.getBudgets();
        final updatedRow = afterUpdate.singleWhere((item) => item.id == budgetId);
        expect(updatedRow.limit, 120000);
        expect(updatedRow.spent, 0);
        expect(updatedRow.category, TransactionCategory.food);

        await repository.deleteBudget(budgetId);
        created = false;
        expect(
          (await repository.getBudgets()).where((item) => item.id == budgetId),
          isEmpty,
        );
      } finally {
        if (created) {
          try {
            await repository.deleteBudget(budgetId);
          } catch (_) {}
        }
        await client.auth.signOut();
      }
    },
    skip: configured ? false : 'Set Supabase URL/key plus NEXORA_E2E_EMAIL and NEXORA_E2E_PASSWORD to run the live budget E2E test.',
  );
}
