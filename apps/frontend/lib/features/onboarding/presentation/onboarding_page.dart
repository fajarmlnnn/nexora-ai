import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nexora/nexora.dart';
import '../../../core/widgets/nexora_mascot.dart';

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
      eyebrow: 'SELAMAT DATANG',
      title: 'Kenali ke mana\nuangmu pergi.',
      message: 'Satu tempat untuk mencatat wallet, transaksi, tujuan, dan anggaran.',
      mascot: NexoraMascotState.welcome,
    ),
    _OnboardingData(
      eyebrow: 'RINGKASAN',
      title: 'Pahami polanya\ndari datamu sendiri.',
      message: 'Ringkasan di beranda dihitung dari transaksi yang kamu catat, bukan dari prediksi palsu.',
      mascot: NexoraMascotState.analyzing,
    ),
    _OnboardingData(
      eyebrow: 'NEXORA AI',
      title: 'Tanya AI hanya\njika gateway aktif.',
      message: 'Nexora AI memakai gateway Laravel. Jika belum dikonfigurasi, aplikasi akan mengatakannya dengan jujur.',
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
    if (mounted) context.go('/auth?redirect=%2F');
  }

  @override
  Widget build(BuildContext context) {
    return NexoraScaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                Text('NEXORA', style: AppTypography.overline.copyWith(letterSpacing: 2.4, color: AppColors.textPrimary)),
                const Spacer(),
                TextButton(
                  onPressed: _finish,
                  child: Text('Lewati', style: AppTypography.labelMedium),
                ),
              ],
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) => _OnboardingSlide(data: _pages[index]),
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
                          margin: const EdgeInsets.only(right: AppSpacing.xs),
                          width: _index == dot ? 32 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _index == dot ? AppColors.brand : AppColors.border,
                            borderRadius: AppRadius.radiusPill,
                          ),
                        ),
                    ],
                  ),
                ),
                Text('${_index + 1}/${_pages.length}', style: AppTypography.caption),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            NexoraButton(
              label: _index == _pages.length - 1 ? 'Mulai bersama Nexora' : 'Lanjut',
              onPressed: () {
                if (_index == _pages.length - 1) {
                  _finish();
                } else {
                  _pageController.nextPage(duration: AppMotion.page, curve: AppMotion.standard);
                }
              },
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        NexoraMascot(size: 200, state: data.mascot),
        const SizedBox(height: AppSpacing.xxl),
        Text(data.eyebrow, style: AppTypography.overline.copyWith(color: AppColors.ai), textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Text(data.title, style: AppTypography.heading1, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Text(data.message, style: AppTypography.bodyMedium, textAlign: TextAlign.center),
      ],
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
