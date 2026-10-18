/// Botanical artwork drawn in code for this project: cream five-petal
/// blossoms with golden centres, sage leaves, buds and stems, after the
/// owner's reference boards (CR-002). Original work with no third-party
/// artwork (provenance: `docs/ASSET_PROVENANCE.md`).
///
/// Arrangements are built from a seed, so the same arrangement always
/// draws the same way: on guest screens (scaled live) and in the bundled
/// template decorations (rendered once to PNG).
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Colours for petals, leaves and stems.
final class FloralPalette {
  const FloralPalette({
    required this.petal,
    required this.petalShade,
    required this.petalEdge,
    required this.centre,
    required this.centreDeep,
    required this.leaf,
    required this.leafShade,
    required this.leafVein,
    required this.stem,
    required this.shadow,
  });

  /// Cream blossoms and sage leaves (portrait reference board).
  static const garden = FloralPalette(
    petal: ui.Color(0xFFFFFDF8),
    petalShade: ui.Color(0xFFEADBC0),
    petalEdge: ui.Color(0x66BFA57E),
    centre: ui.Color(0xFFEFC867),
    centreDeep: ui.Color(0xFFB98A2E),
    leaf: ui.Color(0xFFAFC09D),
    leafShade: ui.Color(0xFF6F875F),
    leafVein: ui.Color(0x99EEF3E6),
    stem: ui.Color(0xFF8C9A70),
    shadow: ui.Color(0x2E5A4630),
  );

  /// Cream blossoms with champagne leaves (landscape reference board).
  static const champagne = FloralPalette(
    petal: ui.Color(0xFFFFFCF6),
    petalShade: ui.Color(0xFFE9D9BF),
    petalEdge: ui.Color(0x55B79C72),
    centre: ui.Color(0xFFECCB7A),
    centreDeep: ui.Color(0xFFB88E45),
    leaf: ui.Color(0xFFE6D6BA),
    leafShade: ui.Color(0xFFB9A07A),
    leafVein: ui.Color(0x99FFF8EC),
    stem: ui.Color(0xFFBCA27A),
    shadow: ui.Color(0x2A5A4630),
  );

  /// Warm ivory blossoms for dark grounds (Darkroom Walnut).
  static const nocturne = FloralPalette(
    petal: ui.Color(0xFFF3E8D6),
    petalShade: ui.Color(0xFFCDB591),
    petalEdge: ui.Color(0x66806341),
    centre: ui.Color(0xFFE2BC6B),
    centreDeep: ui.Color(0xFFA67A2C),
    leaf: ui.Color(0xFF7F8E68),
    leafShade: ui.Color(0xFF4C5A3D),
    leafVein: ui.Color(0x80D9E0C8),
    stem: ui.Color(0xFF6E7A55),
    shadow: ui.Color(0x66000000),
  );

  final ui.Color petal;
  final ui.Color petalShade;
  final ui.Color petalEdge;
  final ui.Color centre;
  final ui.Color centreDeep;
  final ui.Color leaf;
  final ui.Color leafShade;
  final ui.Color leafVein;
  final ui.Color stem;
  final ui.Color shadow;
}

/// One drawn element, in an arrangement's unit box (0 to 1 on both axes,
/// stretched to the destination when painted).
sealed class FloralElement {
  const FloralElement(this.x, this.y, this.size, this.angle);

  final double x;
  final double y;

  /// Radius for blossoms and buds, length for leaves, as a fraction of the
  /// box's shorter side.
  final double size;

  /// Radians, clockwise.
  final double angle;
}

final class Blossom extends FloralElement {
  const Blossom(super.x, super.y, super.size, super.angle, {this.petals = 5});

  final int petals;
}

final class Leaf extends FloralElement {
  const Leaf(super.x, super.y, super.size, super.angle);
}

final class Bud extends FloralElement {
  const Bud(super.x, super.y, super.size, super.angle);
}

/// A stem through [points] (unit box), [width] a fraction of the shorter
/// side.
final class StemLine {
  const StemLine(this.points, this.width);

  final List<(double, double)> points;
  final double width;
}

