# Legacy Laravel authentication boundary

Laravel Sanctum remains in the repository as a backend foundation because the repository still contains backend API tests and controllers built around it. It is **not** the Flutter application's authentication path.

The Flutter application authenticates with Supabase Auth. The old Flutter Laravel-auth client (`core/network/auth_api.dart`, `api_client.dart`, `api_config.dart`, and `token_store.dart`) has been removed because no application code referenced it and keeping it created a misleading second-token path.

## Safe migration rule

Do not remove Laravel Sanctum or Laravel financial tables in the same change as an authentication refactor. First migrate every backend consumer, add equivalent E2E coverage, and then remove the legacy layer in a separately verified change.
