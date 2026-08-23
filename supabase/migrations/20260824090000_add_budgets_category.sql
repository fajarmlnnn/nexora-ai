-- Explicit budget category, independent of budget id/name.
-- Spent remains derived from transactions and is never stored.

alter table public.budgets
  add column if not exists category text;

update public.budgets
set category = case
  when lower(btrim(name)) in ('makan', 'makanan', 'food', 'makan & minum') then 'food'
  when lower(btrim(name)) in ('transport', 'transportasi') then 'transport'
  when lower(btrim(name)) in ('belanja', 'shopping') then 'shopping'
  when lower(btrim(name)) in ('tagihan', 'bills') then 'bills'
  when lower(btrim(name)) in ('hiburan', 'entertainment') then 'entertainment'
  when lower(btrim(name)) in ('kesehatan', 'health') then 'health'
  when lower(btrim(name)) in ('pendidikan', 'education') then 'education'
  else 'other'
end
where category is null or btrim(category) = '';

alter table public.budgets
  alter column category set default 'other';

update public.budgets
set category = 'other'
where category is null or btrim(category) = '';

alter table public.budgets
  alter column category set not null;

alter table public.budgets
  drop constraint if exists budgets_category_allowed;

alter table public.budgets
  add constraint budgets_category_allowed
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
