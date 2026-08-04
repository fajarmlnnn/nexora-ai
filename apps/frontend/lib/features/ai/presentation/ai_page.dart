import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';

class AIPage extends StatelessWidget {
  const AIPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      bottomPadding: false,
      child: ListView(
        padding: AppSpacing.screen.copyWith(bottom: 24),
        children: [
          Row(
            children: [
              BackButton(color: AppColors.textPrimary, onPressed: () => Navigator.maybePop(context)),
              const Spacer(),
              Text('AI Assistant', style: AppTypography.heading2),
              const Spacer(),
              const SizedBox(width: 48),
            ],
          ),
          AppSpacing.gapLG,
          PremiumCard(
            gradient: AppGradients.primary,
            child: Column(
              children: [
                const Icon(LucideIcons.bot, size: 76, color: Colors.white),
                AppSpacing.gapSM,
                Text('Hai, Fajar! 👋', style: AppTypography.heading2),
                Text(
                  'Aku Nexora AI, siap membaca pola uangmu dan memberi rekomendasi personal.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          AppSpacing.gapLG,
          const SectionHeader('Suggested prompts'),
          AppSpacing.gapMD,
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _PromptChip('Bisakah hemat Rp 500.000?'),
              _PromptChip('Budget makan hampir habis?'),
              _PromptChip('Analisis cashflow Mei'),
              _PromptChip('Prioritaskan cicilan'),
            ],
          ),
          AppSpacing.gapLG,
          const SectionHeader('Conversation history'),
          AppSpacing.gapMD,
          const _Bubble(
            text: 'Pengeluaran naik 20% dibanding bulan lalu.',
            icon: LucideIcons.trendingUp,
            color: AppColors.danger,
          ),
          const _Bubble(
            text: 'Budget makan hampir habis. Sisa Rp 380.000 (76%).',
            icon: LucideIcons.utensils,
            color: AppColors.warning,
          ),
          const _Bubble(
            text: 'Kamu bisa menabung Rp 500.000 lebih cepat jika kurangi makan di luar 4 kali.',
            icon: LucideIcons.shieldCheck,
            color: AppColors.success,
          ),
          AppSpacing.gapMD,
          PremiumCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            borderRadius: AppRadius.radiusXL,
            child: Row(
              children: [
                Expanded(child: Text('Tanya apa saja...', style: AppTypography.bodySmall)),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(gradient: AppGradients.button, borderRadius: AppRadius.radiusLG),
                  child: const Icon(LucideIcons.sendHorizontal, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: AppColors.card,
      labelStyle: AppTypography.caption.copyWith(color: AppColors.textPrimary),
      side: const BorderSide(color: AppColors.border),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.icon, required this.color});

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PremiumCard(
        borderRadius: AppRadius.radiusXL,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            PremiumIconBadge(icon: icon, color: color, size: 42),
            AppSpacing.hGapMD,
            Expanded(child: Text(text, style: AppTypography.bodySmall)),
          ],
        ),
      ),
    );
  }
}
