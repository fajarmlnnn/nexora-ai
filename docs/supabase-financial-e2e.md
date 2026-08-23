# Supabase Financial E2E

Financial E2E coverage is intentionally **not stored as a runnable fixture in this repository**.

Nexora must not commit synthetic wallets, transactions, balances, goals, or other financial records. A live financial E2E run belongs in an isolated Supabase test environment provisioned outside the repository.

## Required isolated environment

Provide these values only at runtime through the test runner or CI secret store:

- `NEXORA_SUPABASE_URL`
- `NEXORA_SUPABASE_PUBLISHABLE_KEY`
- `NEXORA_E2E_EMAIL`
- `NEXORA_E2E_PASSWORD`

The account must belong to a dedicated non-production Supabase project. Never use a production account containing real financial data.

## Required verification scope

The external E2E harness must verify, against the real Supabase schema and policies:

1. authenticated current-user isolation;
2. wallet balance cannot be written directly by the client;
3. income, expense, and transfer balance invariants;
4. minimum-balance enforcement;
5. update/delete balance reversal correctness;
6. transfer atomicity and deterministic wallet locking;
7. idempotency under retry and concurrent requests;
8. RLS ownership boundaries;
9. goal contribution ledger linkage and rollback, when that ledger is enabled;
10. wallet/transaction reconciliation after every mutation.

Tests must create only ephemeral records in the isolated test project at runtime, use generated identifiers, and remove their records during teardown. No financial fixture, seed record, fake account, or hard-coded financial state belongs in Git.

Until that isolated runtime harness is provisioned and executed, financial runtime verification remains explicitly **unverified**. Do not replace the missing verification with mocks or placeholder data.
