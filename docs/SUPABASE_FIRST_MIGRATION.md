# Supabase-first migration

## Invariants

- Supabase Auth is the canonical user identity.
- PostgreSQL/RLS is the source of truth for user financial data.
- Financial ledger mutations must use ownership-aware trusted RPCs.
- The client must not be trusted to provide authoritative financial aggregates to AI.
- No production dummy, seed, fixture, or synthetic financial data may be introduced.
- Laravel/Sanctum is legacy until every production consumer is migrated and verified.

## Migration order

1. Harden database privileges and RPC execution.
2. Keep RLS enabled on every user-owned financial table.
3. Route transaction and goal mutations through trusted RPCs.
4. Derive AI financial context from authoritative database records on the server.
5. Inventory Laravel consumers and migrate them one capability at a time.
6. Remove Sanctum only after all consumers are verified against Supabase Auth.
7. Remove unused Laravel code and deployment only after a clean production verification.

## Data safety rule

Security tests must use permission checks, transaction rollbacks, isolated test projects, or non-production fixtures. Never insert synthetic financial rows into the production Supabase project.

## Release gate

Before removing Laravel, verify:

- authentication and session refresh use Supabase Auth;
- wallet/transaction/goal writes use Supabase RPCs;
- AI context is server-derived;
- no Flutter code calls legacy Laravel financial endpoints;
- no production secrets are stored in client code;
- RLS and grants remain least-privilege;
- migration history is committed and reproducible.
