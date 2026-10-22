import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/experience/guest_experience.dart';
import '../../domain/experience/experience_catalog.dart';
import '../../domain/session/countdown_state.dart';

/// The guest countdown (EP03): a numeral in one of nine original frames,
/// chosen by the pack (or the operator).
///
/// Presenters only draw [state]; the session controller owns the timing
/// on monotonic timers, so nothing drawn here can move a capture. Every
/// preset has a still form, used whenever motion is reduced or the pack's
/// animation is off: the same numeral and progress without movement.
/// Movement stays gentle: at most one soft pulse a second and no flashing
/// (WCAG 2.3.1; `test/experience/countdown_test.dart` measures it).
/// Sound is separate, so every preset also works silently.
class GuestCountdown extends StatelessWidget {
  const GuestCountdown({
    super.key,
    required this.state,
    this.size = 260,
    this.presetId,
  });

  final CountdownState state;
  final double size;

  /// Overrides the experience's countdown (previews).
  final String? presetId;

  @override
  Widget build(BuildContext context) {
    final experience = GuestExperience.experienceOf(context);
    final tokens = GuestExperience.tokensOf(context);
    final preset = CountdownPreset.of(presetId ?? experience.countdownPresetId);
    final still = GuestExperience.motionOf(context) == AnimationIntensity.off;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: TweenAnimationBuilder<double>(
          // Restarts every second: the beat runs from 0 to 1 just after
          // the numeral changes, then rests.
          key: ValueKey((state.shot, state.remaining)),
          tween: Tween(begin: still ? 1 : 0, end: 1),
          duration: still ? Duration.zero : const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          builder: (context, beat, _) => _Frame(
            preset: preset,
            tokens: tokens,
            state: state,
            beat: beat,
            still: still,
            size: size,
          ),
        ),
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({
    required this.preset,
    required this.tokens,
    required this.state,
    required this.beat,
    required this.still,
    required this.size,
  });

  final CountdownPreset preset;
  final GuestTokens tokens;
  final CountdownState state;
  final double beat;
  final bool still;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scale = still ? 1.0 : preset.numeralScale(beat);
    final opacity = still ? 1.0 : preset.numeralOpacity(beat);
    return CustomPaint(
      painter: _CountdownPainter(
        preset: preset,
        tokens: tokens,
        state: state,
        beat: beat,
        still: still,
      ),
      child: Center(
        child: Transform.translate(
          offset: Offset(0, preset.numeralOffset * size),
          child: Opacity(
            opacity: opacity.clamp(0, 1),
            child: Transform.scale(
              scale: scale,
              child: Text(
                '${state.remaining}',
                textAlign: TextAlign.center,
                style: preset.numeral(tokens, size),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountdownPainter extends CustomPainter {
  _CountdownPainter({
    required this.preset,
    required this.tokens,
    required this.state,
    required this.beat,
    required this.still,
  });

  final CountdownPreset preset;
  final GuestTokens tokens;
  final CountdownState state;
  final double beat;
  final bool still;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    preset.paintFrame(canvas, size, tokens, state, beat, still);
  }

  @override
  bool shouldRepaint(_CountdownPainter old) =>
      old.preset != preset ||
      old.tokens != tokens ||
      old.state != state ||
      old.beat != beat ||
      old.still != still;
}

/// One countdown look. Frames draw from the pack's tokens only.
abstract base class CountdownPreset {
  const CountdownPreset();

  static const _presets = <String, CountdownPreset>{
    'porcelain-press': PorcelainPressCountdown(),
    'vintage-flip': VintageFlipCountdown(),
    'film-leader': FilmLeaderCountdown(),
    'disco-pulse': DiscoPulseCountdown(),
    'storybook-magic': StorybookMagicCountdown(),
    'party-pop': PartyPopCountdown(),
    'arcade-start': ArcadeStartCountdown(),
    'handheld-boot': HandheldBootCountdown(),
    'gala-elegant': GalaElegantCountdown(),
  };

  /// Every preset id this app draws (matches `ExperienceCatalog`).
  static Iterable<String> get ids => _presets.keys;

  /// The preset [id]; Porcelain Press for anything unknown.
  static CountdownPreset of(String id) =>
      _presets[id] ?? const PorcelainPressCountdown();

  /// The numeral's style at frame [size].
  TextStyle numeral(GuestTokens t, double size) =>
      t.display(size * 0.42).copyWith(height: 1);

  /// Vertical nudge of the numeral, as a fraction of the size.
  double get numeralOffset => 0;

  double numeralScale(double beat) => 1;

  double numeralOpacity(double beat) => 1;

  /// How far the countdown has run, moving smoothly within a second
  /// unless [still].
  static double sweep(CountdownState state, double beat, bool still) {
    final within = still ? 0.0 : beat;
    return ((state.total - state.remaining + within) / state.total).clamp(0, 1);
  }

  void paintFrame(
    Canvas canvas,
    Size size,
    GuestTokens t,
    CountdownState state,
    double beat,
    bool still,
  );
}

Offset _centre(Size size) => size.center(Offset.zero);
double _radius(Size size) => size.shortestSide / 2;

void _arc(
  Canvas canvas,
  Offset c,
  double r,
  double from,
  double sweep,
  Paint p,
) {
  canvas.drawArc(Rect.fromCircle(center: c, radius: r), from, sweep, false, p);
}

/// A pearl medallion whose gold ring fills as the seconds pass; the
/// numeral settles in with a small press (Porcelain Classic).
final class PorcelainPressCountdown extends CountdownPreset {
  const PorcelainPressCountdown();

  @override
  double numeralScale(double beat) => 1.08 - 0.08 * beat;

  @override
  void paintFrame(
    Canvas canvas,
    Size size,
    GuestTokens t,
    CountdownState state,
    double beat,
    bool still,
  ) {
    final c = _centre(size);
    final r = _radius(size) * 0.92;
    canvas.drawCircle(
      c.translate(0, r * 0.05),
      r,
      Paint()
        ..color = t.ink.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [t.highlight, t.panel],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    final ring = r * 0.9;
    _arc(
      canvas,
      c,
      ring,
      0,
      math.pi * 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.06
        ..color = t.panelEdge,
    );
    _arc(
      canvas,
      c,
      ring,
      -math.pi / 2,
      math.pi * 2 * CountdownPreset.sweep(state, beat, still),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = r * 0.06
        ..color = t.accent,
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = t.accentEdge,
    );
  }
}

/// A split-flap card: the upper flap falls each second (Vintage Light
/// Wood).
final class VintageFlipCountdown extends CountdownPreset {
  const VintageFlipCountdown();

  @override
  void paintFrame(
    Canvas canvas,
    Size size,
    GuestTokens t,
    CountdownState state,
    double beat,
    bool still,
  ) {
    final card = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: _centre(size),
        width: size.width * 0.72,
        height: size.height * 0.86,
      ),
      Radius.circular(size.width * 0.06),
    );
    canvas.drawRRect(
      card.shift(const Offset(0, 6)),
      Paint()
        ..color = t.ink.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(card, Paint()..color = t.panel);
    canvas.drawRRect(
      card,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = t.accentEdge,
    );
    // The falling flap: a soft shade sweeping down the upper half.
    if (!still && beat < 1) {
      final top = card.top + card.height / 2 * beat;
      canvas.drawRect(
        Rect.fromLTRB(
          card.left + 3,
          top,
          card.right - 3,
          card.top + card.height / 2,
        ),
        Paint()..color = t.ink.withValues(alpha: 0.08 * (1 - beat)),
      );
    }
    final hinge = card.top + card.height / 2;
    canvas.drawLine(
      Offset(card.left, hinge),
      Offset(card.right, hinge),
      Paint()
        ..strokeWidth = 3
        ..color = t.backdrop,
    );
    for (final x in [card.left + 4, card.right - 4]) {
      canvas.drawCircle(Offset(x, hinge), 5, Paint()..color = t.decorationA);
    }
  }
}

/// A film-leader dial: rings, cross hairs and a hand sweeping round once a
/// second (Retro Film).
final class FilmLeaderCountdown extends CountdownPreset {
  const FilmLeaderCountdown();

  @override
  void paintFrame(
    Canvas canvas,
    Size size,
    GuestTokens t,
    CountdownState state,
    double beat,
    bool still,
  ) {
    final c = _centre(size);
    final r = _radius(size) * 0.95;
    canvas.drawCircle(c, r, Paint()..color = t.panel);
    final sweep = (still ? 1.0 : beat) * math.pi * 2;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      sweep,
      true,
      Paint()..color = t.ink.withValues(alpha: 0.12),
    );
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = t.ink.withValues(alpha: 0.55);
    canvas
      ..drawCircle(c, r * 0.95, line)
      ..drawCircle(c, r * 0.78, line)
      ..drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), line)
      ..drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), line);
    if (!still) {
      final hand = Offset(
        c.dx + math.cos(sweep - math.pi / 2) * r * 0.95,
        c.dy + math.sin(sweep - math.pi / 2) * r * 0.95,
      );
      canvas.drawLine(
        c,
        hand,
        Paint()
          ..strokeWidth = 3
          ..color = t.accentEdge,
      );
    }
  }
}

/// A neon ring whose glow swells gently once a second (Disco Nights).
final class DiscoPulseCountdown extends CountdownPreset {
  const DiscoPulseCountdown();

  @override
  double numeralScale(double beat) => 1.04 - 0.04 * beat;

  @override
  void paintFrame(
    Canvas canvas,
    Size size,
    GuestTokens t,
    CountdownState state,
    double beat,
    bool still,
  ) {
    final c = _centre(size);
    final r = _radius(size) * 0.82;
    canvas.drawCircle(c, r, Paint()..color = t.panel.withValues(alpha: 0.92));
    // The glow eases from 0.55 to 0.35 strength: a swell, never a flash.
    final glow = still ? 0.45 : 0.55 - 0.2 * beat;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.12
        ..color = t.accent.withValues(alpha: glow)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.08),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.035
        ..color = t.accent,
    );
    _arc(
      canvas,
      c,
      r * 0.86,
      -math.pi / 2,
      math.pi * 2 * CountdownPreset.sweep(state, beat, still),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = r * 0.025
        ..color = t.highlight.withValues(alpha: 0.8),
    );
  }
}

