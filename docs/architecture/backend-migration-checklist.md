# Backend migration checklist

This checklist is the gate for removing the legacy Laravel financial/auth foundation.

## Identity

- [ ] Supabase `auth.users.id` is the only application user identity.
- [ ] Every Laravel user-scoped request resolves to the Supabase user UUID.
- [ ] No Flutter production path issues or stores a Laravel Sanctum token.
- [ ] Supabase login/logout/session lifecycle has E2E coverage.

## Data

- [ ] Supabase PostgreSQL is the only source of truth for wallets, transactions, goals, budgets, and related financial state.
- [ ] Every Laravel financial read/write has either been removed or migrated to Supabase PostgreSQL/RPC.
- [ ] Laravel SQLite financial tables are no longer used by production consumers.
- [ ] UUID identity is preserved end-to-end.

## Financial safety

- [ ] Multi-row mutations use atomic PostgreSQL transactions/RPCs.
- [ ] Derived balances cannot be directly manufactured by the client.
- [ ] RLS policies cover SELECT/INSERT/UPDATE/DELETE for every user-owned table.
- [ ] Privileged RPCs validate `auth.uid()` and use a controlled `search_path`.
- [ ] Retryable mutations have idempotency protection.
- [ ] Reversal, deletion, transfer, goal funding, and minimum-balance invariants have E2E tests.

## CI / release gate

- [ ] Android CI is green.
- [ ] Laravel CI is green.
- [ ] Supabase E2E/security tests are green against the target project.
- [ ] No production code imports the legacy Flutter Laravel auth/network layer.
- [ ] No undocumented second source of truth remains.

## Removal gate

Only after all checks above pass should Laravel Sanctum, Laravel `users`, and duplicate Laravel financial tables be removed or reduced to explicitly required server-side service data.
