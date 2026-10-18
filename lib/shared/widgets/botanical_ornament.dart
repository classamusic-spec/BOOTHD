import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_theme.dart';

/// Original botanical line art, drawn in code for this project (no
/// third-party artwork; provenance in `docs/ASSET_PROVENANCE.md`).
///
/// Purely decorative: excluded from accessibility, never carries meaning.
/// Leaf density and colour follow the theme's [OrnamentStyle].
class BotanicalOrnament extends StatelessWidget {
  /// A single arching sprig, growing from bottom-left to top-right (or
  /// mirrored with [flip]).
  const BotanicalOrnament.sprig({
    super.key,
    this.width = 160,
    this.height = 160,
    this.flip = false,
    this.leaves = 9,
    this.seed = 0,
  }) : _kind = _OrnamentKind.sprig;

  /// An open laurel wreath, tied at the bottom.
  const BotanicalOrnament.wreath({
    super.key,
    required double diameter,
    this.leaves = 11,
    this.seed = 0,
  }) : width = diameter,
       height = diameter,
       flip = false,
       _kind = _OrnamentKind.wreath;

  /// Two sprigs meeting at a centre point: a flourish under titles.
  const BotanicalOrnament.flourish({
    super.key,
    this.width = 180,
    this.height = 28,
    this.leaves = 5,
    this.seed = 0,
  }) : flip = false,
       _kind = _OrnamentKind.flourish;

  final double width;
  final double height;
  final bool flip;
  final int leaves;
  final int seed;
  final _OrnamentKind _kind;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final density = switch (theme.ornament) {
      OrnamentStyle.brassBotanical => 0.75,
      _ => 1.0,
    };
    final count = math.max(3, (leaves * density).round());
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(width, height),
          painter: _OrnamentPainter(
            kind: _kind,
            flip: flip,
            leaves: count,
            seed: seed,
            stroke: colors.ornament,
            fill: colors.ornament.withValues(
              alpha: colors.isDark ? 0.16 : 0.12,
            ),
          ),
        ),
      ),
    );
  }
}

enum _OrnamentKind { sprig, wreath, flourish }

/// A point on a curve and the unit direction of growth there.
typedef _CurveSample = ({Offset point, Offset direction});

class _OrnamentPainter extends CustomPainter {
  _OrnamentPainter({
    required this.kind,
    required this.flip,
    required this.leaves,
    required this.seed,
    required this.stroke,
    required this.fill,
  });

  final _OrnamentKind kind;
  final bool flip;
  final int leaves;
  final int seed;
  final Color stroke;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = math.max(1.1, unit / 120)
      ..color = stroke;
    final vein = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = line.strokeWidth * 0.6
      ..color = stroke.withValues(alpha: stroke.a * 0.75);
    final wash = Paint()..color = fill;

