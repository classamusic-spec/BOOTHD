import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../../core/experience/guest_experience.dart';
import '../../domain/experience/experience_catalog.dart';

/// The state a guest button face is drawn in.
@immutable
final class GuestButtonLook {
  const GuestButtonLook({
    required this.enabled,
    required this.pressed,
    required this.focused,
    required this.primary,
    required this.selected,
  });

  final bool enabled;
  final bool pressed;
  final bool focused;
  final bool primary;
  final bool selected;

  @override
  bool operator ==(Object other) =>
      other is GuestButtonLook &&
      other.enabled == enabled &&
      other.pressed == pressed &&
      other.focused == focused &&
      other.primary == primary &&
      other.selected == selected;

  @override
  int get hashCode => Object.hash(enabled, pressed, focused, primary, selected);
}

/// One button family's drawing (EP02). Faces differ only in shape, depth
/// and ornament: the fill and text colours come from the pack's validated
/// pairs (accent and on-accent, panel and ink), so every family is as
/// readable as the pack.
abstract base class GuestButtonFace {
  const GuestButtonFace();

  static GuestButtonFace of(GuestButtonStyle style) => switch (style) {
    GuestButtonStyle.porcelain => const PorcelainFace(),
    GuestButtonStyle.wood => const WoodFace(),
    GuestButtonStyle.toyArcade => const ToyArcadeFace(),
    GuestButtonStyle.retroGame => const RetroGameFace(),
    GuestButtonStyle.gala => const GalaFace(),
    GuestButtonStyle.neonParty => const NeonPartyFace(),
  };

  /// Label and icon colour.
  Color ink(GuestTokens t, GuestButtonLook look) {
    if (!look.enabled) return t.inkMuted;
    return look.primary ? t.onAccent : t.ink;
  }

  /// The face's fill.
  Color fill(GuestTokens t, GuestButtonLook look) {
    if (!look.enabled) return t.panel;
    return look.primary ? t.accent : t.panel;
  }

  /// The face's boundary: always drawn, so the button is identifiable
  /// without its shadow.
  Color edge(GuestTokens t, GuestButtonLook look) =>
      look.enabled ? t.accentEdge : t.panelEdge;

  /// How far the face moves down when fully pressed.
  double get pressTravel => 2;

  double travel(double press) => pressTravel * press;

  EdgeInsets contentPadding(double height) =>
      EdgeInsets.symmetric(horizontal: height * 0.42, vertical: 10);

  TextStyle labelStyle(GuestTokens t, double size) => t.buttonLabel(size);

  String transformLabel(String label) => label;

  /// Paints the face in [rect]; [press] runs from 0 (raised) to 1
  /// (pressed).
  void paint(
    Canvas canvas,
    Rect rect,
    GuestTokens t,
    GuestButtonLook look,
    double press,
  );

  /// The keyboard focus ring: the pack's ink, outside the shape, so it
  /// shows on the backdrop (ink on backdrop is 4.5:1 or more).
  void paintFocus(Canvas canvas, RRect shape, GuestTokens t) {
    canvas.drawRRect(
      shape.inflate(5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = t.ink,
    );
  }

  /// [color] darkened by [amount] (0 to 1) of its lightness.
  static Color shade(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness(hsl.lightness * (1 - amount)).toColor();
  }

  /// [color] lightened by [amount] (0 to 1) of the way to white.
  static Color tint(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness(hsl.lightness + (1 - hsl.lightness) * amount)
        .toColor();
  }
}

/// Paints a [GuestButtonFace] behind the button's content.
class GuestButtonPainter extends CustomPainter {
  GuestButtonPainter({
    required this.face,
    required this.tokens,
    required this.look,
    required this.press,
  });

  final GuestButtonFace face;
  final GuestTokens tokens;
  final GuestButtonLook look;
  final double press;

  @override
  void paint(Canvas canvas, Size size) =>
      face.paint(canvas, Offset.zero & size, tokens, look, press);

  @override
  bool shouldRepaint(GuestButtonPainter old) =>
      old.face != face ||
      old.tokens != tokens ||
      old.look != look ||
      old.press != press;
}

RRect _stadium(Rect rect) =>
    RRect.fromRectAndRadius(rect, Radius.circular(rect.shortestSide / 2));

void _softShadow(
  Canvas canvas,
  RRect shape,
  Color color,
  double blur,
  double dy,
) {
  if (blur <= 0) return;
  canvas.drawRRect(
    shape.shift(Offset(0, dy)),
    Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur / 2),
  );
}

