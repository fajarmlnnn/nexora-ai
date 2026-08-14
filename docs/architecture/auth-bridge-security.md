# Auth Bridge Security

The Laravel gateway must not trust a user ID supplied by Flutter. It derives the identity from the verified Supabase access token. Only the server-side verification result is attached to the request context.

No Supabase service-role/secret key is required for this verification path.
