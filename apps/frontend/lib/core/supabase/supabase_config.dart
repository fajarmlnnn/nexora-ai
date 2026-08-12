class SupabaseConfig {
  const SupabaseConfig._();

  static const url = String.fromEnvironment('NEXORA_SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'NEXORA_SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get isConfigured =>
      url.isNotEmpty && publishableKey.isNotEmpty;

  static void validate() {
    if (url.isEmpty || publishableKey.isEmpty) {
      throw StateError(
        'Supabase is not configured. Provide NEXORA_SUPABASE_URL and '
        'NEXORA_SUPABASE_PUBLISHABLE_KEY with --dart-define.',
      );
    }
  }
}
