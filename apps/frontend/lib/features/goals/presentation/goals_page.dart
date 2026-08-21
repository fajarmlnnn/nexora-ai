import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../controllers/supabase_goals_controller.dart';
import 'add_goal_sheet.dart';

class GoalsPage extends ConsumerStatefulWidget {
  const GoalsPage({super.key});

  @override
  ConsumerState<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends ConsumerState<GoalsPage> {
  int _selectedTab = 0;
  bool _sortByProgress = false;

  static const _tabs = ['Semua', 'Wishlist', 'Saving', 'Debt'];

  @override
  Widget build(BuildContext context) {
    final allGoals = ref.watch(financialGoalsProvider);
    final filteredGoals = switch (_selectedTab) {
      1 => allGoals.where((goal) => goal.type == 'Wishlist').toList(),
      2 => allGoals.where((goal) => goal.type == 'Saving').toList(),
      3 => allGoals.where((goal) => goal.type == 'Debt').toList(),
      _ => [...allGoals],
    };

    if (_sortByProgress) {
      filteredGoals.sort((a, b) => b.progress.compareTo(a.progress));
    }

    return PremiumScaffold(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _Header(
                    onAdd: () => showAddGoalSheet(context, ref),
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(top: 24)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: _Overview(goals: allGoals),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(top: 24)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: _Tabs(
                    labels: _tabs,
                    selected: _selectedTab,
                    onSelected: (index) => setState(() => _selectedTab = index),
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(top: 20)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: _SectionHeader(
                    sortByProgress: _sortByProgress,
                    onToggleSort: () => setState(
                      () => _sortByProgress = !_sortByProgress,
                    ),
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(top: 12)),
              if (filteredGoals.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: _EmptyGoals(onAdd: () => showAddGoalSheet(context, ref)),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: filteredGoals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final goal = filteredGoals[index];
                      return _GoalCard(
                        goal: goal,
                        onTap: () => context.push('/goals/${goal.id}'),
                      );
                    },
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(top: 20)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: _AIRecommendation(),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.only(
                  top: 18,
                  bottom: 108 + MediaQuery.paddingOf(context).bottom,
                ),
                sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Goals',
                style: AppTypography.heading1.copyWith(
                  fontSize: 30,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Rencanakan target finansialmu',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _GlowIconButton(
          icon: LucideIcons.plus,
          onTap: onAdd,
          size: 40,
          iconSize: 24,
        ),
      ],
    );
  }
}

class _GlowIconButton extends StatelessWidget {
  const _GlowIconButton({
    required this.icon,
    required this.onTap,
    this.size = 40,
    this.iconSize = 22,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.goalsPurpleBright, AppColors.goalsPurple],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: .14),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.goalsPurpleBright.withValues(alpha: .28),
                blurRadius: 18,
                spreadRadius: -3,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.goals});

  final List<FinancialGoalSnapshot> goals;

  @override
  Widget build(BuildContext context) {
    final saved = goals.fold<double>(0, (sum, goal) => sum + goal.saved);
    final target = goals.fold<double>(0, (sum, goal) => sum + goal.target);
    final progress = target <= 0
        ? 0.0
        : (saved / target).clamp(0.0, 1.0).toDouble();
    final remaining = math.max(0, target - saved).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.goalsSummaryCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF5E4A8D).withValues(alpha: .25),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.goalsPurple.withValues(alpha: .12),
            blurRadius: 28,
            spreadRadius: -10,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ProgressDonut(value: progress),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryText(saved: saved, target: target),
              ),
              const SizedBox(width: 8),
              _TotalGoalsBadge(count: goals.length),
            ],
          ),
          const SizedBox(height: 20),
          _GradientProgressBar(value: progress, height: 7),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sisa ${rupiah(remaining)} lagi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.goalsPurpleBright,
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

class _SummaryText extends StatelessWidget {
  const _SummaryText({required this.saved, required this.target});

