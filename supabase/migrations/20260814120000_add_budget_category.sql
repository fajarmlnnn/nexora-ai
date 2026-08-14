-- Budget category is configuration, not identity.
-- Existing rows default to `other`; the client retains a legacy id fallback
-- for budgets created before this column existed.
alter table public.budgets
  add column if not exists category text not null default 'other';

alter table public.budgets
  drop constraint if exists budgets_category_valid;

alter table public.budgets
  add constraint budgets_category_valid
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

create index if not exists budgets_user_category_idx
  on public.budgets(user_id, category);

revoke update (user_id, created_at, updated_at) on public.budgets from authenticated;
