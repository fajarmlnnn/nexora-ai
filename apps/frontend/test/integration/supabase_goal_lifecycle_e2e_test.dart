import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

import 'package:frontend/core/supabase/supabase_config.dart';
import 'package:frontend/features/dashboard/models/transaction_model.dart';
import 'package:frontend/features/finance/repositories/supabase_transaction_repository.dart';
import 'package:frontend/features/wallet/models/wallet_model.dart';
import 'package:frontend/features/wallet/repositories/supabase_wallet_repository.dart';

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
    'Goal funding lifecycle restores wallet balance when goal is deleted',
    () async {
      final client = SupabaseClient(
        SupabaseConfig.url,
        SupabaseConfig.publishableKey,
      );
      await client.auth.signInWithPassword(email: email, password: password);
      final user = client.auth.currentUser;
      if (user == null) throw StateError('E2E authentication failed.');

      final walletRepository = SupabaseWalletRepository(client: client);
      final transactionRepository = SupabaseTransactionRepository(client: client);
      final walletId = _uuid();
      final incomeId = _uuid();
      String? goalId;

      try {
        await walletRepository.createWallet(
          WalletModel(
            id: walletId,
            name: 'E2E Goal Wallet',
            bankName: '',
            accountNumber: '',
            balance: 0,
            type: WalletType.cash,
            color: const Color(0xFF2563EB),
            isPrimary: false,
          ),
        );

        await transactionRepository.createTransaction(
          TransactionModel(
            id: incomeId,
            title: 'E2E goal opening balance',
            amount: 100000,
            type: TransactionType.income,
            category: TransactionCategory.salary,
            date: DateTime.now(),
            walletId: walletId,
          ),
        );
        expect((await walletRepository.getWallet(walletId)).balance, 100000);

        final goal = await client.from('goals').insert({
          'user_id': user.id,
          'name': 'E2E rollback goal',
          'type': 'saving',
          'target_amount': 100000,
          'saved_amount': 0,
          'priority': 'normal',
          'status': 'active',
        }).select().single();
        final createdGoalId = goal['id'].toString();
        goalId = createdGoalId;

        // Deleting a goal directly is a financial write and must be blocked.
        await expectLater(
          client.from('goals').delete().eq('id', createdGoalId).eq('user_id', user.id),
          throwsA(isA<PostgrestException>()),
        );

        final updatedGoal = await client.rpc(
          'nexora_contribute_to_goal_from_wallet',
          params: {
            'p_goal_id': createdGoalId,
            'p_wallet_id': walletId,
            'p_amount': 100000,
            'p_note': 'E2E contribution',
            'p_idempotency_key': 'e2e-goal-${_uuid()}',
          },
        );
        expect((updatedGoal as Map)['saved_amount'], 100000);
        expect((await walletRepository.getWallet(walletId)).balance, 0);

        final contribution = await client
            .from('goal_contributions')
            .select('id')
            .eq('goal_id', createdGoalId)
            .single();
        final contributionId = contribution['id'].toString();

        final contributionTransaction = await client
            .from('transactions')
            .select('id, metadata')
            .eq('wallet_id', walletId)
            .eq('type', 'expense')
            .eq('metadata->>goal_contribution_id', contributionId)
            .single();
        final transactionId = contributionTransaction['id'].toString();
        expect((contributionTransaction['metadata'] as Map)['goal_id'].toString(), createdGoalId);

        await client.rpc('nexora_delete_goal', params: {'p_goal_id': createdGoalId});
        goalId = null;

        expect((await walletRepository.getWallet(walletId)).balance, 100000);

        final deletedGoal = await client
            .from('goals')
            .select('id')
            .eq('id', createdGoalId)
            .maybeSingle();
        expect(deletedGoal, isNull);

        final deletedContributions = await client
            .from('goal_contributions')
            .select('id')
            .eq('id', contributionId);
        expect(deletedContributions, isEmpty);

        final deletedTransactions = await client
            .from('transactions')
            .select('id')
            .eq('id', transactionId);
        expect(deletedTransactions, isEmpty);
      } finally {
        if (goalId != null) {
          try {
            await client.rpc('nexora_delete_goal', params: {'p_goal_id': goalId});
          } catch (_) {}
        }
        try {
          await transactionRepository.deleteTransaction(incomeId);
        } catch (_) {}
        try {
          await walletRepository.deleteWallet(walletId);
        } catch (_) {}
        await client.auth.signOut();
      }
    },
    skip: configured ? false : 'Set Supabase URL/key plus NEXORA_E2E_EMAIL and NEXORA_E2E_PASSWORD to run the live E2E test.',
  );
}
