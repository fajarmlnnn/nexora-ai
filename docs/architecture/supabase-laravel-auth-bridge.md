# Supabase → Laravel Auth Bridge

## Decision

Supabase Auth remains the single identity provider for Flutter. Laravel verifies the Supabase access token only for server-side capabilities such as the AI gateway. Laravel does not mint a replacement Flutter login token or create a second application identity.

## Verification flow

```text
Flutter
  |
  | Authorization: Bearer <Supabase access token>
  v
Laravel middleware
  |
  | GET /auth/v1/user
  | apikey: Supabase publishable key
  v
Supabase Auth
  |
  | verified user id
  v
Laravel request attribute: supabase_user_id
  |
  v
AI Gateway
```

Supabase documents server-side `getUser(access_token)` as a way to validate a user's access token. This implementation uses the Auth `/auth/v1/user` endpoint and the project publishable/anon key; it never requires the Supabase service-role/secret key.

## Errors

- missing bearer token → `401 UNAUTHENTICATED`
- invalid/expired token → `401 UNAUTHENTICATED`
- Supabase Auth connection failure → `503 AUTH_PROVIDER_UNAVAILABLE`
- upstream authentication response bodies are not returned to the client

## Scope

This is **not** an auth migration. Flutter login/logout and Supabase financial repositories remain unchanged. Laravel Sanctum remains isolated legacy/foundation code. A later client PR will forward the existing Supabase session access token to `/api/v1/ai/chat` and add Android E2E coverage.
