import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../controllers/supabase_goals_controller.dart';
import 'add_goal_sheet.dart';

const _purpleStart = Color(0xFF6A3BD7);
const _purpleEnd = Color(0xFF9567FD);
const _purpleText = Color(0xFFA78BFA);
const _rose = Color(0xFFD65B9E);
const _roseText = Color(0xFFF472B6);
const _mutedText = Color(0xFFA3AEC4);
const _goalCard = Color(0xFF12121E);
const _track = Color(0xFF1D1B30);

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
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screen.left,
          50,
          AppSpacing.screen.right,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(onAdd: () => showAddGoalSheet(context, ref)),
            const SizedBox(height: 28),
            _Overview(goals: allGoals),
            const SizedBox(height: 24),
            _Tabs(selected: _selectedTab, onSelected: _selectTab),
            const SizedBox(height: 20),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
                itemCount: tabs.length,
                onPageChanged: (index) {
                  if (index != _selectedTab) setState(() => _selectedTab = index);
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
                    onToggleSort: () => setState(() => _sortByProgress = !_sortByProgress),
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
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Goals', style: AppTypography.heading1.copyWith(fontSize: 30, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('Rencanakan target finansialmu', style: AppTypography.bodyMedium.copyWith(color: _mutedText)),
              ],
            ),
          ),
          _GlowButton(onTap: onAdd, size: 40, iconSize: 25),
        ],
      );
}

class _GlowButton extends StatelessWidget {
  const _GlowButton({required this.onTap, required this.size, required this.iconSize});
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(size / 2),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [_purpleStart, _purpleEnd]),
              boxShadow: [BoxShadow(color: _purpleEnd.withValues(alpha: .38), blurRadius: 22, spreadRadius: 1)],
            ),
            child: Icon(LucideIcons.plus, color: Colors.white, size: iconSize),
          ),
        ),
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
    final progress = target <= 0 ? 0.0 : (saved / target).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF120F22),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: .07)),
        boxShadow: [BoxShadow(color: _purpleStart.withValues(alpha: .12), blurRadius: 24, spreadRadius: -12)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _GradientDonut(value: progress, size: 70),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Progress semua goals', style: AppTypography.caption.copyWith(color: _mutedText, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(style: AppTypography.heading3.copyWith(fontSize: 17, fontWeight: FontWeight.w800), children: [
                        TextSpan(text: rupiah(saved)),
                        TextSpan(text: ' tersimpan', style: AppTypography.caption.copyWith(color: _purpleText, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(style: AppTypography.caption.copyWith(color: _mutedText, fontSize: 11), children: [
                        const TextSpan(text: 'dari total '),
                        TextSpan(text: rupiah(target), style: const TextStyle(color: _purpleText, fontWeight: FontWeight.w800)),
                        const TextSpan(text: ' target'),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 58,
                height: 64,
                decoration: BoxDecoration(color: const Color(0xFF1B1435), borderRadius: BorderRadius.circular(16)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(LucideIcons.flag, size: 16, color: _purpleText),
                  const SizedBox(height: 2),
                  Text('${goals.length}', style: AppTypography.heading3.copyWith(fontWeight: FontWeight.w800)),
                  Text('Total goals', style: AppTypography.overline.copyWith(color: _mutedText)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _AnimatedBar(value: progress, color: _purpleEnd, height: 7),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text('Sisa ${rupiah(remaining)} lagi', style: AppTypography.caption.copyWith(color: _mutedText, fontSize: 12))),
            Text('${(progress * 100).round()}%', style: AppTypography.labelLarge.copyWith(color: _purpleText, fontWeight: FontWeight.w900)),
          ]),
        ],
      ),
    );
  }
}

