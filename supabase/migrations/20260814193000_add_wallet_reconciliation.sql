begin;

-- Read-only financial integrity check. It never mutates balances.
-- opening_balance preserves the wallet state that existed before reconciliation
-- was introduced; the ledger then explains every subsequent balance change.
alter table public.wallets
  add column if not exists opening_balance numeric(19,2) not null default 0;

-- Idempotent backfill for existing wallets. This preserves the current stored
-- balance while deriving the historical opening position from the ledger.
update public.wallets w
set opening_balance = w.balance - coalesce((
  select sum(case
    when t.type = 'income' then t.amount
    when t.type = 'expense' then -t.amount
    when t.type = 'transfer' and t.destination_wallet_id = w.id then t.amount
    when t.type = 'transfer' and t.source_wallet_id = w.id then -t.amount
    else 0
  end)
  from public.transactions t
  where t.user_id = w.user_id
    and (t.wallet_id = w.id or t.source_wallet_id = w.id or t.destination_wallet_id = w.id)
), 0);

create or replace function public.nexora_reconcile_wallet(p_wallet_id uuid)
returns table (
  wallet_id uuid,
  stored_balance numeric,
  calculated_balance numeric,
  difference numeric,
  is_consistent boolean
)
language plpgsql
security invoker
set search_path = pg_catalog, public
as $$
declare
  v_user_id uuid;
  v_stored numeric;
  v_opening numeric;
  v_calculated numeric;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select w.balance, w.opening_balance
    into v_stored, v_opening
    from public.wallets w
   where w.id = p_wallet_id
     and w.user_id = v_user_id;

  if not found then
    raise exception 'Wallet not found';
  end if;

  select v_opening + coalesce(sum(case
    when t.type = 'income' and t.wallet_id = p_wallet_id then t.amount
    when t.type = 'expense' and t.wallet_id = p_wallet_id then -t.amount
    when t.type = 'transfer' and t.destination_wallet_id = p_wallet_id then t.amount
    when t.type = 'transfer' and t.source_wallet_id = p_wallet_id then -t.amount
    else 0
  end), 0)
    into v_calculated
    from public.transactions t
   where t.user_id = v_user_id
     and (t.wallet_id = p_wallet_id or t.source_wallet_id = p_wallet_id or t.destination_wallet_id = p_wallet_id);

  return query
  select p_wallet_id,
         v_stored,
         v_calculated,
         v_stored - v_calculated,
         abs(v_stored - v_calculated) < 0.000001;
end;
$$;

revoke all on function public.nexora_reconcile_wallet(uuid) from public, anon;
grant execute on function public.nexora_reconcile_wallet(uuid) to authenticated;

commit;
