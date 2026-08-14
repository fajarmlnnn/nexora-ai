# Auth Bridge PR

This change is deliberately limited to the Laravel server boundary. It verifies the existing Supabase access token for the AI gateway and does not alter Flutter login/logout or the financial Supabase repositories.

The next PR will wire the Flutter AI client to forward the existing Supabase session token and add device-level E2E coverage.
