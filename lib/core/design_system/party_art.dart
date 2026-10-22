/// Party and pixel artwork drawn in code for this project (EP04, EP05):
/// balloons, bunting, confetti and stars for Kid Party Arcade; pixel
/// hearts, coins, sparkles, a pixel border and a lit marquee for Retro
/// Game Quest. Original shapes only: no character, logo, console or game
/// screen is drawn or imitated (provenance: `docs/ASSET_PROVENANCE.md`).
///
/// Deterministic (fixed seeds): the same art draws the same way on guest
/// screens and in the bundled template decorations (`tool/art/`).
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

const _coral = ui.Color(0xFFFF6B6B);
const _sunshine = ui.Color(0xFFFFC94D);
const _sky = ui.Color(0xFF4DA8FF);
const _mint = ui.Color(0xFF3CC9A0);
const _grape = ui.Color(0xFF9B6BFF);
const _partyColors = [_coral, _sunshine, _sky, _mint, _grape];

const _night = ui.Color(0xFF1D1B3A);
const _pixelRed = ui.Color(0xFFFF4D6D);
const _pixelGold = ui.Color(0xFFFFD23F);
const _pixelGoldDark = ui.Color(0xFFC98A12);
const _pixelBlue = ui.Color(0xFF4D7CFE);
const _pixelWhite = ui.Color(0xFFFFFFFF);

/// A balloon with a soft highlight, a knot and a curling string.
void _balloon(
  ui.Canvas canvas,
  ui.Offset centre,
  double radius,
  ui.Color colour,
  double tilt,
) {
  canvas
    ..save()
    ..translate(centre.dx, centre.dy)
    ..rotate(tilt);
  final body = ui.Rect.fromCenter(
    center: ui.Offset.zero,
    width: radius * 1.7,
    height: radius * 2,
  );
  final string = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = radius * 0.03
    ..color = const ui.Color(0xFF6B5A4A);
  final path = ui.Path()..moveTo(0, radius * 1.08);
  for (var i = 1; i <= 6; i++) {
    path.quadraticBezierTo(
      (i.isEven ? 1 : -1) * radius * 0.18,
      radius * (1.08 + i * 0.22 - 0.11),
      0,
      radius * (1.08 + i * 0.22),
    );
  }
  canvas.drawPath(path, string);
  canvas.drawOval(
    body,
    ui.Paint()
      ..shader = ui.Gradient.radial(
        ui.Offset(-radius * 0.3, -radius * 0.4),
        radius * 1.4,
        [
          ui.Color.lerp(colour, const ui.Color(0xFFFFFFFF), 0.35)!,
          colour,
          ui.Color.lerp(colour, const ui.Color(0xFF000000), 0.18)!,
        ],
        const [0, 0.55, 1],
      ),
  );
  canvas.drawPath(
    ui.Path()
      ..moveTo(-radius * 0.12, radius * 1.1)
      ..lineTo(radius * 0.12, radius * 1.1)
      ..lineTo(0, radius * 0.96)
      ..close(),
    ui.Paint()..color = colour,
  );
  canvas.drawOval(
    ui.Rect.fromCenter(
      center: ui.Offset(-radius * 0.35, -radius * 0.45),
      width: radius * 0.32,
      height: radius * 0.55,
    ),
    ui.Paint()..color = const ui.Color(0x66FFFFFF),
  );
  canvas.restore();
}

/// A cluster of five balloons for a corner.
void paintPartyBalloons(ui.Canvas canvas, ui.Rect area) {
  final u = math.min(area.width, area.height);
  for (final (x, y, r, c, t) in [
    (0.30, 0.30, 0.16, _sky, -0.25),
    (0.55, 0.22, 0.15, _coral, 0.1),
    (0.20, 0.55, 0.13, _sunshine, -0.4),
    (0.48, 0.47, 0.14, _grape, 0.05),
    (0.72, 0.36, 0.12, _mint, 0.3),
  ]) {
    _balloon(
      canvas,
      ui.Offset(area.left + area.width * x, area.top + area.height * y),
      u * r,
      c,
      t,
    );
  }
}

