import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  bool _annualBilling = true;

  static const _features = <String>[
    'AI insight untuk pola pemasukan dan pengeluaran',
    'Analisis budget dan rekomendasi personal',
    'Pantauan target tabungan yang lebih mendalam',
    'Laporan finansial dan ekspor data',
    'Prioritas akses ke fitur baru',
  ];

  void _showPreviewNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Halaman ini masih preview. Pembayaran Nexora Pro belum diaktifkan.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          Positioned(
            top: -105,
            right: -90,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandPrimary.withValues(alpha: .075),
              ),
            ),
          ),
          Positioned(
            bottom: 90,
            left: -150,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.info.withValues(alpha: .045),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    _topBar(context),
                    const SizedBox(height: 24),
                    Center(
                      child: Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.brandPrimary.withValues(alpha: .08),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandPrimary.withValues(alpha: .22),
                              blurRadius: 38,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: SvgPicture.asset(
                          'assets/mascot/nexora_n_orb.svg',
                          fit: BoxFit.contain,
                          semanticsLabel: 'Nexora N Orb',
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Choose the Plan\nThat Fits You',
                      textAlign: TextAlign.center,
                      style: AppTypography.heading1.copyWith(
                        fontSize: 27,
                        height: 1.14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Make every money decision more intentional with Nexora AI.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _billingToggle(),
                    const SizedBox(height: 18),
                    _planCard(),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .025),
                        borderRadius: AppRadius.radiusLG,
                        border: Border.all(
                          color: AppColors.borderGlass.withValues(alpha: .7),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            LucideIcons.info,
                            size: 17,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'Preview only. Harga final, paket berlangganan, dan pembayaran akan diaktifkan setelah backend subscription siap.',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Row(
      children: [
        _circleAction(
          icon: LucideIcons.arrowLeft,
          label: 'Kembali',
          onTap: () => context.pop(),
        ),
        const Spacer(),
        Text(
          'NEXORA PRO',
          style: AppTypography.overline.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 42,
          child: TextButton(
            onPressed: _showPreviewNotice,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: AppColors.textSecondary,
              textStyle: AppTypography.caption,
            ),
            child: const Text('Help'),
          ),
        ),
      ],
    );
  }

  Widget _circleAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.white.withValues(alpha: .04),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, size: 19, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _billingToggle() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .045),
          borderRadius: AppRadius.radiusPill,
          border: Border.all(color: AppColors.borderGlass),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BillingOption(
              label: 'Monthly',
              selected: !_annualBilling,
              onTap: () => setState(() => _annualBilling = false),
            ),
            _BillingOption(
              label: 'Annually',
              trailing: 'SAVE',
              selected: _annualBilling,
              onTap: () => setState(() => _annualBilling = true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planCard() {
    return Container(
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        borderRadius: AppRadius.radiusXXL,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF9A75),
            Color(0xFF8B5CF6),
            Color(0xFF38BDF8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPrimary.withValues(alpha: .17),
            blurRadius: 28,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(19, 20, 19, 18),
        decoration: BoxDecoration(
          borderRadius: AppRadius.radiusXXL,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF171426), Color(0xFF0B0A13), Color(0xFF080910)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brandPrimary.withValues(alpha: .18),
                  ),
                  child: const Icon(
                    LucideIcons.crown,
                    size: 17,
                    color: Color(0xFFD8CCFF),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Nexora Pro',
                    style: AppTypography.heading3.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: .10),
                    borderRadius: AppRadius.radiusPill,
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: .22),
                    ),
                  ),
                  child: Text(
                    'PREVIEW',
                    style: AppTypography.overline.copyWith(
                      color: AppColors.info,
                      fontSize: 9,
                      letterSpacing: .7,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _annualBilling ? 'Annual plan' : 'Monthly plan',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pricing to be announced',
              style: AppTypography.heading2.copyWith(
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _annualBilling
                  ? 'Annual billing will be available at launch.'
                  : 'Monthly billing will be available at launch.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Divider(color: Colors.white.withValues(alpha: .09), height: 1),
            const SizedBox(height: 16),
            for (final feature in _features) ...[
              _FeatureRow(label: feature),
              const SizedBox(height: 13),
            ],
            const SizedBox(height: 7),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _showPreviewNotice,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusLG,
                  ),
                ).copyWith(
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (states) => Colors.transparent,
                  ),
                  overlayColor: WidgetStatePropertyAll(
                    Colors.white.withValues(alpha: .09),
                  ),
                ),
                child: Ink(
                  decoration: const BoxDecoration(
                    borderRadius: AppRadius.radiusLG,
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFFF9A75),
                        Color(0xFF9B6BFA),
                        Color(0xFF428DFA),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Center(
                      child: Text(
                        'Explore Nexora Pro',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 11),
            Center(
              child: Text(
                'No payment will be taken in this preview.',
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillingOption extends StatelessWidget {
  const _BillingOption({
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final bool selected;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: AppRadius.radiusPill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: selected ? AppColors.canvas : AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                Text(
                  trailing!,
                  style: AppTypography.overline.copyWith(
                    color: selected ? AppColors.brandPrimaryDeep : AppColors.info,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          LucideIcons.check,
          size: 17,
          color: AppColors.success,
        ),
        AppSpacing.hGapSM,
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: .9),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
