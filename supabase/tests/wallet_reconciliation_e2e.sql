-- Wallet reconciliation contract test.
-- The production RPC is read-only: this script is intended for the authenticated
-- E2E harness, which supplies a real user/session and wallet id.

-- Required assertions for the harness:
-- 1. A newly created wallet reports stored_balance = calculated_balance.
-- 2. Income increases both ledger-derived and stored balance equally.
-- 3. Expense decreases both equally.
-- 4. Transfer decreases source and increases destination without changing
--    aggregate user wealth.
-- 5. Goal contribution and goal deletion/refund leave reconciliation clean.
-- 6. Reversal returns reconciliation to the previous state.
-- 7. A rejected minimum-balance transaction leaves reconciliation unchanged.
-- 8. The RPC cannot be used against another user's wallet.
-- 9. The RPC performs no INSERT/UPDATE/DELETE.

-- This file is intentionally declarative until the existing Flutter live-E2E
-- harness is extended with authenticated RPC calls. It documents the invariant
-- without introducing destructive test data into production.