/// Stems underneath, then leaves, buds and blossoms in drawing order.
final class FloralArrangement {
  const FloralArrangement({required this.stems, required this.elements});

  final List<StemLine> stems;
  final List<FloralElement> elements;

  /// A spray growing from the top-left corner of the box towards the
  /// opposite edges: a main stem with side branches, leaves along them and
  /// blossoms clustered near their ends. [seed] varies it.
  factory FloralArrangement.cornerSpray({int seed = 1, double density = 1}) {
    final random = math.Random(seed);
    final stems = <StemLine>[];
    final leaves = <FloralElement>[];
    final buds = <FloralElement>[];
    final blossoms = <FloralElement>[];

    void branch({
      required (double, double) from,
      required double heading,
      required double length,
      required double bend,
      required double scale,
      required int depth,
    }) {
      final points = <(double, double)>[from];
      var (x, y) = from;
      var angle = heading;
      const steps = 14;
      for (var i = 1; i <= steps; i++) {
        angle += bend / steps;
        x += math.cos(angle) * length / steps;
        y += math.sin(angle) * length / steps;
        points.add((x, y));
      }
      stems.add(StemLine(points, 0.0045 * scale + 0.0015));

      // Leaves in pairs along the stem, smaller towards the tip.
      final leafCount = (5 * density * scale).round().clamp(2, 7);
      for (var i = 0; i < leafCount; i++) {
        final t = 0.18 + 0.62 * i / math.max(1, leafCount - 1);
        final p = points[(t * steps).round()];
        final tangent = heading + bend * t;
        final side = i.isEven ? 1 : -1;
        leaves.add(
          Leaf(
            p.$1,
            p.$2,
            (0.16 - 0.06 * t) * scale * (0.85 + 0.3 * random.nextDouble()),
            tangent + side * (0.75 + 0.35 * random.nextDouble()),
          ),
        );
      }

      // A cluster of blossoms near the tip, a bud beyond it.
      final tip = points.last;
      final tipAngle = heading + bend;
      final clusterSize = depth == 0 ? 3 : 2;
      for (var i = 0; i < clusterSize; i++) {
        final spread = (i - (clusterSize - 1) / 2) * 0.9;
        final reach = (0.05 + 0.04 * random.nextDouble()) * scale;
        blossoms.add(
          Blossom(
            tip.$1 +
                math.cos(tipAngle + spread) * reach -
                math.cos(tipAngle) * 0.04 * scale * i,
            tip.$2 +
                math.sin(tipAngle + spread) * reach -
                math.sin(tipAngle) * 0.04 * scale * i,
            (0.085 - 0.012 * i) * scale * (0.9 + 0.2 * random.nextDouble()),
            random.nextDouble() * math.pi * 2,
          ),
        );
      }
      buds.add(
        Bud(
          tip.$1 + math.cos(tipAngle) * 0.13 * scale,
          tip.$2 + math.sin(tipAngle) * 0.13 * scale,
          0.032 * scale,
          tipAngle,
        ),
      );
      // A blossom part way along the main stems.
      if (depth == 0) {
        final mid = points[(steps * 0.45).round()];
        blossoms.add(
          Blossom(
            mid.$1 + math.cos(heading + bend * 0.45 + 1.4) * 0.05 * scale,
            mid.$2 + math.sin(heading + bend * 0.45 + 1.4) * 0.05 * scale,
            0.07 * scale,
            random.nextDouble() * math.pi * 2,
          ),
        );
      }

      if (depth < 1) {
        for (final (t, turn) in [(0.35, -0.75), (0.6, 0.65)]) {
          final p = points[(t * steps).round()];
          branch(
            from: p,
            heading: heading + bend * t + turn,
            length: length * 0.45,
            bend: -turn * 0.6,
            scale: scale * 0.72,
            depth: depth + 1,
          );
        }
      }
    }

    // Two main stems fanning out from the corner.
    branch(
      from: (0.02, 0.06),
      heading: 0.32 + 0.1 * random.nextDouble(),
      length: 0.72,
      bend: 0.45,
      scale: 1,
      depth: 0,
    );
    branch(
      from: (0.06, 0.02),
      heading: 1.22 + 0.1 * random.nextDouble(),
      length: 0.6,
      bend: -0.4,
      scale: 0.85,
      depth: 0,
    );
    return FloralArrangement(
      stems: stems,
      elements: [...leaves, ...buds, ...blossoms],
    );
  }