/// Pearl and champagne: a glazed pill with a gilded edge and a rim light
/// (Porcelain Classic, Storybook Garden).
final class PorcelainFace extends GuestButtonFace {
  const PorcelainFace();

  @override
  void paint(
    Canvas canvas,
    Rect rect,
    GuestTokens t,
    GuestButtonLook look,
    double press,
  ) {
    final body = _stadium(rect.translate(0, travel(press)));
    if (look.enabled) {
      _softShadow(
        canvas,
        body,
        t.ink.withValues(alpha: lerpDouble(0.22, 0.12, press)!),
        lerpDouble(18, 5, press)!,
        lerpDouble(7, 2, press)!,
      );
    }
    final base = fill(t, look);
    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: press > 0.5
              ? [GuestButtonFace.shade(base, 0.05), base]
              : [
                  GuestButtonFace.tint(base, 0.28),
                  base,
                  GuestButtonFace.shade(base, 0.06),
                ],
        ).createShader(body.outerRect),
    );
    // A glaze highlight across the upper half.
    canvas
      ..save()
      ..clipRRect(body);
    final glaze = Rect.fromLTWH(
      body.left + body.height * 0.45,
      body.top + 3,
      body.width - body.height * 0.9,
      body.height * 0.3,
    );
    canvas.drawRRect(
      _stadium(glaze),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            t.highlight.withValues(alpha: 0.4 * (1 - press)),
            t.highlight.withValues(alpha: 0),
          ],
        ).createShader(glaze),
    );
    canvas.restore();
    canvas.drawRRect(
      body.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = look.selected ? 3 : 2
        ..color = edge(t, look),
    );
    if (look.focused) paintFocus(canvas, body, t);
  }
}

/// Honey oak: a plank with grain, a bevel and brass pins (Vintage Light
/// Wood, Retro Film).
final class WoodFace extends GuestButtonFace {
  const WoodFace();

  @override
  void paint(
    Canvas canvas,
    Rect rect,
    GuestTokens t,
    GuestButtonLook look,
    double press,
  ) {
    const radius = Radius.circular(14);
    const bevel = 5.0;
    final lift = bevel * (1 - press);
    final face = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        rect.left,
        rect.top + travel(press),
        rect.right,
        rect.bottom - lift,
      ),
      radius,
    );
    final base = fill(t, look);
    if (look.enabled) {
      _softShadow(
        canvas,
        RRect.fromRectAndRadius(rect, radius),
        t.ink.withValues(alpha: 0.2),
        10,
        4,
      );
      // The plank's lower edge, seen from the front.
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.translate(0, travel(press)), radius),
        Paint()
          ..color = GuestButtonFace.shade(
            look.primary ? t.accentEdge : t.panelEdge,
            0.1,
          ),
      );
    }
    canvas.drawRRect(
      face,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [GuestButtonFace.tint(base, 0.12), base],
        ).createShader(face.outerRect),
    );
    // Grain: long, gently waving lines.
    canvas
      ..save()
      ..clipRRect(face);
    final grain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = GuestButtonFace.shade(
        base,
        0.35,
      ).withValues(alpha: look.enabled ? 0.16 : 0.08);
    for (var i = 0; i < 7; i++) {
      final y = face.top + face.height * (0.12 + i * 0.13);
      final path = Path()..moveTo(face.left, y);
      for (var x = 0.0; x <= face.width; x += 12) {
        path.lineTo(
          face.left + x,
          y + math.sin(x / (38 + i * 7) + i * 1.7) * (1.6 + (i % 3)),
        );
      }
      canvas.drawPath(path, grain);
    }
    canvas.restore();
    canvas.drawRRect(
      face.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = look.selected ? 3 : 2
        ..color = edge(t, look),
    );
    // Brass pins in the corners.
    final pin = Paint()..color = look.enabled ? t.decorationA : t.panelEdge;
    for (final corner in [
      Offset(face.left + 11, face.top + 11),
      Offset(face.right - 11, face.top + 11),
      Offset(face.left + 11, face.bottom - 11),
      Offset(face.right - 11, face.bottom - 11),
    ]) {
      canvas.drawCircle(corner, 2.6, pin);
    }
    if (look.focused) paintFocus(canvas, face, t);
  }
}

