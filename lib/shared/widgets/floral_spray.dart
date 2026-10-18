import 'package:flutter/material.dart';

import '../../core/design_system/floral_art.dart';

/// Which painted arrangement a [FloralSpray] shows.
enum FloralSprayKind {
  /// Blossoms spilling from a corner (top-left, unless mirrored).
  corner,

  /// A vine running down, for an edge.
  garland,

  /// A small horizontal sprig.
  sprig,
}

/// Cream blossoms and sage leaves painted in code (the same painter as the
/// template decorations): soft, crisp at any size, and decoration only, so
/// screen readers skip it. Dark themes get the night palette.
class FloralSpray extends StatelessWidget {
  const FloralSpray({
    super.key,
    required this.kind,
    required this.width,
    required this.height,
    this.seed,
    this.mirrorX = false,
    this.mirrorY = false,
  });

  final FloralSprayKind kind;
  final double width;
  final double height;

  /// Varies the arrangement; each kind has a pleasing default.
  final int? seed;
  final bool mirrorX;
  final bool mirrorY;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? FloralPalette.nocturne
        : FloralPalette.garden;
    final arrangement = switch (kind) {
      FloralSprayKind.corner => FloralArrangement.cornerSpray(seed: seed ?? 1),
      FloralSprayKind.garland => FloralArrangement.garland(seed: seed ?? 7),
      FloralSprayKind.sprig => FloralArrangement.sprig(seed: seed ?? 3),
    };
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(width, height),
          painter: _FloralPainter(arrangement, palette, mirrorX, mirrorY),
        ),
      ),
    );
  }
}

class _FloralPainter extends CustomPainter {
  _FloralPainter(this.arrangement, this.palette, this.mirrorX, this.mirrorY);

  final FloralArrangement arrangement;
  final FloralPalette palette;
  final bool mirrorX;
  final bool mirrorY;

  @override
  void paint(Canvas canvas, Size size) => paintFloralArrangement(
    canvas,
    arrangement,
    palette,
    Offset.zero & size,
    mirrorX: mirrorX,
    mirrorY: mirrorY,
  );

  @override
  bool shouldRepaint(_FloralPainter old) =>
      old.palette != palette ||
      old.mirrorX != mirrorX ||
      old.mirrorY != mirrorY;
}
