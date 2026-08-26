-- Recovered from the live Supabase migration history.
-- The live project already contains these schema objects; keep every statement
-- idempotent so a fresh environment converges to the same security boundary.

alter table public.wallets
  add column if not exists opening_balance numeric(19,2) not null default 0;

alter table public.goal_contributions
  add column if not exists idempotency_key text;

alter table public.budgets
  add column if not exists category text not null default 'other';

create unique index if not exists goal_contributions_user_idempotency_key_uidx
  on public.goal_contributions(user_id, idempotency_key)
  where idempotency_key is not null;

create unique index if not exists transactions_user_idempotency_key_uidx
  on public.transactions(user_id, idempotency_key)
  where idempotency_key is not null;

-- Prevent future public/anonymous access from appearing merely because a new
-- table or function is created in public by the migration owner.
alter default privileges for role postgres in schema public
  revoke all on tables from public, anon, authenticated;
alter default privileges for role postgres in schema public
  revoke all on sequences from public, anon, authenticated;
alter default privileges for role postgres in schema public
  revoke execute on functions from public, anon, authenticated;

-- Financial ledger remains read-only through the Data API. Mutations use the
-- authenticated, ownership-checked RPC boundaries.
revoke insert, update, delete on public.transactions from anon, authenticated;
grant select on public.transactions to authenticated;

revoke all on public.profiles from anon;
revoke all on public.wallets from anon;
revoke all on public.transactions from anon;
revoke all on public.goals from anon;
revoke all on public.goal_contributions from anon;
revoke all on public.budgets from anon;

revoke insert, update, delete on public.goal_contributions from authenticated;
grant select on public.goal_contributions to authenticated;

-- Column-level revokes do not override an existing table-level grant. Revoke
-- table-level mutation first, then explicitly grant only the columns the client
-- is allowed to control.
revoke update on public.profiles from authenticated;
grant update (display_name, currency_code, timezone) on public.profiles to authenticated;

revoke insert, update, delete on public.wallets from authenticated;
grant insert (id, user_id, name, type, bank_name, account_number, minimum_balance, currency_code, color, is_primary, is_hidden, opening_balance) on public.wallets to authenticated;
grant update (name, type, bank_name, account_number, minimum_balance, currency_code, color, is_primary, is_hidden) on public.wallets to authenticated;
grant delete on public.wallets to authenticated;

revoke update on public.budgets from authenticated;
grant update (id, name, budget_limit, color, category) on public.budgets to authenticated;

revoke update on public.goals from authenticated;
grant update (name, type, target_amount, deadline, priority, status, category, note) on public.goals to authenticated;

-- Keep only one idempotency index per logical key when the older duplicate
-- indexes are present in an upgraded database.
drop index if exists public.goal_contributions_user_idempotency_idx;
drop index if exists public.transactions_user_idempotency_idx;

-- Re-grant only the RPCs intentionally exposed to signed-in users.
grant execute on function public.nexora_contribute_to_goal_from_wallet(uuid, uuid, numeric, text, text) to authenticated;
grant execute on function public.nexora_create_transaction(text, numeric, text, text, timestamptz, text, jsonb, uuid, uuid, uuid, uuid) to authenticated;
grant execute on function public.nexora_delete_goal(uuid) to authenticated;
grant execute on function public.nexora_delete_transaction(uuid) to authenticated;
grant execute on function public.nexora_get_ai_financial_context(date, date, text) to authenticated;
grant execute on function public.nexora_reconcile_wallet(uuid) to authenticated;
grant execute on function public.nexora_update_goal_target(uuid, numeric) to authenticated;
grant execute on function public.nexora_update_transaction(uuid, text, numeric, text, text, timestamptz, jsonb, uuid, uuid, uuid) to authenticated;
