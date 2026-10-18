/// Pixel assertions shared by host tests, the device integration test and
/// the dev-only render spike screen. Pure Dart over straight-alpha RGBA.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'fixture_images.dart';

/// The pixel at ([x], [y]) should be [expected], within [tolerance] per
/// channel. Sample points sit well inside uniform regions, so a correct
/// renderer matches almost exactly.
final class PixelCheck {
  const PixelCheck(
    this.name,
    this.x,
    this.y,
    this.expected, {
    this.tolerance = 3,
  });

  final String name;
  final int x;
  final int y;
  final Rgb expected;
  final int tolerance;
}

final class PixelCheckResult {
  const PixelCheckResult(this.check, this.actual, this.maxDelta);

  final PixelCheck check;
  final Rgb actual;
  final int maxDelta;

  bool get passed => maxDelta <= check.tolerance;

  @override
  String toString() =>
      '${passed ? 'PASS' : 'FAIL'} ${check.name} @(${check.x},${check.y}): '
      'expected ${check.expected}, got $actual (max delta $maxDelta)';
}

Rgb pixelAt(Uint8List rgba, int width, int x, int y) {
  final i = (y * width + x) * 4;
  return Rgb(rgba[i], rgba[i + 1], rgba[i + 2]);
}

int _delta(Rgb a, Rgb b) =>
    math.max((a.r - b.r).abs(), math.max((a.g - b.g).abs(), (a.b - b.b).abs()));

List<PixelCheckResult> evaluateChecks(
  List<PixelCheck> checks,
  Uint8List rgba,
  int width,
) => [
  for (final check in checks)
    () {
      final actual = pixelAt(rgba, width, check.x, check.y);
      return PixelCheckResult(check, actual, _delta(actual, check.expected));
    }(),
];

/// How far a whole image strays from one expected colour (FIX-04 halos).
final class UniformityResult {
  const UniformityResult({
    required this.maxDelta,
    required this.pixelsOverTolerance,
    required this.tolerance,
  });

  final int maxDelta;
  final int pixelsOverTolerance;
  final int tolerance;

  bool get passed => pixelsOverTolerance == 0;

  @override
  String toString() =>
      '${passed ? 'PASS' : 'FAIL'} max delta $maxDelta, '
      '$pixelsOverTolerance pixels over $tolerance';
}

UniformityResult uniformity(Uint8List rgba, Rgb expected, {int tolerance = 2}) {
  var maxDelta = 0;
  var over = 0;
  for (var i = 0; i < rgba.length; i += 4) {
    final delta = math.max(
      (rgba[i] - expected.r).abs(),
      math.max(
        (rgba[i + 1] - expected.g).abs(),
        (rgba[i + 2] - expected.b).abs(),
      ),
    );
    if (delta > maxDelta) maxDelta = delta;
    if (delta > tolerance) over++;
  }
  return UniformityResult(
    maxDelta: maxDelta,
    pixelsOverTolerance: over,
    tolerance: tolerance,
  );
}

/// Whole-image difference between two same-sized RGBA buffers, over the RGB
/// channels of every pixel.
final class ImageDiff {
  const ImageDiff({
    required this.maxDelta,
    required this.meanAbsDelta,
    required this.pixelsOverThreshold,
    required this.pixelCount,
    required this.threshold,
  });

  final int maxDelta;
  final double meanAbsDelta;
  final int pixelsOverThreshold;
  final int pixelCount;
  final int threshold;

  double get fractionOverThreshold => pixelsOverThreshold / pixelCount;

  @override
  String toString() =>
      'max delta $maxDelta, mean ${meanAbsDelta.toStringAsFixed(4)}, '
      '${(fractionOverThreshold * 100).toStringAsFixed(3)}% of pixels over '
      '$threshold';
}

/// With [mask] (one byte per pixel), only pixels whose mask byte is
/// non-zero are compared and counted.
ImageDiff compareRgba(
  Uint8List a,
  Uint8List b, {
  int threshold = 8,
  Uint8List? mask,
}) {
  if (a.length != b.length) {
    throw ArgumentError('images differ in size: ${a.length} vs ${b.length}');
  }
  if (mask != null && mask.length * 4 != a.length) {
    throw ArgumentError('the mask does not match the images');
  }
  var maxDelta = 0;
  var sum = 0;
  var over = 0;
  var pixels = 0;
  for (var i = 0; i < a.length; i += 4) {
    if (mask != null && mask[i >> 2] == 0) continue;
    pixels++;
    var pixelMax = 0;
    for (var c = 0; c < 3; c++) {
      final d = (a[i + c] - b[i + c]).abs();
      sum += d;
      if (d > pixelMax) pixelMax = d;
    }
    if (pixelMax > maxDelta) maxDelta = pixelMax;
    if (pixelMax > threshold) over++;
  }
  if (pixels == 0) throw ArgumentError('no pixels to compare');
  return ImageDiff(
    maxDelta: maxDelta,
    meanAbsDelta: sum / (pixels * 3),
    pixelsOverThreshold: over,
    pixelCount: pixels,
    threshold: threshold,
  );
}

