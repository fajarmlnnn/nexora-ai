-- Wallet balance is derived from transactions. Authenticated clients must
-- never be able to update it directly.
revoke update (balance) on table public.wallets from authenticated;
revoke update (balance) on table public.wallets from anon;
