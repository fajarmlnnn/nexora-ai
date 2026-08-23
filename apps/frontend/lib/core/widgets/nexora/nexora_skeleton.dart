import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';

class NexoraSkeleton extends StatefulWidget {
  const NexoraSkeleton({super.key, this.width, this.height = 16, this.radius = 16, this.margin = EdgeInsets.zero});

  final double? width;
  final double height;
  final double radius;
  final EdgeInsets margin;

  @override
  State<NexoraSkeleton> createState() => _NexoraSkeletonState();
}

class _NexoraSkeletonState extends State<NexoraSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Memuat',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final dx = (_controller.value * 2) - 1;
          return Container(
            width: widget.width,
            height: widget.height,
            margin: widget.margin,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              gradient: LinearGradient(
                begin: Alignment(-1.5 + dx, 0),
                end: Alignment(-0.5 + dx, 0),
                colors: const [AppColors.space800, Color(0x1AFFFFFF), AppColors.space800],
              ),
            ),
          );
        },
      ),
    );
  }
}

class NexoraSkeletonRow extends StatelessWidget {
  const NexoraSkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        NexoraSkeleton(width: 40, height: 40, radius: 16),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [NexoraSkeleton(width: 140, height: 14), SizedBox(height: 8), NexoraSkeleton(width: 90, height: 11)])),
        SizedBox(width: 16),
        NexoraSkeleton(width: 84, height: 15),
      ],
    );
  }
}
