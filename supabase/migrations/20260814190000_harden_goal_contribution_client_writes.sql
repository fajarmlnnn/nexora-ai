-- Authenticated clients may read goal contributions, but financial contribution
-- writes must go through Nexora's atomic RPCs.
REVOKE INSERT, UPDATE, DELETE ON TABLE public.goal_contributions FROM authenticated;
GRANT SELECT ON TABLE public.goal_contributions TO authenticated;

COMMENT ON TABLE public.goal_contributions IS
  'Read-only to authenticated clients; financial contributions must be created or removed by Nexora server-side RPCs so ledger and goal state remain atomic.';