/// Scattered confetti, densest at the edges, the middle left clear for
/// photos.
void paintPartyConfetti(ui.Canvas canvas, ui.Rect area) {
  final random = math.Random(31);
  final u = math.min(area.width, area.height);
  for (var i = 0; i < 200; i++) {
    final x = random.nextDouble();
    final y = random.nextDouble();
    final edge = math.min(math.min(x, 1 - x), math.min(y, 1 - y));
    if (edge > 0.12 && random.nextDouble() > 0.08) continue;
    final colour = _partyColors[random.nextInt(_partyColors.length)];
    final p = ui.Offset(area.left + x * area.width, area.top + y * area.height);
    final size = u * (0.02 + random.nextDouble() * 0.016);
    final paint = ui.Paint()..color = colour;
    canvas
      ..save()
      ..translate(p.dx, p.dy)
      ..rotate(random.nextDouble() * math.pi);
    switch (random.nextInt(3)) {
      case 0:
        canvas.drawRect(
          ui.Rect.fromCenter(
            center: ui.Offset.zero,
            width: size * 2.2,
            height: size,
          ),
          paint,
        );
      case 1:
        canvas.drawCircle(ui.Offset.zero, size * 0.7, paint);
      default:
        canvas.drawPath(
          ui.Path()
            ..moveTo(-size * 1.4, 0)
            ..quadraticBezierTo(-size * 0.7, -size, 0, 0)
            ..quadraticBezierTo(size * 0.7, size, size * 1.4, 0),
          paint
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = size * 0.7
            ..strokeCap = ui.StrokeCap.round,
        );
    }
    canvas.restore();
  }
}