class _GradientDonut extends StatelessWidget {
  const _GradientDonut({required this.value, required this.size});
  final double value;
  final double size;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, 1).toDouble()),
        duration: const Duration(milliseconds: 850),
        curve: Curves.easeOutCubic,
        builder: (context, animated, child) => SizedBox.square(
          dimension: size,
          child: Stack(alignment: Alignment.center, children: [
            CustomPaint(size: Size.square(size), painter: _DonutPainter(value: animated)),
            Text('${(animated * 100).round()}%', style: AppTypography.heading3.copyWith(fontSize: 17, fontWeight: FontWeight.w900)),
          ]),
        ),
      );
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.value});
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = size.width * .13;
    final track = Paint()
      ..color = const Color(0xFF1A1830)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final arc = Paint()
      ..shader = const SweepGradient(colors: [_purpleStart, _purpleEnd, _purpleStart]).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawArc(rect.deflate(stroke / 2), 0, math.pi * 2, false, track);
    canvas.drawArc(rect.deflate(stroke / 2), -math.pi / 2, math.pi * 2 * value, false, arc);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.value != value;
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;
  static const labels = ['Semua', 'Wishlist', 'Saving', 'Debt'];

  @override
  Widget build(BuildContext context) => Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF10101A).withValues(alpha: .85),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: .07)),
        ),
        child: Row(
          children: List.generate(labels.length, (index) {
            final active = selected == index;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: active ? const LinearGradient(colors: [_purpleStart, Color(0xFF8B5CF6)]) : null,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: active ? [BoxShadow(color: _purpleEnd.withValues(alpha: .28), blurRadius: 18, spreadRadius: -5)] : null,
                  ),
                  child: Text(labels[index], style: AppTypography.labelMedium.copyWith(color: active ? Colors.white : _mutedText, fontWeight: FontWeight.w800)),
                ),
              ),
            );
          }),
        ),
      );
}

class _GoalsList extends StatelessWidget {
  const _GoalsList({required this.goals, required this.showSectionHeader, required this.sortByProgress, required this.onToggleSort, required this.showInsight});
  final List<FinancialGoalSnapshot> goals;
  final bool showSectionHeader;
  final bool sortByProgress;
  final bool showInsight;
  final VoidCallback onToggleSort;

