create extension if not exists pgcrypto;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  currency_code text not null default 'IDR' check (currency_code ~ '^[A-Z]{3}$'),
  timezone text not null default 'Asia/Jakarta',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.wallets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 100),
  type text not null default 'cash' check (type in ('cash','bank','ewallet','credit','investment','other')),
  bank_name text,
  account_number text,
  balance numeric(19,2) not null default 0 check (balance >= 0),
  minimum_balance numeric(19,2) not null default 0 check (minimum_balance >= 0),
  currency_code text not null default 'IDR' check (currency_code ~ '^[A-Z]{3}$'),
  color text,
  is_primary boolean not null default false,
  is_hidden boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index wallets_one_primary_per_user_idx on public.wallets(user_id) where is_primary;
create index wallets_user_id_idx on public.wallets(user_id);
create index wallets_user_id_created_at_idx on public.wallets(user_id, created_at desc);

create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  wallet_id uuid references public.wallets(id) on delete restrict,
  source_wallet_id uuid references public.wallets(id) on delete restrict,
  destination_wallet_id uuid references public.wallets(id) on delete restrict,
  type text not null check (type in ('income','expense','transfer')),
  amount numeric(19,2) not null check (amount > 0),
  category text not null default 'other' check (char_length(trim(category)) between 1 and 100),
  description text,
  occurred_at timestamptz not null default now(),
  idempotency_key text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint transactions_idempotency_key_len check (idempotency_key is null or char_length(idempotency_key) between 1 and 255),
  constraint transactions_shape_check check (
    (type in ('income','expense') and wallet_id is not null and source_wallet_id is null and destination_wallet_id is null)
    or
    (type = 'transfer' and wallet_id is null and source_wallet_id is not null and destination_wallet_id is not null and source_wallet_id <> destination_wallet_id)
  )
);

create unique index transactions_user_idempotency_idx on public.transactions(user_id, idempotency_key) where idempotency_key is not null;
create index transactions_user_occurred_at_idx on public.transactions(user_id, occurred_at desc);
create index transactions_user_type_idx on public.transactions(user_id, type);
create index transactions_user_category_idx on public.transactions(user_id, category);
create index transactions_wallet_occurred_at_idx on public.transactions(wallet_id, occurred_at desc);
create index transactions_source_wallet_idx on public.transactions(source_wallet_id);
create index transactions_destination_wallet_idx on public.transactions(destination_wallet_id);

create or replace function public.set_updated_at()
returns trigger language plpgsql security invoker set search_path = pg_catalog, public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = pg_catalog, public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'name', new.raw_user_meta_data ->> 'full_name'))
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.apply_transaction_to_wallets()
returns trigger language plpgsql security definer set search_path = pg_catalog, public
as $$
declare
  old_user uuid;
  new_user uuid;
  source_id uuid;
  destination_id uuid;
  wallet_user uuid;
  current_balance numeric(19,2);
  current_minimum numeric(19,2);
  delta numeric(19,2);
