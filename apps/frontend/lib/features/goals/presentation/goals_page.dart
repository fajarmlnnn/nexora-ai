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
  static const _tabs = ['Semua', 'Wishlist', 'Saving', 'Debt'];
  int _selectedTab = 0;
  bool _sortByProgress = false;

  @override
  Widget build(BuildContext context) {
    final allGoals = ref.watch(financialGoalsProvider);
    final goals = switch (_selectedTab) {
      1 => allGoals.where((goal) => goal.type == 'Wishlist').toList(),
      2 => allGoals.where((goal) => goal.type == 'Saving').toList(),
      3 => allGoals.where((goal) => goal.type == 'Debt').toList(),
      _ => [...allGoals],
    };
    if (_sortByProgress) {
      goals.sort((a, b) => b.progress.compareTo(a.progress));
    }

    return PremiumScaffold(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _Header(onAdd: () => showAddGoalSheet(context, ref)),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(child: _Overview(goals: allGoals)),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _Tabs(
                labels: _tabs,
                selected: _selectedTab,
                onSelected: (value) => setState(() => _selectedTab = value),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
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
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          if (goals.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: _EmptyGoals(
                  onAdd: () => showAddGoalSheet(context, ref),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index.isOdd) return const SizedBox(height: 12);
                    final goal = goals[index ~/ 2];
                    return _GoalCard(
                      goal: goal,
                      onTap: () => context.push('/goals/${goal.id}'),
                    );
                  },
                  childCount: goals.length * 2 - 1,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: const SliverToBoxAdapter(child: _AIRecommendation()),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 108 + MediaQuery.paddingOf(context).bottom,
            ),
          ),
        ],
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
        _GlowIconButton(icon: LucideIcons.plus, onTap: onAdd),
      ],
    );
  }
}

class _GlowIconButton extends StatelessWidget {
  const _GlowIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.goalsPurpleBright, AppColors.goalsPurple],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: .14)),
            boxShadow: [
              BoxShadow(
                color: AppColors.goalsPurpleBright.withValues(alpha: .28),
                blurRadius: 18,
                spreadRadius: -3,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 24),
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
        border: Border.all(color: const Color(0xFF5E4A8D).withValues(alpha: .25)),
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
            children: [
              _ProgressDonut(value: progress),
              const SizedBox(width: 16),
              Expanded(child: _SummaryText(saved: saved, target: target)),
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
                color: Colors.white,
                fontWeight: FontWeight.w800,
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
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - 5,
    );
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = AppColors.goalsTrack;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [AppColors.goalsPurpleBright, AppColors.goalsPurple],
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, fill);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.value != value;
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
          const Icon(LucideIcons.flag, size: 15, color: AppColors.goalsPurpleBright),
          const SizedBox(height: 2),
          Text('$count', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
          Text('Total', style: AppTypography.overline.copyWith(fontSize: 7)),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * value.clamp(0.0, 1.0);
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: AppColors.goalsProgressTrack)),
                SizedBox(
                  width: width,
                  height: height,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.goalsPurple, AppColors.goalsPurpleBright],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.labels, required this.selected, required this.onSelected});
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
        border: Border.all(color: Colors.white.withValues(alpha: .05)),
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
                      ? const LinearGradient(colors: [AppColors.goalsPurple, Color(0xFF8B5CF6)])
                      : null,
                ),
                child: Text(
                  labels[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: active ? Colors.white : const Color(0xFFA3AEC4),
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
  const _SectionHeader({required this.sortByProgress, required this.onToggleSort});
  final bool sortByProgress;
  final VoidCallback onToggleSort;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Goals aktif',
            style: AppTypography.heading3.copyWith(fontWeight: FontWeight.w800),
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
            color: sortByProgress ? AppColors.goalsPurpleBright : AppColors.textSecondary,
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

  Color get accent {
    if (goal.type == 'Wishlist') return AppColors.goalsWishlistText;
    if (goal.type == 'Debt') return const Color(0xFFFF6B7A);
    return AppColors.goalsPurpleBright;
  }

  @override
  Widget build(BuildContext context) {
    final saving = goal.type == 'Saving';
    final iconBackground = goal.type == 'Wishlist'
        ? AppColors.goalsWishlistIcon
        : goal.type == 'Debt'
            ? const Color(0xFF251B2D)
            : AppColors.goalsSavingIconInner;

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
            border: Border.all(color: accent.withValues(alpha: .11)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: .06),
                blurRadius: 18,
                spreadRadius: -7,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: saving
                      ? const RadialGradient(
                          colors: [AppColors.goalsSavingIconOuter, AppColors.goalsSavingIconInner],
                        )
                      : null,
                  color: saving ? null : iconBackground,
                  border: Border.all(color: accent.withValues(alpha: .16)),
                ),
                child: Icon(
                  goal.icon,
                  size: 23,
                  color: saving ? AppColors.goalsPurpleBright : accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GoalMain(goal: goal, accent: accent),
              ),
              const SizedBox(width: 10),
              SizedBox(width: 74, child: _GoalSide(goal: goal, accent: accent)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalMain extends StatelessWidget {
  const _GoalMain({required this.goal, required this.accent});
  final FinancialGoalSnapshot goal;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final description = switch (goal.type) {
      'Wishlist' => 'Target wishlist pribadi',
      'Debt' => 'Rencana pelunasan finansial',
      _ => 'Keamanan finansial utama',
    };

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
                style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                goal.type,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.overline.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10.5,
          ),
        ),
        const SizedBox(height: 8),
        _GradientProgressBar(value: goal.progress, height: 4),
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
            const SizedBox(width: 2),
            const Icon(LucideIcons.ellipsisVertical, size: 17, color: AppColors.textSecondary),
          ],
        ),
        const SizedBox(height: 5),
        Text('Sisa', style: AppTypography.overline.copyWith(color: AppColors.textSecondary)),
        Text(
          rupiah(goal.remaining),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Icon(LucideIcons.calendarDays, size: 12, color: AppColors.textSecondary),
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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
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
            border: Border.all(color: AppColors.goalsPurpleBright.withValues(alpha: .20)),
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w800),
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
          const Icon(LucideIcons.target, size: 36, color: AppColors.goalsPurpleBright),
          const SizedBox(height: 10),
          Text(
            'Belum ada goal',
            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Buat target pertama kamu untuk mulai merencanakan keuangan.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
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
