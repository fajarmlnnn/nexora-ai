import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nexora_mascot.dart';
import '../../../core/widgets/premium_widgets.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.page,
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
    if (mounted) {
      context.go(onboarded ? '/auth?redirect=%2F' : '/onboarding');
    }
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
        builder: (context, _) => Stack(
          fit: StackFit.expand,
          children: [
            const PremiumBackground(),
            IgnorePointer(
              child: CustomPaint(
                painter: _SplashParticles(progress: _controller.value),
              ),
            ),
            Center(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _controller,
                  curve: Curves.easeOut,
                ),
                child: ScaleTransition(
                  scale: Tween(begin: .88, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const NexoraMascot(
                        size: 190,
                        state: NexoraMascotState.welcome,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'NEXORA',
                        style: AppTypography.displaySmall.copyWith(
                          fontSize: 36,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'YOUR PERSONAL FINANCE AI',
                        style: AppTypography.overline.copyWith(
                          letterSpacing: 3.2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Understand your money.\nBuild your future.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: .72),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 32,
              right: 32,
              bottom: 58,
              child: Column(
                children: [
                  Text(
                    'Preparing your Nexora space',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: .48),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      value: _controller.value,
                      backgroundColor: Colors.white.withValues(alpha: .08),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'NEXORA AI',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      letterSpacing: 2.4,
                      color: Colors.white.withValues(alpha: .28),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashParticles extends CustomPainter {
  const _SplashParticles({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < 26; i++) {
      final x = ((i * 71) % 100) / 100 * size.width;
      final baseY = ((i * 43) % 100) / 100 * size.height;
      final y = baseY + math.sin(progress * math.pi * 2 + i) * 18;
      paint.color = Colors.white.withValues(
        alpha: (.08 + (i % 4) * .035) * progress,
      );
      canvas.drawCircle(Offset(x, y), 1.0 + (i % 3) * .7, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashParticles oldDelegate) =>
      oldDelegate.progress != progress;
}
