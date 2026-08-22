import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../controllers/supabase_goals_controller.dart';
import '../../wallet/controllers/wallet_controller.dart';

class GoalDetailPageV2 extends ConsumerWidget {
  const GoalDetailPageV2({super.key, required this.goalId});
  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(financialGoalsProvider);
    final goal = goals.where((item) => item.id == goalId).firstOrNull;

    if (goal == null) {
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
                  Text('Data mungkin sudah dihapus atau belum tersinkron.', textAlign: TextAlign.center, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  FilledButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.arrowLeft), label: const Text('Kembali')),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final progress = goal.progress.clamp(0.0, 1.0).toDouble();
    final remaining = goal.remaining.clamp(0.0, double.infinity).toDouble();
    final wallet = ref.watch(primaryWalletProvider);
    final safeBalance = wallet == null ? 0.0 : (wallet.balance - wallet.minimumBalance).clamp(0.0, double.infinity).toDouble();
    final monthly = goal.suggestedMonthlyContribution;

    return PremiumScaffold(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background.withValues(alpha: .94),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.arrowLeft)),
            title: Text('Goal detail', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
            actions: [IconButton(onPressed: () => _showActions(context, ref, goal), icon: const Icon(LucideIcons.moreVertical))],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverToBoxAdapter(child: _Hero(goal: goal, progress: progress)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverToBoxAdapter(child: Row(children: [Expanded(child: _Metric(label: 'Tersimpan', value: rupiah(goal.saved), icon: LucideIcons.walletCards)), const SizedBox(width: 10), Expanded(child: _Metric(label: 'Sisa target', value: rupiah(remaining), icon: LucideIcons.flag)), const SizedBox(width: 10), Expanded(child: _Metric(label: '/ bulan', value: rupiah(monthly), icon: LucideIcons.calendarDays))])),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverToBoxAdapter(child: _AIPlan(goal: goal, monthly: monthly, safeBalance: safeBalance)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverToBoxAdapter(child: _Milestone(goal: goal, progress: progress)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(child: Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () => _editName(context, ref, goal), icon: const Icon(LucideIcons.squarePen, size: 18), label: const Text('Edit'))), const SizedBox(width: 10), Expanded(flex: 2, child: FilledButton.icon(onPressed: goal.isCompleted ? () => _increaseTarget(context, ref, goal) : () => _contribute(context, ref, goal, safeBalance), icon: const Icon(LucideIcons.plus, size: 19), label: Text(goal.isCompleted ? 'Naikkan target' : 'Tambah dana')))])),
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
      builder: (sheetContext) => SafeArea(child: Container(margin: const EdgeInsets.all(12), padding: const EdgeInsets.fromLTRB(8, 10, 8, 12), decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.radiusXL, border: Border.all(color: AppColors.border.withValues(alpha: .7))), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(width: 40, child: Divider(thickness: 3)),
        ListTile(leading: const Icon(LucideIcons.squarePen), title: const Text('Edit nama goal'), onTap: () => Navigator.pop(sheetContext, 'edit')),
        ListTile(leading: const Icon(LucideIcons.arrowUpRight), title: const Text('Naikkan target'), onTap: () => Navigator.pop(sheetContext, 'increase')),
        ListTile(leading: Icon(goal.status == 'paused' ? LucideIcons.play : LucideIcons.pause), title: Text(goal.status == 'paused' ? 'Lanjutkan goal' : 'Jeda goal'), onTap: () => Navigator.pop(sheetContext, 'pause')),
        ListTile(leading: const Icon(LucideIcons.trash2), iconColor: AppColors.danger, textColor: AppColors.danger, title: const Text('Hapus goal'), onTap: () => Navigator.pop(sheetContext, 'delete')),
      ])));
    if (!context.mounted || action == null) return;
    switch (action) {
      case 'edit': await _editName(context, ref, goal);
      case 'increase': await _increaseTarget(context, ref, goal);
      case 'pause': await _togglePause(context, ref, goal);
      case 'delete': await _delete(context, ref, goal);
    }
  }

  Future<void> _editName(BuildContext context, WidgetRef ref, FinancialGoalSnapshot goal) async {
    final controller = TextEditingController(text: goal.title);
    final value = await showDialog<String>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Edit goal'), content: TextField(controller: controller, autofocus: true, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Nama goal')), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('Simpan'))]));
    controller.dispose();
    if (value == null || value.isEmpty) return;
    await ref.read(financialGoalsProvider.notifier).updateGoal(goal.id, title: value);
  }

  Future<void> _increaseTarget(BuildContext context, WidgetRef ref, FinancialGoalSnapshot goal) async {
    final controller = TextEditingController(text: ((goal.target * .25).clamp(100000.0, double.infinity)).round().toString());
    final amount = await showDialog<double>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Naikkan target'), content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tambahan target')), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(dialogContext, _parseAmount(controller.text)), child: const Text('Tambah'))]));
    controller.dispose();
    if (amount == null || amount <= 0) return;
    await ref.read(financialGoalsProvider.notifier).updateGoal(goal.id, target: goal.target + amount);
  }

  Future<void> _togglePause(BuildContext context, WidgetRef ref, FinancialGoalSnapshot goal) async {
    final ok = goal.status == 'paused' ? await ref.read(financialGoalsProvider.notifier).resumeGoal(goal.id) : await ref.read(financialGoalsProvider.notifier).pauseGoal(goal.id);
    if (context.mounted && ok) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(goal.status == 'paused' ? 'Goal dilanjutkan.' : 'Goal dijeda.')));
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, FinancialGoalSnapshot goal) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Hapus goal?'), content: Text(goal.saved > 0 ? 'Dana ${rupiah(goal.saved)} akan diproses sesuai aturan server.' : 'Goal ini akan dihapus.'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Hapus'))]));
    if (confirmed != true) return;
    try {
      await ref.read(financialGoalsProvider.notifier).removeGoal(goal.id);
      if (context.mounted) Navigator.pop(context);
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus goal: $error')));
    }
  }

  Future<void> _contribute(BuildContext context, WidgetRef ref, FinancialGoalSnapshot goal, double safeBalance) async {
    if (safeBalance <= 0 || goal.remaining <= 0) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Belum ada saldo aman untuk ditambahkan.')));
      return;
    }
    final suggested = goal.suggestedMonthlyContribution.clamp(0.0, goal.remaining).toDouble();
    final controller = TextEditingController(text: (suggested > 0 ? suggested : safeBalance.clamp(0.0, goal.remaining)).round().toString());
    final amount = await showDialog<double>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Tambah dana'), content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Nominal', helperText: 'Saldo aman ${rupiah(safeBalance)}')), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(dialogContext, _parseAmount(controller.text)), child: const Text('Simpan'))]));
    controller.dispose();
    if (amount == null || amount <= 0) return;
    if (amount > safeBalance) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Maksimal aman ${rupiah(safeBalance)}.')));
      return;
    }
    try {
      await ref.read(financialGoalsProvider.notifier).contribute(goal.id, amount);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dana berhasil ditambahkan.')));
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))));
    }
  }

  static double? _parseAmount(String value) => double.tryParse(value.replaceAll('.', '').replaceAll(',', '').replaceAll(' ', ''));
}

