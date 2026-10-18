/// Geometry value types shared by the template document, the scene graph and
/// every renderer (ADR-0003, ADR-0010). Pure Dart.
library;

import 'dart:math' as math;

/// A rectangle in page-normalised coordinates.
///
/// [x] and [width] are fractions of the page width; [y] and [height] are
/// fractions of the page height. Values outside 0..1 describe artwork that
/// overflows the page, which decorations may do (A-06).
final class NormalizedRect {
  const NormalizedRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// The whole page.
  static const page = NormalizedRect(x: 0, y: 0, width: 1, height: 1);

  final double x;
  final double y;
  final double width;
  final double height;

  bool get hasPositiveSize => width > 0 && height > 0;

  bool get isFinite =>
      x.isFinite && y.isFinite && width.isFinite && height.isFinite;

  /// Whether any part of the rectangle lies on the page (0..1 both ways).
  bool get overlapsPage => x < 1 && y < 1 && x + width > 0 && y + height > 0;

  /// The same rectangle in pixels of a page that is [pageWidthPx] by
  /// [pageHeightPx].
  PixelRect toPixels({required int pageWidthPx, required int pageHeightPx}) =>
      PixelRect(
        left: x * pageWidthPx,
        top: y * pageHeightPx,
        width: width * pageWidthPx,
        height: height * pageHeightPx,
      );

  @override
  bool operator ==(Object other) =>
      other is NormalizedRect &&
      other.x == x &&
      other.y == y &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(x, y, width, height);

  @override
  String toString() => 'NormalizedRect($x, $y, $width x $height)';
}

/// A point given as fractions of some box: (0, 0) is its top-left corner,
/// (1, 1) its bottom-right, (0.5, 0.5) its centre.
final class NormalizedPoint {
  const NormalizedPoint(this.x, this.y);

  static const center = NormalizedPoint(0.5, 0.5);

  final double x;
  final double y;

  bool get isFinite => x.isFinite && y.isFinite;

  @override
  bool operator ==(Object other) =>
      other is NormalizedPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'NormalizedPoint($x, $y)';
}

/// A point in pixels.
final class PixelPoint {
  const PixelPoint(this.x, this.y);

  final double x;
  final double y;

  /// This point turned [radians] clockwise (y grows downwards) about
  /// [pivot].
  PixelPoint rotatedAbout(PixelPoint pivot, double radians) {
    final cos = math.cos(radians);
    final sin = math.sin(radians);
    final dx = x - pivot.x;
    final dy = y - pivot.y;
    return PixelPoint(
      pivot.x + dx * cos - dy * sin,
      pivot.y + dx * sin + dy * cos,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PixelPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'PixelPoint($x, $y)';
}

/// An axis-aligned rectangle in pixels. Edges may fall between pixel centres.
final class PixelRect {
  const PixelRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;
  double get centerX => left + width / 2;
  double get centerY => top + height / 2;
  double get shortestSide => math.min(width, height);

  /// The point at [fraction] of this rectangle.
  PixelPoint pointAt(NormalizedPoint fraction) =>
      PixelPoint(left + fraction.x * width, top + fraction.y * height);

  /// The corners in clockwise order from the top-left.
  List<PixelPoint> get corners => [
    PixelPoint(left, top),
    PixelPoint(right, top),
    PixelPoint(right, bottom),
    PixelPoint(left, bottom),
  ];

  /// The bounding box of this rectangle turned [radians] clockwise about
  /// [pivot].
  PixelRect rotatedBounds(PixelPoint pivot, double radians) {
    if (radians == 0) return this;
    final points = [
      for (final corner in corners) corner.rotatedAbout(pivot, radians),
    ];
    final xs = points.map((p) => p.x);
    final ys = points.map((p) => p.y);
    final minX = xs.reduce(math.min);
    final minY = ys.reduce(math.min);
    return PixelRect(
      left: minX,
      top: minY,
      width: xs.reduce(math.max) - minX,
      height: ys.reduce(math.max) - minY,
    );
  }

  /// This rectangle scaled by [factor] about the origin.
  PixelRect scaled(double factor) => PixelRect(
    left: left * factor,
    top: top * factor,
    width: width * factor,
    height: height * factor,
  );

  @override
  bool operator ==(Object other) =>
      other is PixelRect &&
      other.left == left &&
      other.top == top &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(left, top, width, height);

  @override
  String toString() => 'PixelRect($left, $top, $width x $height)';
}

/// The size of an image in pixels.
final class PixelSize {
  const PixelSize(this.width, this.height);

  final int width;
  final int height;

  bool get isPositive => width > 0 && height > 0;

  @override
  bool operator ==(Object other) =>
      other is PixelSize && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => '${width}x$height';
}

/// The largest rectangle with [aspect] (width / height) that fits inside
/// [box], centred in it.
PixelRect containRect(PixelRect box, double aspect) {
  final boxAspect = box.width / box.height;
  final (width, height) = aspect > boxAspect
      ? (box.width, box.width / aspect)
      : (box.height * aspect, box.height);
  return PixelRect(
    left: box.left + (box.width - width) / 2,
    top: box.top + (box.height - height) / 2,
    width: width,
    height: height,
  );
}

/// The region of a [sourceWidth] x [sourceHeight] image that fills a
/// [targetWidth] x [targetHeight] box when scaled uniformly to cover it,
/// keeping the focal point (fractions of the source size) as central as the
/// image edges allow.
PixelRect coverCrop({
  required double sourceWidth,
  required double sourceHeight,
  required double targetWidth,
  required double targetHeight,
  NormalizedPoint focal = NormalizedPoint.center,
}) {
  final scale = math.max(
    targetWidth / sourceWidth,
    targetHeight / sourceHeight,
  );
  final cropWidth = math.min(sourceWidth, targetWidth / scale);
  final cropHeight = math.min(sourceHeight, targetHeight / scale);
  final left = (focal.x * sourceWidth - cropWidth / 2).clamp(
    0.0,
    sourceWidth - cropWidth,
  );
  final top = (focal.y * sourceHeight - cropHeight / 2).clamp(
    0.0,
    sourceHeight - cropHeight,
  );
  return PixelRect(left: left, top: top, width: cropWidth, height: cropHeight);
}
