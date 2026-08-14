# Nexora Auth & Data Boundary v1

## Decision

Supabase Auth is the single identity provider for the Flutter application. Supabase PostgreSQL is the single source of truth for user financial data.

Laravel is an API/service boundary only. It must not create a second application identity or maintain a second financial database for the same user.

## Current production path

```text
Flutter
  |
  +--> Supabase Auth --------------------+
  |                                      |
  +--> Supabase repositories ------------+--> Supabase PostgreSQL
                                         |
                                         +--> RLS / financial RPCs
```

## Laravel boundary

Laravel may be used for server-side capabilities that should not run in the mobile client (AI orchestration, privileged integrations, webhooks, reporting jobs, etc.). Any request that is user-scoped must be bound to the authenticated Supabase user UUID.

Laravel Sanctum endpoints are legacy/foundation code and must not be treated as a second login system for the Flutter application. Do not introduce a Laravel `users` identity that can diverge from `auth.users`.

## Financial invariants

1. Every user-owned row is scoped to the authenticated Supabase user UUID.
2. Client code must not be able to manufacture financial balances by directly writing derived balance fields.
3. Multi-row financial mutations use transactional PostgreSQL functions/RPCs where atomicity matters.
4. Idempotency keys are used for retryable transaction mutations.
5. Wallet deletion is blocked while financial history references the wallet.
6. Goal contributions are read-only to the authenticated table API; contribution creation and removal must use atomic server-side RPCs so the goal and wallet ledger cannot diverge.
7. RLS remains enabled even when server-side functions are used.

## Security boundary

`goal_contributions` is intentionally readable by the authenticated owner but does not grant client `INSERT`, `UPDATE`, or `DELETE`. This prevents a client from manufacturing an accounting record that is not paired with the corresponding wallet transaction.

The goal contribution RPCs remain callable by authenticated users because they are the intended application mutation boundary. They validate `auth.uid()`, ownership, amount, wallet state, minimum balance, and idempotency before changing financial state.

## Migration rule

Do not delete the Laravel auth/database foundation until all consumers are migrated and E2E coverage proves that the replacement path is equivalent. This document therefore defines the target architecture without performing a destructive migration.
