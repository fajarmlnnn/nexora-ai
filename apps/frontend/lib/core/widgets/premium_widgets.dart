import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'nexora/nexora.dart';
import 'nexora_mascot.dart';

String rupiah(num value) {
  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(value);
}

class PremiumScaffold extends StatelessWidget {
  const PremiumScaffold({super.key, required this.child, this.bottomPadding = true, this.floatingActionButton});
  final Widget child;
  final bool bottomPadding;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return NexoraScaffold(
      safeArea: true,
      floatingActionButton: floatingActionButton,
      body: child,
    );
  }
}

class PremiumBackground extends StatelessWidget {
  const PremiumBackground({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

class PremiumCard extends StatelessWidget {
  const PremiumCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.gradient, this.borderRadius = AppRadius.radiusXL});
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
        color: AppColors.surface,
        gradient: gradient,
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.border),
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
    return NexoraSectionHeader(title: title, actionLabel: action, onAction: onAction);
  }
}

class ShimmerSkeleton extends StatelessWidget {
  const ShimmerSkeleton({super.key, this.height = 16, this.width, this.radius = 16});
  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return NexoraSkeleton(width: width, height: height, radius: radius);
  }
}

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return NexoraEmpty(
      icon: icon,
      title: title,
      reason: message,
      ctaLabel: action,
      onPressed: onPressed,
    );
  }
}

class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({super.key, required this.value, this.color = AppColors.brand, this.height = 8});
  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => NexoraProgress(value: value, color: color, height: height);
}

class MetricPill extends StatelessWidget {
  const MetricPill({super.key, required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return NexoraSurface(
      compact: true,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: AppTypography.caption)),
          Text(value, style: AppTypography.labelLarge.copyWith(color: color)),
        ],
      ),
    );
  }
}

class PremiumIconBadge extends StatelessWidget {
  const PremiumIconBadge({super.key, required this.icon, required this.color, this.size = 44});
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: AppRadius.radiusMD,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class PremiumEntrance extends StatelessWidget {
  const PremiumEntrance({super.key, required this.child, this.delay = Duration.zero, this.offset = const Offset(0, .08), this.duration = AppMotion.normal});
  final Widget child;
  final Duration delay;
  final Offset offset;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: AppMotion.standard,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 12 * (1 - value)), child: child),
      ),
      child: child,
    );
  }
}

class NexoraRobot extends StatelessWidget {
  const NexoraRobot({super.key, this.size = 170, this.waving = true});
  final double size;
  final bool waving;

  @override
  Widget build(BuildContext context) {
    return NexoraMascot(size: size, state: waving ? NexoraMascotState.welcome : NexoraMascotState.idle);
  }
}

class AnimatedMoneyText extends StatelessWidget {
  const AnimatedMoneyText({super.key, required this.value, this.style, this.prefix = '', this.color});
  final num value;
  final TextStyle? style;
  final String prefix;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return NexoraAmount(amount: value, role: NexoraAmountRole.primary);
  }
}

class TypingDots extends StatelessWidget {
  const TypingDots({super.key, this.color = AppColors.textMuted});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text('...', style: AppTypography.caption.copyWith(color: color));
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
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _DonutPainter(segments)),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.segments);
  final List<DonutSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(0, (sum, item) => sum + item.value);
    if (total <= 0) return;
    final rect = Offset.zero & size;
    var start = -1.5708;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .16
      ..strokeCap = StrokeCap.round;
    for (final segment in segments) {
      final sweep = (segment.value / total) * 6.2832;
      paint.color = segment.color;
      canvas.drawArc(rect.deflate(size.width * .12), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.segments != segments;
}
