-- Recovered from the live Supabase migration history.
-- This migration intentionally contains only idempotent cleanup/privilege hardening.
-- Keep Data API exposure opt-in; application RPCs are granted explicitly below.

revoke all on public.profiles from anon;
revoke all on public.wallets from anon;
revoke all on public.transactions from anon;
revoke all on public.goals from anon;
revoke all on public.goal_contributions from anon;
revoke all on public.budgets from anon;

revoke all on function public.set_updated_at() from public, anon, authenticated;
revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.apply_transaction_to_wallets() from public, anon, authenticated;
revoke all on function public.enforce_goal_write_boundaries() from public, anon, authenticated;
revoke all on function public.enforce_goal_transaction_linkage() from public, anon, authenticated;
revoke all on function public.prevent_direct_wallet_balance_insert() from public, anon, authenticated;
revoke all on function public.set_goals_updated_at() from public, anon, authenticated;
revoke all on function public.set_budgets_updated_at() from public, anon, authenticated;

-- SECURITY DEFINER financial boundaries remain intentionally callable by
-- authenticated clients; their ownership and input checks are enforced inside
-- the functions themselves.
