-- PostgreSQL grants EXECUTE to PUBLIC by default for newly created functions.
-- Revoke that implicit privilege so these SECURITY DEFINER financial
-- boundaries are reachable only by authenticated clients.
revoke execute on function public.nexora_create_transaction(text,numeric,text,text,timestamptz,text,jsonb,uuid,uuid,uuid,uuid) from public, anon;
revoke execute on function public.nexora_update_transaction(uuid,text,numeric,text,text,timestamptz,jsonb,uuid,uuid,uuid) from public, anon;
revoke execute on function public.nexora_delete_transaction(uuid) from public, anon;

grant execute on function public.nexora_create_transaction(text,numeric,text,text,timestamptz,text,jsonb,uuid,uuid,uuid,uuid) to authenticated;
grant execute on function public.nexora_update_transaction(uuid,text,numeric,text,text,timestamptz,jsonb,uuid,uuid,uuid) to authenticated;
grant execute on function public.nexora_delete_transaction(uuid) to authenticated;