  final double saved;
  final double target;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress semua goals',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: RichText(
            text: TextSpan(
              style: AppTypography.heading3.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              children: [
                TextSpan(text: rupiah(saved)),
                TextSpan(
                  text: ' tersimpan',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.goalsPurpleBright,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: RichText(
            text: TextSpan(
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              children: [
                const TextSpan(text: 'dari total '),
                TextSpan(
                  text: rupiah(target),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.goalsPurpleBright,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const TextSpan(text: ' target'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressDonut extends StatelessWidget {
  const _ProgressDonut({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return SizedBox(
          width: 70,
          height: 70,
          child: CustomPaint(
            painter: _DonutPainter(value: animatedValue),
            child: Center(
              child: Text(
                '${(value * 100).round()}%',
                style: AppTypography.labelLarge.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.value});

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide / 2) - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.butt
      ..color = AppColors.goalsTrack;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    final shader = const LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [AppColors.goalsPurpleBright, AppColors.goalsPurple],
    ).createShader(rect);
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.butt
      ..shader = shader;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.value != value;
}

class _TotalGoalsBadge extends StatelessWidget {
  const _TotalGoalsBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 55,
      decoration: BoxDecoration(
        color: AppColors.goalsTotalBadge,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.flag,
            size: 15,
            color: AppColors.goalsPurpleBright,
          ),
          const SizedBox(height: 2),
          Text(
            '$count',
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Total',
            style: AppTypography.overline.copyWith(fontSize: 7),
          ),
        ],
      ),
    );
  }
}

class _GradientProgressBar extends StatelessWidget {
  const _GradientProgressBar({required this.value, this.height = 6});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        children: [
          Container(
            height: height,
            width: double.infinity,
            color: AppColors.goalsProgressTrack,
          ),
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0).toDouble(),
            child: Container(
              height: height,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.goalsPurple, AppColors.goalsPurpleBright],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.goalsCardAlt.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: .05),
        ),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = index == selected;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: active
                      ? const LinearGradient(
                          colors: [
                            AppColors.goalsPurple,
                            Color(0xFF8B5CF6),
                          ],
                        )
                      : null,
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.goalsPurpleBright.withValues(
                              alpha: .24,
                            ),
                            blurRadius: 14,
                            spreadRadius: -5,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  labels[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: active
                        ? Colors.white
                        : const Color(0xFFA3AEC4),
                    fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
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
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Goals aktif',
            style: AppTypography.heading3.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onToggleSort,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: Icon(
            LucideIcons.slidersHorizontal,
            size: 18,
            color: sortByProgress
                ? AppColors.goalsPurpleBright
                : AppColors.textSecondary,
          ),
          label: Text(
            sortByProgress ? 'Progress' : 'Urutkan',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.onTap});

  final FinancialGoalSnapshot goal;
  final VoidCallback onTap;

  bool get _wishlist => goal.type == 'Wishlist';
  bool get _debt => goal.type == 'Debt';

  Color get _accent {
    if (_wishlist) return AppColors.goalsWishlistText;
    if (_debt) return const Color(0xFFFF6B7A);
    return AppColors.goalsPurpleBright;
  }

  Color get _iconBackground {
    if (_wishlist) return AppColors.goalsWishlistIcon;
    if (_debt) return const Color(0xFF251B2D);
    return AppColors.goalsSavingIconInner;
  }

  String get _badgeLabel => goal.type;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          constraints: const BoxConstraints(minHeight: 100),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.goalsCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _accent.withValues(alpha: .11),
            ),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: .06),
                blurRadius: 18,
                spreadRadius: -7,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 330;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GoalIcon(goal: goal, background: _iconBackground),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GoalMain(
                      goal: goal,
                      accent: _accent,
                      badgeLabel: _badgeLabel,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: compact ? 65 : 76,
                    child: _GoalSide(goal: goal, accent: _accent),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GoalIcon extends StatelessWidget {
  const _GoalIcon({required this.goal, required this.background});

  final FinancialGoalSnapshot goal;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final isSaving = goal.type == 'Saving';
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isSaving
            ? const RadialGradient(
                colors: [
                  AppColors.goalsSavingIconOuter,
                  AppColors.goalsSavingIconInner,
                ],
              )
            : null,
        color: isSaving ? null : background,
        border: Border.all(
          color: isSaving
              ? AppColors.goalsPurpleBright.withValues(alpha: .18)
              : Colors.white.withValues(alpha: .06),
        ),
      ),
      child: Icon(
        goal.icon,
        size: 23,
        color: isSaving ? AppColors.goalsPurpleBright : AppColors.goalsWishlistText,
      ),
    );
  }
}

class _GoalMain extends StatelessWidget {
  const _GoalMain({
    required this.goal,
    required this.accent,
    required this.badgeLabel,
  });

  final FinancialGoalSnapshot goal;
  final Color accent;
  final String badgeLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                goal.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.overline.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 8,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          _descriptionFor(goal),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10.5,
          ),
        ),
        const SizedBox(height: 8),
        _GradientProgressBar(
          value: goal.progress,
          height: 4,
        ),
        const SizedBox(height: 6),
        Text(
          '${rupiah(goal.saved)} / ${rupiah(goal.target)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.overline.copyWith(
            color: AppColors.textSecondary,
            fontSize: 8.5,
          ),
        ),
      ],
    );
  }

  String _descriptionFor(FinancialGoalSnapshot goal) {
    switch (goal.type) {
      case 'Wishlist':
        return 'Target wishlist pribadi';
      case 'Debt':
        return 'Rencana pelunasan finansial';
      default:
        return 'Keamanan finansial utama';
    }
  }
}

class _GoalSide extends StatelessWidget {
  const _GoalSide({required this.goal, required this.accent});

  final FinancialGoalSnapshot goal;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final percent = (goal.progress * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '$percent%',
              style: AppTypography.heading3.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              LucideIcons.ellipsisVertical,
              size: 17,
              color: AppColors.textSecondary,
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'Sisa',
          style: AppTypography.overline.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          rupiah(goal.remaining),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Icon(
              LucideIcons.calendarDays,
              size: 12,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _dateLabel(goal.deadline),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.overline.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 7.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return 'Tanpa tanggal';
    const months = [
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
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _AIRecommendation extends StatelessWidget {
  const _AIRecommendation();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/ai'),
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 95,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.goalsPromo,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.goalsPurpleBright.withValues(alpha: .20),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.goalsPurple.withValues(alpha: .20),
                blurRadius: 26,
                spreadRadius: -8,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.goalsPromoAvatar,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.goalsPurpleBright.withValues(alpha: .34),
                      blurRadius: 18,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: NexoraRobot(size: 48, waving: false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '✦ Nexora AI',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.goalsPurpleBright,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.goalsPurple.withValues(alpha: .20),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'AI',
                            style: AppTypography.overline.copyWith(
                              color: AppColors.goalsPurpleBright,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Butuh bantuan capai goals?',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Dapatkan rekomendasi finansial yang lebih personal.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.overline.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 8.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lihat rekomendasi →',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.goalsPurpleBright,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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

class _EmptyGoals extends StatelessWidget {
  const _EmptyGoals({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.goalsCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Column(
        children: [
          const Icon(
            LucideIcons.target,
            size: 36,
            color: AppColors.goalsPurpleBright,
          ),
          const SizedBox(height: 10),
          Text(
            'Belum ada goal',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Buat target pertama kamu untuk mulai merencanakan keuangan.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Buat goal'),
          ),
        ],
      ),
    );
  }
}
