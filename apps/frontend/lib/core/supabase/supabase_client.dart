import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

class NexoraSupabase {
  const NexoraSupabase._();

  static SupabaseClient get client => Supabase.instance.client;

  static bool get isInitialized =>
      Supabase.instance.client.auth.currentSession != null;

  static Future<bool> initializeIfConfigured() async {
    if (!SupabaseConfig.isConfigured) return false;

    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
        detectSessionInUri: false,
      ),
    );
    return true;
  }

  static Future<void> initialize() async {
    SupabaseConfig.validate();
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
        detectSessionInUri: false,
      ),
    );
  }
}
