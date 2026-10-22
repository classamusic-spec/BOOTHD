/// The bundled template decorations: how each PNG in assets/decorations/
/// is drawn. Original artwork made in code for this project (provenance:
/// docs/ASSET_PROVENANCE.md). Regenerate after a change with
///
///     flutter test tool/art/generate_decorations_test.dart
///
/// and test/assets/decorations_current_test.dart checks the committed
/// files still match.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:porcelain_photo_booth/core/design_system/floral_art.dart';
import 'package:porcelain_photo_booth/core/design_system/party_art.dart';

final class DecorationArt {
  const DecorationArt(this.file, this.width, this.height, this.paint);

  /// File name under assets/decorations/.
  final String file;
  final int width;
  final int height;
  final void Function(ui.Canvas canvas, ui.Rect area) paint;
}

final decorationArt = <DecorationArt>[
  DecorationArt(
    'blossom_corner.png',
    1200,
    1200,
    (canvas, area) => paintFloralArrangement(
      canvas,
      FloralArrangement.cornerSpray(seed: 1),
      FloralPalette.garden,
      area,
    ),
  ),
  DecorationArt(
    'blossom_corner_champagne.png',
    1200,
    1200,
    (canvas, area) => paintFloralArrangement(
      canvas,
      FloralArrangement.cornerSpray(seed: 4),
      FloralPalette.champagne,
      area,
    ),
  ),
  DecorationArt(
    'blossom_garland.png',
    360,
    1800,
    (canvas, area) => paintFloralArrangement(
      canvas,
      FloralArrangement.garland(),
      FloralPalette.garden,
      area,
    ),
  ),
  DecorationArt(
    'blossom_sprig.png',
    900,
    450,
    (canvas, area) => paintFloralArrangement(
      canvas,
      FloralArrangement.sprig(),
      FloralPalette.garden,
      area,
    ),
  ),
  DecorationArt('gold_frame.png', 1200, 1800, _goldFrame),
  DecorationArt('gold_frame_strip.png', 600, 1800, _goldFrame),
  DecorationArt('film_edges.png', 600, 1800, _filmEdges),
  DecorationArt('gold_confetti.png', 1200, 1800, _confetti),
  // EP04: Kid Party Arcade.
  DecorationArt('party_balloons.png', 1200, 1200, paintPartyBalloons),
  DecorationArt('party_confetti.png', 1200, 1800, paintPartyConfetti),
  DecorationArt('party_stars.png', 1200, 1200, paintPartyStars),
  DecorationArt('party_bunting.png', 1800, 540, paintPartyBunting),
  // EP05: Retro Game Quest.
  DecorationArt('pixel_hearts.png', 900, 300, paintPixelHearts),
  DecorationArt('pixel_coins.png', 1200, 1800, paintPixelCoins),
  DecorationArt('pixel_stars.png', 1200, 1200, paintPixelStars),
  DecorationArt('pixel_frame.png', 1200, 1800, paintPixelFrame),
  DecorationArt('pixel_frame_strip.png', 600, 1800, paintPixelFrame),
  DecorationArt('arcade_marquee.png', 1200, 360, paintArcadeMarquee),
];

/// Champagne-gold metal, as a gradient across [rect].
ui.Shader _gold(ui.Rect rect) => ui.Gradient.linear(
  rect.topLeft,
  rect.bottomRight,
  const [
    ui.Color(0xFF8C6B3F),
    ui.Color(0xFFE8CF94),
    ui.Color(0xFFB8934F),
    ui.Color(0xFFF6E5B8),
    ui.Color(0xFFA27D43),
    ui.Color(0xFFE2C383),
  ],
  const [0.0, 0.2, 0.42, 0.58, 0.8, 1.0],
);

/// A double gold rule inset from the edge, with a scrolled flourish in
/// each corner and a small diamond at each side's middle.
void _goldFrame(ui.Canvas canvas, ui.Rect area) {
  final unit = math.min(area.width, area.height);
  final outer = area.deflate(unit * 0.035);
  final inner = area.deflate(unit * 0.06);
  final paint = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..shader = _gold(area);
  canvas
    ..drawRect(outer, paint..strokeWidth = unit * 0.012)
    ..drawRect(inner, paint..strokeWidth = unit * 0.004);
  final fill = ui.Paint()..shader = _gold(area);
  for (final (cx, cy, sx, sy) in [
    (inner.left, inner.top, 1.0, 1.0),
    (inner.right, inner.top, -1.0, 1.0),
    (inner.right, inner.bottom, -1.0, -1.0),
    (inner.left, inner.bottom, 1.0, -1.0),
  ]) {
    final s = unit * 0.11;
    final flourish = ui.Path()
      ..moveTo(cx, cy)
      ..cubicTo(
        cx + sx * s * 0.9,
        cy,
        cx + sx * s,
        cy + sy * s * 0.5,
        cx + sx * s * 0.55,
        cy + sy * s * 0.55,
      )
      ..cubicTo(
        cx + sx * s * 0.25,
        cy + sy * s * 0.6,
        cx + sx * s * 0.3,
        cy + sy * s * 0.25,
        cx + sx * s * 0.45,
        cy + sy * s * 0.3,
      )
      ..moveTo(cx, cy)
      ..cubicTo(
        cx,
        cy + sy * s * 0.9,
        cx + sx * s * 0.5,
        cy + sy * s,
        cx + sx * s * 0.55,
        cy + sy * s * 0.55,
      );
    canvas.drawPath(flourish, paint..strokeWidth = unit * 0.006);
    canvas.drawCircle(
      ui.Offset(cx + sx * s * 0.2, cy + sy * s * 0.2),
      unit * 0.012,
      fill,
    );
  }
  for (final (x, y) in [
    (inner.center.dx, outer.top),
    (inner.center.dx, outer.bottom),
    (outer.left, inner.center.dy),
    (outer.right, inner.center.dy),
  ]) {
    final d = unit * 0.022;
    canvas.drawPath(
      ui.Path()
        ..moveTo(x, y - d)
        ..lineTo(x + d, y)
        ..lineTo(x, y + d)
        ..lineTo(x - d, y)
        ..close(),
      fill,
    );
  }
}

