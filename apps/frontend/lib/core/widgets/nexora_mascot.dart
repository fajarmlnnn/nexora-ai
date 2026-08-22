import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/nexora_brand.dart';

enum NexoraMascotState {
  idle,
  welcome,
  thinking,
  analyzing,
  goal,
  growth,
  security,
  success,
  warning,
}

class NexoraMascot extends StatefulWidget {
  const NexoraMascot({
    super.key,
    this.size = 180,
    this.state = NexoraMascotState.idle,
    this.animate = true,
  });

  final double size;
  final NexoraMascotState state;
  final bool animate;

  @override
  State<NexoraMascot> createState() => _NexoraMascotState();
}

class _NexoraMascotState extends State<NexoraMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant NexoraMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final phase = _controller.value * math.pi * 2;
        final bob = widget.animate ? math.sin(phase) * widget.size * .018 : 0.0;
        return Transform.translate(
          offset: Offset(0, bob),
          child: CustomPaint(
            size: Size.square(widget.size),
            painter: _NexoraMascotPainter(
              state: widget.state,
              phase: phase,
            ),
          ),
        );
      },
    );
  }
}

class _NexoraMascotPainter extends CustomPainter {
  const _NexoraMascotPainter({required this.state, required this.phase});

  final NexoraMascotState state;
  final double phase;

  Color get accent {
    switch (state) {
      case NexoraMascotState.success:
      case NexoraMascotState.growth:
        return NexoraBrand.success;
      case NexoraMascotState.warning:
        return NexoraBrand.warning;
      case NexoraMascotState.security:
        return NexoraBrand.info;
      case NexoraMascotState.analyzing:
      case NexoraMascotState.thinking:
        return NexoraBrand.aiPrimary;
      case NexoraMascotState.goal:
      case NexoraMascotState.welcome:
      case NexoraMascotState.idle:
        return NexoraBrand.primary;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final center = Offset(s / 2, s / 2);
    final glow = Paint()
      ..color = accent.withValues(alpha: .15)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * .12);
    canvas.drawCircle(Offset(s * .5, s * .48), s * .34, glow);

    final shadow = Paint()..color = Colors.black.withValues(alpha: .28);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * .5, s * .88),
        width: s * .56,
        height: s * .09,
      ),
      shadow,
    );

    final limb = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF5F7FF), Color(0xFF8B93BC)],
      ).createShader(Offset.zero & size)
      ..strokeWidth = s * .07
      ..strokeCap = StrokeCap.round;

    final wave = state == NexoraMascotState.welcome || state == NexoraMascotState.success
        ? math.sin(phase) * .16
        : 0.0;

    canvas.drawLine(
      Offset(s * .31, s * .54),
      Offset(s * .18, s * .68),
      limb,
    );
    canvas.drawLine(
      Offset(s * .69, s * .54),
      Offset(s * (.84 + wave), s * (.39 - wave)),
      limb,
    );
    canvas.drawLine(
      Offset(s * .42, s * .72),
      Offset(s * .37, s * .86),
      limb,
    );
    canvas.drawLine(
      Offset(s * .58, s * .72),
      Offset(s * .63, s * .86),
      limb,
    );

    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(s * .5, s * .64),
        width: s * .44,
        height: s * .34,
      ),
      Radius.circular(s * .13),
    );
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFF9CA3C8), Color(0xFF3A416C)],
      ).createShader(body.outerRect);
    canvas.drawRRect(body, bodyPaint);

    final chest = Paint()..color = accent.withValues(alpha: .92);
    canvas.drawCircle(Offset(s * .5, s * .64), s * .09, chest);
    canvas.drawCircle(
      Offset(s * .5, s * .64),
      s * .043,
      Paint()..color = Colors.white.withValues(alpha: .9),
    );

    final head = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(s * .5, s * .37),
        width: s * .60,
        height: s * .42,
      ),
      Radius.circular(s * .18),
    );
    canvas.drawRRect(
      head.inflate(s * .035),
      Paint()..color = Colors.white.withValues(alpha: .72),
    );
    canvas.drawRRect(
      head,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE6EAFF), Color(0xFF7D85AD)],
        ).createShader(head.outerRect),
    );

    final face = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(s * .5, s * .37),
        width: s * .45,
        height: s * .24,
      ),
      Radius.circular(s * .085),
    );
    canvas.drawRRect(face, Paint()..color = const Color(0xFF070A18));

    final eye = Paint()
      ..color = accent
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * .012);
    final eyeY = state == NexoraMascotState.thinking ? s * .35 : s * .37;
    canvas.drawCircle(Offset(s * .42, eyeY), s * .031, eye);
    canvas.drawCircle(Offset(s * .58, eyeY), s * .031, eye);

    final mouth = Paint()
      ..color = Colors.white.withValues(alpha: .78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .009
      ..strokeCap = StrokeCap.round;
    final smile = state == NexoraMascotState.warning ? .35 : .15;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(s * .5, s * .405),
        width: s * .17,
        height: s * .075,
      ),
      smile,
      math.pi - smile * 2,
      false,
      mouth,
    );

    if (state == NexoraMascotState.analyzing || state == NexoraMascotState.thinking) {
      final ring = Paint()
        ..color = accent.withValues(alpha: .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .012;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: s * .43),
        phase,
        math.pi * .72,
        false,
        ring,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NexoraMascotPainter oldDelegate) =>
      oldDelegate.state != state || oldDelegate.phase != phase;
}
