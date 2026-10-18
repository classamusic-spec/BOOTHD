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

ImageDiff compareRgba(Uint8List a, Uint8List b, {int threshold = 8}) {
  if (a.length != b.length) {
    throw ArgumentError('images differ in size: ${a.length} vs ${b.length}');
  }
  var maxDelta = 0;
  var sum = 0;
  var over = 0;
  for (var i = 0; i < a.length; i += 4) {
    var pixelMax = 0;
    for (var c = 0; c < 3; c++) {
      final d = (a[i + c] - b[i + c]).abs();
      sum += d;
      if (d > pixelMax) pixelMax = d;
    }
    if (pixelMax > maxDelta) maxDelta = pixelMax;
    if (pixelMax > threshold) over++;
  }
  final pixels = a.length ~/ 4;
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