  /// A garland down the box: a gently waving stem from top to bottom with
  /// leaves on both sides and blossoms along it.
  factory FloralArrangement.garland({int seed = 7, int blooms = 6}) {
    final random = math.Random(seed);
    final points = <(double, double)>[];
    const steps = 40;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      points.add((0.5 + 0.12 * math.sin(t * math.pi * 3 + seed), t));
    }
    final leaves = <FloralElement>[];
    final buds = <FloralElement>[];
    final blossoms = <FloralElement>[];
    for (var i = 0; i < 18; i++) {
      final t = (i + 0.5) / 18;
      final p = points[(t * steps).round()];
      final side = i.isEven ? 1 : -1;
      leaves.add(
        Leaf(
          p.$1,
          p.$2,
          0.3 * (0.8 + 0.4 * random.nextDouble()),
          math.pi / 2 + side * (0.95 + 0.3 * random.nextDouble()),
        ),
      );
    }
    for (var i = 0; i < blooms; i++) {
      final t = (i + 0.5) / blooms;
      final p = points[(t * steps).round()];
      blossoms.add(
        Blossom(
          p.$1 + (random.nextDouble() - 0.5) * 0.12,
          p.$2,
          0.19 * (0.85 + 0.3 * random.nextDouble()),
          random.nextDouble() * math.pi * 2,
        ),
      );
      buds.add(
        Bud(
          p.$1 + (i.isEven ? 0.2 : -0.2),
          p.$2 + 0.035,
          0.07,
          i.isEven ? -0.4 : math.pi + 0.4,
        ),
      );
    }
    return FloralArrangement(
      stems: [StemLine(points, 0.02)],
      elements: [...leaves, ...buds, ...blossoms],
    );
  }

  /// A small sprig: one curved stem, a few leaves, one blossom and a bud.
  factory FloralArrangement.sprig({int seed = 3}) {
    final random = math.Random(seed);
    final points = <(double, double)>[
      for (var i = 0; i <= 12; i++)
        (0.06 + 0.8 * i / 12, 0.82 - 0.55 * math.sin(i / 12 * math.pi * 0.5)),
    ];
    return FloralArrangement(
      stems: [StemLine(points, 0.016)],
      elements: [
        for (var i = 0; i < 6; i++)
          Leaf(
            points[1 + i * 2].$1,
            points[1 + i * 2].$2,
            0.34 * (0.85 + 0.3 * random.nextDouble()) * (1 - i * 0.07),
            -0.55 + (i.isEven ? -0.95 : 0.95),
          ),
        Bud(points.last.$1 + 0.04, points.last.$2 - 0.06, 0.07, -0.8),
        Blossom(
          points[11].$1 - 0.02,
          points[11].$2 + 0.06,
          0.2,
          random.nextDouble() * 6,
        ),
        Blossom(
          points[7].$1 + 0.02,
          points[7].$2 - 0.12,
          0.16,
          random.nextDouble() * 6,
        ),
      ],
    );
  }
}

/// Paints [arrangement] stretched over [dest]. With [mirrorX] or
/// [mirrorY], flipped (a top-left spray becomes any corner).
void paintFloralArrangement(
  ui.Canvas canvas,
  FloralArrangement arrangement,
  FloralPalette palette,
  ui.Rect dest, {
  bool mirrorX = false,
  bool mirrorY = false,
  bool shadows = true,
}) {
  final unit = math.min(dest.width, dest.height);
  ui.Offset at(double x, double y) => ui.Offset(
    dest.left + (mirrorX ? 1 - x : x) * dest.width,
    dest.top + (mirrorY ? 1 - y : y) * dest.height,
  );
  double turn(double angle) {
    var a = angle;
    if (mirrorX) a = math.pi - a;
    if (mirrorY) a = -a;
    return a;
  }

  canvas.save();
  canvas.clipRect(dest.inflate(unit * 0.02));

  final stemPaint = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.round
    ..color = palette.stem;
  for (final stem in arrangement.stems) {
    final path = ui.Path();
    for (final (i, (x, y)) in stem.points.indexed) {
      final p = at(x, y);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, stemPaint..strokeWidth = stem.width * unit);
  }

  for (final element in arrangement.elements) {
    final centre = at(element.x, element.y);
    final size = element.size * unit;
    final angle = turn(element.angle);
    switch (element) {
      case Leaf():
        _leaf(canvas, centre, size, angle, palette, shadows);
      case Bud():
        _bud(canvas, centre, size, angle, palette, shadows);
      case Blossom(:final petals):
        _blossom(canvas, centre, size, angle, petals, palette, shadows);
    }
  }
  canvas.restore();
}