/// Cross-platform golden tolerance (ADR-0007), provisional until measured
/// on certified iPad and Android hardware. Geometry is checked separately by
/// [PixelCheck]s, which must pass exactly as on the host.
abstract final class GoldenTolerance {
  /// Per-channel difference that counts a pixel as "different".
  static const threshold = 8;

  /// At most this fraction of pixels may differ (anti-aliased edges and
  /// filtered resampling).
  static const maxFractionOver = 0.005;

  /// Mean absolute per-channel difference across the image.
  static const maxMeanAbsDelta = 1.0;

  static bool accepts(ImageDiff diff) =>
      diff.threshold == threshold &&
      diff.fractionOverThreshold <= maxFractionOver &&
      diff.meanAbsDelta <= maxMeanAbsDelta;
}

/// Preview-to-export parity (AC-0407, ADR-0010): a preview against its
/// export box-filtered down to the preview's size, outside text. Previews
/// decode images smaller and resample them once, so hard edges inside
/// photos and decorations differ by up to a pixel's blend; text is
/// rasterised by the font engine at the preview's size, so it is compared
/// by geometry ([TextParity]) rather than by pixels.
abstract final class PreviewTolerance {
  static const threshold = 16;
  static const maxFractionOver = 0.005;
  static const maxMeanAbsDelta = 1.0;

  static bool accepts(ImageDiff diff) =>
      diff.threshold == threshold &&
      diff.fractionOverThreshold <= maxFractionOver &&
      diff.meanAbsDelta <= maxMeanAbsDelta;
}

/// Text in a preview against the same text in the export at the preview's
/// size: the same number of lines, with the ink's bounds within this many
/// preview pixels on every side.
abstract final class TextParity {
  static const maxEdgeShift = 1;
}

/// Averages [factor] x [factor] blocks: a box-filtered downscale.
Uint8List downscale(Uint8List rgba, int width, int height, int factor) {
  final outWidth = width ~/ factor;
  final outHeight = height ~/ factor;
  final out = Uint8List(outWidth * outHeight * 4);
  for (var y = 0; y < outHeight; y++) {
    for (var x = 0; x < outWidth; x++) {
      for (var c = 0; c < 4; c++) {
        var sum = 0;
        for (var dy = 0; dy < factor; dy++) {
          for (var dx = 0; dx < factor; dx++) {
            sum += rgba[((y * factor + dy) * width + x * factor + dx) * 4 + c];
          }
        }
        out[(y * outWidth + x) * 4 + c] = (sum / (factor * factor)).round();
      }
    }
  }
  return out;
}

/// The bounds of "ink" (pixels darker than [threshold] in any channel)
/// inside [left, top, right, bottom), and the number of separate bands of
/// inked rows (text lines).
({int left, int top, int right, int bottom, int bands})? inkIn(
  Uint8List rgba,
  int width, {
  required int left,
  required int top,
  required int right,
  required int bottom,
  int threshold = 160,
}) {
  int? minX, minY, maxX, maxY;
  var bands = 0;
  var previousRowInked = false;
  for (var y = top; y < bottom; y++) {
    var rowInked = false;
    for (var x = left; x < right; x++) {
      final i = (y * width + x) * 4;
      if (rgba[i] < threshold ||
          rgba[i + 1] < threshold ||
          rgba[i + 2] < threshold) {
        rowInked = true;
        minX = minX == null || x < minX ? x : minX;
        maxX = maxX == null || x > maxX ? x : maxX;
        minY ??= y;
        maxY = y;
      }
    }
    if (rowInked && !previousRowInked) bands++;
    previousRowInked = rowInked;
  }
  if (minX == null) return null;
  return (
    left: minX,
    top: minY!,
    right: maxX! + 1,
    bottom: maxY! + 1,
    bands: bands,
  );
}
