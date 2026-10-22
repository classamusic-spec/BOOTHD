import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/design_system/floral_art.dart';
import '../../core/design_system/party_art.dart';
import '../../core/experience/guest_experience.dart';

/// A pack's decorations on a guest screen (EP06): drawn in code from the
/// pack's own colours, kept to the corners and edges so they never sit
/// behind the words or the camera picture, never hit-tested or read out.
/// Unknown ids draw nothing, so a missing decoration never breaks a
/// screen (AC-EP13).
class GuestDecorationLayer extends StatelessWidget {
  const GuestDecorationLayer({super.key, this.dense = false});

  /// Smaller, for busy screens (the camera, texting).
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final tokens = GuestExperience.tokensOf(context);
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: _DecorationPainter(
              ids: tokens.experience.decorations,
              tokens: tokens,
              dense: dense,
            ),
          ),
        ),
      ),
    );
  }
}

/// Every decoration id this app can draw.
const guestDecorationIds = {
  'floral-spray',
  'brass-corners',
  'film-perforations',
  'disco-glints',
  'garden-blooms',
  'garden-bees',
  'deco-fans',
  'party-balloons',
  'party-confetti',
  'party-stars',
  'pixel-hearts',
  'pixel-coins',
  'console-dpad',
  'arcade-marquee',
};

class _DecorationPainter extends CustomPainter {
  _DecorationPainter({
    required this.ids,
    required this.tokens,
    required this.dense,
  });

