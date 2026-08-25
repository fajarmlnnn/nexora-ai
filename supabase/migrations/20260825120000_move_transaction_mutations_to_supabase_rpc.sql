-- Move the financial ledger mutation boundary from direct Data API DML to
-- authenticated, ownership-checked PostgreSQL RPCs. Reads remain available
-- through RLS; writes are server-controlled and still execute the existing
-- balance trigger atomically.

create or replace function public.nexora_create_transaction(
  p_type text,
  p_amount numeric,
  p_category text default 'other',
  p_description text default null,
  p_occurred_at timestamptz default now(),
  p_idempotency_key text default null,
  p_metadata jsonb default '{}'::jsonb,
  p_wallet_id uuid default null,
  p_source_wallet_id uuid default null,
  p_destination_wallet_id uuid default null,
  p_id uuid default null
)
returns setof public.transactions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_existing public.transactions;
  v_row public.transactions;
  v_id uuid := coalesce(p_id, gen_random_uuid());
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'Transaction amount must be greater than zero';
  end if;

  if p_idempotency_key is not null then
    select t.*
      into v_existing
      from public.transactions t
     where t.user_id = v_user_id
       and t.idempotency_key = p_idempotency_key;

    if found then
      if v_existing.type <> p_type
         or v_existing.amount <> p_amount
         or v_existing.category <> coalesce(p_category, 'other')
         or coalesce(v_existing.description, '') <> coalesce(p_description, '')
         or v_existing.wallet_id is distinct from p_wallet_id
         or v_existing.source_wallet_id is distinct from p_source_wallet_id
         or v_existing.destination_wallet_id is distinct from p_destination_wallet_id
         or abs(extract(epoch from (v_existing.occurred_at - coalesce(p_occurred_at, now())))) > 1
      then
        raise exception 'Idempotency key already belongs to a different transaction';
      end if;

      return next v_existing;
      return;
    end if;
  end if;

  insert into public.transactions (
    id,
    user_id,
    wallet_id,
    source_wallet_id,
    destination_wallet_id,
    type,
    amount,
    category,
    description,
    occurred_at,
    idempotency_key,
    metadata
  ) values (
    v_id,
    v_user_id,
    p_wallet_id,
    p_source_wallet_id,
    p_destination_wallet_id,
    p_type,
    p_amount,
    coalesce(p_category, 'other'),
    p_description,
    coalesce(p_occurred_at, now()),
    p_idempotency_key,
    coalesce(p_metadata, '{}'::jsonb)
  )
  returning * into v_row;

  return next v_row;
end;
$$;

create or replace function public.nexora_update_transaction(
  p_transaction_id uuid,
  p_type text,
  p_amount numeric,
  p_category text default 'other',
  p_description text default null,
  p_occurred_at timestamptz default now(),
  p_metadata jsonb default '{}'::jsonb,
  p_wallet_id uuid default null,
  p_source_wallet_id uuid default null,
  p_destination_wallet_id uuid default null
)
returns setof public.transactions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_row public.transactions;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'Transaction amount must be greater than zero';
  end if;

  update public.transactions
     set type = p_type,
         amount = p_amount,
         category = coalesce(p_category, 'other'),
         description = p_description,
         occurred_at = coalesce(p_occurred_at, now()),
         metadata = coalesce(p_metadata, '{}'::jsonb),
         wallet_id = p_wallet_id,
         source_wallet_id = p_source_wallet_id,
         destination_wallet_id = p_destination_wallet_id
   where id = p_transaction_id
     and user_id = v_user_id
  returning * into v_row;

  if not found then
    raise exception 'Transaction not found';
  end if;

  return next v_row;
end;
$$;

create or replace function public.nexora_delete_transaction(
  p_transaction_id uuid
)
returns setof public.transactions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_row public.transactions;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  delete from public.transactions
   where id = p_transaction_id
     and user_id = v_user_id
  returning * into v_row;

  if not found then
    raise exception 'Transaction not found';
  end if;

  return next v_row;
end;
$$;

-- The Data API remains read-only for the financial ledger. All writes go
-- through the ownership-checked RPCs above, while the existing trigger keeps
-- wallet balances synchronized in the same database transaction.
revoke insert, update, delete on public.transactions from anon, authenticated;
grant select on public.transactions to authenticated;

drop policy if exists transactions_insert_own on public.transactions;
drop policy if exists transactions_update_own on public.transactions;
drop policy if exists transactions_delete_own on public.transactions;

grant execute on function public.nexora_create_transaction(text, numeric, text, text, timestamptz, text, jsonb, uuid, uuid, uuid, uuid) to authenticated;
grant execute on function public.nexora_update_transaction(uuid, text, numeric, text, text, timestamptz, jsonb, uuid, uuid, uuid) to authenticated;
grant execute on function public.nexora_delete_transaction(uuid) to authenticated;

revoke execute on function public.nexora_create_transaction(text, numeric, text, text, timestamptz, text, jsonb, uuid, uuid, uuid, uuid) from anon;
revoke execute on function public.nexora_update_transaction(uuid, text, numeric, text, text, timestamptz, jsonb, uuid, uuid, uuid) from anon;
revoke execute on function public.nexora_delete_transaction(uuid) from anon;

-- Anonymous clients do not need direct access to Nexora's user-owned tables.
revoke all on public.profiles from anon;
revoke all on public.wallets from anon;
revoke all on public.transactions from anon;
revoke all on public.goals from anon;
revoke all on public.goal_contributions from anon;
revoke all on public.budgets from anon;

comment on function public.nexora_create_transaction(text, numeric, text, text, timestamptz, text, jsonb, uuid, uuid, uuid, uuid)
is 'Authenticated financial transaction creation boundary. Binds user_id to auth.uid() and relies on the balance trigger for atomic wallet updates.';
comment on function public.nexora_update_transaction(uuid, text, numeric, text, text, timestamptz, jsonb, uuid, uuid, uuid)
is 'Authenticated financial transaction update boundary. Binds ownership to auth.uid() and preserves goal linkage fields.';
comment on function public.nexora_delete_transaction(uuid)
is 'Authenticated financial transaction deletion boundary. Binds ownership to auth.uid() and lets the balance trigger reverse the ledger effect atomically.';