/// A chunky candy button on a thick base that sinks when pressed (Kid
/// Party Arcade).
final class ToyArcadeFace extends GuestButtonFace {
  const ToyArcadeFace();

  static const depth = 9.0;

  @override
  double get pressTravel => depth - 2;

  @override
  EdgeInsets contentPadding(double height) =>
      EdgeInsets.fromLTRB(height * 0.42, 10, height * 0.42, 10 + depth);

  @override
  void paint(
    Canvas canvas,
    Rect rect,
    GuestTokens t,
    GuestButtonLook look,
    double press,
  ) {
    final base = _stadium(
      Rect.fromLTRB(rect.left, rect.top + depth, rect.right, rect.bottom),
    );
    final top = _stadium(
      Rect.fromLTRB(
        rect.left,
        rect.top + travel(press),
        rect.right,
        rect.bottom - depth + travel(press),
      ),
    );
    final colour = fill(t, look);
    if (look.enabled) {
      _softShadow(canvas, base, t.ink.withValues(alpha: 0.25), 12, 4);
    }
    canvas.drawRRect(
      base,
      Paint()..color = look.enabled ? t.accentEdge : t.panelEdge,
    );
    canvas.drawRRect(top, Paint()..color = colour);
    // A glossy blob on the upper left, like moulded plastic.
    if (look.enabled) {
      final gloss = Rect.fromLTWH(
        top.left + top.height * 0.35,
        top.top + top.height * 0.12,
        math.min(top.width * 0.4, top.height * 1.6),
        top.height * 0.28,
      );
      canvas.drawRRect(
        _stadium(gloss),
        Paint()..color = t.highlight.withValues(alpha: 0.5),
      );
    }
    canvas.drawRRect(
      top.deflate(1.25),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = look.selected ? 3.5 : 2.5
        ..color = edge(t, look),
    );
    if (look.focused) {
      paintFocus(
        canvas,
        _stadium(Rect.fromLTRB(rect.left, top.top, rect.right, base.bottom)),
        t,
      );
    }
  }
}

/// Pixel-stepped corners, a heavy outline and a hard drop shadow that the
/// face covers when pressed (Retro Game Quest). Original shapes only.
final class RetroGameFace extends GuestButtonFace {
  const RetroGameFace();

  static const step = 5.0;
  static const drop = 6.0;

  @override
  double get pressTravel => drop;

  @override
  EdgeInsets contentPadding(double height) =>
      EdgeInsets.fromLTRB(height * 0.36, 10, height * 0.36 + drop, 10 + drop);

  @override
  double travel(double press) => drop * press;

  Path _pixelBox(Rect r) {
    const s = step;
    return Path()
      ..moveTo(r.left + 2 * s, r.top)
      ..lineTo(r.right - 2 * s, r.top)
      ..lineTo(r.right - 2 * s, r.top + s)
      ..lineTo(r.right - s, r.top + s)
      ..lineTo(r.right - s, r.top + 2 * s)
      ..lineTo(r.right, r.top + 2 * s)
      ..lineTo(r.right, r.bottom - 2 * s)
      ..lineTo(r.right - s, r.bottom - 2 * s)
      ..lineTo(r.right - s, r.bottom - s)
      ..lineTo(r.right - 2 * s, r.bottom - s)
      ..lineTo(r.right - 2 * s, r.bottom)
      ..lineTo(r.left + 2 * s, r.bottom)
      ..lineTo(r.left + 2 * s, r.bottom - s)
      ..lineTo(r.left + s, r.bottom - s)
      ..lineTo(r.left + s, r.bottom - 2 * s)
      ..lineTo(r.left, r.bottom - 2 * s)
      ..lineTo(r.left, r.top + 2 * s)
      ..lineTo(r.left + s, r.top + 2 * s)
      ..lineTo(r.left + s, r.top + s)
      ..lineTo(r.left + 2 * s, r.top + s)
      ..close();
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect,
    GuestTokens t,
    GuestButtonLook look,
    double press,
  ) {
    final home = Rect.fromLTRB(
      rect.left,
      rect.top,
      rect.right - drop,
      rect.bottom - drop,
    );
    final shift = drop * press;
    final face = home.translate(shift, shift);
    if (look.enabled) {
      // A hard shadow that reads on the backdrop: the ink on light ones, a
      // deep shade of the backdrop on dark ones.
      final dark = t.backdrop.computeLuminance() < 0.2;
      canvas.drawPath(
        _pixelBox(home.translate(drop, drop)),
        Paint()..color = dark ? GuestButtonFace.shade(t.backdrop, 0.75) : t.ink,
      );
    }
    final body = _pixelBox(face);
    canvas.drawPath(body, Paint()..color = fill(t, look));
    canvas
      ..save()
      ..clipPath(body);
    // Pixel bevel: light along the top and left, shade along the bottom
    // and right.
    final light = Paint()
      ..color = t.highlight.withValues(alpha: look.enabled ? 0.55 : 0.2);
    final dark = Paint()..color = GuestButtonFace.shade(fill(t, look), 0.22);
    canvas
      ..drawRect(Rect.fromLTWH(face.left, face.top, face.width, step), light)
      ..drawRect(Rect.fromLTWH(face.left, face.top, step, face.height), light)
      ..drawRect(
        Rect.fromLTWH(face.left, face.bottom - step, face.width, step),
        dark,
      )
      ..drawRect(
        Rect.fromLTWH(face.right - step, face.top, step, face.height),
        dark,
      );
    canvas.restore();
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = look.selected ? 5 : 3.5
        ..strokeJoin = StrokeJoin.miter
        ..color = look.enabled ? t.ink : t.panelEdge,
    );
    if (look.focused) {
      canvas.drawPath(
        _pixelBox(face.inflate(6)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = t.ink,
      );
    }
  }
}

