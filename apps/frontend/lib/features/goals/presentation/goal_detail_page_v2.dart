import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../wallet/controllers/wallet_controller.dart';
import '../controllers/supabase_goals_controller.dart';

class GoalDetailPageV2 extends ConsumerWidget {
  const GoalDetailPageV2({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(financialGoalsProvider);
    if (goalsAsync.isLoading && !goalsAsync.hasValue) {
      return const PremiumScaffold(child: Center(child: CircularProgressIndicator()));
    }
    final goals = goalsAsync.valueOrNull ?? const <FinancialGoalSnapshot>[];
    FinancialGoalSnapshot? goal;
    for (final item in goals) {
      if (item.id == goalId) {
        goal = item;
        break;
      }
    }

    if (goal == null) {
      return _MissingGoal(onBack: () => Navigator.maybePop(context));
    }

    final current = goal;
    final progress = current.progress.clamp(0.0, 1.0).toDouble();
    final wallet = ref.watch(primaryWalletProvider);
    final safeBalance = wallet == null
        ? 0.0
        : (wallet.balance - wallet.minimumBalance)
            .clamp(0.0, double.infinity)
            .toDouble();

    return PremiumScaffold(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background.withValues(alpha: .94),
            surfaceTintColor: Colors.transparent,
            title: Text('Goal detail', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
            leading: IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(LucideIcons.arrowLeft)),
            actions: [
              IconButton(onPressed: () => _showActions(context, ref, current), icon: const Icon(LucideIcons.moreVertical)),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverToBoxAdapter(child: _GoalHero(goal: current, progress: progress)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(child: _Metric(label: 'Tersimpan', value: rupiah(current.saved), icon: LucideIcons.walletCards)),
                  const SizedBox(width: 8),
                  Expanded(child: _Metric(label: 'Sisa', value: rupiah(current.remaining), icon: LucideIcons.flag)),
                  const SizedBox(width: 8),
                  Expanded(child: _Metric(label: '/ bulan', value: rupiah(current.suggestedMonthlyContribution), icon: LucideIcons.calendarDays)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverToBoxAdapter(child: _AIPlan(goal: current)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editName(context, ref, current),
                      icon: const Icon(LucideIcons.squarePen, size: 18),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: current.isCompleted
                          ? () => _increaseTarget(context, ref, current)
                          : () => _contribute(context, ref, current, safeBalance),
                      icon: const Icon(LucideIcons.plus),
                      label: Text(current.isCompleted ? 'Naikkan target' : 'Tambah dana'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: AppSpacing.bottomNav(context) + 28)),
        ],
      ),
    );
  }

  Future<void> _showActions(BuildContext context, WidgetRef ref, FinancialGoalSnapshot goal) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.radiusXL,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 40, child: Divider(thickness: 3)),
                ListTile(
                  leading: const Icon(LucideIcons.squarePen),
                  title: const Text('Edit nama goal'),
                  onTap: () => Navigator.pop(sheetContext, 'edit'),
                ),
                ListTile(
                  leading: const Icon(LucideIcons.arrowUpRight),
                  title: const Text('Naikkan target'),
                  onTap: () => Navigator.pop(sheetContext, 'increase'),
                ),
                ListTile(
                  leading: Icon(goal.status == 'paused' ? LucideIcons.play : LucideIcons.pause),
                  title: Text(goal.status == 'paused' ? 'Lanjutkan goal' : 'Jeda goal'),
                  onTap: () => Navigator.pop(sheetContext, 'pause'),
                ),
                ListTile(
                  leading: const Icon(LucideIcons.trash2),
                  iconColor: AppColors.danger,
                  textColor: AppColors.danger,
                  title: const Text('Hapus goal'),
                  onTap: () => Navigator.pop(sheetContext, 'delete'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!context.mounted || action == null) return;
    switch (action) {
      case 'edit':
        await _editName(context, ref, goal);
      case 'increase':
        await _increaseTarget(context, ref, goal);
      case 'pause':
        await _togglePause(context, ref, goal);
      case 'delete':
        await _delete(context, ref, goal);
    }
  }

  Future<void> _editName(BuildContext context, WidgetRef ref, FinancialGoalSnapshot goal) async {
    final controller = TextEditingController(text: goal.title);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit goal'),
          content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Nama goal')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('Simpan')),
          ],
        );
      },
    );
    controller.dispose();
    if (value?.isNotEmpty == true) {
      await ref.read(financialGoalsProvider.notifier).updateGoal(goal.id, title: value!);
    }
  }

  Future<void> _increaseTarget(BuildContext context, WidgetRef ref, FinancialGoalSnapshot goal) async {
    final controller = TextEditingController(
      text: (goal.target * .25).clamp(100000.0, double.infinity).round().toString(),
    );
    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Naikkan target'),
          content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tambahan target')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, _parseAmount(controller.text)), child: const Text('Tambah')),
          ],
        );
      },
    );
    controller.dispose();
    if (amount != null && amount > 0) {
      await ref.read(financialGoalsProvider.notifier).updateGoal(goal.id, target: goal.target + amount);
    }
  }

  Future<void> _togglePause(BuildContext context, WidgetRef ref, FinancialGoalSnapshot goal) async {
    final ok = goal.status == 'paused'
        ? await ref.read(financialGoalsProvider.notifier).resumeGoal(goal.id)
        : await ref.read(financialGoalsProvider.notifier).pauseGoal(goal.id);
    if (!context.mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(goal.status == 'paused' ? 'Goal dilanjutkan.' : 'Goal dijeda.')),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, FinancialGoalSnapshot goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus goal?'),
          content: Text(
            goal.saved > 0
                ? 'Dana ${rupiah(goal.saved)} akan diproses sesuai aturan server.'
                : 'Goal ini akan dihapus.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Hapus')),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await ref.read(financialGoalsProvider.notifier).removeGoal(goal.id);
    if (context.mounted) Navigator.maybePop(context);
  }

  Future<void> _contribute(BuildContext context, WidgetRef ref, FinancialGoalSnapshot goal, double safeBalance) async {
    if (safeBalance <= 0 || goal.remaining <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belum ada saldo aman untuk ditambahkan.')),
        );
      }
      return;
    }
    final suggested = goal.suggestedMonthlyContribution.clamp(0.0, goal.remaining).toDouble();
    final fallback = safeBalance.clamp(0.0, goal.remaining).toDouble();
    final controller = TextEditingController(
      text: (suggested > 0 ? suggested : fallback).round().toString(),
    );
    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Tambah dana'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Nominal', helperText: 'Saldo aman ${rupiah(safeBalance)}'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, _parseAmount(controller.text)), child: const Text('Simpan')),
          ],
        );
      },
    );
    controller.dispose();
    if (amount == null || amount <= 0 || amount > safeBalance) return;
    await ref.read(financialGoalsProvider.notifier).contribute(goal.id, amount);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dana berhasil ditambahkan.')),
      );
    }
  }

  static double? _parseAmount(String value) {
    return double.tryParse(value.replaceAll('.', '').replaceAll(',', '').replaceAll(' ', ''));
  }
}

