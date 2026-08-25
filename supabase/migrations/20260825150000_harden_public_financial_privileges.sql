-- Defense-in-depth: the public API must not expose direct table writes for financial state.
revoke all on table public.profiles from anon;
revoke all on table public.wallets from anon;
revoke all on table public.transactions from anon;
revoke all on table public.budgets from anon;
revoke all on table public.goals from anon;
revoke all on table public.goal_contributions from anon;

-- Financial mutations must go through trusted, ownership-aware RPCs.
revoke insert, update, delete, truncate, references, trigger on table public.transactions from authenticated;
revoke insert, update, delete, truncate, references, trigger on table public.goal_contributions from authenticated;

-- SECURITY DEFINER functions must never be callable by anonymous/public callers.
revoke execute on function public.nexora_create_transaction(text,numeric,text,text,timestamptz,text,jsonb,uuid,uuid,uuid,uuid) from public;
revoke execute on function public.nexora_create_transaction(text,numeric,text,text,timestamptz,text,jsonb,uuid,uuid,uuid,uuid) from anon;
grant execute on function public.nexora_create_transaction(text,numeric,text,text,timestamptz,text,jsonb,uuid,uuid,uuid,uuid) to authenticated;

revoke execute on function public.nexora_update_transaction(uuid,text,numeric,text,text,timestamptz,jsonb,uuid,uuid,uuid) from public;
revoke execute on function public.nexora_update_transaction(uuid,text,numeric,text,text,timestamptz,jsonb,uuid,uuid,uuid) from anon;
grant execute on function public.nexora_update_transaction(uuid,text,numeric,text,text,timestamptz,jsonb,uuid,uuid,uuid) to authenticated;

revoke execute on function public.nexora_delete_transaction(uuid) from public;
revoke execute on function public.nexora_delete_transaction(uuid) from anon;
grant execute on function public.nexora_delete_transaction(uuid) to authenticated;

revoke execute on function public.nexora_contribute_to_goal_from_wallet(uuid,uuid,numeric,text,text) from public;
revoke execute on function public.nexora_contribute_to_goal_from_wallet(uuid,uuid,numeric,text,text) from anon;
grant execute on function public.nexora_contribute_to_goal_from_wallet(uuid,uuid,numeric,text,text) to authenticated;

revoke execute on function public.nexora_delete_goal(uuid) from public;
revoke execute on function public.nexora_delete_goal(uuid) from anon;
grant execute on function public.nexora_delete_goal(uuid) to authenticated;

revoke execute on function public.nexora_update_goal_target(uuid,numeric) from public;
revoke execute on function public.nexora_update_goal_target(uuid,numeric) from anon;
grant execute on function public.nexora_update_goal_target(uuid,numeric) to authenticated;
