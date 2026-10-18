/// Editor geometry in page pixels (A-08: testable conversions between
/// document, viewport and output pixels; AC-0503, AC-0505).
///
/// A framed layer is an unrotated frame turned clockwise about a pivot
/// given as a fraction of the frame. Handles sit on the turned frame;
/// dragging one keeps the opposite corner or edge where it was on the
/// page.
library;

import 'dart:math' as math;

import '../geometry.dart';
import '../page_spec.dart';
import '../template_document.dart';
import '../template_layers.dart';

enum HandleKind {
  topLeft(-1, -1),
  top(0, -1),
  topRight(1, -1),
  right(1, 0),
  bottomRight(1, 1),
  bottom(0, 1),
  bottomLeft(-1, 1),
  left(-1, 0);

  const HandleKind(this.sx, this.sy);

  /// Which side the handle moves: -1 left or top, 1 right or bottom, 0 none.
  final int sx;
  final int sy;

  bool get isCorner => sx != 0 && sy != 0;
}

/// A framed layer's placement in page pixels.
final class LayerGeometry {
  const LayerGeometry({
    required this.rect,
    this.rotationDegrees = 0,
    this.pivotFraction = NormalizedPoint.center,
  });

  factory LayerGeometry.of(FramedLayer layer, PageSpec page) => LayerGeometry(
    rect: layer.frame.toPixels(
      pageWidthPx: page.widthPx,
      pageHeightPx: page.heightPx,
    ),
    rotationDegrees: layer.rotationDegrees,
    pivotFraction: layer.pivot,
  );

  /// The frame before rotation.
  final PixelRect rect;
  final double rotationDegrees;
  final NormalizedPoint pivotFraction;

  double get radians => rotationDegrees * math.pi / 180;
  PixelPoint get pivot => rect.pointAt(pivotFraction);

  PixelPoint toPage(PixelPoint local) => local.rotatedAbout(pivot, radians);
  PixelPoint toLocal(PixelPoint page) => page.rotatedAbout(pivot, -radians);

  bool contains(PixelPoint page, {double slop = 0}) {
    final p = toLocal(page);
    return p.x >= rect.left - slop &&
        p.x <= rect.right + slop &&
        p.y >= rect.top - slop &&
        p.y <= rect.bottom + slop;
  }

  /// The four corners on the page, clockwise from the top left.
  List<PixelPoint> get corners => [for (final c in rect.corners) toPage(c)];

  /// The axis-aligned box around the turned frame.
  PixelRect get bounds => rect.rotatedBounds(pivot, radians);

  PixelPoint handle(HandleKind kind) => toPage(
    PixelPoint(
      rect.centerX + kind.sx * rect.width / 2,
      rect.centerY + kind.sy * rect.height / 2,
    ),
  );

  /// The rotation handle, [distance] page pixels above the top edge.
  PixelPoint rotationHandle(double distance) =>
      toPage(PixelPoint(rect.centerX, rect.top - distance));

  NormalizedRect frameOn(PageSpec page) => NormalizedRect(
    x: rect.left / page.widthPx,
    y: rect.top / page.heightPx,
    width: rect.width / page.widthPx,
    height: rect.height / page.heightPx,
  );

  LayerGeometry withRect(PixelRect rect) => LayerGeometry(
    rect: rect,
    rotationDegrees: rotationDegrees,
    pivotFraction: pivotFraction,
  );

  /// This geometry with [handle] dragged to [pointer] (page pixels). The
  /// opposite corner or edge stays put on the page. With [keepAspect],
  /// corner handles keep the frame's proportions. Sizes never fall below
  /// [minSize].
  LayerGeometry resized(
    HandleKind handle,
    PixelPoint pointer, {
    bool keepAspect = false,
    double minSize = 4,
  }) {
    final local = toLocal(pointer);
    var left = rect.left;
    var top = rect.top;
    var right = rect.right;
    var bottom = rect.bottom;
    if (handle.sx < 0) left = math.min(local.x, right - minSize);
    if (handle.sx > 0) right = math.max(local.x, left + minSize);
    if (handle.sy < 0) top = math.min(local.y, bottom - minSize);
    if (handle.sy > 0) bottom = math.max(local.y, top + minSize);
    if (keepAspect && handle.isCorner && rect.width > 0 && rect.height > 0) {
      final scale = math.max(
        (right - left) / rect.width,
        (bottom - top) / rect.height,
      );
      final width = math.max(rect.width * scale, minSize);
      final height = math.max(rect.height * scale, minSize);
      if (handle.sx < 0) left = right - width;
      if (handle.sx > 0) right = left + width;
      if (handle.sy < 0) top = bottom - height;
      if (handle.sy > 0) bottom = top + height;
    }
    final resized = PixelRect(
      left: left,
      top: top,
      width: right - left,
      height: bottom - top,
    );
    return LayerGeometry(
      rect: _keepTurnedPlace(resized),
      rotationDegrees: rotationDegrees,
      pivotFraction: pivotFraction,
    );
  }

  /// [local], a frame in this geometry's turned coordinates, as the
  /// unrotated frame that draws in the same place once turned about its own
  /// pivot. Turning about pivot p maps q to R(q - p) + p; matching both
  /// pivots needs a shift of (I - R)(p0 - p1).
  PixelRect _keepTurnedPlace(PixelRect local) {
    if (radians == 0) return local;
    final p0 = pivot;
    final p1 = local.pointAt(pivotFraction);
    final cos = math.cos(radians);
    final sin = math.sin(radians);
    final dx = p0.x - p1.x;
    final dy = p0.y - p1.y;
    final shiftX = dx - (dx * cos - dy * sin);
    final shiftY = dy - (dx * sin + dy * cos);
    return PixelRect(
      left: local.left + shiftX,
      top: local.top + shiftY,
      width: local.width,
      height: local.height,
    );
  }

  /// The rotation after dragging the rotation handle from [start] to
  /// [pointer], snapped to multiples of [snapStep] degrees within
  /// [snapWithin] degrees, normalised to -180 (exclusive) to 180.
  double rotatedTo(
    PixelPoint start,
    PixelPoint pointer, {
    double snapStep = 15,
    double snapWithin = 4,
  }) {
    final p = pivot;
    final from = math.atan2(start.y - p.y, start.x - p.x);
    final to = math.atan2(pointer.y - p.y, pointer.x - p.x);
    var degrees = rotationDegrees + (to - from) * 180 / math.pi;
    if (snapStep > 0) {
      final nearest = (degrees / snapStep).round() * snapStep;
      if ((degrees - nearest).abs() <= snapWithin) degrees = nearest;
    }
    return normalizeDegrees(degrees);
  }
}

/// [degrees] in the range -180 (exclusive) to 180.
double normalizeDegrees(double degrees) {
  var d = degrees % 360;
  if (d > 180) d -= 360;
  if (d <= -180) d += 360;
  return d == -0.0 ? 0 : d;
}

/// The topmost visible framed layer under [point] (page pixels), or null.
/// Locked layers can be selected (to unlock them) when [includeLocked].
String? layerAt(
  TemplateDocument document,
  PixelPoint point, {
  bool includeLocked = true,
  double slop = 0,
}) {
  for (final layer in document.paintOrder.reversed) {
    if (layer is! FramedLayer || !layer.visible) continue;
    if (!includeLocked && layer.locked) continue;
    if (LayerGeometry.of(layer, document.page).contains(point, slop: slop)) {
      return layer.id;
    }
  }
  return null;
}