  @override
  Widget build(BuildContext context) {
    final bottomGap = MediaQuery.paddingOf(context).bottom + 98;
    if (goals.isEmpty) {
      return ListView(padding: EdgeInsets.only(bottom: bottomGap), physics: const BouncingScrollPhysics(), children: [
        if (showSectionHeader) _ListHeader(sortByProgress: sortByProgress, onToggleSort: onToggleSort),
        const EmptyStateCard(icon: LucideIcons.target, title: 'Belum ada goal', message: 'Tambahkan target finansial pertamamu agar Nexora bisa memantau progress.', action: 'Tambah Goal'),
        if (showInsight) ...[const SizedBox(height: 20), const _AiPromoCard()],
      ]);
    }

    return ListView.separated(
      padding: EdgeInsets.only(bottom: bottomGap),
      physics: const BouncingScrollPhysics(),
      itemCount: goals.length + (showSectionHeader ? 1 : 0) + (showInsight ? 1 : 0),
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (showSectionHeader && index == 0) return _ListHeader(sortByProgress: sortByProgress, onToggleSort: onToggleSort);
        final goalIndex = index - (showSectionHeader ? 1 : 0);
        if (showInsight && goalIndex == goals.length) return const Padding(padding: EdgeInsets.only(top: 8), child: _AiPromoCard());
        return _GoalCard(goal: goals[goalIndex]);
      },
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.sortByProgress, required this.onToggleSort});
  final bool sortByProgress;
  final VoidCallback onToggleSort;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Expanded(child: Text('Goals aktif', style: AppTypography.heading3.copyWith(fontSize: 17, fontWeight: FontWeight.w800))),
          TextButton.icon(
            onPressed: onToggleSort,
            icon: Icon(sortByProgress ? LucideIcons.arrowDownWideNarrow : LucideIcons.slidersHorizontal, size: 16, color: _mutedText),
            label: Text('Urutkan', style: AppTypography.caption.copyWith(color: _mutedText, fontWeight: FontWeight.w700)),
          ),
        ]),
      );
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});
  final FinancialGoalSnapshot goal;

  bool get _wishlist => goal.type == 'Wishlist';
  Color get _accent => _wishlist ? _rose : _purpleEnd;
  Color get _percentColor => _wishlist ? _roseText : _purpleText;
  Color get _iconBg => _wishlist ? const Color(0xFF2E1E3B) : const Color(0xFF261D48);
  String get _description {
    final title = goal.title.toLowerCase();
    if (title.contains('darurat')) return 'Keamanan finansial utama';
    if (title.contains('laptop')) return 'Untuk produktivitas kerja';
    if (title.contains('jepang') || title.contains('liburan')) return 'Trip impian musim semi';
    return goal.type == 'Debt' ? 'Lunasi kewajiban bertahap' : 'Target finansial aktif';
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return 'Tanpa deadline';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = goal.progress;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/goals/${goal.id}'),
        child: Ink(
          height: 85,
          padding: const EdgeInsets.fromLTRB(16, 11, 10, 11),
          decoration: BoxDecoration(
            color: _goalCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _purpleEnd.withValues(alpha: .10)),
            boxShadow: [BoxShadow(color: _purpleEnd.withValues(alpha: .09), blurRadius: 18, spreadRadius: -12)],
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _iconBg,
                gradient: goal.type == 'Saving' ? const RadialGradient(colors: [Color(0xFF261D48), Color(0xFF6B54A2)]) : null,
                border: Border.all(color: _accent.withValues(alpha: .22)),
              ),
              child: Icon(goal.icon, color: _percentColor, size: 23),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(goal.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _wishlist ? _rose : const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(99)),
                    child: Text(goal.type, style: AppTypography.overline.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ]),
                const SizedBox(height: 2),
                Text(_description, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(color: _mutedText, fontSize: 10.5)),
                const SizedBox(height: 8),
                _AnimatedBar(value: progress, color: progress == 0 ? _track : _accent, height: 4),
                const SizedBox(height: 6),
                Text('${rupiah(goal.saved)} / ${rupiah(goal.target)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(color: _mutedText, fontSize: 10.5, fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 82,
              child: Stack(children: [
                Positioned(right: 0, top: 0, child: Icon(LucideIcons.moreVertical, size: 17, color: _mutedText.withValues(alpha: .9))),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${(progress * 100).round()}%', style: AppTypography.heading3.copyWith(color: _percentColor, fontWeight: FontWeight.w900, fontSize: 20)),
                    const SizedBox(height: 2),
                    Text('Sisa\n${rupiah(goal.remaining)}', textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(color: _mutedText, fontSize: 10, height: 1.25)),
                    const Spacer(),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      const Icon(LucideIcons.calendarDays, size: 12, color: _mutedText),
                      const SizedBox(width: 4),
                      Flexible(child: Text(_dateLabel(goal.deadline), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.overline.copyWith(color: _mutedText))),
                    ]),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _AnimatedBar extends StatelessWidget {
  const _AnimatedBar({required this.value, required this.color, required this.height});
  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, 1).toDouble()),
        duration: const Duration(milliseconds: 820),
        curve: Curves.easeOutCubic,
        builder: (context, animated, child) => ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(value: animated, minHeight: height, backgroundColor: _track, color: color),
        ),
      );
}

class _AiPromoCard extends StatelessWidget {
  const _AiPromoCard();

  @override
  Widget build(BuildContext context) => Container(
        height: 95,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0C0C18),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _purpleEnd.withValues(alpha: .20)),
          boxShadow: [BoxShadow(color: _purpleEnd.withValues(alpha: .20), blurRadius: 26, spreadRadius: -16)],
        ),
        child: Row(children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF07040B), boxShadow: [BoxShadow(color: _purpleEnd.withValues(alpha: .42), blurRadius: 24, spreadRadius: -4)]),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 30))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('✦ Nexora AI', style: AppTypography.labelMedium.copyWith(color: _purpleText, fontWeight: FontWeight.w900)),
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: _purpleStart.withValues(alpha: .55), borderRadius: BorderRadius.circular(99)), child: Text('AI', style: AppTypography.overline.copyWith(color: Colors.white))),
              ]),
              const SizedBox(height: 4),
              Text('Butuh bantuan capai goals?', style: AppTypography.heading3.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
              Text('AI akan menganalisis kebiasaanmu dan membuat rencana khusus untukmu.', maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(color: _mutedText, fontSize: 10.5)),
              const Spacer(),
              Text('Lihat rekomendasi →', style: AppTypography.labelMedium.copyWith(color: _purpleText, fontWeight: FontWeight.w900)),
            ]),
          ),
        ]),
      );
}
