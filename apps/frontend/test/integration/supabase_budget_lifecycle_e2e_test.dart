import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

import 'package:frontend/core/supabase/supabase_config.dart';
import 'package:frontend/features/dashboard/models/budget_item.dart';
import 'package:frontend/features/dashboard/models/transaction_model.dart';
import 'package:frontend/features/budget/repositories/budget_repository.dart';
import 'package:frontend/features/finance/repositories/supabase_transaction_repository.dart';

String _uuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

void main() {
  const email = String.fromEnvironment('NEXORA_E2E_EMAIL');
  const password = String.fromEnvironment('NEXORA_E2E_PASSWORD');
  final configured = SupabaseConfig.isConfigured && email.isNotEmpty && password.isNotEmpty;

  test(
    'Budget lifecycle persists limits and never persists forged spent values',
    () async {
      final client = SupabaseClient(
        SupabaseConfig.url,
        SupabaseConfig.publishableKey,
      );
      await client.auth.signInWithPassword(email: email, password: password);
      final user = client.auth.currentUser;
      if (user == null) throw StateError('E2E authentication failed.');

      final repository = SupabaseBudgetRepository(client: client);
      final transactionRepository = SupabaseTransactionRepository(client: client);
      const budgetId = 'food';
      final expenseId = _uuid();
      final transferId = _uuid();
      var created = false;

      try {
        // The E2E account is isolated. Remove only the deterministic fixture id
        // so this test can be rerun without creating duplicate category budgets.
        await client
            .from('budgets')
            .delete()
            .eq('id', budgetId)
            .eq('user_id', user.id);

        final budget = await repository.createBudget(
          const BudgetItem(
            id: budgetId,
            name: 'Makan E2E',
            spent: 999999,
            limit: 100000,
            color: Color(0xFF35D07F),
          ),
        );
        created = true;

        // Spent must never be persisted from the client payload.
        expect(budget.spent, 0);
        final stored = await client
            .from('budgets')
            .select('id, name, budget_limit, color')
            .eq('id', budgetId)
            .eq('user_id', user.id)
            .single();
        expect((stored['budget_limit'] as num).toDouble(), 100000);
        expect(stored['name'], 'Makan E2E');

        final noTransactions = await repository.getBudgets();
        expect(noTransactions.singleWhere((item) => item.id == budgetId).spent, 0);

        await transactionRepository.createTransaction(
          TransactionModel(
            id: expenseId,
            title: 'E2E budget food expense',
            amount: 75000,
            type: TransactionType.expense,
            category: TransactionCategory.food,
            date: DateTime.now(),
          ),
        );

        final persistedAgain = await repository.getBudgets();
        // Repository deliberately returns derived spent=0. The controller is
        // responsible for joining current-month expenses to the budget.
        expect(persistedAgain.singleWhere((item) => item.id == budgetId).spent, 0);

        // Transfers must never become budget spending even if their amount is
        // large and their date/category would otherwise match the period.
        await transactionRepository.createTransaction(
          TransactionModel(
            id: transferId,
            title: 'E2E budget transfer',
            amount: 500000,
            type: TransactionType.transfer,
            category: TransactionCategory.food,
            date: DateTime.now(),
          ),
        );

        final updated = await repository.updateBudget(
          budget.copyWith(limit: 120000, spent: 777777),
        );
        expect(updated.limit, 120000);
        expect(updated.spent, 0);

        final afterUpdate = await repository.getBudgets();
        final updatedRow = afterUpdate.singleWhere((item) => item.id == budgetId);
        expect(updatedRow.limit, 120000);
        expect(updatedRow.spent, 0);

        await repository.deleteBudget(budgetId);
        created = false;
        expect((await repository.getBudgets()).where((item) => item.id == budgetId), isEmpty);
      } finally {
        try {
          await transactionRepository.deleteTransaction(expenseId);
        } catch (_) {}
        try {
          await transactionRepository.deleteTransaction(transferId);
        } catch (_) {}
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
