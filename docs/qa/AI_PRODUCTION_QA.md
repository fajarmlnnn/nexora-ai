# Nexora AI Production QA

## Current validated flow

- Production app: `https://nexora-ai.dockhosting.dev`
- Authenticated AI chat: verified from the production application.
- PR #38: merged to `main`.

## Financial period contract

Analytics use a half-open range `[start, end)`. The AI API converts the exclusive `end` into the last included calendar date before sending `period_end` to the backend so natural-language AI responses do not describe a monthly range as ending on the first day of the next month.

Example:

- internal range: `[2026-08-01, 2026-09-01)`
- user-facing period: `2026-08-01` through `2026-08-31`

## Production smoke-test checklist

1. Login with a valid Supabase session.
2. Open Nexora AI.
3. Ask for current-month cashflow.
4. Confirm AI response is returned.
5. Add one income transaction and ask again; verify income/net cashflow change.
6. Add one expense transaction and ask again; verify expense/net cashflow change.
7. Add an internal transfer and verify it does not inflate income or expense.
8. Start a new AI conversation and verify history resets.
9. Force/allow an expired session and verify the client refreshes authentication.
10. Trigger provider/API failure and verify the UI shows a retryable error without exposing secrets.