ui.Path starPath(ui.Offset c, double r, [double inner = 0.45]) {
  final path = ui.Path();
  for (var i = 0; i < 10; i++) {
    final a = i * math.pi / 5 - math.pi / 2;
    final d = i.isEven ? r : r * inner;
    final p = ui.Offset(c.dx + math.cos(a) * d, c.dy + math.sin(a) * d);
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path..close();
}

/// A burst of rounded party stars.
void paintPartyStars(ui.Canvas canvas, ui.Rect area) {
  final random = math.Random(47);
  final u = math.min(area.width, area.height);
  for (var i = 0; i < 18; i++) {
    final c = ui.Offset(
      area.left + area.width * (0.08 + random.nextDouble() * 0.84),
      area.top + area.height * (0.08 + random.nextDouble() * 0.84),
    );
    final r = u * (0.03 + random.nextDouble() * 0.06);
    final colour = _partyColors[i % _partyColors.length];
    final star = starPath(c, r);
    canvas
      // An opaque darker copy for depth: no translucent pixels, so every
      // preview size resamples it the same way.
      ..drawPath(
        star.shift(ui.Offset(r * 0.08, r * 0.1)),
        ui.Paint()
          ..color = ui.Color.lerp(colour, const ui.Color(0xFF000000), 0.35)!,
      )
      ..drawPath(
        star,
        ui.Paint()
          ..color = colour
          ..strokeJoin = ui.StrokeJoin.round,
      )
      ..drawPath(
        star,
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeJoin = ui.StrokeJoin.round
          ..strokeWidth = r * 0.12
          ..color = const ui.Color(0xFFFFFFFF),
      );
  }
}

/// A string of bunting flags across the top.
void paintPartyBunting(ui.Canvas canvas, ui.Rect area) {
  final sag = area.height * 0.25;
  ui.Offset at(double t) => ui.Offset(
    area.left + area.width * t,
    area.top + area.height * 0.12 + sag * 4 * t * (1 - t),
  );
  final string = ui.Path()..moveTo(at(0).dx, at(0).dy);
  for (var i = 1; i <= 40; i++) {
    final p = at(i / 40);
    string.lineTo(p.dx, p.dy);
  }
  canvas.drawPath(
    string,
    ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = area.height * 0.02
      ..color = const ui.Color(0xFF6B5A4A),
  );
  const flags = 11;
  for (var i = 0; i < flags; i++) {
    final a = at((i + 0.15) / flags);
    final b = at((i + 0.85) / flags);
    final tip = ui.Offset(
      (a.dx + b.dx) / 2,
      math.max(a.dy, b.dy) + area.height * 0.5,
    );
    canvas.drawPath(
      ui.Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(tip.dx, tip.dy)
        ..close(),
      ui.Paint()..color = _partyColors[i % _partyColors.length],
    );
  }
}

/// Draws [rows] (one string per row; '.' is empty, other letters pick a
/// colour from [colours]) as square pixels of [cell] at [origin].
void paintPixels(
  ui.Canvas canvas,
  ui.Offset origin,
  double cell,
  List<String> rows,
  Map<String, ui.Color> colours,
) {
  for (final (y, row) in rows.indexed) {
    for (var x = 0; x < row.length; x++) {
      final colour = colours[row[x]];
      if (colour == null) continue;
      canvas.drawRect(
        ui.Rect.fromLTWH(
          origin.dx + x * cell,
          origin.dy + y * cell,
          cell + 0.5,
          cell + 0.5,
        ),
        ui.Paint()..color = colour,
      );
    }
  }
}

const _heart = [
  '.kk...kk.',
  'krrk.krrk',
  'krwrrrrrk',
  'krrrrrrrk',
  '.krrrrrk.',
  '..krrrk..',
  '...krk...',
  '....k....',
];

const _coin = [
  '..kkkk..',
  '.kggggk.',
  'kgwyyygk',
  'kgwyydgk',
  'kgyyydgk',
  'kgyyydgk',
  '.kgddgk.',
  '..kkkk..',
];

const _sparkle = [
  '...w...',
  '...w...',
  '..www..',
  'wwwwwww',
  '..www..',
  '...w...',
  '...w...',
];

const _pixelColours = {
  'k': _night,
  'r': _pixelRed,
  'w': _pixelWhite,
  'g': _pixelGoldDark,
  'y': _pixelGold,
  'd': ui.Color(0xFFE0A526),
  'b': _pixelBlue,
};

/// Three pixel hearts in a row, like lives on a scoreboard.
void paintPixelHearts(ui.Canvas canvas, ui.Rect area) {
  // Three hearts of nine cells with a cell and a half between them.
  final cell = math.min(area.height / 9, area.width / 31);
  for (var i = 0; i < 3; i++) {
    paintPixels(
      canvas,
      ui.Offset(
        area.left + cell * 0.5 + i * cell * 10.5,
        area.top + cell * 0.5,
      ),
      cell,
      _heart,
      _pixelColours,
    );
  }
}

/// Pixel coins scattered round the edges.
void paintPixelCoins(ui.Canvas canvas, ui.Rect area) {
  final random = math.Random(53);
  final u = math.min(area.width, area.height);
  final cell = u * 0.012;
  for (var i = 0; i < 26; i++) {
    final x = random.nextDouble();
    final y = random.nextDouble();
    final edge = math.min(math.min(x, 1 - x), math.min(y, 1 - y));
    if (edge > 0.1) continue;
    paintPixels(
      canvas,
      ui.Offset(
        area.left + x * (area.width - cell * 8),
        area.top + y * (area.height - cell * 8),
      ),
      cell,
      _coin,
      _pixelColours,
    );
  }
}

/// Pixel sparkles of a few sizes.
void paintPixelStars(ui.Canvas canvas, ui.Rect area) {
  final random = math.Random(59);
  final u = math.min(area.width, area.height);
  for (var i = 0; i < 16; i++) {
    final cell = u * (0.008 + random.nextInt(3) * 0.005);
    paintPixels(
      canvas,
      ui.Offset(
        area.left + random.nextDouble() * (area.width - cell * 7),
        area.top + random.nextDouble() * (area.height - cell * 7),
      ),
      cell,
      _sparkle,
      {'w': i.isEven ? _pixelWhite : _pixelGold},
    );
  }
}

/// A chunky pixel border with stepped corners and a dashed inner rule.
void paintPixelFrame(ui.Canvas canvas, ui.Rect area) {
  final u = math.min(area.width, area.height);
  final cell = u * 0.022;
  final paint = ui.Paint()..color = _night;
  final accent = ui.Paint()..color = _pixelBlue;
  // Outer band, three cells thick, with the corners stepped in.
  for (var ring = 0; ring < 3; ring++) {
    final inset = cell * ring;
    final r = area.deflate(inset);
    canvas
      ..drawRect(
        ui.Rect.fromLTWH(r.left + cell * 2, r.top, r.width - cell * 4, cell),
        paint,
      )
      ..drawRect(
        ui.Rect.fromLTWH(
          r.left + cell * 2,
          r.bottom - cell,
          r.width - cell * 4,
          cell,
        ),
        paint,
      )
      ..drawRect(
        ui.Rect.fromLTWH(r.left, r.top + cell * 2, cell, r.height - cell * 4),
        paint,
      )
      ..drawRect(
        ui.Rect.fromLTWH(
          r.right - cell,
          r.top + cell * 2,
          cell,
          r.height - cell * 4,
        ),
        paint,
      );
  }
  for (final (x, y) in [
    (area.left + cell, area.top + cell),
    (area.right - cell * 2, area.top + cell),
    (area.left + cell, area.bottom - cell * 2),
    (area.right - cell * 2, area.bottom - cell * 2),
  ]) {
    canvas.drawRect(ui.Rect.fromLTWH(x, y, cell, cell), paint);
  }
  // A dashed inner line of alternating blocks.
  final inner = area.deflate(cell * 4);
  var on = true;
  for (var x = inner.left; x < inner.right - cell; x += cell) {
    if (on) {
      canvas
        ..drawRect(ui.Rect.fromLTWH(x, inner.top, cell, cell * 0.6), accent)
        ..drawRect(
          ui.Rect.fromLTWH(x, inner.bottom - cell * 0.6, cell, cell * 0.6),
          accent,
        );
    }
    on = !on;
  }
  on = true;
  for (var y = inner.top; y < inner.bottom - cell; y += cell) {
    if (on) {
      canvas
        ..drawRect(ui.Rect.fromLTWH(inner.left, y, cell * 0.6, cell), accent)
        ..drawRect(
          ui.Rect.fromLTWH(inner.right - cell * 0.6, y, cell * 0.6, cell),
          accent,
        );
    }
    on = !on;
  }
}

/// A marquee sign: a deep panel ringed with round lights.
void paintArcadeMarquee(ui.Canvas canvas, ui.Rect area) {
  final r = ui.RRect.fromRectAndRadius(
    area.deflate(area.height * 0.06),
    ui.Radius.circular(area.height * 0.12),
  );
  canvas
    ..drawRRect(r, ui.Paint()..color = _night)
    ..drawRRect(
      r,
      ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = area.height * 0.04
        ..color = _pixelGold,
    );
  final inner = r.deflate(area.height * 0.1);
  final bulb = area.height * 0.045;
  final glow = ui.Paint()
    ..color = const ui.Color(0x66FFD23F)
    ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, bulb);
  final light = ui.Paint()..color = const ui.Color(0xFFFFF4C2);
  final along = (inner.width / (bulb * 4)).floor();
  for (var i = 0; i <= along; i++) {
    final x = inner.left + inner.width * i / along;
    for (final y in [inner.top, inner.bottom]) {
      canvas
        ..drawCircle(ui.Offset(x, y), bulb * 1.6, glow)
        ..drawCircle(ui.Offset(x, y), bulb, light);
    }
  }
  final down = (inner.height / (bulb * 4)).floor();
  for (var i = 1; i < down; i++) {
    final y = inner.top + inner.height * i / down;
    for (final x in [inner.left, inner.right]) {
      canvas
        ..drawCircle(ui.Offset(x, y), bulb * 1.6, glow)
        ..drawCircle(ui.Offset(x, y), bulb, light);
    }
  }
}
