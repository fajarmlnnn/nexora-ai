import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_motion.dart';

/// ------------------------------------------------------------
/// Nexora Design System
/// Component : NCard
/// ------------------------------------------------------------
///
/// Base reusable card component.
///
/// Used by:
/// - BalanceCard
/// - BudgetSummaryCard
/// - AIInsightCard
/// - GoalCard
/// - ReportCard
/// - SettingsCard
class NCard extends StatefulWidget {
  const NCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = AppSpacing.card,
    this.margin,
    this.color = AppColors.card,
    this.gradient,
    this.borderRadius = AppRadius.radiusXL,
    this.showShadow = true,
    this.showBorder = true,
  });

  final Widget child;

  final VoidCallback? onTap;

  final EdgeInsetsGeometry padding;

  final EdgeInsetsGeometry? margin;

  final Color color;

  final Gradient? gradient;

  final BorderRadius borderRadius;

  final bool showShadow;

  final bool showBorder;

  @override
  State<NCard> createState() => _NCardState();
}

class _NCardState extends State<NCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedScale(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      scale: _pressed ? AppMotion.pressedScale : 1,
      child: AnimatedContainer(
        duration: AppMotion.normal,
        curve: AppMotion.standard,
        margin: widget.margin,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.gradient == null ? widget.color : null,
          gradient: widget.gradient,
          borderRadius: widget.borderRadius,
          border: widget.showBorder
              ? Border.all(color: AppColors.border.withValues(alpha: .35))
              : null,
          boxShadow: widget.showShadow ? AppShadows.card : AppShadows.none,
        ),
        child: widget.child,
      ),
    );

    if (widget.onTap == null) {
      return card;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: card,
    );
  }
}
