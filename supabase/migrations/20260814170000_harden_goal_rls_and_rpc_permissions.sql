-- Harden goal RLS performance and SECURITY DEFINER RPC exposure.
-- auth.uid() is evaluated once per statement instead of once per row.
drop policy if exists goals_select_own on public.goals;
create policy goals_select_own on public.goals for select to authenticated using ((select auth.uid()) = user_id);

drop policy if exists goals_insert_own on public.goals;
create policy goals_insert_own on public.goals for insert to authenticated with check ((select auth.uid()) = user_id);

drop policy if exists goals_update_own on public.goals;
create policy goals_update_own on public.goals for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

drop policy if exists goals_delete_own on public.goals;
create policy goals_delete_own on public.goals for delete to authenticated using ((select auth.uid()) = user_id);

drop policy if exists goal_contributions_select_own on public.goal_contributions;
create policy goal_contributions_select_own on public.goal_contributions for select to authenticated using ((select auth.uid()) = user_id);

drop policy if exists goal_contributions_insert_own on public.goal_contributions;
create policy goal_contributions_insert_own on public.goal_contributions for insert to authenticated with check ((select auth.uid()) = user_id);

drop policy if exists goal_contributions_delete_own on public.goal_contributions;
create policy goal_contributions_delete_own on public.goal_contributions for delete to authenticated using ((select auth.uid()) = user_id);

revoke all on function public.enforce_goal_write_boundaries() from public, anon, authenticated;
revoke all on function public.nexora_contribute_to_goal(uuid,numeric,text) from public, anon, authenticated;
revoke all on function public.nexora_update_goal_target(uuid,numeric) from public, anon, authenticated;
grant execute on function public.nexora_contribute_to_goal(uuid,numeric,text) to authenticated;
grant execute on function public.nexora_update_goal_target(uuid,numeric) to authenticated;