    switch (kind) {
      case _OrnamentKind.sprig:
        if (flip) {
          canvas
            ..translate(size.width, 0)
            ..scale(-1, 1);
        }
        final w = size.width;
        final h = size.height;
        _branch(
          canvas,
          _cubic(
            Offset(w * 0.08, h * 0.96),
            Offset(w * 0.18, h * 0.55),
            Offset(w * 0.45, h * 0.18),
            Offset(w * 0.94, h * 0.06),
          ),
          leafLength: unit * 0.2,
          line: line,
          vein: vein,
          wash: wash,
        );
      case _OrnamentKind.flourish:
        final w = size.width;
        final h = size.height;
        final centre = Offset(w / 2, h * 0.62);
        for (final side in [-1.0, 1.0]) {
          _branch(
            canvas,
            _cubic(
              centre.translate(side * w * 0.03, 0),
              centre.translate(side * w * 0.18, -h * 0.12),
              centre.translate(side * w * 0.32, h * 0.12),
              centre.translate(side * w * 0.48, -h * 0.18),
            ),
            leafLength: h * 0.62,
            line: line,
            vein: vein,
            wash: wash,
            leafAngle: 52,
          );
        }
        canvas.drawCircle(
          centre,
          line.strokeWidth * 1.6,
          Paint()..color = stroke,
        );
      case _OrnamentKind.wreath:
        final centre = size.center(Offset.zero);
        final radius = unit * 0.42;
        _CurveSample arc(double from, double to, double t) {
          final angle = from + (to - from) * t;
          final rad = angle * math.pi / 180;
          final sign = (to - from).sign;
          return (
            point: centre + Offset(math.cos(rad), math.sin(rad)) * radius,
            direction: Offset(-math.sin(rad) * sign, math.cos(rad) * sign),
          );
        }

        // Two branches rise from a tie at the bottom, leaving the top open.
        _branch(
          canvas,
          (t) => arc(102, 238, t),
          leafLength: unit * 0.13,
          line: line,
          vein: vein,
          wash: wash,
        );
        _branch(
          canvas,
          (t) => arc(78, -58, t),
          leafLength: unit * 0.13,
          line: line,
          vein: vein,
          wash: wash,
        );
        final tie = centre + Offset(0, radius * 1.01);
        final tiePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = line.strokeWidth
          ..color = stroke;
        for (final side in [-1.0, 1.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(tie.dx, tie.dy)
              ..quadraticBezierTo(
                tie.dx + side * radius * 0.16,
                tie.dy - radius * 0.1,
                tie.dx + side * radius * 0.2,
                tie.dy + radius * 0.06,
              )
              ..quadraticBezierTo(
                tie.dx + side * radius * 0.1,
                tie.dy + radius * 0.07,
                tie.dx,
                tie.dy,
              ),
            tiePaint,
          );
        }
    }
  }

  /// Draws the stem along [curve] and alternating leaves that shrink toward
  /// the growing tip, finishing with a terminal leaf.
  void _branch(
    Canvas canvas,
    _CurveSample Function(double t) curve, {
    required double leafLength,
    required Paint line,
    required Paint vein,
    required Paint wash,
    double leafAngle = 42,
  }) {
    final stem = Path();
    const steps = 48;
    for (var i = 0; i <= steps; i++) {
      final p = curve(i / steps).point;
      i == 0 ? stem.moveTo(p.dx, p.dy) : stem.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(stem, line);

    final random = math.Random(seed);
    for (var i = 0; i < leaves; i++) {
      final t = 0.12 + 0.8 * i / math.max(1, leaves - 1);
      final sample = curve(t);
      final side = i.isEven ? 1.0 : -1.0;
      final jitter = (random.nextDouble() - 0.5) * 8;
      final angle = (leafAngle + jitter) * side * math.pi / 180;
      final direction = _rotate(sample.direction, angle);
      final length =
          leafLength * (1.0 - 0.5 * t) * (0.92 + random.nextDouble() * 0.16);
      _leaf(canvas, sample.point, direction, length, line, vein, wash);
    }
    final tip = curve(1);
    _leaf(canvas, tip.point, tip.direction, leafLength * 0.5, line, vein, wash);
  }

  void _leaf(
    Canvas canvas,
    Offset stemPoint,
    Offset direction,
    double length,
    Paint line,
    Paint vein,
    Paint wash,
  ) {
    final normal = Offset(-direction.dy, direction.dx);
    final base = stemPoint + direction * (length * 0.1);
    final tip = base + direction * length;
    final width = length * 0.34;
    final shape = Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(
        (base + direction * (length * 0.18) + normal * width).dx,
        (base + direction * (length * 0.18) + normal * width).dy,
        (base + direction * (length * 0.68) + normal * (width * 0.72)).dx,
        (base + direction * (length * 0.68) + normal * (width * 0.72)).dy,
        tip.dx,
        tip.dy,
      )
      ..cubicTo(
        (base + direction * (length * 0.68) - normal * (width * 0.72)).dx,
        (base + direction * (length * 0.68) - normal * (width * 0.72)).dy,
        (base + direction * (length * 0.18) - normal * width).dx,
        (base + direction * (length * 0.18) - normal * width).dy,
        base.dx,
        base.dy,
      )
      ..close();
    canvas
      ..drawLine(stemPoint, base, line)
      ..drawPath(shape, wash)
      ..drawPath(shape, line)
      ..drawLine(
        base + direction * (length * 0.08),
        base + direction * (length * 0.72),
        vein,
      );
  }

  static _CurveSample Function(double) _cubic(
    Offset p0,
    Offset p1,
    Offset p2,
    Offset p3,
  ) => (t) {
    final u = 1 - t;
    final point =
        p0 * (u * u * u) +
        p1 * (3 * u * u * t) +
        p2 * (3 * u * t * t) +
        p3 * (t * t * t);
    final derivative =
        (p1 - p0) * (3 * u * u) +
        (p2 - p1) * (6 * u * t) +
        (p3 - p2) * (3 * t * t);
    return (point: point, direction: derivative / derivative.distance);
  };

  static Offset _rotate(Offset v, double radians) {
    final c = math.cos(radians);
    final s = math.sin(radians);
    return Offset(v.dx * c - v.dy * s, v.dx * s + v.dy * c);
  }

  @override
  bool shouldRepaint(_OrnamentPainter old) =>
      old.kind != kind ||
      old.flip != flip ||
      old.leaves != leaves ||
      old.seed != seed ||
      old.stroke != stroke ||
      old.fill != fill;
}
