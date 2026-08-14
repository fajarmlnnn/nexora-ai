# Supabase + Flutter setup

Nexora uses Supabase Auth and Supabase PostgreSQL as the current production source of truth for the Flutter application. Laravel remains a transition/reference backend until any server-side capabilities are migrated and verified against the Supabase identity/data boundary.

## Configuration

Never commit Supabase credentials to source control.

Run the app with:

```bash
flutter run \
  --dart-define=NEXORA_SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
  --dart-define=NEXORA_SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

The Flutter configuration intentionally uses the publishable key variable name. Do not use a service-role key in the app.

For CI/release builds, inject the same values through the build system's secret/configuration mechanism.

## Current client boundary

- `lib/core/supabase/supabase_config.dart` — compile-time configuration.
- `lib/core/supabase/supabase_client.dart` — single Supabase bootstrap/client boundary.
- `lib/core/supabase/supabase_auth_repository.dart` — Supabase Auth adapter.
- `lib/features/wallet/repositories/supabase_wallet_repository.dart` — Wallet adapter.
- Transaction, goal, budget, and other user-owned financial repositories should use the same Supabase boundary unless a documented server-side orchestration path is required.

The unused Flutter Laravel/Dio authentication client has been removed. Laravel Sanctum remains only as legacy/backend foundation until all backend consumers are migrated and separately verified.

## Security rules

- Only the publishable/anon key belongs in the Flutter app. Never ship a service-role key.
- RLS is the database authorization boundary.
- Flutter must not write wallet `balance` directly during profile edits.
- Financial balance changes must happen through transaction operations/database logic.
- Multi-row financial mutations must use atomic PostgreSQL functions/RPCs where required.
- Never trust a client-provided `user_id`; Supabase RLS must enforce ownership with `auth.uid()`.

## Local verification

```bash
flutter pub get
flutter analyze
flutter test
```

Supabase configuration is required for the authenticated production path. Test-only/local UI flows may use mocks where explicitly documented.