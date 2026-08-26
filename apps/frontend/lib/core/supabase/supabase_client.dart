import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

class NexoraSupabase {
  const NexoraSupabase._();

  static bool _sdkInitialized = false;

  static SupabaseClient get client => Supabase.instance.client;

  /// True once `Supabase.initialize()` has completed successfully.
  /// This does NOT mean the user is logged in — use [hasSession] for that.
  static bool get isSdkInitialized => _sdkInitialized;

  /// True only when the SDK is initialized AND a user session currently
  /// exists. Safe to call even before [initialize]/[initializeIfConfigured]
  /// have run.
  static bool get hasSession =>
      _sdkInitialized && Supabase.instance.client.auth.currentSession != null;

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
    _sdkInitialized = true;
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
    _sdkInitialized = true;
  }
}
