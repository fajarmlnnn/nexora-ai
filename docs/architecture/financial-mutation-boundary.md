# Financial mutation boundary

## Rule

A financial mutation is any operation that can change wallet balance, transaction history, goal funding, budget state, or another derived financial value.

These operations must have one authoritative persistence path.

## Current rule for Flutter

Flutter may read user-owned financial data from Supabase through repositories protected by RLS. It must not invent or directly overwrite derived balances.

Use PostgreSQL/RPC for operations that must change multiple rows atomically, including:

- transfer between wallets
- goal funding from a wallet
- goal deletion that reverses funding
- transaction reversal
- any future operation that changes several financial records as one logical action

## Laravel rule

Laravel is allowed to orchestrate server-side capabilities, but it must not maintain a second financial state for the same user. If Laravel performs a financial mutation, it must call the authoritative Supabase/PostgreSQL path and preserve the authenticated Supabase user UUID.

Until that integration exists, do not expose the legacy Laravel financial controllers as a second production mutation path.

## Review questions

Before adding a financial endpoint, answer:

1. Where is the single source of truth?
2. Which database transaction makes the mutation atomic?
3. How is the authenticated user bound to every row?
4. What happens if the request is retried?
5. What happens if the operation fails halfway through?
6. Which E2E invariant proves the resulting balances and history are correct?
