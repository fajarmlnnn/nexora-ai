# Auth Bridge Server Boundary

The AI gateway accepts a Supabase access token, verifies it with Supabase Auth, and derives the user UUID from the verified response. It does not accept a caller-supplied user ID as authority.