class _MissingGoal extends StatelessWidget {
  const _MissingGoal({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: AppSpacing.screen,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.target, size: 48, color: AppColors.primaryLight),
                const SizedBox(height: 16),
                Text('Goal tidak ditemukan', style: AppTypography.heading3),
                const SizedBox(height: 8),
                Text(
                  'Data mungkin sudah dihapus atau belum tersinkron.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onBack,
                  icon: const Icon(LucideIcons.arrowLeft),
                  label: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalHero extends StatelessWidget {
  const _GoalHero({required this.goal, required this.progress});
  final FinancialGoalSnapshot goal;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final accent = goal.isCompleted ? AppColors.success : AppColors.primaryLight;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.surfaceElevated, AppColors.canvasElevated],
        ),
        borderRadius: AppRadius.radiusXL,
        border: Border.all(color: AppColors.primary.withValues(alpha: .25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .13),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.heading2.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      goal.type,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: .13),
                ),
                child: Icon(
                  goal.isCompleted ? LucideIcons.circleCheck : LucideIcons.target,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            rupiah(goal.saved),
            style: AppTypography.display.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'dari ${rupiah(goal.target)} target',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: AppRadius.radiusPill,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: Colors.white.withValues(alpha: .08),
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${(progress * 100).round()}%',
                style: AppTypography.labelLarge.copyWith(color: accent, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              Text(
                goal.isCompleted ? 'Goal tercapai 🎉' : 'Sisa ${rupiah(goal.remaining)}',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 13, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .72),
        borderRadius: AppRadius.radiusLG,
        border: Border.all(color: AppColors.border.withValues(alpha: .55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryLight),
          const SizedBox(height: 8),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption),
          const SizedBox(height: 3),
          FittedBox(
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _AIPlan extends StatelessWidget {
  const _AIPlan({required this.goal});
  final FinancialGoalSnapshot goal;

  @override
  Widget build(BuildContext context) {
    final monthly = goal.suggestedMonthlyContribution;
    final months = monthly > 0 ? (goal.remaining / monthly).ceil() : 0;
    final message = goal.isCompleted
        ? 'Target sudah tercapai. Pertahankan ritmenya.'
        : months > 0
            ? 'Dengan ${rupiah(monthly)}/bulan, estimasi $months bulan lagi.'
            : 'Mulai dengan kontribusi rutin agar target punya momentum.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.surface, AppColors.surfaceElevated]),
        borderRadius: AppRadius.radiusXL,
        border: Border.all(color: AppColors.primary.withValues(alpha: .2)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .14),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.sparkles, color: AppColors.primaryLight),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nexora AI Plan', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
