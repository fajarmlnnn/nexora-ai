import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../controllers/supabase_goals_controller.dart';
import '../../wallet/controllers/wallet_controller.dart';

class GoalDetailPage extends ConsumerWidget {
  const GoalDetailPage({super.key, required this.goalId});
  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(financialGoalsProvider);
    final matches = goals.where((goal) => goal.id == goalId);
    final goal = matches.isEmpty ? null : matches.first;

    if (goal == null) {
      return PremiumScaffold(
        child: Center(
          child: Text('Goal tidak ditemukan', style: AppTypography.heading3),
        ),
      );
    }

    final wallet = ref.watch(primaryWalletProvider);
    final available = wallet == null
        ? 0.0
        : (wallet.balance - wallet.minimumBalance)
            .clamp(0.0, double.infinity)
            .toDouble();
    final monthly = goal.suggestedMonthlyContribution;
    final completed = goal.isCompleted;
    final suggested = completed
        ? (goal.target * .25).clamp(100000.0, double.infinity).toDouble()
        : monthly;

    return PremiumScaffold(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: AppSpacing.screen.copyWith(
          bottom: AppSpacing.bottomNav(context) + 28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              goal: goal,
              onMenu: () => _showMenu(context, ref, goal),
            ),
            const SizedBox(height: 12),
            _HeroProgress(goal: goal),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Tersimpan',
                    value: rupiah(goal.saved),
                    footer: goal.progress <= 0
                        ? 'Dari target'
                        : '${(goal.progress * 100).round()}% dari target',
                    icon: LucideIcons.walletCards,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    title: 'Sisa target',
                    value: rupiah(goal.remaining),
                    footer: goal.progress >= 1
                        ? 'Tercapai'
                        : '${((1 - goal.progress) * 100).round()}% lagi',
                    icon: LucideIcons.flag,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    title: '/ bulan',
                    value: rupiah(monthly),
                    footer: 'Rekomendasi AI',
                    icon: LucideIcons.calendarDays,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ProgressChart(goal: goal),
            const SizedBox(height: 12),
            _AIInsight(
              goal: goal,
              monthly: monthly,
              available: available,
              walletName: wallet?.name,
              onContribute: () => _contribute(
                context,
                ref,
                goal,
                suggested,
                available,
              ),
            ),
            const SizedBox(height: 12),
            _ContributionHistory(goalId: goal.id),
            const SizedBox(height: 12),
            _StatusCard(goal: goal),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rename(context, ref, goal),
                    icon: const Icon(LucideIcons.squarePen, size: 18),
                    label: const Text('Edit Goal'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.radiusLG,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _contribute(
                      context,
                      ref,
                      goal,
                      suggested,
                      available,
                    ),
                    icon: const Icon(LucideIcons.plus, size: 19),
                    label: Text(completed ? 'Naikkan Target' : 'Tambah Dana'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.radiusLG,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMenu(
    BuildContext context,
    WidgetRef ref,
    FinancialGoalSnapshot goal,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.radiusXL,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(LucideIcons.squarePen),
                title: const Text('Edit nama goal'),
                onTap: () => Navigator.pop(sheetContext, 'rename'),
              ),
              ListTile(
                leading: const Icon(LucideIcons.arrowUpRight),
                title: const Text('Naikkan target'),
                onTap: () => Navigator.pop(sheetContext, 'increase'),
              ),
              ListTile(
                leading: Icon(
                  goal.status == 'paused'
                      ? LucideIcons.play
                      : LucideIcons.pause,
                ),
                title: Text(
                  goal.status == 'paused' ? 'Lanjutkan goal' : 'Jeda goal',
                ),
                onTap: () => Navigator.pop(sheetContext, 'pause'),
              ),
              ListTile(
                leading: const Icon(LucideIcons.trash2),
                title: const Text('Hapus goal'),
                textColor: AppColors.danger,
                iconColor: AppColors.danger,
                onTap: () => Navigator.pop(sheetContext, 'delete'),
              ),
            ],
          ),
        ),
      ),
    );

    if (!context.mounted || action == null) return;
    switch (action) {
      case 'rename':
        await _rename(context, ref, goal);
      case 'increase':
        await _increase(context, ref, goal);
      case 'pause':
        await _pause(context, ref, goal);
      case 'delete':
        await _delete(context, ref, goal);
    }
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    FinancialGoalSnapshot goal,
  ) async {
    final controller = TextEditingController(text: goal.title);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit goal'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nama goal'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty) return;
    await ref.read(financialGoalsProvider.notifier).updateGoal(
          goal.id,
          title: value,
        );
  }

  Future<void> _increase(
    BuildContext context,
    WidgetRef ref,
    FinancialGoalSnapshot goal,
  ) async {
    final controller = TextEditingController(
      text: ((goal.target * .25).clamp(100000.0, double.infinity)).round().toString(),
    );
    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Naikkan target'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Tambahan target'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              double.tryParse(
                controller.text.replaceAll('.', '').replaceAll(',', ''),
              ),
            ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Target ditambah ${rupiah(amount)}.')),
      );
    }
  }

  Future<void> _pause(
    BuildContext context,
    WidgetRef ref,
    FinancialGoalSnapshot goal,
  ) async {
    final paused = goal.status == 'paused';
    final ok = paused
        ? await ref.read(financialGoalsProvider.notifier).resumeGoal(goal.id)
        : await ref.read(financialGoalsProvider.notifier).pauseGoal(goal.id);
    if (context.mounted && ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(paused ? 'Goal dilanjutkan.' : 'Goal dijeda.'),
        ),
      );
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    FinancialGoalSnapshot goal,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus goal?'),
        content: Text(
          goal.saved > 0
              ? 'Dana ${rupiah(goal.saved)} akan dikembalikan ke wallet sesuai aturan server.'
              : 'Goal ini akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(financialGoalsProvider.notifier).removeGoal(goal.id);
      if (context.mounted) Navigator.pop(context);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus goal: $error')),
        );
      }
    }
  }

  Future<void> _contribute(
    BuildContext context,
    WidgetRef ref,
    FinancialGoalSnapshot goal,
    double suggested,
    double available,
  ) async {
    if (goal.isCompleted) {
      await _increase(context, ref, goal);
      return;
    }
    if (available <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saldo yang aman untuk disetor saat ini Rp 0.')),
        );
      }
      return;
    }

    final initial = suggested > 0
        ? suggested.clamp(0.0, goal.remaining).toDouble()
        : available.clamp(0.0, goal.remaining).toDouble();
    final controller = TextEditingController(text: initial.round().toString());
    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tambah dana ke goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Nominal',
            helperText: 'Maksimal aman ${rupiah(available)}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              double.tryParse(
                controller.text.replaceAll('.', '').replaceAll(',', ''),
              ),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount == null || amount <= 0) return;
    if (amount > available) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Maksimal aman ${rupiah(available)}.')),
        );
      }
      return;
    }

    try {
      await ref.read(financialGoalsProvider.notifier).contribute(goal.id, amount);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dana berhasil ditambahkan.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
      }
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.goal, required this.onMenu});
  final FinancialGoalSnapshot goal;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final completed = goal.isCompleted;
    final subtitle = switch (goal.type.toLowerCase()) {
      'saving' => 'Keamanan finansial utama',
      'wishlist' => 'Target yang ingin kamu wujudkan',
      'debt' => 'Rencana pelunasan kewajiban',
      _ => 'Target finansial kamu',
    };

    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (completed ? AppColors.success : AppColors.primary)
                .withValues(alpha: .12),
            borderRadius: AppRadius.radiusLG,
            border: Border.all(
              color: (completed ? AppColors.success : AppColors.primary)
                  .withValues(alpha: .24),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: Icon(
              completed ? Icons.lock_open_rounded : Icons.lock_rounded,
              key: ValueKey(completed),
              color: completed ? AppColors.success : AppColors.primaryLight,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      goal.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.heading3,
                    ),
                  ),
                  const SizedBox(width: 7),
                  _Badge(goal.type),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onMenu,
          icon: const Icon(Icons.more_vert_rounded),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: .16),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          text,
          style: AppTypography.overline.copyWith(
            color: AppColors.primaryLight,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _HeroProgress extends StatelessWidget {
  const _HeroProgress({required this.goal});
  final FinancialGoalSnapshot goal;

  @override
  Widget build(BuildContext context) {
    final completed = goal.isCompleted;
    final percent = (goal.progress * 100).round();
    final accent = completed ? AppColors.success : AppColors.primaryLight;

    return PremiumCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      borderRadius: AppRadius.radiusXL,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _HeroSide(
                  title: 'Progress Goal',
                  value: '$percent%',
                  footer: completed ? '● Tercapai' : '● On Track',
                  accent: accent,
                ),
              ),
              const SizedBox(width: 8),
              _ProgressLock(progress: goal.progress, completed: completed),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroSide(
                  title: 'Terkumpul',
                  value: rupiah(goal.saved),
                  footer: 'dari target\n${rupiah(goal.target)}',
                  accent: AppColors.primaryLight,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: goal.progress),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: AppColors.border.withValues(alpha: .3),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '⚑  Sisa target: ${rupiah(goal.remaining)}',
                  style: AppTypography.caption,
                ),
              ),
              if (goal.deadline != null)
                Text(
                  '▣  ${_date(goal.deadline!)}',
                  style: AppTypography.caption,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroSide extends StatelessWidget {
  const _HeroSide({
    required this.title,
    required this.value,
    required this.footer,
    required this.accent,
    this.alignEnd = false,
  });
  final String title;
  final String value;
  final String footer;
  final Color accent;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.caption),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.heading2.copyWith(
              color: accent,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            footer,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            style: AppTypography.caption,
          ),
        ],
      );
}

