import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/context_ai_insight.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../controllers/supabase_goals_controller.dart';
import 'add_goal_sheet.dart';

class GoalsPage extends ConsumerStatefulWidget {
  const GoalsPage({super.key});
  @override
  ConsumerState<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends ConsumerState<GoalsPage> {
  final _pageController = PageController();
  int _selectedTab = 0;

  @override
  void dispose() { _pageController.dispose(); super.dispose(); }

  void _selectTab(int index) {
    if (index == _selectedTab) return;
    setState(() => _selectedTab = index);
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(financialGoalsProvider);
    return PremiumScaffold(
      child: Padding(
        padding: AppSpacing.screen,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Goals', style: AppTypography.heading1),
              Text('Rencanakan target finansialmu', style: AppTypography.bodySmall),
            ])),
            IconButton(onPressed: () => showAddGoalSheet(context, ref), icon: const Icon(LucideIcons.plus), tooltip: 'Tambah Goal'),
          ]),
          const SizedBox(height: 10),
          _Overview(goals: goals),
          const SizedBox(height: 10),
          _Tabs(selected: _selectedTab, onSelected: _selectTab),
          const SizedBox(height: 7),
          Expanded(child: PageView(
            controller: _pageController,
            onPageChanged: (index) { if (index != _selectedTab) setState(() => _selectedTab = index); },
            children: [
              _List(goals: goals, showInsight: true),
              _List(goals: goals.where((g) => g.type == 'Wishlist').toList()),
              _List(goals: goals.where((g) => g.type == 'Saving').toList()),
              _List(goals: goals.where((g) => g.type == 'Debt').toList()),
            ],
          )),
        ]),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.goals});
  final List<FinancialGoalSnapshot> goals;
  @override
  Widget build(BuildContext context) {
    final saved = goals.fold<double>(0, (s, g) => s + g.saved);
    final target = goals.fold<double>(0, (s, g) => s + g.target);
    final progress = target <= 0 ? 0.0 : (saved / target).clamp(0.0, 1.0);
    return PremiumCard(padding: const EdgeInsets.all(14), borderRadius: AppRadius.radiusXL, child: Row(children: [
      SizedBox(width: 58, height: 58, child: Stack(alignment: Alignment.center, children: [
        CircularProgressIndicator(value: progress, strokeWidth: 6, backgroundColor: AppColors.border.withValues(alpha: .35), valueColor: const AlwaysStoppedAnimation(AppColors.primaryLight)),
        Text('${(progress * 100).round()}%', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w800)),
      ])),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Progress semua goals', style: AppTypography.caption),
        Text('${rupiah(saved)} tersimpan', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
        Text('dari ${rupiah(target)} target', style: AppTypography.caption),
      ])),
      Text('${goals.length}', style: AppTypography.heading3.copyWith(color: AppColors.primaryLight)),
    ]));
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;
  static const labels = ['Semua', 'Wishlist', 'Saving', 'Debt'];
  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: AppRadius.radiusLG, border: Border.all(color: AppColors.border.withValues(alpha: .3))),
    child: Row(children: List.generate(labels.length, (i) => Expanded(child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelected(i),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(gradient: selected == i ? AppGradients.primary : null, borderRadius: AppRadius.radiusMD, boxShadow: selected == i ? AppShadows.glow : null),
        child: Text(labels[i], style: AppTypography.caption.copyWith(color: selected == i ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w700)),
      ),
    )))),
  );
}

class _List extends StatelessWidget {
  const _List({required this.goals, this.showInsight = false});
  final List<FinancialGoalSnapshot> goals;
  final bool showInsight;
  @override
  Widget build(BuildContext context) => ListView.separated(
    physics: const BouncingScrollPhysics(),
    padding: EdgeInsets.only(bottom: AppSpacing.bottomNav(context) + 20),
    itemCount: goals.length + (showInsight ? 1 : 0),
    separatorBuilder: (_, _) => const SizedBox(height: 7),
    itemBuilder: (context, index) {
      if (showInsight && index == goals.length) return const ContextAIInsight(message: 'Buka goal untuk melihat progres, histori, AI planner, deadline, dan rekomendasi target berikutnya.');
      return _Card(goal: goals[index]);
    },
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.goal});
  final FinancialGoalSnapshot goal;
  @override
  Widget build(BuildContext context) {
    final completed = goal.isCompleted;
    final accent = completed ? AppColors.success : AppColors.primaryLight;
    final progress = goal.progress;
    final status = completed ? 'Tercapai' : progress >= .75 ? 'On track' : progress >= .4 ? 'Berjalan' : 'Perlu dorongan';
    return Material(color: Colors.transparent, child: InkWell(
      borderRadius: AppRadius.radiusXL,
      onTap: () => context.push('/goals/${goal.id}'),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: AppRadius.radiusXL, border: Border.all(color: AppColors.border.withValues(alpha: .5)), boxShadow: AppShadows.card),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: accent.withValues(alpha: .10), borderRadius: AppRadius.radiusLG), child: Icon(goal.icon, color: accent, size: 21)),
          const SizedBox(width: 9),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(goal.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800))), Text('${(progress * 100).round()}%', style: AppTypography.caption.copyWith(color: accent, fontWeight: FontWeight.w800))]),
            Row(children: [Text(goal.type, style: AppTypography.caption), const SizedBox(width: 6), Text(status, style: AppTypography.caption.copyWith(color: accent, fontWeight: FontWeight.w700)), const Spacer(), const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.textMuted)]),
            const SizedBox(height: 6),
            AnimatedProgressBar(value: progress, color: accent),
            const SizedBox(height: 4),
            Text('${rupiah(goal.saved)} / ${rupiah(goal.target)}', style: AppTypography.caption),
          ])),
        ]),
      ),
    ));
  }
}
