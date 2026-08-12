import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

class NexoraSupabase {
  const NexoraSupabase._();

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    SupabaseConfig.validate();

    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
        detectSessionInUri: false,
      ),
    );
  }
}