void _shadow(ui.Canvas canvas, ui.Path path, double size, FloralPalette p) {
  canvas.drawPath(
    path.shift(ui.Offset(size * 0.03, size * 0.08)),
    ui.Paint()
      ..color = p.shadow
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, size * 0.08),
  );
}

void _leaf(
  ui.Canvas canvas,
  ui.Offset base,
  double length,
  double angle,
  FloralPalette p,
  bool shadows,
) {
  final w = length * 0.4;
  final local = ui.Path()
    ..moveTo(0, 0)
    ..cubicTo(length * 0.28, -w * 0.62, length * 0.72, -w * 0.5, length, 0)
    ..cubicTo(length * 0.7, w * 0.48, length * 0.3, w * 0.58, 0, 0)
    ..close();
  final matrix = _matrix(base, angle);
  final path = local.transform(matrix);
  if (shadows) _shadow(canvas, path, length, p);
  canvas.drawPath(
    path,
    ui.Paint()
      ..shader = ui.Gradient.linear(
        base,
        base + ui.Offset(math.cos(angle), math.sin(angle)) * length,
        [p.leafShade, p.leaf],
      ),
  );
  // The far half a shade darker: the leaf's fold.
  final half = ui.Path()
    ..moveTo(0, 0)
    ..cubicTo(length * 0.3, w * 0.58, length * 0.7, w * 0.48, length, 0)
    ..close();
  canvas.drawPath(
    half.transform(matrix),
    ui.Paint()..color = p.leafShade.withValues(alpha: 0.22),
  );
  final vein = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.round
    ..strokeWidth = math.max(0.6, length * 0.018)
    ..color = p.leafVein;
  canvas.drawPath(
    (ui.Path()
          ..moveTo(length * 0.04, 0)
          ..quadraticBezierTo(length * 0.5, -w * 0.06, length * 0.9, 0))
        .transform(matrix),
    vein,
  );
  final side = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.round
    ..strokeWidth = math.max(0.4, length * 0.008)
    ..color = p.leafVein.withValues(alpha: p.leafVein.a * 0.55);
  for (final t in [0.3, 0.5, 0.7]) {
    for (final s in [-1, 1]) {
      canvas.drawPath(
        (ui.Path()
              ..moveTo(length * t, 0)
              ..lineTo(length * (t + 0.12), s * w * 0.3))
            .transform(matrix),
        side,
      );
    }
  }
}

void _bud(
  ui.Canvas canvas,
  ui.Offset base,
  double size,
  double angle,
  FloralPalette p,
  bool shadows,
) {
  final matrix = _matrix(base, angle);
  final body =
      (ui.Path()
            ..moveTo(0, 0)
            ..cubicTo(
              size * 0.2,
              -size * 0.9,
              size * 1.6,
              -size * 0.7,
              size * 2,
              0,
            )
            ..cubicTo(size * 1.6, size * 0.7, size * 0.2, size * 0.9, 0, 0)
            ..close())
          .transform(matrix);
  if (shadows) _shadow(canvas, body, size * 2, p);
  canvas.drawPath(
    body,
    ui.Paint()
      ..shader = ui.Gradient.radial(
        base + ui.Offset(math.cos(angle), math.sin(angle)) * size * 1.3,
        size * 1.6,
        [p.petal, p.petalShade],
      ),
  );
  canvas.drawPath(
    body,
    ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = math.max(0.5, size * 0.05)
      ..color = p.petalEdge,
  );
  // Two small sepals hugging the base.
  for (final s in [-1, 1]) {
    canvas.drawPath(
      (ui.Path()
            ..moveTo(0, 0)
            ..quadraticBezierTo(
              size * 0.5,
              s * size * 0.6,
              size * 0.95,
              s * size * 0.1,
            )
            ..quadraticBezierTo(size * 0.45, s * size * 0.15, 0, 0)
            ..close())
          .transform(matrix),
      ui.Paint()..color = p.leafShade,
    );
  }
}

