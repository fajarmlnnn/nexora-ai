import 'package:supabase_flutter/supabase_flutter.dart';

/// Honest display name from the authenticated profile. Never a hardcoded person.
String displayNameFor(User? user, {String fallback = 'Pengguna Nexora'}) {
  final metadataName = user?.userMetadata?['name']?.toString().trim();
  if (metadataName != null && metadataName.isNotEmpty) return metadataName;

  final fullName = user?.userMetadata?['full_name']?.toString().trim();
  if (fullName != null && fullName.isNotEmpty) return fullName;

  final email = user?.email?.trim();
  if (email != null && email.contains('@')) {
    final local = email.split('@').first.trim();
    if (local.isNotEmpty) return local;
  }

  return fallback;
}

String greetingForNow(DateTime now) {
  final hour = now.hour;
  if (hour < 11) return 'Selamat pagi';
  if (hour < 15) return 'Selamat siang';
  if (hour < 18) return 'Selamat sore';
  return 'Selamat malam';
}
