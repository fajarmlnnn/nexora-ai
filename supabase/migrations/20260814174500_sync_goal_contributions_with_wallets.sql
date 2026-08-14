alter table public.goal_contributions
  add column if not exists idempotency_key text;

create unique index if not exists goal_contributions_user_idempotency_idx
  on public.goal_contributions(user_id, idempotency_key)
  where idempotency_key is not null;

-- The previous RPC only changed goal_contributions/goals. Disable it so an
-- outdated client cannot create money in a goal without debiting a wallet.
revoke all on function public.nexora_contribute_to_goal(uuid,numeric,text)
  from public, anon, authenticated;

create or replace function public.nexora_contribute_to_goal_from_wallet(
  p_goal_id uuid,
  p_wallet_id uuid,
  p_amount numeric,
  p_note text default null,
  p_idempotency_key text default null
)
returns public.goals
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_goal public.goals;
  v_wallet public.wallets;
  v_existing public.goal_contributions;
  v_contribution public.goal_contributions;
  v_new_saved numeric(19,2);
  v_status text;
  v_key text := nullif(trim(p_idempotency_key), '');
  v_transaction_key text;
begin
  if v_user is null then
    raise exception 'Not authenticated';
  end if;
  if p_amount is null or p_amount <= 0 then
    raise exception 'Contribution amount must be greater than zero';
  end if;
  if p_wallet_id is null then
    raise exception 'Funding wallet is required';
  end if;
  if v_key is not null and char_length(v_key) > 255 then
    raise exception 'Idempotency key is too long';
  end if;

  -- Idempotent retries return the already-committed goal without debiting the
  -- wallet or inserting another contribution/transaction.
  if v_key is not null then
    select * into v_existing
    from public.goal_contributions
    where user_id = v_user and idempotency_key = v_key
    limit 1;
    if found then
      select * into v_goal
      from public.goals
      where id = v_existing.goal_id and user_id = v_user;
      if not found then
        raise exception 'Goal not found';
      end if;
      return v_goal;
    end if;
  end if;

  -- Lock the goal first, then the wallet. The transaction trigger also locks
  -- the wallet, so the order prevents concurrent contribution races.
  select * into v_goal
  from public.goals
  where id = p_goal_id and user_id = v_user
  for update;
  if not found then
    raise exception 'Goal not found';
  end if;
  if v_goal.status = 'paused' then
    raise exception 'Goal is paused';
  end if;

  select * into v_wallet
  from public.wallets
  where id = p_wallet_id and user_id = v_user
  for update;
  if not found then
    raise exception 'Funding wallet not found';
  end if;
  if v_wallet.balance - p_amount < v_wallet.minimum_balance then
    raise exception 'Wallet balance cannot fall below minimum balance';
  end if;

  v_new_saved := v_goal.saved_amount + p_amount;
  v_status := case
    when v_new_saved >= v_goal.target_amount then 'completed'
    else 'active'
  end;

  perform set_config('nexora.goal_write_context', 'rpc', true);

  insert into public.goal_contributions(
    goal_id,
    user_id,
    amount,
    note,
    idempotency_key
  )
  values (
    v_goal.id,
    v_user,
    p_amount,
    nullif(trim(p_note), ''),
    v_key
  )
  returning * into v_contribution;

  v_transaction_key := case
    when v_key is null then null
    else 'goal-contribution:' || v_key
  end;

  -- This is intentionally a normal expense transaction. The existing
  -- transactions_balance_trigger is the single source of truth for wallet
  -- balance changes, so goal funding cannot silently change the wallet by
  -- bypassing the financial transaction ledger.
  insert into public.transactions(
    user_id,
    wallet_id,
    type,
    amount,
    category,
    description,
    occurred_at,
    idempotency_key,
    metadata
  )
  values (
    v_user,
    v_wallet.id,
    'expense',
    p_amount,
    'other',
    'Setoran goal: ' || v_goal.name,
    now(),
    v_transaction_key,
    jsonb_build_object(
      'goal_id', v_goal.id,
      'goal_contribution_id', v_contribution.id,
      'kind', 'goal_contribution'
    )
  );

  update public.goals
  set saved_amount = v_new_saved,
      status = v_status,
      updated_at = now()
  where id = v_goal.id and user_id = v_user
  returning * into v_goal;

  return v_goal;
end;
$$;

revoke all on function public.nexora_contribute_to_goal_from_wallet(uuid,uuid,numeric,text,text)
  from public, anon;
grant execute on function public.nexora_contribute_to_goal_from_wallet(uuid,uuid,numeric,text,text)
  to authenticated;

-- Reconcile existing goal contributions that were created by the old RPC.
-- Only contributions without a corresponding goal-contribution transaction
-- are migrated, so rerunning this migration is safe.
do $$
declare
  r record;
  v_wallet uuid;
  v_tx_key text;
begin
  for r in
    select
      gc.id as contribution_id,
      gc.goal_id,
      gc.user_id,
      gc.amount,
      gc.contributed_at,
      g.name as goal_name
    from public.goal_contributions gc
    join public.goals g on g.id = gc.goal_id
    where not exists (
      select 1
      from public.transactions t
      where t.user_id = gc.user_id
        and t.metadata ->> 'goal_contribution_id' = gc.id::text
    )
    order by gc.created_at asc
  loop
    select w.id into v_wallet
    from public.wallets w
    where w.user_id = r.user_id
    order by w.is_primary desc, w.created_at asc
    limit 1;

    if v_wallet is null then
      raise exception 'Cannot reconcile goal contribution %: user has no wallet', r.contribution_id;
    end if;

    v_tx_key := 'goal-reconcile:' || r.contribution_id::text;

    insert into public.transactions(
      user_id,
      wallet_id,
      type,
      amount,
      category,
      description,
      occurred_at,
      idempotency_key,
      metadata
    )
    values (
      r.user_id,
      v_wallet,
      'expense',
      r.amount,
      'other',
      'Setoran goal: ' || r.goal_name,
      r.contributed_at,
      v_tx_key,
      jsonb_build_object(
        'goal_id', r.goal_id,
        'goal_contribution_id', r.contribution_id,
        'kind', 'goal_contribution_reconciliation'
      )
    );
  end loop;
end $$;