/// A ring of small stars that light one by one and turn slowly
/// (Storybook Garden).
final class StorybookMagicCountdown extends CountdownPreset {
  const StorybookMagicCountdown();

  @override
  double numeralOpacity(double beat) => 0.4 + 0.6 * beat;

  @override
  void paintFrame(
    Canvas canvas,
    Size size,
    GuestTokens t,
    CountdownState state,
    double beat,
    bool still,
  ) {
    final c = _centre(size);
    final r = _radius(size);
    canvas.drawCircle(c, r * 0.7, Paint()..color = t.panel);
    canvas.drawCircle(
      c,
      r * 0.7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = t.panelEdge,
    );
    const count = 12;
    final lit = (CountdownPreset.sweep(state, beat, still) * count).round();
    final turn = still
        ? 0.0
        : CountdownPreset.sweep(state, beat, still) * math.pi / 3;
    for (var i = 0; i < count; i++) {
      final a = i / count * math.pi * 2 - math.pi / 2 + turn;
      final p = Offset(
        c.dx + math.cos(a) * r * 0.86,
        c.dy + math.sin(a) * r * 0.86,
      );
      _star(canvas, p, r * 0.07, i < lit ? t.decorationA : t.panelEdge);
    }
  }

  static void _star(Canvas canvas, Offset c, double r, Color colour) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = i * math.pi / 5 - math.pi / 2;
      final d = i.isEven ? r : r * 0.45;
      final p = Offset(c.dx + math.cos(a) * d, c.dy + math.sin(a) * d);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path..close(), Paint()..color = colour);
  }
}

