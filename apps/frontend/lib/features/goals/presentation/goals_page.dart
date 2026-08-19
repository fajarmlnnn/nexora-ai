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
  final PageController _pageController = PageController();
  int _selectedTab = 0;
  bool _sortByProgress = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (index == _selectedTab) return;
    setState(() => _selectedTab = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final allGoals = ref.watch(financialGoalsProvider);
    final tabs = <List<FinancialGoalSnapshot>>[
      allGoals,
      allGoals.where((goal) => goal.type == 'Wishlist').toList(),
      allGoals.where((goal) => goal.type == 'Saving').toList(),
      allGoals.where((goal) => goal.type == 'Debt').toList(),
    ];

    return PremiumScaffold(
      child: Padding(
        padding: AppSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(onAdd: () => showAddGoalSheet(context, ref)),
            const SizedBox(height: 14),
            _Overview(goals: allGoals),
            const SizedBox(height: 14),
            _Tabs(selected: _selectedTab, onSelected: _selectTab),
            const SizedBox(height: 12),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const PageScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                itemCount: tabs.length,
                onPageChanged: (index) {
                  if (index != _selectedTab) {
                    setState(() => _selectedTab = index);
                  }
                },
                itemBuilder: (context, index) {
                  final goals = [...tabs[index]];
                  if (_sortByProgress) {
                    goals.sort((a, b) => b.progress.compareTo(a.progress));
                  }
                  return _GoalsList(
                    goals: goals,
                    showSectionHeader: index == 0,
                    sortByProgress: _sortByProgress,
                    onToggleSort: () => setState(
                      () => _sortByProgress = !_sortByProgress,
                    ),
                    showInsight: index == 0,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Goals', style: AppTypography.heading1),
                const SizedBox(height: 2),
                Text(
                  'Rencanakan target finansialmu',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAdd,
              borderRadius: AppRadius.radiusLG,
              child: Ink(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: AppRadius.radiusLG,
                  boxShadow: AppShadows.glow,
                ),
                child: const Icon(
                  LucideIcons.plus,
                  size: 27,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
}

class _Overview extends StatelessWidget {
  const _Overview({required this.goals});
  final List<FinancialGoalSnapshot> goals;

  @override
  Widget build(BuildContext context) {
    final saved = goals.fold<double>(0, (sum, goal) => sum + goal.saved);
    final target = goals.fold<double>(0, (sum, goal) => sum + goal.target);
    final remaining = (target - saved).clamp(0.0, double.infinity).toDouble();
    final progress = target <= 0
        ? 0.0
        : (saved / target).clamp(0.0, 1.0).toDouble();

    return PremiumCard(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      borderRadius: AppRadius.radiusXL,
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 78,
                height: 78,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) => SizedBox(
                        width: 78,
                        height: 78,
                        child: CircularProgressIndicator(
                          value: value,
                          strokeWidth: 8,
                          backgroundColor:
                              AppColors.border.withValues(alpha: .35),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primaryLight,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Progress semua goals', style: AppTypography.caption),
                    const SizedBox(height: 3),
                    RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        children: [
                          TextSpan(text: rupiah(saved)),
                          TextSpan(
                            text: ' tersimpan',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: AppTypography.caption,
                        children: [
                          const TextSpan(text: 'dari total '),
                          TextSpan(
                            text: rupiah(target),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const TextSpan(text: ' target'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 58,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .10),
                  borderRadius: AppRadius.radiusLG,
                ),
                child: Column(
                  children: [
                    const Icon(
                      LucideIcons.flag,
                      size: 17,
                      color: AppColors.primaryLight,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${goals.length}',
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text('Total goals', style: AppTypography.overline),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: AppColors.border.withValues(alpha: .32),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primaryLight,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sisa ${rupiah(remaining)} lagi',
                  style: AppTypography.caption,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;
  static const labels = ['Semua', 'Wishlist', 'Saving', 'Debt'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.radiusLG,
        border: Border.all(color: AppColors.border.withValues(alpha: .35)),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = selected == index;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: active ? AppGradients.primary : null,
                  borderRadius: AppRadius.radiusMD,
                  boxShadow: active ? AppShadows.glow : null,
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  style: AppTypography.caption.copyWith(
                    color: active ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                  child: Text(labels[index]),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _GoalsList extends StatelessWidget {
  const _GoalsList({
    required this.goals,
    required this.showSectionHeader,
    required this.sortByProgress,
    required this.onToggleSort,
    required this.showInsight,
  });
  final List<FinancialGoalSnapshot> goals;
  final bool showSectionHeader;
  final bool sortByProgress;
  final bool showInsight;
  final VoidCallback onToggleSort;

  @override
  Widget build(BuildContext context) {
    final extra = (showSectionHeader ? 1 : 0) + (showInsight ? 1 : 0);

    if (goals.isEmpty) {
      return ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: AppSpacing.bottomNav(context) + 20,
        ),
        children: [
          const SizedBox(height: 34),
          Center(
            child: Column(
              children: [
                const Icon(
                  LucideIcons.target,
                  size: 44,
                  color: AppColors.primaryLight,
                ),
                const SizedBox(height: 12),
                Text(
                  'Belum ada goal',
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Buat target pertama kamu.',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          if (showInsight) ...[
            const SizedBox(height: 22),
            const ContextAIInsight(
              message:
                  'Butuh bantuan mencapai goals? Nexora AI bisa membantu membuat rencana target dan rekomendasi langkah berikutnya.',
            ),
          ],
        ],
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        bottom: AppSpacing.bottomNav(context) + 20,
      ),
      itemCount: goals.length + extra,
      separatorBuilder: (context, index) => const SizedBox(height: 9),
      itemBuilder: (context, index) {
        if (showSectionHeader && index == 0) {
          return _SectionHeader(
            sortByProgress: sortByProgress,
            onToggleSort: onToggleSort,
          );
        }

        final goalIndex = index - (showSectionHeader ? 1 : 0);
        if (showInsight && goalIndex == goals.length) {
          return const ContextAIInsight(
            message:
                'Butuh bantuan mencapai goals? AI akan menganalisis kebiasaanmu dan membuat rekomendasi khusus untukmu.',
          );
        }
        return _GoalCard(goal: goals[goalIndex]);
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.sortByProgress,
    required this.onToggleSort,
  });
  final bool sortByProgress;
  final VoidCallback onToggleSort;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(
            'Goals aktif',
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onToggleSort,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(
              LucideIcons.slidersHorizontal,
              size: 17,
              color: AppColors.textSecondary,
            ),
            label: Text(
              sortByProgress ? 'Progress' : 'Urutkan',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});
  final FinancialGoalSnapshot goal;

  Color get _accent {
    if (goal.isCompleted) return AppColors.success;
    switch (goal.type) {
      case 'Wishlist':
        return const Color(0xFFFF6BB5);
      case 'Debt':
        return const Color(0xFFFF6375);
      default:
        return AppColors.primaryLight;
    }
  }

  String get _status {
    if (goal.isCompleted) return 'Tercapai';
    if (goal.progress >= .75) return 'On track';
    if (goal.progress >= .4) return 'Berjalan';
    return 'Perlu dorongan';
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return 'Tanpa deadline';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    final progress = goal.progress;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.radiusXL,
        onTap: () => context.push('/goals/${goal.id}'),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 12, 9, 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadius.radiusXL,
            border: Border.all(color: AppColors.border.withValues(alpha: .48)),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .12),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withValues(alpha: .18)),
                ),
                child: Icon(goal.icon, color: accent, size: 25),
              ),
              const SizedBox(width: 11),
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
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            goal.type,
                            style: AppTypography.overline.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedProgressBar(value: progress, color: accent),
                    const SizedBox(height: 5),
                    Text(
                      '${rupiah(goal.saved)} / ${rupiah(goal.target)}',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 84,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(progress * 100).round()}%',
                      style: AppTypography.labelLarge.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Sisa', style: AppTypography.overline),
                    Text(
                      rupiah(goal.remaining),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.overline.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          LucideIcons.calendarDays,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _dateLabel(goal.deadline),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.overline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  LucideIcons.moreVertical,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
