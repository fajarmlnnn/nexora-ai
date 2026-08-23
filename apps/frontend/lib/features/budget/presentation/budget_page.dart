import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nexora/nexora.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../dashboard/models/budget_item.dart';
import '../../dashboard/models/transaction_model.dart';
import '../controllers/budget_controller.dart';
import 'add_budget_sheet.dart';

class BudgetPage extends ConsumerWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetItemsProvider);
    final now = DateTime.now();
    final periodLabel = _formatBudgetPeriod(now);

    return NexoraScaffold(
      appBar: NexoraAppBar(
        title: 'Anggaran',
        subtitle: 'Ringkasan $periodLabel',
        actions: [
          NexoraIconButton(
            icon: LucideIcons.plus,
            tooltip: 'Tambah anggaran',
            onPressed: () => showAddBudgetSheet(context, ref),
          ),
        ],
      ),
      body: budgetsAsync.when(
        loading: () => ListView(
          padding: AppSpacing.screen,
          children: const [
            NexoraSkeleton(width: 180, height: 32),
            SizedBox(height: AppSpacing.lg),
            NexoraSkeleton(height: 190),
            SizedBox(height: AppSpacing.lg),
            NexoraSkeleton(height: 330),
          ],
        ),
        error: (error, stackTrace) => Padding(
          padding: AppSpacing.screen,
          child: NexoraEmpty(
            error: true,
            icon: LucideIcons.triangleAlert,
            title: 'Anggaran belum tersedia',
            reason: 'Data anggaran gagal dimuat. Coba lagi.',
            onPressed: () => ref.read(budgetItemsProvider.notifier).retry(),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Padding(
              padding: AppSpacing.screen,
              child: NexoraEmpty(
                icon: LucideIcons.wallet,
                title: 'Belum ada anggaran',
                reason: 'Buat anggaran per kategori. Pengeluaran dihitung dari transaksi bulan ini.',
                ctaLabel: 'Tambah anggaran',
                onPressed: () => showAddBudgetSheet(context, ref),
              ),
            );
          }
          return ListView(
            padding: AppSpacing.screen,
            children: [
              _BudgetOverview(items: items),
              const SizedBox(height: AppSpacing.lg),
              const NexoraSectionHeader(title: 'Semua kategori'),
              const SizedBox(height: AppSpacing.sm),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _BudgetRow(
                    item: item,
                    onDelete: () async {
                      final confirmed = await NexoraDialog.confirm(
                        context,
                        title: 'Hapus anggaran?',
                        message: 'Hapus anggaran ${item.name}?',
                        confirmLabel: 'Hapus',
                        danger: true,
                      );
                      if (!confirmed) return;
                      await ref.read(budgetItemsProvider.notifier).deleteBudget(item.id);
                    },
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              NexoraBanner(
                title: 'Analisis',
                message: _insight(items),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _formatBudgetPeriod(DateTime date) {
  const months = <String>[
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

String _insight(List<BudgetItem> items) {
  final over = items.where((item) => item.isOverBudget).toList();
  if (over.isEmpty) {
    return 'Semua kategori masih dalam batas. Pengeluaran dihitung dari transaksi bulan ini.';
  }
  return '${over.length} kategori melebihi batas. Prioritaskan ${over.first.name} sebelum menambah pengeluaran baru.';
}

class _BudgetOverview extends StatelessWidget {
  const _BudgetOverview({required this.items});
  final List<BudgetItem> items;

  @override
  Widget build(BuildContext context) {
    final totalLimit = items.fold<double>(0, (sum, item) => sum + item.limit);
    final totalSpent = items.fold<double>(0, (sum, item) => sum + item.spent);
    final remaining = totalLimit - totalSpent;
    final isOver = remaining < 0;
    final progress = totalLimit <= 0 ? 0.0 : (totalSpent / totalLimit).clamp(0.0, 1.0);

    return NexoraSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Anggaran bulan ini', style: AppTypography.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(rupiah(totalLimit), style: AppTypography.heroAmount),
          const SizedBox(height: AppSpacing.md),
          NexoraProgress(value: progress, color: isOver ? AppColors.danger : AppColors.brand),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: Text('Terpakai ${rupiah(totalSpent)}', style: AppTypography.caption)),
              Text(isOver ? 'Over ${rupiah(remaining.abs())}' : 'Sisa ${rupiah(remaining)}', style: AppTypography.caption.copyWith(color: isOver ? AppColors.danger : AppColors.success)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.item, required this.onDelete});
  final BudgetItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = item.isOverBudget ? AppColors.danger : AppColors.brand;
    return NexoraSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(item.name, style: AppTypography.labelLarge)),
              NexoraIconButton(icon: LucideIcons.trash2, tooltip: 'Hapus ${item.name}', onPressed: onDelete),
            ],
          ),
          Text('${item.category.labelId} • ${rupiah(item.spent)} / ${rupiah(item.limit)}', style: AppTypography.caption),
          const SizedBox(height: AppSpacing.sm),
          NexoraProgress(value: item.progress, color: accent),
          if (item.isOverBudget) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('Melebihi anggaran ${rupiah(item.spent - item.limit)}', style: AppTypography.caption.copyWith(color: AppColors.danger)),
          ],
        ],
      ),
    );
  }
}