class _Hero extends StatelessWidget {
  const _Hero({required this.goal, required this.progress});
  final FinancialGoalSnapshot goal;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final complete = goal.isCompleted;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF241744), Color(0xFF16162C), Color(0xFF101A2D)]), borderRadius: AppRadius.radiusXL, border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: .22)), boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: .13), blurRadius: 32, spreadRadius: -12, offset: const Offset(0, 18))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(goal.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.heading2.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 6), Text(goal.type, style: AppTypography.caption.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w800, letterSpacing: .4))])), Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, color: (complete ? AppColors.success : AppColors.primary).withValues(alpha: .13)), child: Icon(complete ? LucideIcons.circleCheck : LucideIcons.target, color: complete ? AppColors.success : AppColors.primaryLight, size: 22))]),
        const SizedBox(height: 24),
        Text(rupiah(goal.saved), style: AppTypography.display.copyWith(fontSize: 34, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text('dari ${rupiah(goal.target)} target', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 18),
        ClipRRect(borderRadius: BorderRadius.circular(999), child: SizedBox(height: 9, child: Stack(children: [Positioned.fill(child: ColoredBox(color: Colors.white.withValues(alpha: .08))), FractionallySizedBox(widthFactor: progress, child: const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF22D3EE)]))))])),
        const SizedBox(height: 10),
        Row(children: [Text('${(progress * 100).round()}%', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w900, color: AppColors.primaryLight)), const Spacer(), Text(complete ? 'Goal tercapai 🎉' : 'Sisa ${rupiah(goal.remaining)}', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w700))]),
      ]),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.fromLTRB(12, 14, 10, 13), decoration: BoxDecoration(color: AppColors.surface.withValues(alpha: .72), borderRadius: AppRadius.radiusLG, border: Border.all(color: AppColors.border.withValues(alpha: .55))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 16, color: AppColors.primaryLight), const SizedBox(height: 9), Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(color: AppColors.textMuted)), const SizedBox(height: 3), FittedBox(alignment: Alignment.centerLeft, fit: BoxFit.scaleDown, child: Text(value, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w900)))]));
}

