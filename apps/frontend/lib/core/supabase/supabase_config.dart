class SupabaseConfig {
  const SupabaseConfig._();

  static const url = String.fromEnvironment('NEXORA_SUPABASE_URL');
  static const anonKey = String.fromEnvironment('NEXORA_SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static void validate() {
    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'Supabase is not configured. Provide NEXORA_SUPABASE_URL and '
        'NEXORA_SUPABASE_ANON_KEY with --dart-define.',
      );
    }
  }
}
