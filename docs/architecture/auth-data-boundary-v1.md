# Nexora Auth & Data Boundary v2

## Decision

Supabase Auth is the single identity provider for the Flutter application. Supabase PostgreSQL is the single source of truth for user financial data.

Laravel is **not** a second application backend for financial state. It is retained only for server-side capabilities that genuinely require a trusted runtime, such as AI orchestration and external integrations. Laravel Sanctum is legacy foundation code and is not part of the Flutter authentication path.

## Current production path

```text
Flutter
  |
  +--> Supabase Auth -----------------------------+
  |                                               |
  +--> Supabase repositories ---------------------+--> Supabase PostgreSQL
                                                  |
                                                  +--> RLS
                                                  +--> Financial RPCs
                                                  +--> Atomic balance triggers

Flutter
  |
  +--> AI service / trusted backend boundary
```

## Laravel boundary

Laravel may remain for AI orchestration, privileged provider integrations, webhooks, reporting jobs, or other capabilities that must not run in the mobile client.

Any user-scoped Laravel request must be bound to the authenticated Supabase user UUID. Laravel must never issue or become a second user identity, and it must not maintain a duplicate wallet/transaction/goal/budget source of truth.

Laravel Sanctum endpoints are legacy/foundation code and must not be used as the Flutter login/session mechanism.

## Financial mutation boundary

The financial ledger is now **read-only through the authenticated Data API**.

- `transactions` SELECT remains available to `authenticated` and is protected by RLS ownership.
- `transactions` INSERT/UPDATE/DELETE are revoked from `authenticated`.
- Transaction mutations use `nexora_create_transaction`, `nexora_update_transaction`, and `nexora_delete_transaction`.
- These functions bind ownership to `auth.uid()`, use a controlled `search_path`, and rely on the existing balance trigger for atomic wallet synchronization.
- RPC execution is restricted to `authenticated`; implicit `PUBLIC`/`anon` execution is revoked.
- Idempotency keys remain part of transaction creation.

This keeps the mobile client from manufacturing a ledger row through arbitrary table DML while preserving the existing UI/repository contract.

## Financial invariants

1. Every user-owned row is scoped to the authenticated Supabase user UUID.
2. Client code cannot directly write derived wallet balances.
3. Transaction writes are server-controlled RPC mutations.
4. Multi-row financial mutations use transactional PostgreSQL functions/RPCs where atomicity matters.
5. Idempotency keys are used for retryable transaction mutations.
6. Wallet deletion is blocked while financial history references the wallet.
7. Goal contributions are read-only to the authenticated table API; contribution creation/removal uses atomic server-side RPCs.
8. RLS remains enabled even when server-side functions are used.
9. Anonymous clients have no direct table privileges on Nexora's user-owned financial tables.

## Security boundary

`goal_contributions` is intentionally readable by the authenticated owner but does not grant client `INSERT`, `UPDATE`, or `DELETE`. This prevents a client from manufacturing an accounting record that is not paired with the corresponding wallet transaction.

The goal contribution RPCs remain callable by authenticated users because they are the intended application mutation boundary. They validate `auth.uid()`, ownership, amount, wallet state, minimum balance, and idempotency before changing financial state.

## Migration status

The financial transaction mutation boundary has been migrated to Supabase RPCs. The remaining Laravel/Sanctum foundation is retained until every production consumer is proven to be migrated and the full E2E gate passes.

Do not delete the Laravel auth/database foundation solely because the target architecture is documented. Removal is a separate, evidence-based step after consumer inventory, E2E coverage, deployment validation, and rollback planning.