/// A round party bubble with confetti drifting out each second (Kid Party
/// Arcade).
final class PartyPopCountdown extends CountdownPreset {
  const PartyPopCountdown();

  @override
  double numeralScale(double beat) =>
      1.18 - 0.18 * Curves.easeOutBack.transform(beat);

  @override
  void paintFrame(
    Canvas canvas,
    Size size,
    GuestTokens t,
    CountdownState state,
    double beat,
    bool still,
  ) {
    final c = _centre(size);
    final r = _radius(size) * 0.72;
    canvas.drawCircle(
      c.translate(0, r * 0.08),
      r,
      Paint()..color = t.accentEdge,
    );
    canvas.drawCircle(c, r, Paint()..color = t.accent);
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(-r * 0.35, -r * 0.5),
        width: r * 0.6,
        height: r * 0.26,
      ),
      Paint()..color = t.highlight.withValues(alpha: 0.45),
    );
    if (!still) {
      final spread = r * (1.05 + 0.3 * beat);
      final fade = 1 - beat;
      for (var i = 0; i < 10; i++) {
        final a = i / 10 * math.pi * 2 + state.remaining;
        final p = Offset(
          c.dx + math.cos(a) * spread,
          c.dy + math.sin(a) * spread,
        );
        canvas.drawCircle(
          p,
          r * 0.05,
          Paint()
            ..color = (i.isEven ? t.decorationA : t.decorationB).withValues(
              alpha: fade,
            ),
        );
      }
    }
  }

  @override
  TextStyle numeral(GuestTokens t, double size) =>
      super.numeral(t, size).copyWith(color: t.onAccent);
}

/// A pixel box over a row of segment blocks that fill each second (Retro
/// Game Quest, Arcade Cabinet). Original shapes; no game is imitated.
final class ArcadeStartCountdown extends CountdownPreset {
  const ArcadeStartCountdown();

