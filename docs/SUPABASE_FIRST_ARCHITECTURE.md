# Supabase-first architecture

## Canonical boundaries

- Supabase Auth is the canonical user identity.
- Supabase PostgreSQL is the source of truth for financial state.
- RLS is mandatory for user-owned data.
- Financial mutations use ownership-aware trusted RPCs rather than direct client DML.
- AI services must derive authoritative financial context from server-side data; client-provided aggregates are untrusted hints only.
- Laravel/Sanctum is legacy and must not become a second identity or financial source of truth.

## Migration safety

Do not remove Laravel until every production consumer has been identified and migrated. Prefer feature-by-feature cutover, read-only verification, then removal.

## Production data policy

Never create dummy users, wallets, transactions, goals, budgets, contributions, or synthetic financial history in the production Supabase project. End-to-end mutation tests must use an isolated test project or a transaction that is guaranteed to roll back.

## Verification checklist

1. Inspect schema, RLS, grants, functions, triggers, and migrations.
2. Verify client code calls the intended RPCs.
3. Verify RPCs derive ownership from `auth.uid()`.
4. Verify financial balance changes remain trigger/RPC controlled.
5. Verify AI financial context is authoritative and server-derived.
6. Run static/security/dependency checks in CI.
7. Only then remove legacy Laravel paths.