void _blossom(
  ui.Canvas canvas,
  ui.Offset centre,
  double radius,
  double angle,
  int petals,
  FloralPalette p,
  bool shadows,
) {
  final random = math.Random((centre.dx * 7 + centre.dy * 13).round());
  final outline = ui.Path();
  final petalPaths = <ui.Path>[];
  for (var i = 0; i < petals; i++) {
    final a =
        angle + i * 2 * math.pi / petals + (random.nextDouble() - 0.5) * 0.12;
    final length = radius * (0.92 + 0.16 * random.nextDouble());
    final width = length * 0.95;
    final petal =
        (ui.Path()
              ..moveTo(0, 0)
              ..cubicTo(
                length * 0.2,
                -width * 0.42,
                length * 0.68,
                -width * 0.6,
                length * 0.95,
                -width * 0.26,
              )
              ..quadraticBezierTo(length * 1.06, 0, length * 0.95, width * 0.26)
              ..cubicTo(
                length * 0.68,
                width * 0.6,
                length * 0.2,
                width * 0.42,
                0,
                0,
              )
              ..close())
            .transform(_matrix(centre, a));
    petalPaths.add(petal);
    outline.addPath(petal, ui.Offset.zero);
  }
  if (shadows) _shadow(canvas, outline, radius, p);

  final fill = ui.Paint()
    ..shader = ui.Gradient.radial(
      centre,
      radius * 1.05,
      [p.petalShade, p.petal, p.petal],
      [0.0, 0.55, 1.0],
    );
  final edge = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = math.max(0.5, radius * 0.022)
    ..color = p.petalEdge;
  final vein = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.round
    ..strokeWidth = math.max(0.4, radius * 0.012)
    ..color = p.petalEdge.withValues(alpha: p.petalEdge.a * 0.5);
  for (final (i, petal) in petalPaths.indexed) {
    canvas
      ..drawPath(petal, fill)
      ..drawPath(petal, edge);
    final a = angle + i * 2 * math.pi / petals;
    for (final spread in [-0.18, 0.0, 0.18]) {
      final start =
          centre +
          ui.Offset(math.cos(a + spread), math.sin(a + spread)) * radius * 0.3;
      final end =
          centre +
          ui.Offset(math.cos(a + spread * 1.4), math.sin(a + spread * 1.4)) *
              radius *
              0.75;
      canvas.drawLine(start, end, vein);
    }
  }

  // Golden centre with a ring of stamens.
  final heart = radius * 0.24;
  canvas.drawCircle(
    centre,
    heart,
    ui.Paint()
      ..shader = ui.Gradient.radial(
        centre - ui.Offset(heart * 0.3, heart * 0.3),
        heart * 1.3,
        [p.centre, p.centreDeep],
      ),
  );
  final stamen = ui.Paint()..color = p.centreDeep;
  for (var i = 0; i < 12; i++) {
    final a = angle + i * math.pi / 6;
    canvas.drawCircle(
      centre + ui.Offset(math.cos(a), math.sin(a)) * heart * 1.25,
      math.max(0.5, radius * 0.035),
      stamen,
    );
  }
}

Float64List _matrix(ui.Offset origin, double angle) {
  final cos = math.cos(angle);
  final sin = math.sin(angle);
  return Float64List(16)
    ..[0] = cos
    ..[1] = sin
    ..[4] = -sin
    ..[5] = cos
    ..[10] = 1
    ..[12] = origin.dx
    ..[13] = origin.dy
    ..[15] = 1;
}
