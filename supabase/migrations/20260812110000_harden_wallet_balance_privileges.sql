-- Wallet balances are derived from transactions. The authenticated client must
-- never be able to set or mutate balance directly. The transaction trigger is
-- SECURITY DEFINER and can still maintain balances safely.

-- Remove broad table privileges first; column-level REVOKE cannot override a
-- table-level GRANT in PostgreSQL.
revoke insert, update on public.wallets from authenticated;

-- Wallet creation fields. `balance` is intentionally omitted so a client
-- cannot create a wallet with an arbitrary balance.
grant insert (
  user_id,
  name,
  type,
  bank_name,
  account_number,
  minimum_balance,
  currency_code,
  color,
  is_primary,
  is_hidden
) on public.wallets to authenticated;

-- Wallet profile/settings fields. `balance`, ownership, timestamps and the
-- primary key are intentionally not client-writable.
grant update (
  name,
  type,
  bank_name,
  account_number,
  minimum_balance,
  currency_code,
  color,
  is_primary,
  is_hidden
) on public.wallets to authenticated;

-- Keep the existing RLS policies as the row-level ownership boundary.
-- Balance changes continue to happen only through the transaction trigger.
