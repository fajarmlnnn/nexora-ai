# Nexora architecture

The canonical architecture decisions are documented here.

- [`auth-data-boundary-v1.md`](auth-data-boundary-v1.md) — Supabase Auth identity and Supabase PostgreSQL financial source of truth.
- [`financial-mutation-boundary.md`](financial-mutation-boundary.md) — rules for financial writes and atomicity.
- [`backend-migration-checklist.md`](backend-migration-checklist.md) — gates for migrating/removing the legacy Laravel foundation.
- [`legacy-backend-auth.md`](legacy-backend-auth.md) — why the legacy Laravel auth layer remains temporarily.

Before adding a backend feature, determine whether it belongs in Supabase/Postgres (user-owned financial state and atomic financial mutations) or Laravel (server-side orchestration/integrations). Do not introduce a second source of truth or second application identity.
