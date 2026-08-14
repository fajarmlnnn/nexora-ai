begin;

-- Read-only financial integrity check. It never mutates balances.
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
  v_calculated numeric;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select w.balance
    into v_stored
    from public.wallets w
   where w.id = p_wallet_id
     and w.user_id = v_user_id;

  if not found then
    raise exception 'Wallet not found';
  end if;

  -- Wallet balance is maintained by the transaction ledger triggers/RPCs.
  -- Reconciliation derives the expected balance from the same financial
  -- transaction semantics and is intentionally read-only.
  select coalesce(sum(
    case
      when t.type in ('income', 'deposit') then t.amount
      when t.type in ('expense', 'withdrawal') then -t.amount
      else 0
    end
  ), 0)
    into v_calculated
    from public.transactions t
   where t.wallet_id = p_wallet_id
     and t.user_id = v_user_id;

  -- Transfers are represented by source/destination wallet references and
  -- must affect each wallet exactly once in the derived calculation.
  select v_calculated
       + coalesce(sum(case when t.source_account = p_wallet_id::text then -t.amount else 0 end), 0)
       + coalesce(sum(case when t.destination_account = p_wallet_id::text then t.amount else 0 end), 0)
    into v_calculated
    from public.transactions t
   where t.user_id = v_user_id
     and t.type = 'transfer';

  return query
  select p_wallet_id,
         v_stored,
         v_calculated,
         v_stored - v_calculated,
         abs(v_stored - v_calculated) < 0.000001;
end;
$$;

revoke all on function public.nexora_reconcile_wallet(uuid) from public;
grant execute on function public.nexora_reconcile_wallet(uuid) to authenticated;

commit;
