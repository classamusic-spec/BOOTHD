import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_colors.dart';
import '../../core/design_system/porcelain_depth.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';

/// The shape of a [TactileSurface].
enum TactileShape { rounded, stadium, circle }

/// How a tactile surface looks in one interaction state. Interpolated, so
/// presses and state changes animate.
@immutable
final class TactileLook {
  const TactileLook({
    required this.fillTop,
    required this.fillBottom,
    this.border,
    this.borderWidth = 1,
    this.elevation = 0,
    this.inset = 0,
    this.highlight = 0,
    this.travel = 0,
  });

  /// Vertical glaze gradient.
  final Color fillTop;
  final Color fillBottom;

  /// Boundary stroke; null for none.
  final Color? border;
  final double borderWidth;

  /// Outer shadow level (see [PorcelainDepth]).
  final double elevation;

  /// Strength of the shadow inside the shape, 0 to 1: a pressed control or
  /// a well.
  final double inset;

  /// Strength of the rim light along the top edge, 0 to 1.
  final double highlight;

  /// Downward travel in logical pixels (1 dp when pressed).
  final double travel;

  static TactileLook lerp(TactileLook a, TactileLook b, double t) {
    Color? border;
    if (a.border != null || b.border != null) {
      border = Color.lerp(
        a.border ?? b.border!.withValues(alpha: 0),
        b.border ?? a.border!.withValues(alpha: 0),
        t,
      );
    }
    return TactileLook(
      fillTop: Color.lerp(a.fillTop, b.fillTop, t)!,
      fillBottom: Color.lerp(a.fillBottom, b.fillBottom, t)!,
      border: border,
      borderWidth: lerpDouble(a.borderWidth, b.borderWidth, t)!,
      elevation: lerpDouble(a.elevation, b.elevation, t)!,
      inset: lerpDouble(a.inset, b.inset, t)!,
      highlight: lerpDouble(a.highlight, b.highlight, t)!,
      travel: lerpDouble(a.travel, b.travel, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TactileLook &&
      other.fillTop == fillTop &&
      other.fillBottom == fillBottom &&
      other.border == border &&
      other.borderWidth == borderWidth &&
      other.elevation == elevation &&
      other.inset == inset &&
      other.highlight == highlight &&
      other.travel == travel;

  @override
  int get hashCode => Object.hash(
    fillTop,
    fillBottom,
    border,
    borderWidth,
    elevation,
    inset,
    highlight,
    travel,
  );
}

/// Paints porcelain depth behind [child]: shadows, glaze, inner shadow, rim
/// light, boundary and (when [focused]) a focus ring outside the shape.
/// Changes of [look] animate over [duration]; pass `Duration.zero` for
/// reduced motion.
class TactileSurface extends ImplicitlyAnimatedWidget {
  const TactileSurface({
    super.key,
    required this.look,
    this.shape = TactileShape.rounded,
    this.radius = PorcelainRadius.control,
    this.focused = false,
    this.child,
    required super.duration,
    super.curve = Curves.easeOutCubic,
  });

  final TactileLook look;
  final TactileShape shape;

  /// Corner radius for [TactileShape.rounded].
  final double radius;
  final bool focused;
  final Widget? child;

  @override
  AnimatedWidgetBaseState<TactileSurface> createState() =>
      _TactileSurfaceState();
}

class _TactileLookTween extends Tween<TactileLook> {
  _TactileLookTween({super.begin});

  @override
  TactileLook lerp(double t) => TactileLook.lerp(begin!, end!, t);
}

class _TactileSurfaceState extends AnimatedWidgetBaseState<TactileSurface> {
  _TactileLookTween? _look;
  Tween<double>? _focus;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _look = visitor(
      _look,
      widget.look,
      (value) => _TactileLookTween(begin: value as TactileLook),
    ) as _TactileLookTween?;
    _focus = visitor(
      _focus,
      widget.focused ? 1.0 : 0.0,
      (value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    final look = _look!.evaluate(animation);
    final focus = _focus!.evaluate(animation);
    final colors = context.porcelain.colors;
    return Transform.translate(
      offset: Offset(0, look.travel),
      child: CustomPaint(
        painter: _TactilePainter(
          look: look,
          shape: widget.shape,
          radius: widget.radius,
          colors: colors,
          focus: focus,
        ),
        child: widget.child,
      ),
    );
  }
}

class _TactilePainter extends CustomPainter {
  _TactilePainter({
    required this.look,
    required this.shape,
    required this.radius,
    required this.colors,
    required this.focus,
  });

  final TactileLook look;
  final TactileShape shape;
  final double radius;
  final PorcelainColors colors;
  final double focus;

  /// The shape grown by [outset] on every side, keeping corners concentric.
  RRect _shape(Rect rect, [double outset = 0]) {
    final grown = rect.inflate(outset);
    return switch (shape) {
      TactileShape.rounded => RRect.fromRectAndRadius(
        grown,
        Radius.circular(radius + outset),
      ),
      TactileShape.stadium || TactileShape.circle => RRect.fromRectAndRadius(
        grown,
        Radius.circular(grown.shortestSide / 2),
      ),
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final body = _shape(rect);

    for (final shadow in PorcelainDepth.shadows(colors, look.elevation)) {
      canvas.drawRRect(
        body.shift(shadow.offset).inflate(shadow.spreadRadius),
        shadow.toPaint(),
      );
    }

    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [look.fillTop, look.fillBottom],
        ).createShader(rect),
    );

    if (look.inset > 0.01 || look.highlight > 0.01) {
      canvas
        ..save()
        ..clipRRect(body);
      if (look.inset > 0.01) {
        // A frame around the shape, blurred and nudged down, leaves a soft
        // shadow inside the top edge: the shape reads as pressed in.
        final frame = Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(rect.inflate(24))
          ..addRRect(body.shift(Offset(0, 1.5 + 1.5 * look.inset)));
        canvas.drawPath(
          frame,
          Paint()
            ..color = colors.insetShadow.withValues(
              alpha: colors.insetShadow.a * look.inset,
            )
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              2 + 2.5 * look.inset,
            ),
        );
      }
      if (look.highlight > 0.01) {
        final rim = colors.highlight.withValues(
          alpha: colors.highlight.a * look.highlight,
        );
        canvas.drawRRect(
          body.deflate(0.75),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [rim, rim.withValues(alpha: 0)],
              stops: const [0, 0.45],
            ).createShader(rect),
        );
      }
      canvas.restore();
    }

    final border = look.border;
    if (border != null && border.a > 0 && look.borderWidth > 0) {
      canvas.drawRRect(
        body.deflate(look.borderWidth / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = look.borderWidth
          ..color = border,
      );
    }

    if (focus > 0.01) {
      const gap = PorcelainSize.focusRingGap;
      const width = PorcelainSize.focusRingWidth;
      canvas.drawRRect(
        _shape(rect, gap + width / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..color = colors.focusRing.withValues(
            alpha: colors.focusRing.a * focus,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_TactilePainter old) =>
      old.look != look ||
      old.shape != shape ||
      old.radius != radius ||
      old.colors != colors ||
      old.focus != focus;
}