/// Dark film bands down both sides with rounded sprocket holes.
void _filmEdges(ui.Canvas canvas, ui.Rect area) {
  final band = area.width * 0.11;
  final film = ui.Paint()..color = const ui.Color(0xFF1C1713);
  final hole = ui.Paint()..blendMode = ui.BlendMode.clear;
  canvas.saveLayer(area, ui.Paint());
  canvas
    ..drawRect(ui.Rect.fromLTWH(area.left, area.top, band, area.height), film)
    ..drawRect(
      ui.Rect.fromLTWH(area.right - band, area.top, band, area.height),
      film,
    );
  final holeW = band * 0.42;
  final holeH = band * 0.3;
  final step = holeH * 2.1;
  for (var y = area.top + step / 2; y < area.bottom; y += step) {
    for (final x in [area.left + band / 2, area.right - band / 2]) {
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromCenter(
            center: ui.Offset(x, y),
            width: holeW,
            height: holeH,
          ),
          ui.Radius.circular(holeH * 0.25),
        ),
        hole,
      );
    }
  }
  canvas.restore();
  // A faint amber edge where film meets the picture.
  final edge = ui.Paint()
    ..color = const ui.Color(0x99D8A55A)
    ..strokeWidth = area.width * 0.004;
  canvas
    ..drawLine(
      ui.Offset(area.left + band, area.top),
      ui.Offset(area.left + band, area.bottom),
      edge,
    )
    ..drawLine(
      ui.Offset(area.right - band, area.top),
      ui.Offset(area.right - band, area.bottom),
      edge,
    );
}

/// Gold dots, small stars and curled ribbons, thicker towards the edges.
void _confetti(ui.Canvas canvas, ui.Rect area) {
  final random = math.Random(26);
  final unit = math.min(area.width, area.height);
  final fill = ui.Paint()..shader = _gold(area);
  for (var i = 0; i < 160; i++) {
    // Mostly along the edges, keeping the middle for photos.
    final edge = random.nextInt(4);
    final along = random.nextDouble();
    final depth = math.pow(random.nextDouble(), 2.2) * 0.22;
    final (fx, fy) = switch (edge) {
      0 => (along, depth),
      1 => (1 - depth, along),
      2 => (along, 1 - depth),
      _ => (depth, along),
    };
    final centre = ui.Offset(
      area.left + fx * area.width,
      area.top + fy * area.height,
    );
    final size = unit * (0.004 + 0.01 * random.nextDouble());
    switch (random.nextInt(5)) {
      case 0:
        _star(canvas, centre, size * 1.8, fill);
      case 1:
        canvas.drawPath(
          ui.Path()
            ..moveTo(centre.dx - size * 3, centre.dy)
            ..cubicTo(
              centre.dx - size,
              centre.dy - size * 3,
              centre.dx + size,
              centre.dy + size * 3,
              centre.dx + size * 3,
              centre.dy,
            ),
          ui.Paint()
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = size * 0.8
            ..strokeCap = ui.StrokeCap.round
            ..shader = _gold(area),
        );
      default:
        canvas.drawCircle(centre, size, fill);
    }
  }
}

void _star(ui.Canvas canvas, ui.Offset c, double r, ui.Paint paint) {
  final path = ui.Path();
  for (var i = 0; i < 8; i++) {
    final a = -math.pi / 2 + i * math.pi / 4;
    final radius = i.isEven ? r : r * 0.32;
    final p = c + ui.Offset(math.cos(a), math.sin(a)) * radius;
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  canvas.drawPath(path..close(), paint);
}

/// Renders [art] to PNG bytes with a transparent background.
Future<List<int>> renderDecoration(DecorationArt art) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  art.paint(
    canvas,
    ui.Rect.fromLTWH(0, 0, art.width.toDouble(), art.height.toDouble()),
  );
  final image = await recorder.endRecording().toImage(art.width, art.height);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return png!.buffer.asUint8List();
}
