create or replace function public.nexora_get_ai_financial_context(
  p_period_start date,
  p_period_end date,
  p_timezone text default 'Asia/Jakarta'
)
returns jsonb
language sql
security invoker
stable
set search_path = pg_catalog, public
as $$
  with bounds as (
    select
      (p_period_start::timestamp at time zone p_timezone) as starts_at,
      ((p_period_end + 1)::timestamp at time zone p_timezone) as ends_at
  ),
  scoped as (
    select t.type, t.amount, t.category
    from public.transactions t
    cross join bounds b
    where t.occurred_at >= b.starts_at
      and t.occurred_at < b.ends_at
      and t.user_id = (select auth.uid())
  ),
  totals as (
    select
      coalesce(sum(amount) filter (where type = 'income'), 0)::numeric(19,2) as income,
      coalesce(sum(amount) filter (where type = 'expense'), 0)::numeric(19,2) as expense,
      count(*)::integer as transaction_count
    from scoped
  ),
  categories as (
    select category, sum(amount)::numeric(19,2) as value
    from scoped
    where type = 'expense'
    group by category
    order by value desc, category asc
    limit 1
  )
  select jsonb_build_object(
    'income', totals.income,
    'expense', totals.expense,
    'net_cashflow', (totals.income - totals.expense)::numeric(19,2),
    'savings_rate', case
      when totals.income > 0
        then round(((totals.income - totals.expense) / totals.income) * 100, 2)
      else 0
    end,
    'top_expense_category', categories.category,
    'top_expense_value', coalesce(categories.value, 0)::numeric(19,2),
    'period_start', p_period_start,
    'period_end', p_period_end,
    'transaction_count', totals.transaction_count,
    'source', 'supabase_authoritative'
  )
  from totals
  left join categories on true;
$$;

revoke execute on function public.nexora_get_ai_financial_context(date, date, text) from public, anon;
grant execute on function public.nexora_get_ai_financial_context(date, date, text) to authenticated;
