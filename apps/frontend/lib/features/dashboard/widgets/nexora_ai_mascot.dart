import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Official Nexora AI mascot used by AI insight surfaces.
///
/// The artwork is kept as a single SVG master asset so the mascot stays
/// visually identical across the product instead of being redrawn by
/// different CustomPainters.
class NexoraAIMascot extends StatefulWidget {
  const NexoraAIMascot({super.key, this.size = 108});

  final double size;

  @override
  State<NexoraAIMascot> createState() => _NexoraAIMascotState();
}

class _NexoraAIMascotState extends State<NexoraAIMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
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
        final lift = Tween<double>(begin: 0, end: -3.0).transform(t);
        final scale = Tween<double>(begin: .98, end: 1.0).transform(t);

        return Transform.translate(
          offset: Offset(0, lift),
          child: Transform.scale(
            scale: scale,
            child: SizedBox.square(
              dimension: widget.size,
              child: SvgPicture.asset(
                'assets/mascot/nexora_mascot_master.svg',
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }
}
