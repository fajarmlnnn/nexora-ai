-- Deleting a goal must not destroy the financial history that funded it.
-- Goal contributions are linked to ledger transactions by metadata. Removing
-- those expense transactions first makes the existing transaction balance
-- trigger credit the funding wallet back atomically.
create or replace function public.nexora_delete_goal(p_goal_id uuid)
returns public.goals
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_goal public.goals;
  v_has_unlinked_contribution boolean;
begin
  if v_user is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_goal
  from public.goals
  where id = p_goal_id
    and user_id = v_user
  for update;

  if not found then
    raise exception 'Goal not found';
  end if;

  -- Every contribution created by the current goal funding flow must have a
  -- corresponding ledger transaction. Refuse deletion rather than silently
  -- deleting money history if the database is inconsistent.
  select exists (
    select 1
    from public.goal_contributions gc
    where gc.goal_id = v_goal.id
      and not exists (
        select 1
        from public.transactions t
        where t.user_id = v_user
          and t.metadata ->> 'goal_contribution_id' = gc.id::text
      )
  ) into v_has_unlinked_contribution;

  if v_has_unlinked_contribution then
    raise exception 'Goal has an unlinked contribution; deletion was blocked to protect wallet history';
  end if;

  -- DELETE on transactions invokes transactions_balance_trigger. For an
  -- expense, that trigger adds the amount back to the wallet. Do this before
  -- deleting the goal/contributions so the reserved money returns to the
  -- wallet in the same database transaction.
  delete from public.transactions t
  where t.user_id = v_user
    and t.metadata ->> 'goal_id' = v_goal.id::text
    and t.metadata ->> 'kind' in ('goal_contribution', 'goal_contribution_reconciliation');

  -- Contributions then cascade away with the goal.
  delete from public.goals
  where id = v_goal.id
    and user_id = v_user;

  return v_goal;
end;
$$;

revoke all on function public.nexora_delete_goal(uuid) from public, anon;
grant execute on function public.nexora_delete_goal(uuid) to authenticated;
