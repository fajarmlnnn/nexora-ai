# Supabase → Laravel Auth Bridge

## Decision

Supabase Auth remains the single identity provider for Flutter. Laravel verifies the Supabase access token only for server-side capabilities such as the AI gateway.

Laravel must not mint a replacement login token for Flutter and must not create a second application identity that can diverge from `auth.users`.

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

Supabase documents `auth.getUser(access_token)` / the Auth `/auth/v1/user` endpoint as a server-side way to validate a user's access token. The gateway uses the project publishable/anon key for this verification and never needs the Supabase service-role/secret key.

## Error behavior

- missing bearer token → `401 UNAUTHENTICATED`
- invalid/expired token → `401 UNAUTHENTICATED`
- Supabase Auth connection failure → `503 AUTH_PROVIDER_UNAVAILABLE`
- upstream auth response bodies are never returned to the client

## Migration boundary

This is intentionally **not** a login migration. Existing Flutter login/logout remains Supabase-based. Laravel Sanctum remains legacy/foundation code for existing backend tests and endpoints, but it is not used by the Flutter AI route.

A later frontend task may attach the current Supabase session access token to the AI API client. That task should be tested separately so an AI integration failure cannot break login/logout.
