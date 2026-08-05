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

class _GoalsPageState extends State<GoalsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(length: 4, vsync: this);

  final goals = const [
    _GoalData(
      'Dana Darurat',
      'Wishlist',
      0.62,
      10000000,
      50000000,
      LucideIcons.laptop,
      AppColors.primary,
    ),
    _GoalData(
      'Liburan ke Jepang',
      'Saving',
      0.78,
      7000000,
      20000000,
      LucideIcons.shieldCheck,
      AppColors.success,
    ),
    _GoalData(
      'SPayLater',
      'Debt',
      0.44,
      1250000,
      2500000,
      LucideIcons.creditCard,
      AppColors.danger,
    ),
    _GoalData(
      'DP Rumah',
      'Wishlist',
      0.36,
      18000000,
      60000000,
      LucideIcons.plane,
      AppColors.info,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
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
      child: Padding(
        padding: AppSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Goals', style: AppTypography.heading1),
            AppSpacing.gapXS,
            Text(
              'Track dreams, savings, and debt in one place.',
              style: AppTypography.bodyMedium,
            ),
            AppSpacing.gapLG,
            Container(
              height: 52,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.radiusXL,
              ),
              child: TabBar(
                controller: _controller,
                indicator: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: AppRadius.radiusLG,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: AppTypography.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelColor: AppColors.textSecondary,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Wishlist'),
                  Tab(text: 'Saving'),
                  Tab(text: 'Debt'),
                ],
              ),
            ),
            AppSpacing.gapLG,
            Expanded(
              child: TabBarView(
                controller: _controller,
                children: [
                  _GoalList(goals: goals, showCelebration: true),
                  _GoalList(
                    goals: goals.where((g) => g.type == 'Wishlist').toList(),
                  ),
                  _GoalList(
                    goals: goals.where((g) => g.type == 'Saving').toList(),
                  ),
                  _GoalList(
                    goals: goals.where((g) => g.type == 'Debt').toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalList extends StatelessWidget {
  const _GoalList({required this.goals, this.showCelebration = false});
  final List<_GoalData> goals;
  final bool showCelebration;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: goals.length + (showCelebration ? 1 : 0),
      separatorBuilder: (_, _) => AppSpacing.gapMD,
      itemBuilder: (context, index) {
        if (showCelebration && index == goals.length) {
          return const _CelebrationCard();
        }
        return _GoalCard(goal: goals[index]);
      },
    );
  }
}

class _CelebrationCard extends StatelessWidget {
  const _CelebrationCard();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Row(
        children: [
          const NexoraRobot(size: 86),
          AppSpacing.hGapMD,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kamu Hebat! 🎉', style: AppTypography.heading3),
                AppSpacing.gapXS,
                Text(
                  'Tabunganmu bulan ini naik 18% dibanding bulan lalu. Pertahankan ritmenya.',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
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
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.radiusXL,
        border: Border.all(color: AppColors.border.withValues(alpha: .55)),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: goal.color.withValues(alpha: .16),
              borderRadius: AppRadius.radiusXL,
            ),
            child: Icon(goal.icon, color: goal.color, size: 30),
          ),
          AppSpacing.hGapMD,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(goal.title, style: AppTypography.labelLarge),
                    ),
                    Text(
                      '${(goal.progress * 100).round()}%',
                      style: AppTypography.labelMedium.copyWith(
                        color: goal.color,
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapXXS,
                Text(goal.type, style: AppTypography.bodySmall),
                AppSpacing.gapSM,
                AnimatedProgressBar(value: goal.progress, color: goal.color),
                AppSpacing.gapXS,
                Text(
                  '${rupiah(goal.saved)} / ${rupiah(goal.target)}',
                  style: AppTypography.caption,
                ),
                AppSpacing.gapXS,
                Text(
                  'AI: ${goal.suggestion}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalData {
  const _GoalData(
    this.title,
    this.type,
    this.progress,
    this.saved,
    this.target,
    this.icon,
    this.color,
  );
  final String title;
  final String type;
  final double progress;
  final double saved;
  final double target;
  final IconData icon;
  String get suggestion {
    final monthly = ((target - saved) / 8).round();
    return 'kontribusi ${rupiah(monthly)}/bulan, estimasi selesai Feb 2027';
  }

  final Color color;
}
