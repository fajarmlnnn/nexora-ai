# Auth Bridge Checklist

- [x] Keep Supabase Auth as the Flutter identity provider.
- [x] Verify Supabase access tokens server-side before AI gateway execution.
- [x] Attach the verified Supabase UUID to the Laravel request context.
- [x] Do not mint a second Flutter login token.
- [x] Do not expose a Supabase service-role/secret key.
- [x] Return generic authentication errors.
- [x] Cover missing token, invalid token, verified identity, and provider outage.
- [ ] Wire Flutter AI API client to forward the current Supabase access token.
- [ ] Add Android E2E coverage for the authenticated AI request.
- [ ] Only after the above, consider broader Laravel endpoint integration.