class _ProgressLock extends StatelessWidget {
  const _ProgressLock({required this.progress, required this.completed});
  final double progress;
  final bool completed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 88,
        height: 88,
        child: Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 750),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => CircularProgressIndicator(
                value: value,
                strokeWidth: 7,
                backgroundColor: AppColors.border.withValues(alpha: .35),
                valueColor: AlwaysStoppedAnimation<Color>(
                  completed ? AppColors.success : AppColors.primaryLight,
                ),
              ),
            ),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                boxShadow: AppShadows.glow,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  completed ? Icons.lock_open_rounded : Icons.lock_rounded,
                  key: ValueKey(completed),
                  color: completed ? AppColors.success : AppColors.primaryLight,
                  size: 25,
                ),
              ),
            ),
          ],
        ),
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.footer,
    required this.icon,
  });
  final String title;
  final String value;
  final String footer;
  final IconData icon;

  @override
  Widget build(BuildContext context) => PremiumCard(
        padding: const EdgeInsets.all(10),
        borderRadius: AppRadius.radiusLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 17, color: AppColors.primaryLight),
            const SizedBox(height: 6),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption),
            const SizedBox(height: 3),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(footer, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.overline.copyWith(color: AppColors.primaryLight)),
          ],
        ),
      );
}

class _ProgressChart extends StatelessWidget {
  const _ProgressChart({required this.goal});
  final FinancialGoalSnapshot goal;

