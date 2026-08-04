import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..forward();

  @override
  void initState() {
    super.initState();
    _completeSplash();
  }

  Future<void> _completeSplash() async {
    await Future<void>.delayed(const Duration(seconds: 2));
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
                          Container(
                            width: 118,
                            height: 118,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: .65),
                                  blurRadius: 80,
                                  spreadRadius: 18,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.hexagon, color: Colors.white, size: 92),
                          ),
                          const SizedBox(height: 22),
                          Text('NEXORA', style: AppTypography.heading1.copyWith(fontSize: 36, letterSpacing: 2)),
                          Text('Your Personal Finance AI', style: AppTypography.bodyMedium),
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
