import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';

/// Visual plan selector. Billing remains disconnected until pricing and a
/// payment provider are finalized.
class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  bool _annual = true;

  @override
  Widget build(BuildContext context) {
    final price = _annual ? 'Rp249.000' : 'Rp29.000';
    final period = _annual ? '/ tahun' : '/ bulan';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          Positioned(
            top: -130,
            left: -100,
            child: _Glow(color: AppColors.brandPrimary.withValues(alpha: .22)),
          ),
          Positioned(
            bottom: -170,
            right: -100,
            child: _Glow(color: AppColors.info.withValues(alpha: .12)),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                  child: Row(
                    children: [
                      _HeaderButton(
                        icon: LucideIcons.x,
                        onTap: () => context.pop(),
                        label: 'Close plans',
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceGlass,
                          borderRadius: AppRadius.radiusPill,
                          border: Border.all(color: AppColors.borderGlass),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.crown, size: 14, color: AppColors.warning),
                            const SizedBox(width: 6),
                            Text(
                              'NEXORA PRO',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFFB58D),
                                AppColors.brandPrimaryBright,
                                AppColors.info,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.brandPrimary.withValues(alpha: .28),
                                blurRadius: 28,
                                spreadRadius: -3,
                              ),
                            ],
                          ),
                          child: const Icon(LucideIcons.sparkles, size: 27, color: Colors.white),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Choose the Plan\nThat Fits You',
                          textAlign: TextAlign.center,
                          style: AppTypography.heading1.copyWith(
                            fontSize: 28,
                            height: 1.12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Bawa kebiasaan finansialmu ke level berikutnya dengan insight AI yang lebih dalam.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.space800,
                            borderRadius: AppRadius.radiusPill,
                            border: Border.all(color: AppColors.borderGlass),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _BillingChoice(
                                  label: 'Monthly',
                                  selected: !_annual,
                                  onTap: () => setState(() => _annual = false),
                                ),
                              ),
                              Expanded(
                                child: _BillingChoice(
                                  label: 'Annually',
                                  selected: _annual,
                                  onTap: () => setState(() => _annual = true),
                                  badge: 'SAVE 28%',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(1.4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFFB58D),
                                AppColors.brandPrimaryBright,
                                AppColors.info,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(29),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.brandPrimary.withValues(alpha: .18),
                                blurRadius: 28,
                                spreadRadius: -6,
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D0D14),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: Colors.white.withValues(alpha: .06)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 35,
                                      height: 35,
                                      decoration: BoxDecoration(
                                        color: AppColors.brandPrimary.withValues(alpha: .18),
                                        borderRadius: AppRadius.radiusMD,
                                      ),
                                      child: const Icon(LucideIcons.crown, size: 18, color: AppColors.brandPrimaryBright),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Pro Plan',
                                        style: AppTypography.heading3.copyWith(fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceGlassStrong,
                                        borderRadius: AppRadius.radiusPill,
                                        border: Border.all(color: AppColors.borderGlass),
                                      ),
                                      child: Text(
                                        'PREVIEW',
                                        style: AppTypography.caption.copyWith(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: .8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          price,
                                          style: AppTypography.heading1.copyWith(
                                            fontSize: 31,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -1,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 5),
                                      child: Text(
                                        period,
                                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_annual) ...[
                                  const SizedBox(height: 5),
                                  Text(
                                    'Setara Rp20.750 / bulan',
                                    style: AppTypography.caption.copyWith(color: AppColors.info, fontWeight: FontWeight.w700),
                                  ),
                                ],
                                const SizedBox(height: 7),
                                Text(
                                  'Harga simulasi untuk preview UI; belum ada tagihan yang dibuat.',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textMuted,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const _PlanFeature(text: 'Insight AI keuangan yang lebih mendalam'),
                                const _PlanFeature(text: 'Analisis cashflow dan pola pengeluaran'),
                                const _PlanFeature(text: 'Strategi target tabungan yang dipersonalisasi'),
                                const _PlanFeature(text: 'Ringkasan bulanan dan rekomendasi aksi'),
                                const _PlanFeature(text: 'Pengalaman bebas gangguan'),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFFB58D),
                                          AppColors.brandPrimary,
                                          AppColors.info,
                                        ],
                                      ),
                                      borderRadius: AppRadius.radiusPill,
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _showPreviewNotice,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(vertical: 15),
                                        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusPill),
                                      ),
                                      child: const Text(
                                        'Explore Pro',
                                        style: TextStyle(fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'Kamu tetap bisa memakai fitur dasar Nexora secara gratis.',
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(color: AppColors.textMuted, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPreviewNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paket Pro masih berupa preview. Belum ada pembayaran yang diproses.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _BillingChoice extends StatelessWidget {
  const _BillingChoice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFF4F1FC) : Colors.transparent,
      borderRadius: AppRadius.radiusPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusPill,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: selected ? const Color(0xFF181323) : AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 5),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFE3D8FF) : AppColors.surfaceGlassStrong,
                      borderRadius: AppRadius.radiusPill,
                    ),
                    child: Text(
                      badge!,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: selected ? AppColors.brandPrimaryDeep : AppColors.textSecondary,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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

class _PlanFeature extends StatelessWidget {
  const _PlanFeature({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.check, size: 16, color: AppColors.textPrimary),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap, required this.label});
  final IconData icon;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: Material(
        color: AppColors.surfaceGlass,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, color: AppColors.textPrimary, size: 19),
          ),
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 310,
        height: 310,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 90, spreadRadius: 24),
          ],
        ),
      ),
    );
  }
}
