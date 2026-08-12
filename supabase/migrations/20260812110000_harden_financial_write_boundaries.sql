-- Clients can read their own wallets, but balance is derived from transactions.
revoke insert (balance) on public.wallets from authenticated;
revoke update (balance) on public.wallets from authenticated;

-- Defense in depth: ownership is enforced by RLS; derived balances are changed only
-- by the SECURITY DEFINER transaction trigger.
revoke execute on function public.apply_transaction_to_wallets() from public, anon, authenticated;

-- Keep the function callable by the trigger owner while preventing direct RPC calls.
-- RLS policies continue to enforce per-user row ownership on profiles, wallets,
-- and transactions.