  Future<List<Map<String, dynamic>>> _load() async {
    if (!NexoraSupabase.isInitialized ||
        NexoraSupabase.client.auth.currentUser == null) {
      return const [];
    }
    final rows = await NexoraSupabase.client
        .from('goal_contributions')
        .select('amount, contributed_at')
        .eq('goal_id', goal.id)
        .order('contributed_at', ascending: true)
        .limit(200);
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: _load(),
        builder: (context, snapshot) {
          final rows = snapshot.data ?? const <Map<String, dynamic>>[];
          return PremiumCard(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            borderRadius: AppRadius.radiusXL,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Grafik Progres',
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Text('6 Bulan Terakhir ▾'),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('Terkumpul', style: AppTypography.overline),
                    const SizedBox(width: 14),
                    Text('┄┄ Target ideal', style: AppTypography.overline),
                  ],
                ),
                const SizedBox(height: 7),
                SizedBox(
                  height: 190,
                  child: CustomPaint(
                    painter: _GoalChartPainter(
                      target: goal.target,
                      saved: goal.saved,
                      rows: rows,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class _GoalChartPainter extends CustomPainter {
  const _GoalChartPainter({
    required this.target,
    required this.saved,
    required this.rows,
  });
  final double target;
  final double saved;
  final List<Map<String, dynamic>> rows;

  @override
  void paint(Canvas canvas, Size size) {
    const top = 16.0;
    const bottomInset = 28.0;
    final left = 34.0;
    final right = size.width - 10.0;
    final bottom = size.height - bottomInset;
    final chartHeight = bottom - top;

    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: .22)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = top + i * chartHeight / 3;
      canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
    }

    final now = DateTime.now();
    final months = List.generate(
      6,
      (index) => DateTime(now.year, now.month - 5 + index, 1),
    );
    final monthly = List<double>.filled(6, 0);

    for (final row in rows) {
      final date = DateTime.tryParse(row['contributed_at']?.toString() ?? '');
      final amount = (row['amount'] as num?)?.toDouble() ?? 0;
      if (date == null) continue;
      for (var i = 0; i < months.length; i++) {
        if (date.year == months[i].year && date.month == months[i].month) {
          monthly[i] += amount;
          break;
        }
      }
    }

    var running = 0.0;
    final actual = <double>[];
    for (final amount in monthly) {
      running += amount;
      actual.add(running);
    }

    if (rows.isEmpty) {
      for (var i = 0; i < 6; i++) {
        actual[i] = saved * (i / 5);
      }
    } else if (actual.last < saved) {
      actual[5] = saved;
    }

    final scale = [target, saved, ...actual].fold<double>(
      1,
      (maxValue, value) => value > maxValue ? value : maxValue,
    );

    final ideal = Path();
    final actualPath = Path();
    for (var i = 0; i < 6; i++) {
      final x = left + i * (right - left) / 5;
      final idealY = bottom - chartHeight * i / 5;
      final actualY = bottom - chartHeight * (actual[i] / scale);
      if (i == 0) {
        ideal.moveTo(x, idealY);
        actualPath.moveTo(x, actualY);
      } else {
        ideal.lineTo(x, idealY);
        actualPath.lineTo(x, actualY);
      }
    }

    _drawDashed(
      canvas,
      ideal,
      Paint()
        ..color = AppColors.textMuted.withValues(alpha: .55)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    final fill = Path.from(actualPath)
      ..lineTo(right, bottom)
      ..lineTo(left, bottom)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: .28),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(left, top, right - left, chartHeight)),
    );

    canvas.drawPath(
      actualPath,
      Paint()
        ..color = AppColors.primaryLight
        ..strokeWidth = 2.6
        ..style = PaintingStyle.stroke,
    );

    const labels = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    for (var i = 0; i < 6; i++) {
      final x = left + i * (right - left) / 5;
      final y = bottom - chartHeight * (actual[i] / scale);
      canvas.drawCircle(
        Offset(x, y),
        i == 5 ? 5 : 3,
        Paint()..color = AppColors.primaryLight,
      );
      final text = TextPainter(
        text: TextSpan(
          text: labels[months[i].month - 1],
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(x - text.width / 2, bottom + 7));
    }

    final valueText = TextPainter(
      text: TextSpan(
        text: rupiah(actual[5]),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryLight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    valueText.paint(
      canvas,
      Offset(
        right - valueText.width,
        bottom - chartHeight * (actual[5] / scale) - 18,
      ),
    );
  }

  static void _drawDashed(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + 5).clamp(0.0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GoalChartPainter oldDelegate) =>
      oldDelegate.target != target ||
      oldDelegate.saved != saved ||
      oldDelegate.rows != rows;
}

class _AIInsight extends StatelessWidget {
  const _AIInsight({
    required this.goal,
    required this.monthly,
    required this.available,
    required this.walletName,
    required this.onContribute,
  });
  final FinancialGoalSnapshot goal;
  final double monthly;
  final double available;
  final String? walletName;
  final VoidCallback onContribute;

  @override
  Widget build(BuildContext context) {
    final completed = goal.isCompleted;
    final message = completed
        ? 'Target ini sudah tercapai. Pertahankan kebiasaanmu atau naikkan target berikutnya.'
        : 'Kamu masih butuh ${rupiah(goal.remaining)}. Dengan setoran sekitar ${rupiah(monthly)} per bulan, target lebih terarah.';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: AppRadius.radiusXL,
        boxShadow: AppShadows.glow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .10),
                ),
                padding: const EdgeInsets.all(3),
                child: SvgPicture.asset(
                  'assets/mascot/nexora_mascot_master.svg',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.sparkles,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Nexora AI Insight',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .12),
                        borderRadius: AppRadius.radiusPill,
                      ),
                      child: Text(
                        'AI',
                        style: AppTypography.overline.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            message,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: .94),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 9),
          _AIChip(
            icon: LucideIcons.badgeCheck,
            text: completed
                ? 'Konsistensimu bagus! Pertahankan.'
                : 'Rekomendasi setoran: ${rupiah(monthly)} / bulan',
          ),
          if (!completed && available > 0) ...[
            const SizedBox(height: 7),
            _AIChip(
              icon: LucideIcons.walletCards,
              text:
                  '${walletName ?? 'Wallet'} • bisa disetor sekarang ${rupiah(available)}',
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Lihat rekomendasi detail →',
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: onContribute,
                child: Text(
                  completed ? 'Naikkan' : 'Tambah dana',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AIChip extends StatelessWidget {
  const _AIChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .10),
          borderRadius: AppRadius.radiusLG,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
}

class _ContributionHistory extends StatelessWidget {
  const _ContributionHistory({required this.goalId});
  final String goalId;

  Future<List<Map<String, dynamic>>> _load() async {
    if (!NexoraSupabase.isInitialized ||
        NexoraSupabase.client.auth.currentUser == null) {
      return const [];
    }
    final rows = await NexoraSupabase.client
        .from('goal_contributions')
        .select('id, amount, note, contributed_at')
        .eq('goal_id', goalId)
        .order('contributed_at', ascending: false)
        .limit(8);
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: _load(),
        builder: (context, snapshot) {
          final rows = snapshot.data ?? const <Map<String, dynamic>>[];
          return PremiumCard(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            borderRadius: AppRadius.radiusXL,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Aktivitas Transaksi',
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      'Lihat semua',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: LinearProgressIndicator(minHeight: 2),
                  )
                else if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'Belum ada setoran ke goal ini.',
                      style: AppTypography.caption,
                    ),
                  )
                else
                  ...rows.map((row) => _ContributionTile(row: row)),
              ],
            ),
          );
        },
      );
}

