/// Geometry value types shared by the template document, the scene graph and
/// every renderer (ADR-0003). Pure Dart.
library;

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

  final double x;
  final double y;
  final double width;
  final double height;

  bool get hasPositiveSize => width > 0 && height > 0;

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

  @override
  bool operator ==(Object other) =>
      other is PixelSize && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => '${width}x$height';
}
