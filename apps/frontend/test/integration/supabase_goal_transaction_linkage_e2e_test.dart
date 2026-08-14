import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

import 'package:frontend/core/supabase/supabase_config.dart';

String _uuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
}

void main() {
  const email = String.fromEnvironment('NEXORA_E2E_EMAIL');
  const password = String.fromEnvironment('NEXORA_E2E_PASSWORD');
  final configured = SupabaseConfig.isConfigured && email.isNotEmpty && password.isNotEmpty;

  test(
    'Goal refund deletion can only target server-linked contribution transactions',
    () async {
      final client = SupabaseClient(
        SupabaseConfig.url,
        SupabaseConfig.publishableKey,
      );
      await client.auth.signInWithPassword(email: email, password: password);

      final user = client.auth.currentUser;
      expect(user, isNotNull);

      final walletId = _uuid();
      final goalId = _uuid();
      final fakeTransactionId = _uuid();
      final fakeContributionId = _uuid();

      try {
        final wallet = await client
            .from('wallets')
            .insert({
              'id': walletId,
              'user_id': user!.id,
              'name': 'E2E Goal Link Wallet',
              'type': 'cash',
              'minimum_balance': 0,
              'currency_code': 'IDR',
              'color': '#2563EB',
              'is_primary': false,
              'is_hidden': false,
            })
            .select('id')
            .single();
        expect(wallet['id'], walletId);

        final goal = await client
            .from('goals')
            .insert({
              'id': goalId,
              'user_id': user.id,
              'name': 'E2E Goal Link Goal',
              'type': 'saving',
              'target_amount': 10000,
              'saved_amount': 0,
              'status': 'active',
            })
            .select('id')
            .single();
        expect(goal['id'], goalId);

        // A client-created transaction may contain arbitrary metadata, but it
        // cannot manufacture the server-owned contribution linkage used by the
        // goal deletion/refund path.
        await expectLater(
          client.from('transactions').insert({
            'id': fakeTransactionId,
            'user_id': user.id,
            'wallet_id': walletId,
            'type': 'expense',
            'amount': 1000,
            'category': 'other',
            'description': 'E2E forged goal transaction',
            'occurred_at': DateTime.now().toUtc().toIso8601String(),
            'metadata': {
              'goal_id': goalId,
              'goal_contribution_id': fakeContributionId,
              'kind': 'goal_contribution',
            },
            'goal_contribution_id': fakeContributionId,
          }),
          throwsA(isA<PostgrestException>()),
        );

        // The old client-writable contribution path must stay closed.
        await expectLater(
          client.from('goal_contributions').insert({
            'id': fakeContributionId,
            'goal_id': goalId,
            'user_id': user.id,
            'amount': 1000,
            'idempotency_key': 'forged-$fakeContributionId',
          }),
          throwsA(isA<PostgrestException>()),
        );

        await expectLater(
          client.from('goal_contributions').delete().eq('goal_id', goalId),
          throwsA(isA<PostgrestException>()),
        );
      } finally {
        try {
          await client.rpc('nexora_delete_goal', params: {'p_goal_id': goalId});
        } catch (_) {
          // Best-effort cleanup; preserve the original test failure.
        }
        try {
          await client.from('transactions').delete().eq('id', fakeTransactionId);
        } catch (_) {}
        try {
          await client.from('wallets').delete().eq('id', walletId);
        } catch (_) {}
        await client.auth.signOut();
      }
    },
    skip: configured
        ? false
        : 'Set Supabase URL/key plus NEXORA_E2E_EMAIL and NEXORA_E2E_PASSWORD to run the live security E2E test.',
  );
}
