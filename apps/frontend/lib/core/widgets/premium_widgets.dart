import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';

String rupiah(num value) {
  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(value);
}

class PremiumScaffold extends StatelessWidget {
  const PremiumScaffold({
    super.key,
    required this.child,
    this.bottomPadding = true,
    this.floatingActionButton,
  });

  final Widget child;
  final bool bottomPadding;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          const Positioned.fill(child: PremiumBackground()),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding ? 92 : 0),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumBackground extends StatelessWidget {
  const PremiumBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF060A16), AppColors.background],
        ),
      ),
      child: Stack(
        children: const [
          Positioned(
            top: -90,
            right: -60,
            child: _Glow(size: 240, color: AppColors.primary),
          ),
          Positioned(
            bottom: 72,
            left: -110,
            child: _Glow(size: 210, color: AppColors.info),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .26),
            blurRadius: 96,
            spreadRadius: 42,
          ),
        ],
      ),
    );
  }
}

class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.gradient,
    this.borderRadius = AppRadius.radiusXXL,
  });

  final Widget child;
  final EdgeInsets padding;
  final Gradient? gradient;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? AppColors.card.withValues(alpha: .9) : null,
        gradient: gradient,
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.border.withValues(alpha: .55)),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTypography.heading3)),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              action!,
              style: AppTypography.caption.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class ShimmerSkeleton extends StatefulWidget {
  const ShimmerSkeleton({
    super.key,
    this.height = 18,
    this.width,
    this.radius = 14,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + _controller.value * 2, 0),
              end: Alignment(_controller.value * 2, 0),
              colors: const [
                AppColors.cardSecondary,
                AppColors.glass,
                AppColors.cardSecondary,
              ],
            ),
          ),
        );
      },
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: AppRadius.radiusXXL,
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTypography.labelLarge),
          const SizedBox(height: 4),
          Text(message, textAlign: TextAlign.center, style: AppTypography.bodySmall),
          const SizedBox(height: 14),
          FilledButton(onPressed: onPressed ?? () {}, child: Text(action)),
        ],
      ),
    );
  }
}

class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 8,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1).toDouble()),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return ClipRRect(
          borderRadius: AppRadius.radiusLG,
          child: LinearProgressIndicator(
            value: animatedValue,
            minHeight: height,
            color: color,
            backgroundColor: AppColors.divider,
          ),
        );
      },
    );
  }
}

class DonutSegment {
  const DonutSegment({required this.value, required this.color});

  final double value;
  final Color color;
}

class Donut extends StatelessWidget {
  const Donut({super.key, required this.segments, this.size = 128});

  final List<DonutSegment> segments;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return CustomPaint(
          size: Size.square(size),
          painter: _DonutPainter(segments: segments, animationValue: value),
        );
      },
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.segments, required this.animationValue});

  final List<DonutSegment> segments;
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(0, (sum, segment) => sum + segment.value);
    if (total <= 0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    var start = -math.pi / 2;

    for (final segment in segments) {
      paint.color = segment.color;
      final sweep = (segment.value / total) * math.pi * 2 * animationValue;
      canvas.drawArc(Offset.zero & size, start, sweep - .06, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.segments != segments;
  }
}

class MetricPill extends StatelessWidget {
  const MetricPill({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(14),
      borderRadius: AppRadius.radiusXL,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .15),
              borderRadius: AppRadius.radiusLG,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.caption),
                Text(value, style: AppTypography.labelLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumIconBadge extends StatelessWidget {
  const PremiumIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 46,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .16),
        borderRadius: AppRadius.radiusLG,
      ),
      child: Icon(icon, color: color, size: size * .48),
    );
  }
}
