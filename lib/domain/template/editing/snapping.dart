/// Snapping while moving and resizing (AC-0505): to the page edges and
/// centre, to other layers' edges and centres, and to an optional grid.
library;

import '../geometry.dart';
import '../template_document.dart';
import '../template_layers.dart';
import 'editor_geometry.dart';

enum GuideAxis {
  /// A vertical line at an x position.
  vertical,

  /// A horizontal line at a y position.
  horizontal,
}

/// A line something snapped to, in page pixels, for the editor to show.
final class SnapGuide {
  const SnapGuide(this.axis, this.position);

  final GuideAxis axis;
  final double position;

  @override
  bool operator ==(Object other) =>
      other is SnapGuide && other.axis == axis && other.position == position;

  @override
  int get hashCode => Object.hash(axis, position);

  @override
  String toString() => 'SnapGuide(${axis.name} $position)';
}

/// Where things can snap to, in page pixels.
final class SnapTargets {
  const SnapTargets({required this.xs, required this.ys, this.grid});

  /// Targets for [document]: the page edges and centre, and the edges and
  /// centres of every visible framed layer not in [exclude]. With
  /// [gridSpacing] (page pixels), grid lines too.
  factory SnapTargets.of(
    TemplateDocument document, {
    Set<String> exclude = const {},
    double? gridSpacing,
  }) {
    final page = document.page;
    final xs = <double>{0, page.widthPx / 2, page.widthPx.toDouble()};
    final ys = <double>{0, page.heightPx / 2, page.heightPx.toDouble()};
    for (final layer in document.layers) {
      if (layer is! FramedLayer || !layer.visible) continue;
      if (exclude.contains(layer.id)) continue;
      final bounds = LayerGeometry.of(layer, page).bounds;
      xs.addAll([bounds.left, bounds.centerX, bounds.right]);
      ys.addAll([bounds.top, bounds.centerY, bounds.bottom]);
    }
    return SnapTargets(
      xs: xs.toList()..sort(),
      ys: ys.toList()..sort(),
      grid: gridSpacing,
    );
  }

  final List<double> xs;
  final List<double> ys;
  final double? grid;
}

final class SnapResult {
  const SnapResult({required this.dx, required this.dy, required this.guides});

  static const none = SnapResult(dx: 0, dy: 0, guides: []);

  /// How far to move the box to snap, in page pixels.
  final double dx;
  final double dy;
  final List<SnapGuide> guides;
}

/// Snaps a box being moved: its left, centre or right to the nearest x
/// target, and its top, centre or bottom to the nearest y target, each
/// only within [threshold] page pixels.
SnapResult snapBox(PixelRect box, SnapTargets targets, double threshold) {
  final (dx, gx) = _nearest(
    [box.left, box.centerX, box.right],
    targets.xs,
    targets.grid,
    threshold,
  );
  final (dy, gy) = _nearest(
    [box.top, box.centerY, box.bottom],
    targets.ys,
    targets.grid,
    threshold,
  );
  return SnapResult(
    dx: dx,
    dy: dy,
    guides: [
      if (gx != null) SnapGuide(GuideAxis.vertical, gx),
      if (gy != null) SnapGuide(GuideAxis.horizontal, gy),
    ],
  );
}

/// Snaps one moving edge (a resize): [x] or [y] to its nearest target.
(double, SnapGuide?) snapEdge(
  double value,
  GuideAxis axis,
  SnapTargets targets,
  double threshold,
) {
  final (delta, guide) = _nearest(
    [value],
    axis == GuideAxis.vertical ? targets.xs : targets.ys,
    targets.grid,
    threshold,
  );
  return (delta, guide == null ? null : SnapGuide(axis, guide));
}

/// The smallest move (and the line it reaches) that puts one of [values]
/// on a target or grid line, if any is within [threshold].
(double, double?) _nearest(
  List<double> values,
  List<double> targets,
  double? grid,
  double threshold,
) {
  double? best;
  double? line;
  void consider(double value, double target) {
    final delta = target - value;
    if (delta.abs() <= threshold &&
        (best == null || delta.abs() < best!.abs())) {
      best = delta;
      line = target;
    }
  }

  for (final value in values) {
    for (final target in targets) {
      consider(value, target);
    }
    if (grid != null && grid > 0) {
      consider(value, (value / grid).round() * grid);
    }
  }
  return (best ?? 0, line);
}
