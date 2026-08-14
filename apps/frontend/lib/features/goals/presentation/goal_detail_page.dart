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
import '../controllers/supabase_goals_controller.dart';

class GoalDetailPage extends ConsumerWidget {
  const GoalDetailPage({super.key, required this.goalId});
  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(financialGoalsProvider).where((g) => g.id == goalId).firstOrNull;
    if (goal == null) return PremiumScaffold(child: Center(child: Text('Goal tidak ditemukan', style: AppTypography.heading3)));

    final completed = goal.isCompleted;
    final suggested = completed ? (goal.target * .25).clamp(100000.0, double.infinity) : goal.remaining;
    return PremiumScaffold(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: AppSpacing.screen.copyWith(bottom: AppSpacing.bottomNav(context) + 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.arrowLeft)),
          Expanded(child: Text(goal.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.heading2)),
          PopupMenuButton<String>(onSelected: (v) => _menu(context, ref, goal, v), itemBuilder: (_) => const [
            PopupMenuItem(value: 'rename', child: Text('Edit nama')),
            PopupMenuItem(value: 'increase', child: Text('Naikkan target')),
            PopupMenuItem(value: 'pause', child: Text('Pause / Resume')),
            PopupMenuItem(value: 'delete', child: Text('Hapus goal')),
          ]),
        ]),
        const SizedBox(height: 8),
        PremiumCard(padding: const EdgeInsets.all(18), borderRadius: AppRadius.radiusXL, child: Column(children: [
          SizedBox(width: 142, height: 142, child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(value: goal.progress, strokeWidth: 11, backgroundColor: AppColors.border.withValues(alpha: .35), valueColor: AlwaysStoppedAnimation(completed ? AppColors.success : AppColors.primaryLight)),
            Column(mainAxisSize: MainAxisSize.min, children: [Text('${(goal.progress * 100).round()}%', style: AppTypography.heading1.copyWith(fontSize: 26)), Text(completed ? 'Tercapai' : 'Progress', style: AppTypography.caption)]),
          ])),
          const SizedBox(height: 15),
          Text(rupiah(goal.saved), style: AppTypography.currency.copyWith(fontSize: 23, fontWeight: FontWeight.w900)),
          Text('dari target ${rupiah(goal.target)}', style: AppTypography.bodySmall),
          const SizedBox(height: 10),
          Container(width: double.infinity, padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: (completed ? AppColors.success : AppColors.primary).withValues(alpha: .08), borderRadius: AppRadius.radiusLG), child: Row(children: [
            Icon(completed ? LucideIcons.badgeCheck : LucideIcons.flag, size: 18, color: completed ? AppColors.success : AppColors.primaryLight),
            const SizedBox(width: 9),
            Expanded(child: Text(completed ? 'Target tercapai. Lanjutkan goal yang sama dengan menaikkan target.' : 'Sisa target: ${rupiah(goal.remaining)}', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700))),
          ])),
        ])),
        const SizedBox(height: 10),
        _AI(goal: goal, completed: completed, suggested: suggested, onTopUp: () => _contribute(context, ref, goal, suggested), onIncrease: () => _increase(context, ref, goal, suggested)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _Stat('Tersimpan', rupiah(goal.saved), LucideIcons.walletCards)),
          const SizedBox(width: 7),
          Expanded(child: _Stat('Sisa', rupiah(goal.remaining), LucideIcons.flag)),
          const SizedBox(width: 7),
          Expanded(child: _Stat('/ bulan', rupiah(goal.suggestedMonthlyContribution), LucideIcons.calendarDays)),
        ]),
        const SizedBox(height: 10),
        PremiumCard(padding: const EdgeInsets.all(14), borderRadius: AppRadius.radiusXL, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Status Goal', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          Text('Priority: ${goal.priority}  •  Status: ${goal.status}', style: AppTypography.caption),
          if (goal.deadline != null) ...[
            const SizedBox(height: 4),
            Text('Deadline: ${goal.deadline!.day}/${goal.deadline!.month}/${goal.deadline!.year} • ${goal.daysRemaining < 0 ? 'melewati deadline' : '${goal.daysRemaining} hari lagi'}', style: AppTypography.caption),
          ],
        ])),
      ]),
    ));
  }

  Future<void> _menu(BuildContext context, WidgetRef ref, FinancialGoalSnapshot goal, String value) async {
    if (value == 'increase') { await _increase(context, ref, goal, (goal.target * .25).clamp(100000.0, double.infinity)); return; }
    if (value == 'rename') {
      final c = TextEditingController(text: goal.title);
      final title = await showDialog<String>(context: context, builder: (_) => AlertDialog(title: const Text('Edit goal'), content: TextField(controller: c, autofocus: true), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('Simpan'))]));
      c.dispose();
      if (title != null && title.isNotEmpty) await ref.read(financialGoalsProvider.notifier).updateGoal(goal.id, title: title);
      return;
    }
    if (value == 'pause') {
      final ok = goal.status == 'paused' ? await ref.read(financialGoalsProvider.notifier).resumeGoal(goal.id) : await ref.read(financialGoalsProvider.notifier).pauseGoal(goal.id);
      if (context.mounted && ok) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(goal.status == 'paused' ? 'Goal dilanjutkan.' : 'Goal dijeda.')));
      return;
    }
    if (value == 'delete') {
      final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Hapus goal?'), content: Text('Goal "${goal.title}" dan histori kontribusinya akan dihapus.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus'))]));
      if (ok == true) { await ref.read(financialGoalsProvider.notifier).removeGoal(goal.id); if (context.mounted) Navigator.pop(context); }
    }
  }

  Future<void> _increase(BuildContext context, WidgetRef ref, FinancialGoalSnapshot goal, double suggested) async {
    final c = TextEditingController(text: suggested.round().toString());
    final amount = await showDialog<double>(context: context, builder: (_) => AlertDialog(title: const Text('Naikkan target'), content: TextField(controller: c, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tambahan target')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(context, double.tryParse(c.text.replaceAll('.', '').replaceAll(',', ''))), child: const Text('Tambah')]));
    c.dispose();
    if (amount == null || amount <= 0) return;
    final ok = await ref.read(financialGoalsProvider.notifier).updateGoal(goal.id, target: goal.target + amount);
    if (context.mounted && ok) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Target ditambah ${rupiah(amount)}.')));
  }

  Future<void> _contribute(BuildContext context, WidgetRef ref, FinancialGoalSnapshot goal, double suggested) async {
    if (goal.isCompleted) { await _increase(context, ref, goal, suggested); return; }
    final c = TextEditingController(text: suggested.round().toString());
    final amount = await showDialog<double>(context: context, builder: (_) => AlertDialog(title: const Text('Tambah dana ke goal'), content: TextField(controller: c, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nominal')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(context, double.tryParse(c.text.replaceAll('.', '').replaceAll(',', ''))), child: const Text('Simpan')]));
    c.dispose();
    if (amount == null || amount <= 0) return;
    final ok = await ref.read(financialGoalsProvider.notifier).contribute(goal.id, amount);
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Progress goal diperbarui.' : 'Kontribusi gagal disimpan.')));
  }
}

class _AI extends StatelessWidget {
  const _AI({required this.goal, required this.completed, required this.suggested, required this.onTopUp, required this.onIncrease});
  final FinancialGoalSnapshot goal; final bool completed; final double suggested; final VoidCallback onTopUp; final VoidCallback onIncrease;
  @override
  Widget build(BuildContext context) {
    final message = completed ? 'Goal sudah 100%. Jangan buat goal baru yang sama. Naikkan target sekitar ${rupiah(suggested)} dan lanjutkan akumulasi di goal ini.' : 'Kamu masih butuh ${rupiah(goal.remaining)}. Saran setoran sekitar ${rupiah(goal.suggestedMonthlyContribution)} per bulan.';
    return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: AppRadius.radiusXL, boxShadow: AppShadows.glow), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(LucideIcons.sparkles, color: Colors.white, size: 18), const SizedBox(width: 7), Text('Nexora AI Goal Planner', style: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w800))]),
      const SizedBox(height: 8), Text(message, style: AppTypography.bodySmall.copyWith(color: Colors.white.withValues(alpha: .92), height: 1.35)),
      const SizedBox(height: 10), Wrap(spacing: 7, children: [OutlinedButton.icon(onPressed: onTopUp, icon: const Icon(LucideIcons.plus, size: 15), label: Text(completed ? 'Naikkan Target' : 'Tambah Dana'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: Colors.white.withValues(alpha: .45)))), if (completed) OutlinedButton.icon(onPressed: onIncrease, icon: const Icon(LucideIcons.arrowUpRight, size: 15), label: const Text('Target Baru'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: Colors.white.withValues(alpha: .45))))]),
    ]));
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon);
  final String label; final String value; final IconData icon;
  @override
  Widget build(BuildContext context) => PremiumCard(padding: const EdgeInsets.all(10), borderRadius: AppRadius.radiusLG, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 16, color: AppColors.primaryLight), const SizedBox(height: 6), Text(label, style: AppTypography.caption), const SizedBox(height: 2), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800))]));
}
