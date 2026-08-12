import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

import 'package:frontend/core/supabase/supabase_config.dart';

String _uuid() {
  final random = Random();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}';
}

void main() {
  const email = String.fromEnvironment('NEXORA_E2E_EMAIL');
  const password = String.fromEnvironment('NEXORA_E2E_PASSWORD');
  final configured = SupabaseConfig.isConfigured && email.isNotEmpty && password.isNotEmpty;

  test(
    'Supabase financial security boundaries reject client balance and ownership writes',
    () async {
      final client = SupabaseClient(
        SupabaseConfig.url,
        SupabaseConfig.publishableKey,
      );
      await client.auth.signInWithPassword(email: email, password: password);

      final user = client.auth.currentUser;
      expect(user, isNotNull);

      final walletId = _uuid();
      final forgedWalletId = _uuid();
      final forgedBalanceWalletId = _uuid();

      try {
        // A client may create a wallet, but balance is derived and must not be
        // writable through the authenticated table API.
        final created = await client
            .from('wallets')
            .insert({
              'id': walletId,
              'user_id': user!.id,
              'name': 'E2E Security Wallet',
              'type': 'cash',
              'bank_name': '',
              'account_number': '',
              'minimum_balance': 0,
              'currency_code': 'IDR',
              'color': '#2563EB',
              'is_primary': false,
              'is_hidden': false,
            })
            .select('id, balance, user_id')
            .single();

        expect(created['id'], walletId);
        expect(created['user_id'], user.id);
        expect(created['balance'], 0);

        // A client must not be able to create a wallet with an arbitrary
        // starting balance, even if table privileges are accidentally broadened.
        await expectLater(
          client.from('wallets').insert({
            'id': forgedBalanceWalletId,
            'user_id': user.id,
            'name': 'E2E Forged Balance',
            'type': 'cash',
            'bank_name': '',
            'account_number': '',
            'balance': 999999,
            'minimum_balance': 0,
            'currency_code': 'IDR',
            'color': '#DC2626',
            'is_primary': false,
            'is_hidden': false,
          }),
          throwsA(isA<PostgrestException>()),
        );

        // Direct balance mutation must be rejected by column privileges.
        await expectLater(
          client.from('wallets').update({'balance': 999999}).eq('id', walletId),
          throwsA(isA<PostgrestException>()),
        );

        final unchanged = await client
            .from('wallets')
            .select('balance')
            .eq('id', walletId)
            .single();
        expect(unchanged['balance'], 0);

        // A forged ownership value must be rejected by the RLS INSERT policy.
        await expectLater(
          client.from('wallets').insert({
            'id': forgedWalletId,
            'user_id': _uuid(),
            'name': 'E2E Forged Ownership',
            'type': 'cash',
            'bank_name': '',
            'account_number': '',
            'minimum_balance': 0,
            'currency_code': 'IDR',
            'color': '#DC2626',
            'is_primary': false,
            'is_hidden': false,
          }),
          throwsA(isA<PostgrestException>()),
        );

        // The authenticated user must never be able to change wallet ownership.
        await expectLater(
          client
              .from('wallets')
              .update({'user_id': _uuid()})
              .eq('id', walletId),
          throwsA(isA<PostgrestException>()),
        );

        final ownership = await client
            .from('wallets')
            .select('user_id')
            .eq('id', walletId)
            .single();
        expect(ownership['user_id'], user.id);
      } finally {
        for (final id in [walletId, forgedBalanceWalletId]) {
          try {
            await client.from('wallets').delete().eq('id', id);
          } catch (_) {
            // Best-effort cleanup; preserve the original test failure.
          }
        }
        await client.auth.signOut();
      }
    },
    skip: configured
        ? false
        : 'Set Supabase URL/key plus NEXORA_E2E_EMAIL and NEXORA_E2E_PASSWORD to run the live security E2E test.',
  );
}
