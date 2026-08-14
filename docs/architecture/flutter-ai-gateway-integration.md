# Flutter → Laravel → Gemini AI Integration

## Runtime boundary

Flutter never receives or stores the Gemini API key. It reads the current Supabase session access token and sends it to the Laravel AI gateway.

```text
Flutter AI Assistant
      |
      | Authorization: Bearer <Supabase access token>
      v
Laravel /api/v1/ai/chat
      |
      | server-side AI_API_KEY
      v
Gemini OpenAI-compatible API
```

## Client configuration

The Flutter API base URL is supplied at build/run time with:

```bash
flutter run --dart-define=NEXORA_API_BASE_URL=https://your-laravel-host/api/v1
```

For a local Android emulator with Laravel listening on the host machine, use the emulator host address instead of `localhost`, for example:

```bash
flutter run --dart-define=NEXORA_API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Do not commit a private server URL or any AI provider secret to the Flutter repository.

## Request contract

The client sends the current conversation (maximum 20 messages) plus the canonical `FinancialAnalyticsSnapshot` fields:

- income
- expense
- net_cashflow
- savings_rate
- top_expense_category
- top_expense_value
- period_start
- period_end

The backend remains responsible for allowlisting and sanitizing the financial context before it reaches Gemini.

## Session handling

- No second login system is introduced.
- A missing Supabase session returns a client-side `UNAUTHENTICATED` error.
- A server `401` triggers one Supabase session refresh and one retry.
- A second `401` is surfaced to the UI.
- `429` and `503` are mapped to user-safe messages.
- Network and timeout failures never expose provider details.

## Security

Never put `AI_API_KEY`, Gemini URLs containing credentials, or raw provider responses into Flutter configuration. The only credential sent by Flutter is the existing Supabase access token in the Authorization header.