begin
  if tg_op in ('UPDATE','DELETE') then
    old_user := old.user_id;
    if old.type in ('income','expense') then
      select id, user_id, balance, minimum_balance into source_id, wallet_user, current_balance, current_minimum
      from public.wallets where id = old.wallet_id for update;
      if source_id is null or wallet_user <> old_user then raise exception 'Source wallet is invalid for transaction'; end if;
      delta := case when old.type = 'income' then -old.amount else old.amount end;
      if current_balance + delta < current_minimum then raise exception 'Wallet balance cannot fall below minimum balance'; end if;
      update public.wallets set balance = balance + delta, updated_at = now() where id = old.wallet_id;
    else
      select id, user_id into source_id, wallet_user from public.wallets where id = old.source_wallet_id for update;
      if source_id is null or wallet_user <> old_user then raise exception 'Source wallet is invalid for transaction'; end if;
      select id, user_id into destination_id, wallet_user from public.wallets where id = old.destination_wallet_id for update;
      if destination_id is null or wallet_user <> old_user then raise exception 'Destination wallet is invalid for transaction'; end if;
      if old.source_wallet_id < old.destination_wallet_id then
        update public.wallets set balance = balance + old.amount, updated_at = now() where id = old.source_wallet_id;
        update public.wallets set balance = balance - old.amount, updated_at = now() where id = old.destination_wallet_id;
      else
        update public.wallets set balance = balance - old.amount, updated_at = now() where id = old.destination_wallet_id;
        update public.wallets set balance = balance + old.amount, updated_at = now() where id = old.source_wallet_id;
      end if;
    end if;
  end if;

  if tg_op in ('INSERT','UPDATE') then
    new_user := new.user_id;
    if new.type in ('income','expense') then
      select id, user_id, balance, minimum_balance into source_id, wallet_user, current_balance, current_minimum
      from public.wallets where id = new.wallet_id for update;
      if source_id is null or wallet_user <> new_user then raise exception 'Wallet is invalid for transaction'; end if;
      delta := case when new.type = 'income' then new.amount else -new.amount end;
      if current_balance + delta < current_minimum then raise exception 'Wallet balance cannot fall below minimum balance'; end if;
      update public.wallets set balance = balance + delta, updated_at = now() where id = new.wallet_id;
    else
      if new.source_wallet_id < new.destination_wallet_id then
        select id, user_id, balance, minimum_balance into source_id, wallet_user, current_balance, current_minimum from public.wallets where id = new.source_wallet_id for update;
        if source_id is null or wallet_user <> new_user then raise exception 'Source wallet is invalid for transfer'; end if;
        if current_balance - new.amount < current_minimum then raise exception 'Source wallet balance cannot fall below minimum balance'; end if;
        update public.wallets set balance = balance - new.amount, updated_at = now() where id = new.source_wallet_id;
        select id, user_id into destination_id, wallet_user from public.wallets where id = new.destination_wallet_id for update;
        if destination_id is null or wallet_user <> new_user then raise exception 'Destination wallet is invalid for transfer'; end if;
        update public.wallets set balance = balance + new.amount, updated_at = now() where id = new.destination_wallet_id;
      else
        select id, user_id into destination_id, wallet_user from public.wallets where id = new.destination_wallet_id for update;
        if destination_id is null or wallet_user <> new_user then raise exception 'Destination wallet is invalid for transfer'; end if;
        select id, user_id, balance, minimum_balance into source_id, wallet_user, current_balance, current_minimum from public.wallets where id = new.source_wallet_id for update;
        if source_id is null or wallet_user <> new_user then raise exception 'Source wallet is invalid for transfer'; end if;
        if current_balance - new.amount < current_minimum then raise exception 'Source wallet balance cannot fall below minimum balance'; end if;
        update public.wallets set balance = balance + new.amount, updated_at = now() where id = new.destination_wallet_id;
        update public.wallets set balance = balance - new.amount, updated_at = now() where id = new.source_wallet_id;
      end if;
    end if;
  end if;
  return coalesce(new, old);
end;
$$;

create trigger profiles_updated_at before update on public.profiles for each row execute function public.set_updated_at();
create trigger wallets_updated_at before update on public.wallets for each row execute function public.set_updated_at();
create trigger transactions_updated_at before update on public.transactions for each row execute function public.set_updated_at();
create trigger transactions_balance_trigger after insert or update or delete on public.transactions for each row execute function public.apply_transaction_to_wallets();

alter table public.profiles enable row level security;
alter table public.wallets enable row level security;
alter table public.transactions enable row level security;

create policy profiles_select_own on public.profiles for select to authenticated using ((select auth.uid()) = id);
create policy profiles_insert_own on public.profiles for insert to authenticated with check ((select auth.uid()) = id);
create policy profiles_update_own on public.profiles for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

create policy wallets_select_own on public.wallets for select to authenticated using ((select auth.uid()) = user_id);
create policy wallets_insert_own on public.wallets for insert to authenticated with check ((select auth.uid()) = user_id);
create policy wallets_update_own on public.wallets for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy wallets_delete_own on public.wallets for delete to authenticated using ((select auth.uid()) = user_id);

create policy transactions_select_own on public.transactions for select to authenticated using ((select auth.uid()) = user_id);
create policy transactions_insert_own on public.transactions for insert to authenticated with check ((select auth.uid()) = user_id);
create policy transactions_update_own on public.transactions for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy transactions_delete_own on public.transactions for delete to authenticated using ((select auth.uid()) = user_id);

grant select, insert, update, delete on public.profiles to authenticated;
grant select, insert, update, delete on public.wallets to authenticated;
grant select, insert, update, delete on public.transactions to authenticated;

revoke execute on function public.set_updated_at() from public, anon, authenticated;
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.apply_transaction_to_wallets() from public, anon, authenticated;