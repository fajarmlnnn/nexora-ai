# Nexora architecture

The canonical architecture decision is documented in [`auth-data-boundary-v1.md`](auth-data-boundary-v1.md).

Before adding a new backend feature, verify whether it belongs in Supabase/Postgres (user-owned financial state and atomic financial mutations) or Laravel (server-side orchestration/integrations). Avoid introducing a second source of truth.
