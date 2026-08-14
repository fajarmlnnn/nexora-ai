import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../dashboard/controllers/financial_overview_controller.dart';

class GoalDetailPage extends ConsumerWidget {
  const GoalDetailPage({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(financialGoalsProvider).cast<FinancialGoalSnapshot?>().firstWhere(
      (item) => item?.id == goalId,
      orElse: () => null,
    );

    if (goal == null) {
      return PremiumScaffold(
        child: Center(child: Text('Goal tidak ditemukan', style: AppTypography.heading3)),
      );
    }

    final progress = goal.progress;
    final remaining = goal.remaining;
    final completed = goal.isCompleted;
    final suggestedTopUp = completed ? (goal.target * .25).clamp(100000.0, double.infinity) : remaining;

    return PremiumScaffold(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: AppSpacing.screen.copyWith(bottom: AppSpacing.bottomNav(context) + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.arrowLeft),
                  tooltip: 'Kembali',
                ),
                Expanded(child: Text(goal.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.heading2)),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenu(context, ref, goal, value),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'increase', child: Text('Naikkan target')),
                    PopupMenuItem(value: 'delete', child: Text('Hapus goal')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            PremiumCard(
              padding: const EdgeInsets.all(18),
              borderRadius: AppRadius.radiusXL,
              child: Column(
                children: [
                  SizedBox(
                    width: 142,
                    height: 142,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 11,
                          backgroundColor: AppColors.border.withValues(alpha: .35),
                          valueColor: AlwaysStoppedAnimation<Color>(completed ? AppColors.success : AppColors.primaryLight),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${(progress * 100).round()}%', style: AppTypography.heading1.copyWith(fontSize: 26)),
                            Text(completed ? 'Tercapai' : 'Progress', style: AppTypography.caption),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(rupiah(goal.saved), style: AppTypography.currency.copyWith(fontSize: 23, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text('dari target ${rupiah(goal.target)}', style: AppTypography.bodySmall),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: (completed ? AppColors.success : AppColors.primary).withValues(alpha: .08),
                      borderRadius: AppRadius.radiusLG,
                      border: Border.all(color: (completed ? AppColors.success : AppColors.primary).withValues(alpha: .15)),
                    ),
                    child: Row(
                      children: [
                        Icon(completed ? LucideIcons.badgeCheck : LucideIcons.flag, size: 18, color: completed ? AppColors.success : AppColors.primaryLight),
                        const SizedBox(width: 9),
                        Expanded(child: Text(completed ? 'Target tercapai. Goal ini tidak perlu dibuat ulang.' : 'Sisa target: ${rupiah(remaining)}', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _AIPlannerCard(
              goal: goal,
              completed: completed,
              suggestedTopUp: suggestedTopUp,
              onTopUp: () => _showContribution(context, ref, goal, completed ? suggestedTopUp : remaining),
              onIncreaseTarget: () => _increaseTarget(context, ref, goal, suggestedTopUp),
            ),
            const SizedBox(height: 10),
            _DetailStats(goal: goal),
            const SizedBox(height: 10),
            _QuickActions(goal: goal),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMenu(BuildContext context, WidgetRef ref, FinancialGoalSnapshot goal, String value) async {
    if (value == 'increase') {
      await _increaseTarget(context, ref, goal, (goal.target * .25).clamp(100000.0, double.infinity));
      return;
    }
    if (value == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Hapus goal?'),
          content: Text('Goal "${goal.title}" akan dihapus dari daftar.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
          ],
        ),
      );
      if (confirmed == true) {
        await ref.read(financialGoalsProvider.notifier).removeGoal(goal.id);
        if (context.mounted) Navigator.pop(context);
      }
    }
  }

  Future<void> _increaseTarget(BuildContext context, WidgetRef ref, FinancialGoalSnapshot goal, double suggested) async {
    final controller = TextEditingController(text: suggested.round().toString());
    final amount = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah target goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Nominal tambahan'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.replaceAll('.', '').replaceAll(',', ''));
              Navigator.pop(context, value);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount == null || amount <= 0) return;
    final ok = await ref.read(financialGoalsProvider.notifier).updateGoal(
      goal.id,
      target: goal.target + amount,
    );
    if (context.mounted && ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Target ${goal.title} ditambah ${rupiah(amount)}.')));
    }
  }

  Future<void> _showContribution(BuildContext context, WidgetRef ref, FinancialGoalSnapshot goal, double suggested) async {
    if (goal.isCompleted) {
      await _increaseTarget(context, ref, goal, suggested);
      return;
    }
    final controller = TextEditingController(text: suggested.round().toString());
    final amount = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah dana ke goal'),
        content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nominal')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, double.tryParse(controller.text.replaceAll('.', '').replaceAll(',', ''))), child: const Text('Simpan')),
        ],
      ),
    );
    controller.dispose();
    if (amount == null || amount <= 0) return;
    final ok = await ref.read(financialGoalsProvider.notifier).contribute(goal.id, amount);
    if (context.mounted && ok) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Progress goal diperbarui.')));
  }
}

class _AIPlannerCard extends StatelessWidget {
  const _AIPlannerCard({required this.goal, required this.completed, required this.suggestedTopUp, required this.onTopUp, required this.onIncreaseTarget});
  final FinancialGoalSnapshot goal;
  final bool completed;
  final double suggestedTopUp;
  final VoidCallback onTopUp;
  final VoidCallback onIncreaseTarget;

  @override
  Widget build(BuildContext context) {
    final message = completed
        ? 'Goal ini sudah 100% tercapai. Jangan bikin goal baru dengan nama yang sama. Nexora menyarankan menambah target sebesar ${rupiah(suggestedTopUp)} lalu lanjutkan akumulasi di goal yang sama.'
        : 'Untuk mencapai ${goal.title}, kamu masih butuh ${rupiah(goal.remaining)}. Prioritaskan setoran berikutnya ke goal ini sebelum membuat target baru.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: AppRadius.radiusXL,
        boxShadow: AppShadows.glow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [const Icon(LucideIcons.sparkles, color: Colors.white, size: 18), const SizedBox(width: 7), Text('Nexora AI Goal Planner', style: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w800))]),
          const SizedBox(height: 8),
          Text(message, style: AppTypography.bodySmall.copyWith(color: Colors.white.withValues(alpha: .92), height: 1.35)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              OutlinedButton.icon(onPressed: onTopUp, icon: const Icon(LucideIcons.plus, size: 15), label: Text(completed ? 'Lanjutkan Goal' : 'Tambah Dana'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: Colors.white.withValues(alpha: .45)))),
              if (completed) OutlinedButton.icon(onPressed: onIncreaseTarget, icon: const Icon(LucideIcons.arrowUpRight, size: 15), label: const Text('Naikkan Target'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: Colors.white.withValues(alpha: .45)))),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailStats extends StatelessWidget {
  const _DetailStats({required this.goal});
  final FinancialGoalSnapshot goal;

  @override
  Widget build(BuildContext context) {
    final monthly = goal.target <= 0 ? 0 : (goal.remaining / 6).ceilToDouble();
    return Row(
      children: [
        Expanded(child: _Stat(label: 'Tersimpan', value: rupiah(goal.saved), icon: LucideIcons.walletCards)),
        const SizedBox(width: 7),
        Expanded(child: _Stat(label: 'Sisa', value: rupiah(goal.remaining), icon: LucideIcons.flag)),
        const SizedBox(width: 7),
        Expanded(child: _Stat(label: 'Saran / bln', value: rupiah(monthly), icon: LucideIcons.calendarDays)),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => PremiumCard(
    padding: const EdgeInsets.all(10),
    borderRadius: AppRadius.radiusLG,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 16, color: AppColors.primaryLight), const SizedBox(height: 6), Text(label, style: AppTypography.caption), const SizedBox(height: 2), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800))]),
  );
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions({required this.goal});
  final FinancialGoalSnapshot goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) => PremiumCard(
    padding: const EdgeInsets.all(13),
    borderRadius: AppRadius.radiusXL,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Goal controls', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 7),
      Text('Progress goal tersimpan lokal saat ini. Tahap berikutnya bisa kita hubungkan ke transaksi Supabase agar setiap setoran otomatis mengurangi saldo wallet dan menambah progress goal.', style: AppTypography.caption.copyWith(height: 1.35)),
    ]),
  );
}