  final List<String> ids;
  final GuestTokens tokens;
  final bool dense;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final unit = size.shortestSide * (dense ? 0.16 : 0.24);
    // Corners in turn: top left, bottom right, top right, bottom left.
    final corners = [
      Rect.fromLTWH(-unit * 0.1, -unit * 0.1, unit, unit),
      Rect.fromLTWH(
        size.width - unit * 0.9,
        size.height - unit * 0.9,
        unit,
        unit,
      ),
      Rect.fromLTWH(size.width - unit * 0.9, -unit * 0.1, unit, unit),
      Rect.fromLTWH(-unit * 0.1, size.height - unit * 0.9, unit, unit),
    ];
    final used = <int>{};
    for (final id in ids.take(4)) {
      final corner = (_lower.contains(id) ? _lowerFirst : _upperFirst)
          .firstWhere((c) => !used.contains(c), orElse: () => -1);
      if (corner < 0) break;
      if (_paint(canvas, id, corners[corner], size, corner)) used.add(corner);
    }
  }

  /// Emblems that sit beside a wide title if put at the top: they go to
  /// the bottom corners first.
  static const _lower = {
    'console-dpad',
    'arcade-marquee',
    'pixel-hearts',
    'pixel-coins',
  };
  static const _upperFirst = [0, 1, 2, 3];
  static const _lowerFirst = [3, 1, 0, 2];

  bool _paint(Canvas canvas, String id, Rect area, Size size, int corner) {
    final t = tokens;
    switch (id) {
      case 'floral-spray' || 'garden-blooms':
        paintFloralArrangement(
          canvas,
          FloralArrangement.cornerSpray(seed: 1 + corner * 3),
          FloralPalette.garden,
          area,
        );
      case 'brass-corners':
        _brassCorner(canvas, area, corner, t.decorationA);
      case 'film-perforations':
        _filmBand(canvas, area, size, corner, t.decorationA, t.backdrop);
      case 'disco-glints':
        _glints(canvas, area, t.highlight, t.accent);
      case 'garden-bees':
        _bee(
          canvas,
          area.center,
          area.width * 0.16,
          t.decorationA,
          t.ink,
          t.highlight,
        );
      case 'deco-fans':
        _fan(canvas, area, corner, t.decorationA);
      case 'party-balloons':
        paintPartyBalloons(canvas, area);
      case 'party-confetti':
        paintPartyConfetti(canvas, area);
      case 'party-stars':
        paintPartyStars(canvas, area);
      case 'pixel-hearts':
        paintPixelHearts(
          canvas,
          Rect.fromLTWH(
            area.left + area.width * 0.1,
            area.top + area.height * 0.35,
            area.width * 0.8,
            area.width * 0.8 / 3,
          ),
        );
      case 'pixel-coins':
        paintPixelCoins(canvas, area);
      case 'console-dpad':
        _dpad(canvas, area, t.decorationA, t.decorationB);
      case 'arcade-marquee':
        paintArcadeMarquee(
          canvas,
          Rect.fromLTWH(
            area.left + area.width * 0.1,
            area.top + area.height * 0.3,
            area.width * 0.8,
            area.width * 0.24,
          ),
        );
      default:
        return false;
    }
    return true;
  }

  static void _brassCorner(Canvas canvas, Rect area, int corner, Color colour) {
    final flipX = corner == 1 || corner == 2;
    final flipY = corner == 1 || corner == 3;
    canvas.save();
    canvas.translate(
      flipX ? area.right : area.left,
      flipY ? area.bottom : area.top,
    );
    canvas.scale(flipX ? -1 : 1, flipY ? -1 : 1);
    final w = area.width;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.02
      ..color = colour;
    for (final inset in [0.22, 0.3]) {
      canvas.drawPath(
        Path()
          ..moveTo(w * inset, w * 0.85)
          ..lineTo(w * inset, w * inset)
          ..lineTo(w * 0.85, w * inset),
        paint,
      );
    }
    final d = w * 0.05;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.22, w * 0.22 - d)
        ..lineTo(w * 0.22 + d, w * 0.22)
        ..lineTo(w * 0.22, w * 0.22 + d)
        ..lineTo(w * 0.22 - d, w * 0.22)
        ..close(),
      Paint()..color = colour,
    );
    canvas.restore();
  }

  static void _filmBand(
    Canvas canvas,
    Rect area,
    Size size,
    int corner,
    Color band,
    Color hole,
  ) {
    final width = area.width * 0.3;
    final left = corner == 1 || corner == 2 ? size.width - width : 0.0;
    final rect = Rect.fromLTWH(left, 0, width, size.height);
    canvas.drawRect(rect, Paint()..color = band.withValues(alpha: 0.85));
    final holeW = width * 0.42;
    final holeH = width * 0.3;
    for (var y = holeH; y < size.height; y += holeH * 2.2) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(rect.center.dx, y),
            width: holeW,
            height: holeH,
          ),
          Radius.circular(holeH * 0.25),
        ),
        Paint()..color = hole,
      );
    }
  }

  static void _glints(Canvas canvas, Rect area, Color light, Color accent) {
    final random = math.Random(5);
    for (var i = 0; i < 6; i++) {
      final c = Offset(
        area.left + random.nextDouble() * area.width,
        area.top + random.nextDouble() * area.height,
      );
      final r = area.width * (0.04 + random.nextDouble() * 0.06);
      final path = Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r);
      canvas.drawPath(path, Paint()..color = i.isEven ? light : accent);
    }
  }

  static void _bee(
    Canvas canvas,
    Offset c,
    double r,
    Color body,
    Color ink,
    Color light,
  ) {
    final wing = Paint()..color = light.withValues(alpha: 0.6);
    canvas
      ..drawOval(
        Rect.fromCenter(
          center: c.translate(-r * 0.3, -r * 0.8),
          width: r * 0.9,
          height: r * 1.1,
        ),
        wing,
      )
      ..drawOval(
        Rect.fromCenter(
          center: c.translate(r * 0.3, -r * 0.8),
          width: r * 0.9,
          height: r * 1.1,
        ),
        wing,
      )
      ..drawOval(
        Rect.fromCenter(center: c, width: r * 2, height: r * 1.4),
        Paint()..color = body,
      );
    final stripe = Paint()..color = ink;
    for (final dx in [-0.3, 0.2]) {
      canvas.drawRect(
        Rect.fromCenter(
          center: c.translate(r * dx, 0),
          width: r * 0.22,
          height: r * 1.3,
        ),
        stripe,
      );
    }
  }

  static void _fan(Canvas canvas, Rect area, int corner, Color colour) {
    final origin = switch (corner) {
      0 => area.topLeft,
      1 => area.bottomRight,
      2 => area.topRight,
      _ => area.bottomLeft,
    };
    final start = switch (corner) {
      0 => 0.0,
      1 => math.pi,
      2 => math.pi / 2,
      _ => -math.pi / 2,
    };
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = area.width * 0.012
      ..color = colour;
    for (var ring = 1; ring <= 4; ring++) {
      final r = area.width * 0.2 * ring;
      canvas.drawArc(
        Rect.fromCircle(center: origin, radius: r),
        start,
        math.pi / 2,
        false,
        paint,
      );
    }
    for (var ray = 0; ray <= 6; ray++) {
      final a = start + math.pi / 2 * ray / 6;
      canvas.drawLine(
        origin + Offset(math.cos(a), math.sin(a)) * area.width * 0.2,
        origin + Offset(math.cos(a), math.sin(a)) * area.width * 0.8,
        paint,
      );
    }
  }

  static void _dpad(Canvas canvas, Rect area, Color pad, Color buttons) {
    final c = area.center;
    final arm = area.width * 0.11;
    final paint = Paint()..color = pad;
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: c.translate(-area.width * 0.15, 0),
            width: arm * 3,
            height: arm,
          ),
          Radius.circular(arm * 0.2),
        ),
        paint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: c.translate(-area.width * 0.15, 0),
            width: arm,
            height: arm * 3,
          ),
          Radius.circular(arm * 0.2),
        ),
        paint,
      );
    final dot = Paint()..color = buttons;
    canvas
      ..drawCircle(c.translate(area.width * 0.2, -arm * 0.6), arm * 0.55, dot)
      ..drawCircle(c.translate(area.width * 0.32, arm * 0.4), arm * 0.55, dot);
  }

  @override
  bool shouldRepaint(_DecorationPainter old) =>
      old.ids != ids || old.tokens != tokens || old.dense != dense;
}
