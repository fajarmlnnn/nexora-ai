# Auth Bridge Rollout

## Phase 1 — server boundary

- Supabase remains the identity provider.
- Laravel verifies Supabase access tokens for the AI route.
- No second Flutter identity is created.
- Legacy Sanctum routes remain isolated.

## Phase 2 — client wiring

- Read the current Supabase session access token in Flutter.
- Forward it as `Authorization: Bearer <token>` to `/api/v1/ai/chat`.
- Keep Supabase login/logout unchanged.
- Add mocked API tests and an Android E2E authenticated request.

## Phase 3 — broader server capabilities

- Reuse the verified `supabase_user_id` for any user-scoped server capability.
- Never trust a client-supplied user ID.
- Keep financial ownership in Supabase/RLS unless an explicit architecture decision changes that boundary.
