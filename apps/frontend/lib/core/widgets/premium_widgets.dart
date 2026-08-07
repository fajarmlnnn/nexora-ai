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
          SafeArea(bottom: false, child: child),
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
        gradient: gradient ?? AppGradients.glass,
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
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: .28),
                      blurRadius: 54,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
              const NexoraRobot(size: 112, waving: false),
              Positioned(
                right: 18,
                top: 20,
                child: PremiumIconBadge(
                  icon: icon,
                  color: AppColors.primaryLight,
                  size: 34,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTypography.labelLarge),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
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
    final total = segments.fold<double>(
      0,
      (sum, segment) => sum + segment.value,
    );
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
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.segments != segments;
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

class PremiumEntrance extends StatelessWidget {
  const PremiumEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, .08),
  });

  final Widget child;
  final Duration delay;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 620 + delay.inMilliseconds),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final safeValue = delay == Duration.zero
            ? value
            : ((value * (620 + delay.inMilliseconds) - delay.inMilliseconds) /
                      620)
                  .clamp(0.0, 1.0)
                  .toDouble();
        return Opacity(
          opacity: safeValue,
          child: Transform.translate(
            offset: Offset(
              offset.dx * 80 * (1 - safeValue),
              offset.dy * 80 * (1 - safeValue),
            ),
            child: Transform.scale(
              scale: .96 + (.04 * safeValue),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class NexoraRobot extends StatefulWidget {
  const NexoraRobot({super.key, this.size = 170, this.waving = true});

  final double size;
  final bool waving;

  @override
  State<NexoraRobot> createState() => _NexoraRobotState();
}

class _NexoraRobotState extends State<NexoraRobot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

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
        final bob =
            math.sin(_controller.value * math.pi * 2) * widget.size * .025;
        final wave = math.sin(_controller.value * math.pi * 2) * .28;
        return Transform.translate(
          offset: Offset(0, bob),
          child: CustomPaint(
            size: Size.square(widget.size),
            painter: _NexoraRobotPainter(wave: widget.waving ? wave : 0),
          ),
        );
      },
    );
  }
}

class _NexoraRobotPainter extends CustomPainter {
  _NexoraRobotPainter({required this.wave});

  final double wave;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final glow = Paint()
      ..color = AppColors.primary.withValues(alpha: .22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * .5, s * .88),
        width: s * .8,
        height: s * .16,
      ),
      glow,
    );

    final limb = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE9ECFF), Color(0xFF8A92B8)],
      ).createShader(Offset.zero & size)
      ..strokeWidth = s * .085
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(s * .31, s * .53), Offset(s * .18, s * .68), limb);
    canvas.drawLine(
      Offset(s * .69, s * .53),
      Offset(s * (.84 + wave * .08), s * (.36 - wave * .08)),
      limb,
    );
    canvas.drawLine(Offset(s * .4, s * .72), Offset(s * .35, s * .86), limb);
    canvas.drawLine(Offset(s * .6, s * .72), Offset(s * .65, s * .86), limb);

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(s * .5, s * .62),
        width: s * .46,
        height: s * .38,
      ),
      Radius.circular(s * .16),
    );
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFF8D93B8), Color(0xFF353B67)],
      ).createShader(bodyRect.outerRect);
    canvas.drawRRect(bodyRect, bodyPaint);
    canvas.drawCircle(
      Offset(s * .5, s * .63),
      s * .105,
      Paint()..color = AppColors.primary.withValues(alpha: .9),
    );
    canvas.drawCircle(
      Offset(s * .5, s * .63),
      s * .055,
      Paint()..color = Colors.white.withValues(alpha: .85),
    );

    final head = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(s * .5, s * .36),
        width: s * .62,
        height: s * .43,
      ),
      Radius.circular(s * .19),
    );
    canvas.drawRRect(
      head.inflate(s * .04),
      Paint()..color = Colors.white.withValues(alpha: .7),
    );
    canvas.drawRRect(
      head,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFDEE3FF), Color(0xFF7F86AE)],
        ).createShader(head.outerRect),
    );
    final face = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(s * .5, s * .36),
        width: s * .46,
        height: s * .25,
      ),
      Radius.circular(s * .1),
    );
    canvas.drawRRect(face, Paint()..color = const Color(0xFF070A18));
    final eye = Paint()
      ..color = AppColors.primaryLight
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(Offset(s * .42, s * .35), s * .035, eye);
    canvas.drawCircle(Offset(s * .58, s * .35), s * .035, eye);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(s * .5, s * .405),
        width: s * .18,
        height: s * .08,
      ),
      .2,
      math.pi - .4,
      false,
      Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .01,
    );
  }

  @override
  bool shouldRepaint(covariant _NexoraRobotPainter oldDelegate) =>
      oldDelegate.wave != wave;
}

class AnimatedMoneyText extends StatelessWidget {
  const AnimatedMoneyText({
    super.key,
    required this.value,
    required this.style,
    this.prefix = '',
    this.color,
  });

  final num value;
  final TextStyle style;
  final String prefix;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Text(
          '$prefix${rupiah(animatedValue)}',
          style: color == null ? style : style.copyWith(color: color),
        );
      },
    );
  }
}

class TypingDots extends StatefulWidget {
  const TypingDots({super.key, this.color = AppColors.primaryLight});

  final Color color;

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
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
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < 3; index++)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: widget.color.withValues(
                    alpha:
                        .35 +
                        .65 *
                            math
                                .sin((_controller.value + index / 3) * math.pi)
                                .abs(),
                  ),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        );
      },
    );
  }
}
