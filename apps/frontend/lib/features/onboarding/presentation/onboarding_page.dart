import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/nexora_brand.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nexora_mascot.dart';
import '../../../core/widgets/premium_widgets.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _index = 0;

  static const _pages = [
    _OnboardingData(
      eyebrow: 'WELCOME TO NEXORA',
      title: 'Kenali ke mana\nuangmu pergi.',
      message:
          'Satu tempat untuk memahami kondisi finansialmu dengan lebih sederhana.',
      mascot: NexoraMascotState.welcome,
    ),
    _OnboardingData(
      eyebrow: 'NEXORA INTELLIGENCE',
      title: 'Biarkan AI\nmenemukan polanya.',
      message:
          'Nexora menganalisis transaksi, cashflow, dan tujuanmu untuk menemukan insight yang berguna.',
      mascot: NexoraMascotState.analyzing,
    ),
    _OnboardingData(
      eyebrow: 'PRIVATE BY DESIGN',
      title: 'Bangun masa depan\nfinansialmu.',
      message:
          'Data finansial tetap berada dalam kendalimu, sementara Nexora membantu kamu mengambil keputusan dengan lebih percaya diri.',
      mascot: NexoraMascotState.security,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('nexora_onboarded', true);
    if (mounted) {
      context.go('/auth?redirect=%2F');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      bottomPadding: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'NEXORA',
                  style: AppTypography.labelLarge.copyWith(
                    letterSpacing: 2.4,
                    color: Colors.white.withValues(alpha: .9),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Skip',
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white.withValues(alpha: .58),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) =>
                    _OnboardingSlide(data: _pages[index]),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      for (var dot = 0; dot < _pages.length; dot++)
                        AnimatedContainer(
                          duration: AppMotion.normal,
                          margin: const EdgeInsets.only(right: 7),
                          width: _index == dot ? 30 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            gradient: _index == dot
                                ? NexoraBrand.primaryGradient
                                : null,
                            color: _index == dot
                                ? null
                                : NexoraBrand.glassBorder,
                            borderRadius: AppRadius.radiusPill,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${_index + 1}/${_pages.length}',
                  style: AppTypography.caption,
                ),
              ],
            ),
            AppSpacing.gapLG,
            SizedBox(
              width: double.infinity,
              height: 58,
              child: FilledButton(
                onPressed: () {
                  if (_index == _pages.length - 1) {
                    _finish();
                  } else {
                    _pageController.nextPage(
                      duration: AppMotion.page,
                      curve: AppMotion.standard,
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusXL,
                  ),
                ),
                child: Text(
                  _index == _pages.length - 1 ? 'Mulai bersama Nexora' : 'Lanjut',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.data});

  final _OnboardingData data;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.page,
      switchInCurve: AppMotion.standard,
      child: Column(
        key: ValueKey(data.title),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 286,
            height: 330,
            decoration: BoxDecoration(
              borderRadius: AppRadius.radiusXXL,
              gradient: NexoraBrand.glass,
              border: Border.all(color: NexoraBrand.glassBorder),
              boxShadow: NexoraBrand.cardGlow,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 32,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          NexoraBrand.aiPrimary.withValues(alpha: .22),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                NexoraMascot(
                  size: 220,
                  state: data.mascot,
                ),
                Positioned(
                  bottom: 24,
                  child: _StateChip(state: data.mascot),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            data.eyebrow,
            style: AppTypography.overline.copyWith(
              color: NexoraBrand.aiPrimary,
              letterSpacing: 2.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            data.title,
            style: AppTypography.heading1.copyWith(fontSize: 29),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            data.message,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: .66),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.state});
  final NexoraMascotState state;

  @override
  Widget build(BuildContext context) {
    final label = switch (state) {
      NexoraMascotState.welcome => 'WELCOME',
      NexoraMascotState.analyzing => 'ANALYZING',
      NexoraMascotState.security => 'PROTECTED',
      _ => 'NEXORA',
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .38),
        borderRadius: AppRadius.radiusPill,
        border: Border.all(color: NexoraBrand.glassBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Text(
          label,
          style: AppTypography.overline.copyWith(
            color: Colors.white.withValues(alpha: .72),
            letterSpacing: 1.6,
          ),
        ),
      ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.eyebrow,
    required this.title,
    required this.message,
    required this.mascot,
  });

  final String eyebrow;
  final String title;
  final String message;
  final NexoraMascotState mascot;
}
