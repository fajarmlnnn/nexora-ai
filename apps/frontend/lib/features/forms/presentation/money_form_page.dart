import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';

class MoneyFormPage extends StatelessWidget {
  const MoneyFormPage({super.key, required this.income});

  final bool income;

  @override
  Widget build(BuildContext context) {
    final accent = income ? AppColors.success : AppColors.danger;
    final title = income ? 'Tambah Pemasukan' : 'Tambah Pengeluaran';

    return PremiumScaffold(
      bottomPadding: false,
      child: ListView(
        padding: AppSpacing.screen,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: BackButton(color: Colors.white, onPressed: () => Navigator.pop(context)),
          ),
          Hero(
            tag: income ? 'income-action' : 'expense-action',
            child: Icon(
              income ? LucideIcons.arrowUpCircle : LucideIcons.arrowDownCircle,
              color: accent,
              size: 92,
            ),
          ),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: AppTypography.heading1),
          Text(
            income ? 'Catat pemasukan agar cashflow selalu akurat.' : 'Catat pengeluaran sebelum budget bocor.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
          AppSpacing.gapLG,
          _FormFieldCard(label: 'Jumlah', value: income ? 'Rp 15.000.000' : 'Rp 35.000'),
          _FormFieldCard(label: 'Kategori', value: income ? 'Gaji' : 'Makan & Minum'),
          const _FormFieldCard(label: 'Tanggal', value: '26 Mei 2024'),
          const _FormFieldCard(label: 'Catatan (Opsional)', value: 'Tambahkan catatan'),
          const _FormFieldCard(label: 'Metode', value: 'E-Wallet'),
          AppSpacing.gapMD,
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              padding: const EdgeInsets.all(18),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXL),
            ),
            child: Text(income ? 'Simpan Pemasukan' : 'Simpan Pengeluaran'),
          ),
        ],
      ),
    );
  }
}

class _FormFieldCard extends StatelessWidget {
  const _FormFieldCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: PremiumCard(
        borderRadius: AppRadius.radiusXL,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.caption),
                  const SizedBox(height: 4),
                  Text(value, style: AppTypography.labelLarge),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronDown, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