class _AIPlan extends StatelessWidget {
  const _AIPlan({required this.goal, required this.monthly, required this.safeBalance});
  final FinancialGoalSnapshot goal;
  final double monthly;
  final double safeBalance;
  @override
  Widget build(BuildContext context) {
    final months = monthly <= 0 ? 0 : (goal.remaining / monthly).ceil();
    final title = goal.isCompleted ? 'Target sudah tercapai' : months > 0 ? 'Sekitar $months bulan lagi' : 'Siapkan kontribusi pertama';
    return Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF20173B), Color(0xFF171B32)]), borderRadius: AppRadius.radiusXL, border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: .2))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 38, height: 38, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF22D3EE)])), child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 18)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Nexora AI plan', style: AppTypography.caption.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w900, letterSpacing: .5)), const SizedBox(height: 4), Text(title, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(monthly > 0 ? 'Rekomendasi kontribusi ${rupiah(monthly)}/bulan. Saldo aman saat ini ${rupiah(safeBalance)}.' : 'Tambahkan kontribusi untuk membangun momentum target.', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, height: 1.4))]))]));
  }
}

class _Milestone extends StatelessWidget {
  const _Milestone({required this.goal, required this.progress});
  final FinancialGoalSnapshot goal;
  final double progress;
  @override
  Widget build(BuildContext context) {
    final next = ((progress * 4).floor() + 1).clamp(1, 4);
    final labels = ['25%', '50%', '75%', '100%'];
    return Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.surface.withValues(alpha: .58), borderRadius: AppRadius.radiusXL, border: Border.all(color: AppColors.border.withValues(alpha: .5))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text('Milestone', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w900)), const Spacer(), Text(progress >= 1 ? 'Selesai' : 'Berikutnya ${labels[next - 1]}', style: AppTypography.caption.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w800))]), const SizedBox(height: 16), Row(children: List.generate(4, (index) { final reached = progress >= (index + 1) / 4; return Expanded(child: Row(children: [Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, color: reached ? AppColors.primary : AppColors.background, border: Border.all(color: reached ? AppColors.primary : AppColors.border)), child: reached ? const Icon(Icons.check, size: 14, color: Colors.white) : Center(child: Text('${index + 1}', style: AppTypography.overline))), if (index < 3) Expanded(child: Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 5), color: progress > (index + 1) / 4 ? AppColors.primary : AppColors.border))])); }))]));
  }
}
