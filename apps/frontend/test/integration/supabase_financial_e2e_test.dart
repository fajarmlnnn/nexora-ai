import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:frontend/core/supabase/supabase_config.dart';
import 'package:frontend/features/dashboard/models/transaction_model.dart';
import 'package:frontend/features/finance/repositories/supabase_transaction_repository.dart';
import 'package:frontend/features/wallet/models/wallet_model.dart';
import 'package:frontend/features/wallet/repositories/supabase_wallet_repository.dart';

String _uuid() {
  final random = Random();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const email = String.fromEnvironment('NEXORA_E2E_EMAIL');
  const password = String.fromEnvironment('NEXORA_E2E_PASSWORD');
  final configured = SupabaseConfig.isConfigured && email.isNotEmpty && password.isNotEmpty;

  test(
    'Supabase financial flow preserves balances and ownership',
    () async {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
      );

      final client = Supabase.instance.client;
      await client.auth.signInWithPassword(email: email, password: password);

      final user = client.auth.currentUser;
      expect(user, isNotNull);

      final walletRepository = SupabaseWalletRepository(client: client);
      final transactionRepository = SupabaseTransactionRepository(client: client);
      final walletAId = _uuid();
      final walletBId = _uuid();
      final transactionIds = <String>[];

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
      } finally {
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
