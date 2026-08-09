import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(length: 4, vsync: this);

  final goals = const [
    _GoalData('Dana Darurat', 'Wishlist', 10000000, 50000000, LucideIcons.shieldCheck, AppColors.primary),
    _GoalData('Liburan ke Jepang', 'Saving', 7000000, 20000000, LucideIcons.plane, AppColors.success),
    _GoalData('SPayLater', 'Debt', 1250000, 2500000, LucideIcons.creditCard, AppColors.danger),
    _GoalData('DP Rumah', 'Wishlist', 18000000, 60000000, LucideIcons.house, AppColors.info),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      child: Padding(
        padding: AppSpacing.screen.copyWith(bottom: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GoalsHeader(),
            const SizedBox(height: 12),
            _GoalsOverview(goals: goals),
            const SizedBox(height: 12),
            _GoalTabs(controller: _controller),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _controller,
                children: [
                  _GoalList(goals: goals, showInsight: true),
                  _GoalList(goals: goals.where((g) => g.type == 'Wishlist').toList()),
                  _GoalList(goals: goals.where((g) => g.type == 'Saving').toList()),
                  _GoalList(goals: goals.where((g) => g.type == 'Debt').toList()),
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
  const _GoalsHeader();

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
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.card,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border.withValues(alpha: .45)),
          ),
          child: const Icon(LucideIcons.plus, color: AppColors.primaryLight, size: 20),
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      borderRadius: AppRadius.radiusXL,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF20273A), Color(0xFF171D2B)],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: AppColors.border.withValues(alpha: .35),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
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
  const _GoalTabs({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: .72),
        borderRadius: AppRadius.radiusLG,
        border: Border.all(color: AppColors.border.withValues(alpha: .3)),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: AppRadius.radiusMD,
          boxShadow: AppShadows.glow,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelPadding: EdgeInsets.zero,
        labelStyle: AppTypography.caption.copyWith(fontWeight: FontWeight.w800),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        tabs: const [
          Tab(text: 'Semua'),
          Tab(text: 'Wishlist'),
          Tab(text: 'Saving'),
          Tab(text: 'Debt'),
        ],
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
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (showInsight && index == goals.length) return const _GoalInsight();
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.radiusXL,
        border: Border.all(color: AppColors.border.withValues(alpha: .5)),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: goal.color.withValues(alpha: .13),
              borderRadius: AppRadius.radiusLG,
            ),
            child: Icon(goal.icon, color: goal.color, size: 23),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(goal.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    Text('${(progress * 100).round()}%', style: AppTypography.caption.copyWith(color: goal.color, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Text(goal.type, style: AppTypography.caption),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: goal.color.withValues(alpha: .10),
                        borderRadius: AppRadius.radiusPill,
                      ),
                      child: Text(status, style: AppTypography.caption.copyWith(color: goal.color, fontSize: 9, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                AnimatedProgressBar(value: progress, color: goal.color),
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

class _GoalInsight extends StatelessWidget {
  const _GoalInsight();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: AppRadius.radiusXL,
      child: Row(
        children: [
          const NexoraRobot(size: 48),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nexora Insight', style: AppTypography.caption.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('Prioritaskan Dana Darurat agar fondasi keuanganmu lebih aman.', maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.caption),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _GoalData {
  const _GoalData(this.title, this.type, this.saved, this.target, this.icon, this.color);

  final String title;
  final String type;
  final double saved;
  final double target;
  final IconData icon;
  final Color color;

  double get progress => target <= 0 ? 0 : (saved / target).clamp(0.0, 1.0);
}
