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
    'Supabase goal contribution writes are RPC-only',
    () async {
      final client = SupabaseClient(
        SupabaseConfig.url,
        SupabaseConfig.publishableKey,
      );
      await client.auth.signInWithPassword(email: email, password: password);

      final user = client.auth.currentUser;
      expect(user, isNotNull);

      final goalId = _uuid();
      final contributionId = _uuid();

      try {
        final goal = await client
            .from('goals')
            .insert({
              'id': goalId,
              'user_id': user!.id,
              'name': 'E2E Goal Write Boundary',
              'type': 'saving',
              'target_amount': 10000,
              'saved_amount': 0,
              'status': 'active',
            })
            .select('id, saved_amount, status')
            .single();

        expect(goal['id'], goalId);
        expect(goal['saved_amount'], 0);
        expect(goal['status'], 'active');

        // saved_amount is server-controlled and cannot be forged through the
        // ordinary authenticated table API.
        await expectLater(
          client.from('goals').update({'saved_amount': 5000}).eq('id', goalId),
          throwsA(isA<PostgrestException>()),
        );

        final unchanged = await client
            .from('goals')
            .select('saved_amount')
            .eq('id', goalId)
            .single();
        expect(unchanged['saved_amount'], 0);

        // Contributions are read-only to the client. Creating one directly
        // would bypass the wallet ledger and is therefore rejected.
        await expectLater(
          client.from('goal_contributions').insert({
            'id': contributionId,
            'goal_id': goalId,
            'user_id': user.id,
            'amount': 5000,
            'idempotency_key': 'direct-write-$contributionId',
          }),
          throwsA(isA<PostgrestException>()),
        );

        // Deleting a contribution directly would orphan its financial ledger
        // transaction, so the client must use the goal deletion/reconciliation
        // RPC instead.
        await expectLater(
          client
              .from('goal_contributions')
              .delete()
              .eq('goal_id', goalId),
          throwsA(isA<PostgrestException>()),
        );
      } finally {
        try {
          await client.rpc('nexora_delete_goal', params: {'p_goal_id': goalId});
        } catch (_) {
          // Best-effort cleanup; preserve the original test failure.
        }
        await client.auth.signOut();
      }
    },
    skip: configured
        ? false
        : 'Set Supabase URL/key plus NEXORA_E2E_EMAIL and NEXORA_E2E_PASSWORD to run the live security E2E test.',
  );
}
