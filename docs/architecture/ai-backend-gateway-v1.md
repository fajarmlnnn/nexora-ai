# Nexora AI Backend Gateway v1

## Boundary

Flutter must never contain an AI provider API key. The mobile app authenticates with the Laravel API using a Sanctum bearer token, then calls `POST /api/v1/ai/chat`.

```text
Flutter AI Assistant
        |
        | Bearer token
        v
Laravel /api/v1/ai/chat
        |
        | server-side API key
        v
OpenAI-compatible provider
```

Supabase remains the authentication/data system used by the current Flutter financial flows. Laravel is the protected API boundary for server-side AI access.

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
AI_PROVIDER=openai_compatible
AI_BASE_URL=https://api.openai.com/v1
AI_API_KEY=server-side-secret
AI_MODEL=gpt-4o-mini
AI_TIMEOUT=30
AI_MAX_TOKENS=700
```

`AI_API_KEY` must not be committed, shipped in Flutter, or returned by any API response.

## Safety controls

- authenticated with Sanctum
- `20 requests/minute` route throttle
- max 20 messages per request
- max 4,000 characters per message
- only `user` and `assistant` roles are accepted from the client
- financial context is allowlisted and sanitized
- provider failures are normalized to a generic `503`
- no conversation persistence is introduced by this gateway
