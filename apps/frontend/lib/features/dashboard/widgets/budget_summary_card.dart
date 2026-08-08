import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/card/n_card.dart';
import '../../../core/widgets/layout/n_section_header.dart';
import '../models/budget_item.dart';

class BudgetSummaryCard extends StatelessWidget {
  const BudgetSummaryCard({super.key, required this.items});

  final List<BudgetItem> items;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(4).toList();
    final remainingCount = math.max(0, items.length - visibleItems.length);

    return NCard(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NSectionHeader(
            title: 'Budget Summary',
            actionLabel: 'See All',
            onActionPressed: () {},
          ),

          const SizedBox(height: 14),

          SizedBox(
            height: 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: visibleItems.length + (remainingCount > 0 ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(width: 18),
              itemBuilder: (context, index) {
                if (index >= visibleItems.length) {
                  return _MoreBudgetItem(count: remainingCount);
                }

                return _BudgetCircle(item: visibleItems[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetCircle extends StatelessWidget {
  const _BudgetCircle({required this.item});

  final BudgetItem item;

  Color get accentColor {
    if (item.isOverBudget || item.progress >= .85) {
      return AppColors.danger;
    }

    if (item.progress >= .60) {
      return AppColors.warning;
    }

    return AppColors.primaryLight;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (item.progress * 100).round();

    return SizedBox(
      width: 62,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: item.progress),
              duration: const Duration(milliseconds: 850),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return CustomPaint(
                  painter: _BudgetProgressPainter(
                    progress: value,
                    color: accentColor,
                  ),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .035),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _icon(item.id),
                        size: 17,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 1),

          Text(
            '$percentage%',
            style: AppTypography.caption.copyWith(
              color: accentColor.withValues(alpha: .78),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetProgressPainter extends CustomPainter {
  const _BudgetProgressPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final radius = size.width / 2 - 3;

    final backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: .055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    if (progress <= 0) {
      return;
    }

    final progressPaint = Paint()
      ..color = color.withValues(alpha: .78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BudgetProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _MoreBudgetItem extends StatelessWidget {
  const _MoreBudgetItem({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .035),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .07)),
            ),
            child: Center(
              child: Text(
                '+$count',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Lainnya',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

IconData _icon(String id) {
  return switch (id) {
    'food' => LucideIcons.utensils,
    'transport' => LucideIcons.car,
    'shopping' => LucideIcons.shoppingBag,
    'entertainment' => LucideIcons.gamepad2,
    'health' => LucideIcons.heartPulse,
    'education' => LucideIcons.bookOpen,
    'bills' => LucideIcons.receiptText,
    _ => LucideIcons.circleDollarSign,
  };
}
