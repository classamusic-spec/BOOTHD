import '../value_objects/orientation.dart';

/// Unit of a physical page dimension.
enum LengthUnit {
  inch('in'),
  millimetre('mm');

  const LengthUnit(this.code);

  /// The unit as written in template documents.
  final String code;

  static LengthUnit? fromCode(String code) {
    for (final unit in values) {
      if (unit.code == code) return unit;
    }
    return null;
  }
}

/// A physical page with an explicit unit and print resolution (A-06).
///
/// Output pixel sizes derive from these, so a 4x6 inch page at 300 DPI is
/// always 1200x1800 pixels (A-07 step 3).
final class PageSpec {
  const PageSpec({
    required this.width,
    required this.height,
    required this.unit,
    required this.dpi,
  });

  /// 2x6 inch photo strip at 300 DPI: 600x1800.
  static const twoBySix = PageSpec(
    width: 2,
    height: 6,
    unit: LengthUnit.inch,
    dpi: 300,
  );

  /// 4x6 inch portrait at 300 DPI: 1200x1800.
  static const fourBySixPortrait = PageSpec(
    width: 4,
    height: 6,
    unit: LengthUnit.inch,
    dpi: 300,
  );

  /// 6x4 inch landscape at 300 DPI: 1800x1200.
  static const fourBySixLandscape = PageSpec(
    width: 6,
    height: 4,
    unit: LengthUnit.inch,
    dpi: 300,
  );

  /// 4x4 inch square at 300 DPI: 1200x1200.
  static const fourByFour = PageSpec(
    width: 4,
    height: 4,
    unit: LengthUnit.inch,
    dpi: 300,
  );

  /// Print resolutions accepted in documents.
  static const minDpi = 72;
  static const maxDpi = 1200;

  /// Largest page side in pixels (the database's limit too).
  static const maxSidePx = 20000;

  /// Largest page area: bounds the memory of one full-size render.
  static const maxAreaPx = 40000000;

  final double width;
  final double height;
  final LengthUnit unit;
  final int dpi;

  double get _inchesPerUnit => switch (unit) {
    LengthUnit.inch => 1,
    LengthUnit.millimetre => 1 / 25.4,
  };

  int get widthPx => (width * _inchesPerUnit * dpi).round();
  int get heightPx => (height * _inchesPerUnit * dpi).round();

  /// Page pixels per typographic point (1/72 inch), for text and strokes
  /// sized in points.
  double get pixelsPerPoint => dpi / 72;

  PageOrientation get orientation =>
      PageOrientation.fromPixelSize(width: widthPx, height: heightPx);

  /// Problems with this page, empty when it can be rendered.
  List<String> get problems => [
    if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0)
      'width and height must be positive numbers',
    if (dpi < minDpi || dpi > maxDpi) 'dpi must be $minDpi to $maxDpi',
    if (width.isFinite &&
        height.isFinite &&
        width > 0 &&
        height > 0 &&
        dpi >= minDpi &&
        dpi <= maxDpi) ...[
      if (widthPx < 1 || heightPx < 1) 'the page is smaller than one pixel',
      if (widthPx > maxSidePx || heightPx > maxSidePx)
        'each side must be at most $maxSidePx pixels',
      if (widthPx * heightPx > maxAreaPx)
        'the page must be at most $maxAreaPx pixels in area',
    ],
  ];

  bool get isValid => problems.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is PageSpec &&
      other.width == width &&
      other.height == height &&
      other.unit == unit &&
      other.dpi == dpi;

  @override
  int get hashCode => Object.hash(width, height, unit, dpi);

  @override
  String toString() => 'PageSpec($width x $height ${unit.code} @ $dpi dpi)';
}

/// A named page size offered when creating a template (P-07).
final class PagePreset {
  const PagePreset(this.id, this.name, this.page);

  final String id;
  final String name;
  final PageSpec page;

  /// The print formats of release 1 (FLUTTER_PLATFORM_STRATEGY §7).
  static const all = [
    PagePreset('2x6', '2 × 6 strip', PageSpec.twoBySix),
    PagePreset('4x6', '4 × 6 portrait', PageSpec.fourBySixPortrait),
    PagePreset('6x4', '6 × 4 landscape', PageSpec.fourBySixLandscape),
    PagePreset('4x4', '4 × 4 square', PageSpec.fourByFour),
  ];
}
