-- RLS predicates are intentionally written as init-plan expressions so auth.uid()
-- is evaluated once per statement instead of once per row.
-- This migration is kept as a versioned record for the live project.

-- No-op on fresh databases because the baseline migration already uses the
-- optimized form. Kept intentionally to match the live migration history.
