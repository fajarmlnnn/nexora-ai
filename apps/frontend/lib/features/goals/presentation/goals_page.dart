import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(length: 4, vsync: this);

  final goals = const [
    _GoalData('MacBook Pro', 'Wishlist', 0.62, 1550, 2500, LucideIcons.laptop, AppColors.primary),
    _GoalData('Emergency Fund', 'Saving', 0.78, 7800, 10000, LucideIcons.shieldCheck, AppColors.success),
    _GoalData('Credit Card', 'Debt', 0.44, 2200, 5000, LucideIcons.creditCard, AppColors.danger),
    _GoalData('Japan Trip', 'Wishlist', 0.36, 1800, 5000, LucideIcons.plane, AppColors.info),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 82),
        child: FloatingActionButton(
          heroTag: 'goals-add',
          onPressed: () {},
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          child: const Icon(LucideIcons.plus, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Goals', style: AppTypography.heading1),
              AppSpacing.gapXS,
              Text('Track dreams, savings, and debt in one place.', style: AppTypography.bodyMedium),
              AppSpacing.gapLG,
              Container(
                height: 52,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: AppRadius.radiusXL),
                child: TabBar(
                  controller: _controller,
                  indicator: BoxDecoration(gradient: AppGradients.primary, borderRadius: AppRadius.radiusLG),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: AppTypography.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: const [Tab(text: 'All'), Tab(text: 'Wishlist'), Tab(text: 'Saving'), Tab(text: 'Debt')],
                ),
              ),
              AppSpacing.gapLG,
              Expanded(
                child: TabBarView(
                  controller: _controller,
                  children: [
                    _GoalList(goals: goals),
                    _GoalList(goals: goals.where((g) => g.type == 'Wishlist').toList()),
                    _GoalList(goals: goals.where((g) => g.type == 'Saving').toList()),
                    _GoalList(goals: goals.where((g) => g.type == 'Debt').toList()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalList extends StatelessWidget {
  const _GoalList({required this.goals});
  final List<_GoalData> goals;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: goals.length,
      separatorBuilder: (_, __) => AppSpacing.gapMD,
      itemBuilder: (context, index) => _GoalCard(goal: goals[index]),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});
  final _GoalData goal;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: AppRadius.radiusXL, border: Border.all(color: AppColors.border.withValues(alpha: .55)), boxShadow: AppShadows.card),
      child: Row(
        children: [
          Container(width: 62, height: 62, decoration: BoxDecoration(color: goal.color.withValues(alpha: .16), borderRadius: AppRadius.radiusXL), child: Icon(goal.icon, color: goal.color, size: 30)),
          AppSpacing.hGapMD,
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text(goal.title, style: AppTypography.labelLarge)), Text('${(goal.progress * 100).round()}%', style: AppTypography.labelMedium.copyWith(color: goal.color))]),
              AppSpacing.gapXXS,
              Text(goal.type, style: AppTypography.bodySmall),
              AppSpacing.gapSM,
              ClipRRect(borderRadius: AppRadius.radiusLG, child: LinearProgressIndicator(value: goal.progress, minHeight: 8, color: goal.color, backgroundColor: AppColors.divider)),
              AppSpacing.gapXS,
              Text('\$${goal.saved.toStringAsFixed(0)} saved of \$${goal.target.toStringAsFixed(0)}', style: AppTypography.caption),
            ]),
          ),
        ],
      ),
    );
  }
}

class _GoalData {
  const _GoalData(this.title, this.type, this.progress, this.saved, this.target, this.icon, this.color);
  final String title;
  final String type;
  final double progress;
  final double saved;
  final double target;
  final IconData icon;
  final Color color;
}
