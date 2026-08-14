-- Persistent per-user budget limits.
-- `spent` is intentionally not stored: it is derived from transactions in the app.
create table if not exists public.budgets (
  id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  budget_limit numeric(20, 2) not null,
  color bigint not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, id),
  constraint budgets_name_not_blank check (length(btrim(name)) > 0),
  constraint budgets_limit_positive check (budget_limit > 0),
  constraint budgets_color_non_negative check (color >= 0)
);

create index if not exists budgets_user_id_idx on public.budgets(user_id);

alter table public.budgets enable row level security;

-- Only the authenticated owner can see or mutate a budget row.
drop policy if exists "Users can read own budgets" on public.budgets;
create policy "Users can read own budgets"
  on public.budgets for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can create own budgets" on public.budgets;
create policy "Users can create own budgets"
  on public.budgets for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update own budgets" on public.budgets;
create policy "Users can update own budgets"
  on public.budgets for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can delete own budgets" on public.budgets;
create policy "Users can delete own budgets"
  on public.budgets for delete
  to authenticated
  using ((select auth.uid()) = user_id);

-- Keep timestamps server-owned.
create or replace function public.set_budgets_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists budgets_set_updated_at on public.budgets;
create trigger budgets_set_updated_at
before update on public.budgets
for each row execute function public.set_budgets_updated_at();

-- Clients must never be able to reassign ownership through a column update.
revoke update (user_id, created_at, updated_at) on public.budgets from authenticated;
