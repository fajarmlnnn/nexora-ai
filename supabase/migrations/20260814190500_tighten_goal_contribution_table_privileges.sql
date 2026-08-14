-- Authenticated clients only need to read goal contributions.
-- Remove table-level privileges that are not part of the client API boundary.
REVOKE TRIGGER, TRUNCATE, REFERENCES ON TABLE public.goal_contributions FROM authenticated;