class _ContributionTile extends StatelessWidget {
  const _ContributionTile({required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(row['contributed_at']?.toString() ?? '');
    final note = row['note']?.toString().trim();
    final amount = (row['amount'] as num?)?.toDouble() ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.arrowDownToLine,
              color: AppColors.success,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note == null || note.isEmpty ? 'Transfer ke goal' : note,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date == null ? 'Tanggal tidak tersedia' : _dateTime(date),
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          Text(
            '+ ${rupiah(amount)}',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.goal});
  final FinancialGoalSnapshot goal;

  @override
  Widget build(BuildContext context) => PremiumCard(
        padding: const EdgeInsets.all(14),
        borderRadius: AppRadius.radiusXL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status Goal',
              style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _Pill('Priority: ${goal.priority}'),
                _Pill('Status: ${goal.status}', success: goal.isCompleted),
              ],
            ),
            if (goal.deadline != null) ...[
              const SizedBox(height: 8),
              Text(
                'Target tercapai ${_date(goal.deadline!)} • ${goal.daysRemaining < 0 ? 'melewati deadline' : '${goal.daysRemaining} hari lagi'}',
                style: AppTypography.caption,
              ),
            ],
          ],
        ),
      );
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, {this.success = false});
  final String text;
  final bool success;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: (success ? AppColors.success : AppColors.primary)
              .withValues(alpha: .10),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          text,
          style: AppTypography.overline.copyWith(
            color: success ? AppColors.success : AppColors.primaryLight,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')} ${_month(value.month)} ${value.year}';

String _dateTime(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')} ${_month(value.month)} ${value.year} • ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _month(int value) => const [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ][value];
