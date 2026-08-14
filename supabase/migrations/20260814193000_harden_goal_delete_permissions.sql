-- Goal deletion is a financial operation because goal contributions are
-- represented by ledger transactions that must be reversed atomically.
-- Clients must use nexora_delete_goal() instead of deleting the goal row.
revoke delete on public.goals from authenticated;
revoke delete on public.goals from anon;

revoke all on function public.nexora_delete_goal(uuid) from public, anon;
grant execute on function public.nexora_delete_goal(uuid) to authenticated;
