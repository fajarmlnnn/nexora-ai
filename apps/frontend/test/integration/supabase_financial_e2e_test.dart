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
    'Supabase financial flow preserves balances, ownership, and persistence',
    () async {
      final client = SupabaseClient(
        SupabaseConfig.url,
        SupabaseConfig.publishableKey,
      );
      await client.auth.signInWithPassword(email: email, password: password);

      final user = client.auth.currentUser;
      expect(user, isNotNull);

      final walletRepository = SupabaseWalletRepository(client: client);
      final transactionRepository = SupabaseTransactionRepository(client: client);
      final walletAId = _uuid();
      final walletBId = _uuid();
      final transactionIds = <String>[];
      String? persistenceProbeId;
      String? goalProbeId;

      try {
        final walletA = await walletRepository.createWallet(
          WalletModel(
            id: walletAId,
            name: 'E2E Wallet A',
            bankName: '',
            accountNumber: '',
            balance: 999999999,
            type: WalletType.cash,
            color: const Color(0xFF2563EB),
            isPrimary: false,
          ),
        );
        expect(walletA.balance, 0);

        final walletB = await walletRepository.createWallet(
          WalletModel(
            id: walletBId,
            name: 'E2E Wallet B',
            bankName: '',
            accountNumber: '',
            balance: 999999999,
            type: WalletType.bank,
            color: const Color(0xFF16A34A),
          ),
        );
        expect(walletB.balance, 0);

        final income = await transactionRepository.createTransaction(
          TransactionModel(
            id: _uuid(),
            title: 'E2E opening income',
            amount: 100000,
            type: TransactionType.income,
            category: TransactionCategory.salary,
            date: DateTime.now(),
            walletId: walletAId,
          ),
        );
        transactionIds.add(income.id);
        expect((await walletRepository.getWallet(walletAId)).balance, 100000);

        final expense = await transactionRepository.createTransaction(
          TransactionModel(
            id: _uuid(),
            title: 'E2E expense',
            amount: 25000,
            type: TransactionType.expense,
            category: TransactionCategory.food,
            date: DateTime.now(),
            walletId: walletAId,
          ),
        );
        transactionIds.add(expense.id);
        expect((await walletRepository.getWallet(walletAId)).balance, 75000);

        final transfer = await transactionRepository.createTransaction(
          TransactionModel(
            id: _uuid(),
            title: 'E2E transfer',
            amount: 30000,
            type: TransactionType.transfer,
            category: TransactionCategory.other,
            date: DateTime.now(),
            sourceAccount: walletAId,
            destinationAccount: walletBId,
          ),
        );
        transactionIds.add(transfer.id);
        expect((await walletRepository.getWallet(walletAId)).balance, 45000);
        expect((await walletRepository.getWallet(walletBId)).balance, 30000);

        await expectLater(
          transactionRepository.createTransaction(
            TransactionModel(
              id: _uuid(),
              title: 'E2E overdraft transfer',
              amount: 50000,
              type: TransactionType.transfer,
              category: TransactionCategory.other,
              date: DateTime.now(),
              sourceAccount: walletAId,
              destinationAccount: walletBId,
            ),
          ),
          throwsA(isA<PostgrestException>()),
        );
        expect((await walletRepository.getWallet(walletAId)).balance, 45000);
        expect((await walletRepository.getWallet(walletBId)).balance, 30000);

        await expectLater(
          client.from('transactions').insert({
            'id': _uuid(),
            'user_id': user!.id,
            'wallet_id': _uuid(),
            'type': 'income',
            'amount': '1000.00',
            'category': 'other',
            'description': 'E2E forged wallet ownership',
            'occurred_at': DateTime.now().toUtc().toIso8601String(),
            'idempotency_key': _uuid(),
          }),
          throwsA(isA<PostgrestException>()),
        );

        await transactionRepository.deleteTransaction(expense.id);
        transactionIds.remove(expense.id);
        expect((await walletRepository.getWallet(walletAId)).balance, 70000);

        final updatedTransfer = await transactionRepository.updateTransaction(
          transfer.copyWith(amount: 10000),
        );
        expect(updatedTransfer.amount, 10000);
        expect((await walletRepository.getWallet(walletAId)).balance, 90000);
        expect((await walletRepository.getWallet(walletBId)).balance, 10000);

        final duplicate = await transactionRepository.createTransaction(
          income,
          idempotencyKey: income.id,
        );
        expect(duplicate.id, income.id);
        expect((await walletRepository.getWallet(walletAId)).balance, 90000);

        await expectLater(
          transactionRepository.createTransaction(
            income.copyWith(amount: 123456),
            idempotencyKey: income.id,
          ),
          throwsA(isA<StateError>()),
        );
        expect((await walletRepository.getWallet(walletAId)).balance, 90000);

        // Two requests deliberately start together. The database trigger locks
        // the wallet row before checking the balance. Exactly one 55k expense
        // may therefore commit; the other must see the new 35k balance and
        // fail instead of allowing a negative/corrupted balance.
        final concurrentTransactions = [
          TransactionModel(
            id: _uuid(),
            title: 'E2E concurrent expense A',
            amount: 55000,
            type: TransactionType.expense,
            category: TransactionCategory.other,
            date: DateTime.now(),
            walletId: walletAId,
          ),
          TransactionModel(
            id: _uuid(),
            title: 'E2E concurrent expense B',
            amount: 55000,
            type: TransactionType.expense,
            category: TransactionCategory.other,
            date: DateTime.now(),
            walletId: walletAId,
          ),
        ];

        final results = await Future.wait(
          concurrentTransactions.map((transaction) async {
            try {
              final created = await transactionRepository.createTransaction(transaction);
              transactionIds.add(created.id);
              return true;
            } on PostgrestException {
              return false;
            }
          }),
        );

        expect(results.where((success) => success).length, 1);
        expect(results.where((success) => !success).length, 1);
        expect((await walletRepository.getWallet(walletAId)).balance, 35000);

        // Persistence regression test: a fresh Supabase client simulates a
        // cold start/reinstall. After signing in again, transactions must be
        // loaded from Supabase rather than from an in-memory/local-only store.
        persistenceProbeId = (await transactionRepository.getTransactions(limit: 1)).first.id;
        await client.auth.signOut();
        final freshClient = SupabaseClient(
          SupabaseConfig.url,
          SupabaseConfig.publishableKey,
        );
        try {
          await freshClient.auth.signInWithPassword(email: email, password: password);
          final freshTransactions = await SupabaseTransactionRepository(client: freshClient)
              .getTransactions(limit: 100);
          expect(freshTransactions.any((item) => item.id == persistenceProbeId), isTrue);

          // Goal insert regression test: user_id must be explicit because the
          // goals RLS policy intentionally requires user_id = auth.uid().
          final goal = await freshClient.from('goals').insert({
            'user_id': freshClient.auth.currentUser!.id,
            'name': 'E2E goal',
            'type': 'saving',
            'target_amount': 100000,
            'saved_amount': 0,
            'priority': 'normal',
            'status': 'active',
          }).select().single();
          goalProbeId = goal['id'].toString();
          expect(goal['user_id'].toString(), freshClient.auth.currentUser!.id);
        } finally {
          if (goalProbeId != null) {
            await freshClient.from('goals').delete().eq('id', goalProbeId!);
          }
          await freshClient.auth.signOut();
        }

        // Restore the original authenticated client for deterministic cleanup.
        await client.auth.signInWithPassword(email: email, password: password);
      } finally {
        if (persistenceProbeId != null && !transactionIds.contains(persistenceProbeId)) {
          transactionIds.add(persistenceProbeId);
        }
        for (final id in transactionIds.reversed) {
          try {
            await transactionRepository.deleteTransaction(id);
          } catch (_) {
            // Best-effort cleanup; preserve the original test failure.
          }
        }
        try {
          await walletRepository.deleteWallet(walletAId);
        } catch (_) {}
        try {
          await walletRepository.deleteWallet(walletBId);
        } catch (_) {}
        await client.auth.signOut();
      }
    },
    skip: configured ? false : 'Set Supabase URL/key plus NEXORA_E2E_EMAIL and NEXORA_E2E_PASSWORD to run the live E2E test.',
  );
}
