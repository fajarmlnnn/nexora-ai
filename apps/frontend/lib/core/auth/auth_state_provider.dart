import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_auth_repository.dart';

final supabaseAuthRepositoryProvider = Provider<SupabaseAuthRepository>((ref) {
  return SupabaseAuthRepository();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final repository = ref.watch(supabaseAuthRepositoryProvider);
  return repository.authStateChanges.handleError((Object _, StackTrace __) {});
});

final currentSessionProvider = Provider<Session?>((ref) {
  return ref.watch(supabaseAuthRepositoryProvider).session;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(supabaseAuthRepositoryProvider).currentUser;
});
