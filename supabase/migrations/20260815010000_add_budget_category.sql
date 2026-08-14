begin;

-- Budget identity and transaction category are different concepts.
-- Existing rows are backfilled from the legacy id/name convention before the
-- column becomes mandatory. New rows must always provide an expense category.
alter table public.budgets
  add column if not exists category text;

update public.budgets
set category = case
  when lower(trim(id)) in ('food', 'makan', 'makanan') then 'food'
  when lower(trim(id)) in ('transport', 'transportasi') then 'transport'
  when lower(trim(id)) in ('shopping', 'belanja') then 'shopping'
  when lower(trim(id)) in ('bills', 'tagihan') then 'bills'
  when lower(trim(id)) in ('entertainment', 'hiburan') then 'entertainment'
  when lower(trim(id)) in ('health', 'kesehatan') then 'health'
  when lower(trim(id)) in ('education', 'pendidikan') then 'education'
  when lower(trim(id)) in ('other', 'lainnya') then 'other'
  when lower(trim(name)) in ('makan', 'makanan') then 'food'
  when lower(trim(name)) in ('transportasi', 'transport') then 'transport'
  when lower(trim(name)) in ('belanja', 'shopping') then 'shopping'
  when lower(trim(name)) in ('tagihan', 'bills') then 'bills'
  when lower(trim(name)) in ('hiburan', 'entertainment') then 'entertainment'
  when lower(trim(name)) in ('kesehatan', 'health') then 'health'
  when lower(trim(name)) in ('pendidikan', 'education') then 'education'
  else 'other'
end
where category is null;

alter table public.budgets
  alter column category set default 'other',
  alter column category set not null;

alter table public.budgets
  drop constraint if exists budgets_category_check;

alter table public.budgets
  add constraint budgets_category_check
  check (category in (
    'food',
    'transport',
    'shopping',
    'bills',
    'entertainment',
    'health',
    'education',
    'other'
  ));

-- Nexora currently exposes one monthly budget per expense category. Keeping
-- this invariant in the database prevents duplicate budgets from double-counting
-- the same transaction category in dashboard totals.
create unique index if not exists budgets_user_category_unique
  on public.budgets(user_id, category);

create index if not exists budgets_user_category_idx
  on public.budgets(user_id, category);

comment on column public.budgets.category is
  'Explicit transaction category tracked by this budget; independent from budget id.';

commit;
