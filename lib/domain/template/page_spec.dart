/// Unit of a physical page dimension.
enum LengthUnit { inch, millimetre }

/// A physical page with an explicit unit and print resolution (A-06).
///
/// Output pixel sizes derive from these, so a 4x6 inch page at 300 DPI is
/// always 1200x1800 pixels.
final class PageSpec {
  const PageSpec({
    required this.width,
    required this.height,
    required this.unit,
    required this.dpi,
  });

  /// 4x6 inch portrait at 300 DPI (1200x1800 px), the M01 spike page.
  static const fourBySixPortrait = PageSpec(
    width: 4,
    height: 6,
    unit: LengthUnit.inch,
    dpi: 300,
  );

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

  bool get isValid => width > 0 && height > 0 && dpi > 0;
}