  @override
  double get numeralOffset => -0.12;

  @override
  void paintFrame(
    Canvas canvas,
    Size size,
    GuestTokens t,
    CountdownState state,
    double beat,
    bool still,
  ) {
    final s = size.shortestSide;
    final box = Rect.fromCenter(
      center: _centre(size).translate(0, -s * 0.06),
      width: s * 0.8,
      height: s * 0.62,
    );
    canvas.drawRect(
      box.translate(s * 0.03, s * 0.03),
      Paint()..color = t.ink.withValues(alpha: 0.6),
    );
    canvas.drawRect(box, Paint()..color = t.panel);
    canvas.drawRect(
      box,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.03
        ..color = t.ink,
    );
    final segments = state.total;
    final filled = state.total - state.remaining;
    final gap = s * 0.02;
    final width = (box.width - gap * (segments - 1)) / segments;
    for (var i = 0; i < segments; i++) {
      final cell = Rect.fromLTWH(
        box.left + i * (width + gap),
        box.bottom + s * 0.06,
        width,
        s * 0.08,
      );
      final on = i < filled || (!still && i == filled && beat > 0.5);
      canvas.drawRect(cell, Paint()..color = on ? t.accent : t.panelEdge);
      canvas.drawRect(
        cell,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = t.ink,
      );
    }
  }
}

/// A small screen with a loading bar, like a device starting up (Retro
/// Game Quest, Handheld Retro). Generic rounded shapes only.
final class HandheldBootCountdown extends CountdownPreset {
  const HandheldBootCountdown();

  @override
  double get numeralOffset => -0.08;

  @override
  void paintFrame(
    Canvas canvas,
    Size size,
    GuestTokens t,
    CountdownState state,
    double beat,
    bool still,
  ) {
    final s = size.shortestSide;
    final bezel = RRect.fromRectAndRadius(
      Rect.fromCenter(center: _centre(size), width: s * 0.9, height: s * 0.78),
      Radius.circular(s * 0.06),
    );
    canvas.drawRRect(bezel, Paint()..color = t.accentEdge);
    final screen = bezel.deflate(s * 0.06);
    canvas.drawRRect(screen, Paint()..color = t.panel);
    // Faint scan lines.
    final line = Paint()..color = t.ink.withValues(alpha: 0.05);
    for (var y = screen.top; y < screen.bottom; y += 4) {
      canvas.drawRect(Rect.fromLTWH(screen.left, y, screen.width, 1), line);
    }
    final bar = Rect.fromLTWH(
      screen.left + s * 0.06,
      screen.bottom - s * 0.14,
      screen.width - s * 0.12,
      s * 0.06,
    );
    canvas.drawRect(
      bar,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = t.ink,
    );
    const ticks = 10;
    final lit = (CountdownPreset.sweep(state, beat, still) * ticks).floor();
    final w = (bar.width - 4) / ticks;
    for (var i = 0; i < lit; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          bar.left + 2 + i * w + 1,
          bar.top + 3,
          w - 2,
          bar.height - 6,
        ),
        Paint()..color = t.accent,
      );
    }
  }
}

/// A gilt hairline circle drawn as the seconds pass, a diamond at its tip
/// (Midnight Gala).
final class GalaElegantCountdown extends CountdownPreset {
  const GalaElegantCountdown();

  @override
  double numeralOpacity(double beat) => 0.35 + 0.65 * beat;

  @override
  TextStyle numeral(GuestTokens t, double size) =>
      super.numeral(t, size).copyWith(fontWeight: FontWeight.w500);

  @override
  void paintFrame(
    Canvas canvas,
    Size size,
    GuestTokens t,
    CountdownState state,
    double beat,
    bool still,
  ) {
    final c = _centre(size);
    final r = _radius(size) * 0.88;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = t.panelEdge,
    );
    canvas.drawCircle(
      c,
      r * 0.94,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = t.accentEdge.withValues(alpha: 0.5),
    );
    final sweep = math.pi * 2 * CountdownPreset.sweep(state, beat, still);
    _arc(
      canvas,
      c,
      r,
      -math.pi / 2,
      sweep,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = t.accent,
    );
    final tip = Offset(
      c.dx + math.cos(sweep - math.pi / 2) * r,
      c.dy + math.sin(sweep - math.pi / 2) * r,
    );
    final d = r * 0.05;
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy - d)
        ..lineTo(tip.dx + d, tip.dy)
        ..lineTo(tip.dx, tip.dy + d)
        ..lineTo(tip.dx - d, tip.dy)
        ..close(),
      Paint()..color = t.accentEdge,
    );
  }
}
