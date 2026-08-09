import 'package:flutter/material.dart';

/// Displays a single-line value normally and automatically marquee-scrolls it
/// only when the rendered text is wider than the available space.
class ScrollingText extends StatefulWidget {
  const ScrollingText({
    super.key,
    required this.text,
    required this.style,
    this.alignment = Alignment.centerLeft,
    this.gap = 48,
    this.scrollDuration = const Duration(milliseconds: 3200),
  });

  final String text;
  final TextStyle style;
  final Alignment alignment;
  final double gap;
  final Duration scrollDuration;

  @override
  State<ScrollingText> createState() => _ScrollingTextState();
}

class _ScrollingTextState extends State<ScrollingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.scrollDuration,
  );

  double _distance = 0;
  bool _overflow = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateOverflow(double maxWidth) {
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    final overflow = painter.width > maxWidth + .5;
    final distance = painter.width - maxWidth + widget.gap;

    if (overflow != _overflow ||
        (overflow && (distance - _distance).abs() > .5)) {
      _overflow = overflow;
      _distance = distance;

      if (_overflow) {
        _controller
          ..reset()
          ..repeat();
      } else {
        _controller
          ..stop()
          ..value = 0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _updateOverflow(constraints.maxWidth);

        if (!_overflow) {
          return Align(
            alignment: widget.alignment,
            child: Text(
              widget.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: widget.style,
            ),
          );
        }

        final sequence = TweenSequence<double>([
          TweenSequenceItem(
            tween: ConstantTween(0),
            weight: 18,
          ),
          TweenSequenceItem(
            tween: Tween(begin: 0, end: -_distance),
            weight: 58,
          ),
          TweenSequenceItem(
            tween: ConstantTween(0),
            weight: 18,
          ),
          TweenSequenceItem(
            tween: Tween(begin: -_distance, end: 0),
            weight: 58,
          ),
          TweenSequenceItem(
            tween: ConstantTween(0),
            weight: 18,
          ),
        ]);

        return ClipRect(
          child: SizedBox(
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final offset = sequence.transform(_controller.value);
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.text, maxLines: 1, style: widget.style),
                      SizedBox(width: widget.gap),
                      Text(widget.text, maxLines: 1, style: widget.style),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}