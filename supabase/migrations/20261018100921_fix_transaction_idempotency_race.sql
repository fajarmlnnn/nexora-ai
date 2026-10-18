-- Resolve concurrent retries for identical financial transaction requests.
-- A pre-insert SELECT alone is not sufficient: two concurrent requests can
-- both observe no row. The unique idempotency index arbitrates the insert;
-- the losing request then returns the persisted row after verifying payload
-- equivalence. This migration adds no new tables and does not touch user data.

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
  on conflict (user_id, idempotency_key)
    where idempotency_key is not null
    do nothing
  returning * into v_row;

  if found then
    return next v_row;
    return;
  end if;

  -- The only conflict intentionally ignored above is the scoped idempotency
  -- key. SELECT happens after ON CONFLICT has waited for a concurrent writer,
  -- so a committed competing request is visible here.
  select t.*
    into v_existing
    from public.transactions t
   where t.user_id = v_user_id
     and t.idempotency_key = p_idempotency_key
   for update;

  if not found then
    raise exception 'Transaction insert did not complete and no idempotent transaction was found';
  end if;

  if v_existing.type <> p_type
     or v_existing.amount <> p_amount
     or v_existing.category <> coalesce(p_category, 'other')
     or coalesce(v_existing.description, '') <> coalesce(p_description, '')
     or v_existing.wallet_id is distinct from p_wallet_id
     or v_existing.source_wallet_id is distinct from p_source_wallet_id
     or v_existing.destination_wallet_id is distinct from p_destination_wallet_id
     or v_existing.metadata is distinct from coalesce(p_metadata, '{}'::jsonb)
     or abs(extract(epoch from (v_existing.occurred_at - coalesce(p_occurred_at, now())))) > 1
  then
    raise exception 'Idempotency key already belongs to a different transaction';
  end if;

  return next v_existing;
end;
$$;

revoke execute on function public.nexora_create_transaction(text, numeric, text, text, timestamptz, text, jsonb, uuid, uuid, uuid, uuid) from public, anon;
grant execute on function public.nexora_create_transaction(text, numeric, text, text, timestamptz, text, jsonb, uuid, uuid, uuid, uuid) to authenticated;

comment on function public.nexora_create_transaction(text, numeric, text, text, timestamptz, text, jsonb, uuid, uuid, uuid, uuid)
is 'Authenticated transaction creation. Handles concurrent idempotent retries through the unique idempotency index and keeps wallet balance updates atomic through the ledger trigger.';
