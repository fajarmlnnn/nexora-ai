-- Goal deletion is a financial operation because contributions may have
-- corresponding wallet ledger transactions. Authenticated clients must use
-- the atomic nexora_delete_goal RPC instead of direct DELETE.
REVOKE DELETE ON TABLE public.goals FROM authenticated;
DROP POLICY IF EXISTS goals_delete_own ON public.goals;
