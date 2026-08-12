# Supabase + Flutter setup

Nexora uses Supabase as the target production backend while Laravel remains the transition/reference backend until end-to-end parity is verified.

## Configuration

Never commit Supabase credentials to source control.

Run the app with:

```bash
flutter run \
  --dart-define=NEXORA_SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
  --dart-define=NEXORA_SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY
```

For CI/release builds, inject the same values through the build system's secret/configuration mechanism.

## Current client boundary

- `lib/core/supabase/supabase_config.dart` — compile-time configuration.
- `lib/core/supabase/supabase_client.dart` — single Supabase bootstrap/client boundary.
- `lib/core/supabase/supabase_auth_repository.dart` — Auth adapter.
- `lib/features/wallet/repositories/supabase_wallet_repository.dart` — Wallet adapter.

The existing Laravel/Dio client is intentionally retained during migration. Do not delete it until Supabase Auth, Wallet, Transaction, and end-to-end financial consistency tests have reached parity.

## Security rules

- Only the publishable/anon key belongs in the Flutter app. Never ship a service-role key.
- RLS is the database authorization boundary.
- Flutter must not write wallet `balance` directly during profile edits.
- Financial balance changes must happen through transaction operations/database logic.
- Never trust a client-provided `user_id`; Supabase RLS must enforce ownership with `auth.uid()`.

## Local verification

```bash
flutter pub get
flutter analyze
flutter test
```

If Supabase is not configured, the app keeps the legacy startup path during migration. Once the migration is complete, startup should require valid Supabase configuration.