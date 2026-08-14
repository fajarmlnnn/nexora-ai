# Nexora AI Backend Gateway v1

## Boundary

Flutter must never contain an AI provider API key. Supabase Auth remains the single identity provider for the Flutter application. The Laravel gateway verifies the Supabase access token before handling an AI request; it does not mint a second application identity.

```text
Flutter AI Assistant
        |
        | Supabase access token
        v
Laravel /api/v1/ai/chat
        |
        | verify token with Supabase Auth
        v
Supabase Auth user identity
        |
        | server-side AI API key
        v
OpenAI-compatible provider
```

Supabase remains the authentication and financial-data system used by the current Flutter flows. Laravel is the protected server-side AI boundary. Legacy Laravel Sanctum auth endpoints remain isolated and are not the identity mechanism for Flutter.

## Contract

Request:

```json
{
  "messages": [
    {"role": "user", "content": "Bagaimana cashflow saya?"}
  ],
  "financial_context": {
    "income": 3000000,
    "expense": 2000000,
    "net_cashflow": 1000000,
    "savings_rate": 0.33,
    "top_expense_category": "food",
    "top_expense_value": 800000,
    "period_start": "2026-08-01",
    "period_end": "2026-09-01"
  }
}
```

Only the allowlisted financial analytics fields are forwarded to the provider. Secrets and arbitrary context keys are discarded.

Response:

```json
{
  "success": true,
  "data": {
    "message": {
      "role": "assistant",
      "content": "..."
    }
  }
}
```

Provider failures return HTTP `503` with `AI_PROVIDER_UNAVAILABLE` and never expose provider error bodies or credentials.

## Configuration

Set these values only in the Laravel server environment:

```dotenv
SUPABASE_URL=https://project-id.supabase.co
SUPABASE_PUBLISHABLE_KEY=server-visible-publishable-key
AI_PROVIDER=openai_compatible
AI_BASE_URL=https://api.openai.com/v1
AI_API_KEY=server-side-secret
AI_MODEL=gpt-4o-mini
AI_TIMEOUT=30
AI_MAX_TOKENS=700
```

`AI_API_KEY` must not be committed, shipped in Flutter, or returned by any API response. The Supabase publishable/anon key is not a secret, but it remains server configuration here so the gateway owns its Auth verification contract.

## Safety controls

- Supabase Auth access token is required for the AI route
- token is verified through Supabase Auth before controller execution
- verified Supabase user UUID is attached to the request as `supabase_user_id`
- Laravel does not create or persist a second Flutter identity
- `20 requests/minute` route throttle
- max 20 messages per request
- max 4,000 characters per message
- only `user` and `assistant` roles are accepted from the client
- financial context is allowlisted and sanitized
- provider failures are normalized to a generic `503`
- no conversation persistence is introduced by this gateway

## Migration rule

This is an auth bridge for the server-side AI boundary, not an auth migration. Flutter login/logout remains Supabase-based. A future frontend integration may forward the current Supabase access token to this endpoint. Laravel Sanctum must not replace Supabase Auth unless the architecture decision is explicitly changed and all consumers are migrated with equivalent E2E coverage.
