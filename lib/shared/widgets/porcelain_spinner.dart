import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_motion.dart';

/// Indeterminate progress: a slowly turning gilded arc. With reduced motion
/// it is a still hourglass, so busy states stay visible without movement.
class PorcelainSpinner extends StatefulWidget {
  const PorcelainSpinner({super.key, required this.color, this.size = 20});

  final Color color;
  final double size;

  @override
  State<PorcelainSpinner> createState() => _PorcelainSpinnerState();
}

class _PorcelainSpinnerState extends State<PorcelainSpinner>
    with SingleTickerProviderStateMixin {
  late final _turns = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (PorcelainMotion.of(context).isReduced) {
      _turns.stop();
    } else if (!_turns.isAnimating) {
      _turns.repeat();
    }
  }

  @override
  void dispose() {
    _turns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (PorcelainMotion.of(context).isReduced) {
      return Icon(PorcelainIcons.busy, color: widget.color, size: widget.size);
    }
    return SizedBox.square(
      dimension: widget.size,
      child: RotationTransition(
        turns: _turns,
        child: CustomPaint(painter: _ArcPainter(widget.color)),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide / 9;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas
      ..drawArc(
        rect,
        0,
        2 * math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = color.withValues(alpha: color.a * 0.2),
      )
      ..drawArc(
        rect,
        -math.pi / 2,
        math.pi * 1.2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.color != color;
}
