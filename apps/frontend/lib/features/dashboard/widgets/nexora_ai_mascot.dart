import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Visual state used by the Home AI surface.
enum NexoraMascotVisualState { positive, warning, critical }

/// Official Nexora AI mascot.
///
/// The master SVG remains the source of truth for the artwork. This widget
/// only adds the product-level motion, glow and state treatment around it.
class NexoraAIMascot extends StatefulWidget {
  const NexoraAIMascot({
    super.key,
    this.size = 108,
    this.accent,
    this.state = NexoraMascotVisualState.positive,
  });

  final double size;
  final Color? accent;
  final NexoraMascotVisualState state;

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

  Color get _defaultAccent => switch (widget.state) {
        NexoraMascotVisualState.positive => const Color(0xFF22D3A1),
        NexoraMascotVisualState.warning => const Color(0xFFF5B94C),
        NexoraMascotVisualState.critical => const Color(0xFFFF5D73),
      };

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent ?? _defaultAccent;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final eased = Curves.easeInOut.transform(_controller.value);
        final lift = Tween<double>(begin: 2, end: -3).transform(eased);
        final scale = Tween<double>(begin: .97, end: 1).transform(eased);

        return SizedBox.square(
          dimension: widget.size,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Transform.scale(
                scale: .72 + (eased * .05),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: .28),
                        blurRadius: 30,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const SizedBox.square(dimension: 52),
                ),
              ),
              Transform.translate(
                offset: Offset(0, lift),
                child: Transform.scale(
                  scale: scale,
                  child: SvgPicture.asset(
                    'assets/mascot/nexora_mascot_master.svg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 2 + (eased * 2),
                right: 5,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF0C0A17), width: 2),
                    boxShadow: [
                      BoxShadow(color: accent.withValues(alpha: .55), blurRadius: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
