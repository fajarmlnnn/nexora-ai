import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nexora/nexora.dart';
import '../../../core/widgets/nexora_mascot.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _completeSplash();
  }

  Future<void> _completeSplash() async {
    await Future<void>.delayed(AppMotion.slow);
    if (!mounted) return;

    final hasSession = SupabaseConfig.isConfigured && NexoraSupabase.client.auth.currentSession != null;
    if (hasSession) {
      context.go('/');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool('nexora_onboarded') ?? false;
    if (!mounted) return;
    context.go(onboarded ? '/auth?redirect=%2F' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return NexoraScaffold(
      safeArea: false,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const NexoraMascot(size: 180, state: NexoraMascotState.welcome),
            const SizedBox(height: AppSpacing.lg),
            Text('NEXORA', style: AppTypography.displayLarge.copyWith(letterSpacing: 6)),
            const SizedBox(height: AppSpacing.xs),
            Text('Asisten keuangan personal', style: AppTypography.bodySmall),
          ],
        ),
      ),
    );
  }
}
