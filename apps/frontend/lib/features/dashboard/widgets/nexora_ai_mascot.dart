import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Dashboard-specific Nexora AI mascot.
///
/// Designed to match the visual language of the dashboard reference:
/// rounded white/silver robot, dark visor, purple core and soft violet glow.
class NexoraAIMascot extends StatefulWidget {
  const NexoraAIMascot({super.key, this.size = 92});

  final double size;

  @override
  State<NexoraAIMascot> createState() => _NexoraAIMascotState();
}

class _NexoraAIMascotState extends State<NexoraAIMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
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
        final t = Curves.easeInOut.transform(_controller.value);
        final bob = math.sin(t * math.pi) * widget.size * .025;
        return Transform.translate(
          offset: Offset(0, -bob),
          child: CustomPaint(
            size: Size.square(widget.size),
            painter: _NexoraAIMascotPainter(animation: t),
          ),
        );
      },
    );
  }
}

class _NexoraAIMascotPainter extends CustomPainter {
  const _NexoraAIMascotPainter({required this.animation});

  final double animation;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final center = Offset(s * .5, s * .5);

    // Soft violet grounding glow.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * .5, s * .91),
        width: s * .72,
        height: s * .14,
      ),
      Paint()
        ..color = AppColors.primary.withValues(alpha: .24)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * .10),
    );

    final silver = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFDCE1F5),
          Color(0xFF8D94B8),
        ],
      ).createShader(Offset.zero & size);

    final darkSilver = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE7EAFF), Color(0xFF7C84AA)],
      ).createShader(Offset.zero & size);

    // Legs.
    canvas.drawLine(
      Offset(s * .40, s * .70),
      Offset(s * .34, s * .87),
      Paint()
        ..color = const Color(0xFFDDE2F5)
        ..strokeWidth = s * .105
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(s * .60, s * .70),
      Offset(s * .66, s * .87),
      Paint()
        ..color = const Color(0xFF9AA2C4)
        ..strokeWidth = s * .105
        ..strokeCap = StrokeCap.round,
    );

    // Body.
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * .28, s * .50, s * .44, s * .28),
      Radius.circular(s * .10),
    );
    canvas.drawRRect(body, darkSilver);

    // Purple chest core.
    final coreCenter = Offset(s * .50, s * .65);
    canvas.drawCircle(
      coreCenter,
      s * .105,
      Paint()
        ..color = AppColors.primary.withValues(alpha: .22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * .08),
    );
    canvas.drawCircle(
      coreCenter,
      s * .075,
      Paint()..color = AppColors.primaryLight,
    );
    canvas.drawCircle(
      coreCenter.translate(0, -s * .012),
      s * .034,
      Paint()..color = Colors.white.withValues(alpha: .82),
    );

    // Arms with a subtle idle/wave motion.
    final wave = math.sin(animation * math.pi) * .08;
    final armPaint = Paint()
      ..color = const Color(0xFFDCE1F5)
      ..strokeWidth = s * .095
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(s * .29, s * .55),
      Offset(s * (.16 - wave), s * (.70 + wave)),
      armPaint,
    );
    canvas.drawLine(
      Offset(s * .71, s * .55),
      Offset(s * (.84 + wave), s * (.70 - wave)),
      armPaint,
    );

    // Head shell.
    final head = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * .18, s * .17, s * .64, s * .43),
      Radius.circular(s * .15),
    );
    canvas.drawRRect(
      head.inflate(s * .035),
      Paint()..color = Colors.white.withValues(alpha: .58),
    );
    canvas.drawRRect(head, silver);

    // Dark glass visor.
    final visor = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * .27, s * .28, s * .46, s * .22),
      Radius.circular(s * .095),
    );
    canvas.drawRRect(
      visor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0C1022), Color(0xFF02040C)],
        ).createShader(visor.outerRect),
    );

    // Friendly glowing eyes.
    final eyeGlow = Paint()
      ..color = AppColors.primaryLight.withValues(alpha: .45)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * .045);
    canvas.drawCircle(Offset(s * .42, s * .39), s * .052, eyeGlow);
    canvas.drawCircle(Offset(s * .58, s * .39), s * .052, eyeGlow);

    final eye = Paint()..color = AppColors.primaryLight;
    canvas.drawCircle(Offset(s * .42, s * .39), s * .026, eye);
    canvas.drawCircle(Offset(s * .58, s * .39), s * .026, eye);

    // Small smile.
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(s * .50, s * .435),
        width: s * .17,
        height: s * .08,
      ),
      .18,
      math.pi - .36,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: .72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .012
        ..strokeCap = StrokeCap.round,
    );

    // Head antenna / AI node.
    final antenna = Paint()
      ..color = const Color(0xFFDDE2F5)
      ..strokeWidth = s * .025
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(s * .50, s * .17),
      Offset(s * .50, s * .09),
      antenna,
    );
    canvas.drawCircle(
      Offset(s * .50, s * .075),
      s * .035,
      Paint()
        ..color = AppColors.primaryLight
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * .025),
    );
    canvas.drawCircle(
      Offset(s * .50, s * .075),
      s * .019,
      Paint()..color = Colors.white,
    );

    // Tiny shoulder joints for a more finished mascot silhouette.
    canvas.drawCircle(Offset(s * .285, s * .55), s * .055, Paint()..color = const Color(0xFFB9C0DD));
    canvas.drawCircle(Offset(s * .715, s * .55), s * .055, Paint()..color = const Color(0xFF9BA3C5));

    // Keep the center visually anchored.
    canvas.drawCircle(center.translate(0, s * .34), 0, Paint());
  }

  @override
  bool shouldRepaint(covariant _NexoraAIMascotPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
