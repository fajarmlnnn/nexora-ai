import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..forward();

  @override
  void initState() {
    super.initState();
    _completeSplash();
  }

  Future<void> _completeSplash() async {
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool('nexora_onboarded') ?? false;
    if (mounted) context.go(onboarded ? '/' : '/onboarding');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF050815), Color(0xFF161044), AppColors.background],
              ),
            ),
            child: Stack(
              children: [
                for (var index = 0; index < 18; index++)
                  Positioned(
                    left: (index * 37) % MediaQuery.sizeOf(context).width,
                    top: 80 + math.sin(_controller.value * 6 + index) * 40 + index * 28,
                    child: Opacity(
                      opacity: .15 + .35 * _controller.value,
                      child: const Icon(Icons.auto_awesome, color: AppColors.primaryLight, size: 12),
                    ),
                  ),
                Center(
                  child: FadeTransition(
                    opacity: _controller,
                    child: ScaleTransition(
                      scale: Tween(begin: .82, end: 1.0).animate(
                        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const NexoraRobot(size: 178),
                          const SizedBox(height: 18),
                          Text('NEXORA', style: AppTypography.heading1.copyWith(fontSize: 38, letterSpacing: 9)),
                          const SizedBox(height: 8),
                          Text('YOUR PERSONAL FINANCE AI', style: AppTypography.caption.copyWith(letterSpacing: 3, color: Colors.white70)),
                          const SizedBox(height: 22),
                          Text(
                            'AI yang memahami keuanganmu.\nBukan hanya mencatatnya.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
