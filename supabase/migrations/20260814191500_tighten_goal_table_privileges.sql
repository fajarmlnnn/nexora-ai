-- The mobile client needs goal CRUD only within the explicit RLS/API
-- boundary. It does not need table-level DDL-adjacent privileges.
REVOKE TRIGGER, TRUNCATE, REFERENCES ON TABLE public.goals FROM authenticated;
