# Backend migration checklist

This checklist is the gate for removing the legacy Laravel financial/auth foundation.

## Identity

- [x] Supabase `auth.users.id` is the application identity used by the Flutter production path.
- [ ] Every Laravel user-scoped request resolves to the Supabase user UUID.
- [x] No Flutter production path issues or stores a Laravel Sanctum token.
- [ ] Supabase login/logout/session lifecycle has full E2E coverage.

## Data

- [x] Supabase PostgreSQL is the source of truth for wallets, transactions, goals, budgets, and related financial state.
- [ ] Every Laravel financial read/write has either been removed or migrated to Supabase PostgreSQL/RPC.
- [ ] Laravel SQLite financial tables are proven unused by production consumers.
- [x] UUID identity is preserved end-to-end for Supabase financial state.

## Financial safety

- [x] Multi-row mutations use atomic PostgreSQL transactions/RPCs where required.
- [x] Derived wallet balances cannot be directly manufactured by the client.
- [x] RLS policies protect the exposed user-owned financial tables.
- [x] Privileged financial RPCs validate `auth.uid()` and use a controlled `search_path`.
- [x] Retryable transaction mutations have idempotency protection.
- [ ] Reversal, deletion, transfer, goal funding, and minimum-balance invariants have complete E2E coverage.

## CI / release gate

- [ ] Android CI is green on the migration branch.
- [ ] Laravel CI is green while the legacy service boundary remains.
- [ ] Supabase E2E/security tests are green against the target project after the RPC migration.
- [x] No production code imports the legacy Flutter Laravel auth/network layer.
- [ ] No undocumented second source of truth remains.
- [x] Composer dependency audit is a CI gate.
- [x] CodeQL PHP analysis is configured for the backend.
- [x] Filesystem vulnerability/secret/misconfiguration scanning is configured for HIGH/CRITICAL findings.

## Current migration step completed

- Transaction INSERT/UPDATE/DELETE through the Supabase Data API have been removed from the authenticated client privilege surface.
- Transaction mutations now use `nexora_create_transaction`, `nexora_update_transaction`, and `nexora_delete_transaction`.
- Anonymous clients have no direct privileges on Nexora's public user-owned financial tables.
- SECURITY DEFINER transaction RPCs explicitly revoke implicit PUBLIC/anon execution and grant only `authenticated`.
- AI financial context is derived server-side from Supabase using the authenticated user's identity instead of accepting client-provided financial aggregates.

## Removal gate

Only after all checks above pass should Laravel Sanctum, Laravel `users`, and duplicate Laravel financial tables be removed or reduced to explicitly required server-side service data.
