import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_auth_repository.dart';

final supabaseAuthRepositoryProvider = Provider<SupabaseAuthRepository>((ref) {
  return SupabaseAuthRepository();
});

/// Single auth event stream used by routing and all user-scoped providers.
/// Supabase persists the session on-device, while consumers react to restored
/// and changed sessions instead of relying on a one-time snapshot.
final authStateProvider = StreamProvider<AuthState>((ref) {
  final repository = ref.watch(supabaseAuthRepositoryProvider);
  return repository.authStateChanges.handleError((Object error, StackTrace stack) {
    // Keep the provider alive after an auth stream error; routing and the
    // current session remain available from the repository/client.
  });
});

/// Reactive session provider. Auth events invalidate dependent financial
/// features so logout/login and session restoration use the correct account.
final currentSessionProvider = Provider<Session?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(supabaseAuthRepositoryProvider).session;
});

/// Reactive user provider. Any auth event causes dependent user-scoped
/// features to rebuild against the currently authenticated user.
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(supabaseAuthRepositoryProvider).currentUser;
});
