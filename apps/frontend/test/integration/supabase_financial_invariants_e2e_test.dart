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
    'Transaction lifecycle preserves minimum balance and reverses updates/deletes',
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
      final expenseId = _uuid();

      try {
        await walletRepository.createWallet(
          WalletModel(
            id: walletId,
            name: 'E2E Minimum Balance Wallet',
            bankName: '',
            accountNumber: '',
            balance: 0,
            type: WalletType.cash,
            color: const Color(0xFF2563EB),
            isPrimary: false,
            minimumBalance: 10000,
          ),
        );

        await transactionRepository.createTransaction(
          TransactionModel(
            id: incomeId,
            title: 'E2E invariant income',
            amount: 100000,
            type: TransactionType.income,
            category: TransactionCategory.salary,
            date: DateTime.now(),
            walletId: walletId,
          ),
        );
        expect((await walletRepository.getWallet(walletId)).balance, 100000);

        final expense = await transactionRepository.createTransaction(
          TransactionModel(
            id: expenseId,
            title: 'E2E invariant expense',
            amount: 85000,
            type: TransactionType.expense,
            category: TransactionCategory.other,
            date: DateTime.now(),
            walletId: walletId,
          ),
        );
        expect(expense.id, expenseId);
        expect((await walletRepository.getWallet(walletId)).balance, 15000);

        final updated = await transactionRepository.updateTransaction(
          expense.copyWith(amount: 90000),
        );
        expect(updated.amount, 90000);
        expect((await walletRepository.getWallet(walletId)).balance, 10000);

        await expectLater(
          transactionRepository.updateTransaction(expense.copyWith(amount: 90001)),
          throwsA(isA<PostgrestException>()),
        );
        expect((await walletRepository.getWallet(walletId)).balance, 10000);

        await transactionRepository.deleteTransaction(expenseId);
        expect((await walletRepository.getWallet(walletId)).balance, 100000);

        // Reversing the opening income would take the wallet below its configured
        // minimum. Lower the minimum only for deterministic test teardown; the
        // invariant itself was already exercised above.
        await client
            .from('wallets')
            .update({'minimum_balance': 0})
            .eq('id', walletId)
            .eq('user_id', user.id);

        await transactionRepository.deleteTransaction(incomeId);
        expect((await walletRepository.getWallet(walletId)).balance, 0);
      } finally {
        for (final id in [expenseId, incomeId]) {
          try {
            await transactionRepository.deleteTransaction(id);
          } catch (_) {}
        }
        try {
          await walletRepository.deleteWallet(walletId);
        } catch (_) {}
        await client.auth.signOut();
      }
    },
    skip: configured ? false : 'Set Supabase URL/key plus NEXORA_E2E_EMAIL and NEXORA_E2E_PASSWORD to run the live financial invariant E2E test.',
  );
}
