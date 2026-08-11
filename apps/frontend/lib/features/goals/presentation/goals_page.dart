import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/context_ai_insight.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../dashboard/controllers/financial_overview_controller.dart';
import 'add_goal_sheet.dart';

class GoalsPage extends ConsumerStatefulWidget {
  const GoalsPage({super.key});

  @override
  ConsumerState<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends ConsumerState<GoalsPage> {
  final PageController _pageController = PageController();
  int _selectedTab = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (index == _selectedTab) return;
    setState(() => _selectedTab = index);
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  Future<void> _addGoal() => showAddGoalSheet(context, ref);

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(financialGoalsProvider).map(_GoalData.fromSnapshot).toList(growable: false);

    return PremiumScaffold(
      child: Padding(
        padding: AppSpacing.screen.copyWith(bottom: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GoalsHeader(onAdd: _addGoal),
            const SizedBox(height: 10),
            _GoalsOverview(goals: goals),
            const SizedBox(height: 10),
            _GoalTabs(selected: _selectedTab, onSelected: _selectTab),
            const SizedBox(height: 7),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  if (index != _selectedTab) setState(() => _selectedTab = index);
                },
                children: [
                  _GoalList(goals: goals, showInsight: true),
                  _GoalList(goals: goals.where((goal) => goal.type == 'Wishlist').toList()),
                  _GoalList(goals: goals.where((goal) => goal.type == 'Saving').toList()),
                  _GoalList(goals: goals.where((goal) => goal.type == 'Debt').toList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalsHeader extends StatelessWidget {
  const _GoalsHeader({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Goals', style: AppTypography.heading1),
              const SizedBox(height: 1),
              Text('Rencanakan target finansialmu', style: AppTypography.bodySmall),
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onAdd,
            customBorder: const CircleBorder(),
            child: Ink(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border.withValues(alpha: .45)),
              ),
              child: const Center(child: Icon(LucideIcons.plus, color: AppColors.primaryLight, size: 20)),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalsOverview extends StatelessWidget {
  const _GoalsOverview({required this.goals});
  final List<_GoalData> goals;

  @override
  Widget build(BuildContext context) {
    final saved = goals.fold<double>(0, (sum, goal) => sum + goal.saved);
    final target = goals.fold<double>(0, (sum, goal) => sum + goal.target);
    final progress = target == 0 ? 0.0 : (saved / target).clamp(0.0, 1.0);

    return PremiumCard(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      borderRadius: AppRadius.radiusXL,
      child: Row(
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(value: progress, strokeWidth: 6, backgroundColor: AppColors.border.withValues(alpha: .35), valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryLight)),
                Text('${(progress * 100).round()}%', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Progress semua goals', style: AppTypography.caption),
                const SizedBox(height: 2),
                Text('${rupiah(saved)} tersimpan', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 1),
                Text('dari ${rupiah(target)} target', style: AppTypography.caption),
              ],
            ),
          ),
          Text('${goals.length}', style: AppTypography.heading3.copyWith(color: AppColors.primaryLight)),
          const SizedBox(width: 3),
          Text('goals', style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _GoalTabs extends StatelessWidget {
  const _GoalTabs({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;
  static const labels = ['Semua', 'Wishlist', 'Saving', 'Debt'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.card.withValues(alpha: .72), borderRadius: AppRadius.radiusLG, border: Border.all(color: AppColors.border.withValues(alpha: .3))),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / labels.length;
          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                alignment: Alignment(-1 + (selected * 2 / (labels.length - 1)), 0),
                child: Container(width: itemWidth, height: 38, decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: AppRadius.radiusMD, boxShadow: AppShadows.glow)),
              ),
              Row(
                children: List.generate(labels.length, (index) {
                  final active = selected == index;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelected(index),
                      child: Center(
                        child: Text(labels[index], maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(color: active ? Colors.white : AppColors.textSecondary, fontWeight: active ? FontWeight.w800 : FontWeight.w600)),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GoalList extends StatelessWidget {
  const _GoalList({required this.goals, this.showInsight = false});
  final List<_GoalData> goals;
  final bool showInsight;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(top: 2, bottom: AppSpacing.bottomNav(context) + 20),
      itemCount: goals.length + (showInsight ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 7),
      itemBuilder: (context, index) {
        if (showInsight && index == goals.length) {
          return const ContextAIInsight(message: 'Dana Darurat sudah menjadi prioritas. Saat sebuah goal selesai, Nexora bisa menyarankan mengalihkan dana ke target yang masih relevan.');
        }
        return _GoalCard(goal: goals[index]);
      },
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});
  final _GoalData goal;

  @override
  Widget build(BuildContext context) {
    final progress = goal.progress;
    final status = progress >= .75 ? 'On track' : progress >= .4 ? 'Berjalan' : 'Perlu dorongan';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: AppRadius.radiusXL, border: Border.all(color: AppColors.border.withValues(alpha: .5)), boxShadow: AppShadows.card),
      child: Row(
        children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .12), borderRadius: AppRadius.radiusLG), child: Icon(goal.icon, color: AppColors.primaryLight, size: 21)),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Expanded(child: Text(goal.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800))), Text('${(progress * 100).round()}%', style: AppTypography.caption.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w800))]),
                const SizedBox(height: 1),
                Row(children: [Text(goal.type, style: AppTypography.caption), const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .10), borderRadius: AppRadius.radiusPill), child: Text(status, style: AppTypography.caption.copyWith(color: AppColors.primaryLight, fontSize: 9, fontWeight: FontWeight.w700)))]),
                const SizedBox(height: 6),
                AnimatedProgressBar(value: progress, color: AppColors.primaryLight),
                const SizedBox(height: 4),
                Text('${rupiah(goal.saved)} / ${rupiah(goal.target)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalData {
  const _GoalData(this.title, this.type, this.saved, this.target, this.icon);
  final String title;
  final String type;
  final double saved;
  final double target;
  final IconData icon;

  double get progress => target <= 0 ? 0 : (saved / target).clamp(0.0, 1.0);

  factory _GoalData.fromSnapshot(FinancialGoalSnapshot snapshot) => _GoalData(snapshot.title, snapshot.type, snapshot.saved, snapshot.target, snapshot.icon);
}