/// Black tie: crisp rectangle, double gilt rule, spaced capitals (Midnight
/// Gala).
final class GalaFace extends GuestButtonFace {
  const GalaFace();

  @override
  String transformLabel(String label) => label.toUpperCase();

  @override
  TextStyle labelStyle(GuestTokens t, double size) =>
      super.labelStyle(t, size * 0.8).copyWith(letterSpacing: size * 0.14);

  @override
  void paint(
    Canvas canvas,
    Rect rect,
    GuestTokens t,
    GuestButtonLook look,
    double press,
  ) {
    final body = RRect.fromRectAndRadius(
      rect.translate(0, travel(press)),
      const Radius.circular(6),
    );
    if (look.enabled) {
      _softShadow(
        canvas,
        body,
        t.ink.withValues(alpha: lerpDouble(0.18, 0.08, press)!),
        lerpDouble(22, 6, press)!,
        lerpDouble(8, 2, press)!,
      );
    }
    final base = fill(t, look);
    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GuestButtonFace.tint(base, 0.14),
            base,
            GuestButtonFace.tint(base, 0.08),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(body.outerRect),
    );
    final rule = Paint()
      ..style = PaintingStyle.stroke
      ..color = edge(t, look);
    canvas
      ..drawRRect(
        body.deflate(0.75),
        rule..strokeWidth = look.selected ? 2.5 : 1.5,
      )
      ..drawRRect(
        body.deflate(5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = ink(t, look).withValues(alpha: 0.35),
      );
    if (look.focused) paintFocus(canvas, body, t);
  }
}

/// A glowing neon tube around a glassy pill (Disco Nights).
final class NeonPartyFace extends GuestButtonFace {
  const NeonPartyFace();

  @override
  void paint(
    Canvas canvas,
    Rect rect,
    GuestTokens t,
    GuestButtonLook look,
    double press,
  ) {
    final body = _stadium(rect.translate(0, travel(press)).deflate(3));
    final tube = look.enabled ? t.accent : t.panelEdge;
    if (look.enabled) {
      // The glow brightens as the button is pressed, as if switched on.
      canvas.drawRRect(
        body.inflate(2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..color = tube.withValues(alpha: lerpDouble(0.45, 0.8, press)!)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            lerpDouble(9, 13, press)!,
          ),
      );
    }
    final base = fill(t, look);
    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GuestButtonFace.tint(base, 0.1),
            GuestButtonFace.shade(base, 0.08),
          ],
        ).createShader(body.outerRect),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = look.selected ? 4 : 3
        ..color = look.primary ? t.accentEdge : tube,
    );
    // The bright core of the tube.
    canvas.drawRRect(
      body.deflate(1.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = t.highlight.withValues(alpha: look.enabled ? 0.7 : 0.25),
    );
    if (look.focused) paintFocus(canvas, body.inflate(4), t);
  }
}
