import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
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
      title: 'Halo, Fajar! 👋',
      message:
          'Aku Nexora AI, siap membantumu mengelola keuanganmu setiap hari.',
      icon: LucideIcons.sparkles,
    ),
    _OnboardingData(
      title: 'AI yang bekerja untuk keuanganmu',
      message:
          'Nexora AI menganalisis transaksi, menemukan pola, dan memberi insight terbaik untukmu.',
      icon: LucideIcons.chartNoAxesCombined,
    ),
    _OnboardingData(
      title: 'Aman & Privasi Terjamin',
      message:
          'Data keuanganmu aman dengan enkripsi tingkat tinggi dan hanya kamu yang memiliki akses.',
      icon: LucideIcons.shieldCheck,
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
        padding: AppSpacing.screen,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _finish, child: const Text('Skip')),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var dot = 0; dot < _pages.length; dot++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.all(4),
                    width: _index == dot ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _index == dot
                          ? AppColors.primary
                          : AppColors.border,
                      borderRadius: AppRadius.radiusLG,
                    ),
                  ),
              ],
            ),
            AppSpacing.gapLG,
            FilledButton(
              onPressed: () {
                if (_index == _pages.length - 1) {
                  _finish();
                } else {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                  );
                }
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                padding: const EdgeInsets.all(18),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXL),
              ),
              child: Text(_index == _pages.length - 1 ? 'Get Started' : 'Next'),
            ),
            AppSpacing.gapLG,
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
      duration: const Duration(milliseconds: 350),
      child: Column(
        key: ValueKey(data.title),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: .35),
                      blurRadius: 80,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
              if (data.icon == LucideIcons.sparkles)
                const NexoraRobot(size: 218)
              else
                Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: AppRadius.radiusXXL,
                  ),
                  child: Icon(data.icon, size: 96, color: Colors.white),
                ),
            ],
          ),
          AppSpacing.gapLG,
          Text(
            data.title,
            style: AppTypography.heading1,
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapSM,
          Text(
            data.message,
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;
}
