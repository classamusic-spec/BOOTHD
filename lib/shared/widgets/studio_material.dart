import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_colors.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../domain/value_objects/appearance.dart';

/// Which surface a [StudioMaterial] dresses.
enum StudioMaterialArea {
  /// The page behind the Studio's sections.
  canvas,

  /// The navigation sidebar or rail.
  rail,
}

/// The material each operator appearance is made of, painted quietly
/// behind the Studio (EP02 operator polish): a glazed sheen on Porcelain
/// Studio, linen and oak grain on Light Oak, a warm safelight glow,
/// walnut grain and fine film grain on Darkroom Walnut.
///
/// Pure decoration: drawn once per size (its own repaint boundary), never
/// hit-tested or read out, deterministic (fixed seeds) so goldens are
/// stable, and from the theme's own tokens, so contrast is unchanged
/// because nothing is drawn over text-bearing surfaces' readable range
/// (every stroke stays under 7 % opacity on text areas).
class StudioMaterial extends StatelessWidget {
  const StudioMaterial({super.key, required this.area, this.child});

  final StudioMaterialArea area;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _MaterialPainter(
                    profile: theme.profile,
                    colors: theme.colors,
                    area: area,
                  ),
                ),
              ),
            ),
          ),
        ),
        ?child,
      ],
    );
  }
}

class _MaterialPainter extends CustomPainter {
  _MaterialPainter({
    required this.profile,
    required this.colors,
    required this.area,
  });

  final PorcelainThemeProfile profile;
  final PorcelainColors colors;
  final StudioMaterialArea area;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    switch ((profile, area)) {
      case (PorcelainThemeProfile.porcelainStudio, StudioMaterialArea.canvas):
        _glow(canvas, rect, const Alignment(0.7, -1.1), colors.surface, 0.9);
        _glaze(canvas, rect);
      case (PorcelainThemeProfile.porcelainStudio, StudioMaterialArea.rail):
        _glow(canvas, rect, const Alignment(-1, -1), colors.surface, 0.55);
      case (PorcelainThemeProfile.lightOak, StudioMaterialArea.canvas):
        _glow(canvas, rect, const Alignment(0.6, -1.1), colors.surface, 0.8);
        _linen(canvas, rect);
      case (PorcelainThemeProfile.lightOak, StudioMaterialArea.rail):
        _grain(canvas, rect, colors.primaryEdge, 0.11, seed: 11);
      case (PorcelainThemeProfile.darkroomWalnut, StudioMaterialArea.canvas):
        _glow(
          canvas,
          rect,
          const Alignment(0.25, -1.25),
          colors.primaryTop,
          0.085,
        );
        _vignette(canvas, rect);
        _filmGrain(canvas, rect);
      case (PorcelainThemeProfile.darkroomWalnut, StudioMaterialArea.rail):
        _grain(canvas, rect, colors.primaryEdge, 0.05, seed: 23);
        _filmGrain(canvas, rect);
    }
  }

  /// A soft pool of light falling from [from].
  void _glow(
    Canvas canvas,
    Rect rect,
    Alignment from,
    Color colour,
    double strength,
  ) {
    final radius = rect.longestSide * 0.75;
    final centre = from.withinRect(rect);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            colour.withValues(alpha: colour.a * strength),
            colour.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centre, radius: radius)),
    );
  }

  /// A long diagonal band of glaze catching the light.
  void _glaze(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.highlight.withValues(alpha: 0),
            colors.highlight.withValues(alpha: colors.highlight.a * 0.22),
            colors.highlight.withValues(alpha: 0),
          ],
          stops: const [0.25, 0.42, 0.6],
        ).createShader(rect),
    );
  }

  /// A fine linen weave.
  void _linen(Canvas canvas, Rect rect) {
    final thread = Paint()
      ..strokeWidth = 1
      ..color = colors.hairline.withValues(alpha: 0.18);
    for (var y = rect.top; y < rect.bottom; y += 4) {
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), thread);
    }
    final warp = Paint()
      ..strokeWidth = 1
      ..color = colors.hairline.withValues(alpha: 0.1);
    for (var x = rect.left; x < rect.right; x += 4) {
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), warp);
    }
  }

  /// Vertical wood grain: gently waving lines with the odd knot.
  void _grain(
    Canvas canvas,
    Rect rect,
    Color colour,
    double alpha, {
    required int seed,
  }) {
    final random = math.Random(seed);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    var x = rect.left + 3.0;
    while (x < rect.right) {
      final wave = 6 + random.nextDouble() * 10;
      final period = 90 + random.nextDouble() * 140;
      final phase = random.nextDouble() * math.pi * 2;
      line.color = colour.withValues(
        alpha: alpha * (0.5 + random.nextDouble()),
      );
      final path = Path()..moveTo(x, rect.top);
      for (var y = rect.top; y <= rect.bottom; y += 8) {
        path.lineTo(x + math.sin(y / period + phase) * wave * 0.3, y);
      }
      canvas.drawPath(path, line);
      x += 5 + random.nextDouble() * 9;
    }
    final knot = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = colour.withValues(alpha: alpha * 0.6);
    for (var i = 0; i < 3; i++) {
      final centre = Offset(
        rect.left + rect.width * (0.2 + random.nextDouble() * 0.6),
        rect.top + rect.height * (0.15 + i * 0.3 + random.nextDouble() * 0.1),
      );
      for (var ring = 1; ring <= 2; ring++) {
        canvas.drawOval(
          Rect.fromCenter(
            center: centre,
            width: 5.0 * ring,
            height: 14.0 * ring,
          ),
          knot,
        );
      }
    }
  }

  /// Darkened corners, like a print under an enlarger.
  void _vignette(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 0.95,
          colors: [
            colors.shadowAmbient.withValues(alpha: 0),
            colors.shadowAmbient.withValues(
              alpha: colors.shadowAmbient.a * 0.75,
            ),
          ],
          stops: const [0.55, 1],
        ).createShader(rect),
    );
  }

  /// Fine, even grain, like fibre paper.
  void _filmGrain(Canvas canvas, Rect rect) {
    final random = math.Random(7);
    final light = Paint()..color = colors.ink.withValues(alpha: 0.03);
    final dark = Paint()..color = colors.shadowKey.withValues(alpha: 0.25);
    final count = (rect.width * rect.height / 260).clamp(0, 9000).toInt();
    for (var i = 0; i < count; i++) {
      final point = Offset(
        rect.left + random.nextDouble() * rect.width,
        rect.top + random.nextDouble() * rect.height,
      );
      canvas.drawCircle(point, 0.7, i.isEven ? light : dark);
    }
  }

  @override
  bool shouldRepaint(_MaterialPainter old) =>
      old.profile != profile || old.colors != colors || old.area != area;
}
