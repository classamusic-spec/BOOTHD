/// Orientation concepts that must never be conflated (ADR-0004).
///
/// * [GuestOrientationPreference]: what the operator configured for a booth.
/// * [ViewportOrientation]: the shape of the window the OS actually granted.
/// * [PageOrientation]: the shape of a template's output page.
///
/// Camera sensor and EXIF orientation are a fourth concept, owned by the
/// camera boundary (ADR-0002). None of these types converts into another.
library;

/// The guest presentation an operator prefers for a booth.
///
/// A preference, not a guarantee: iPadOS 26+ and Android large screens may
/// ignore orientation requests, so guest layouts follow [ViewportOrientation].
enum GuestOrientationPreference { portrait, landscape }

/// The orientation of the window the app currently has.
enum ViewportOrientation {
  portrait,
  landscape;

  /// Derives the orientation from the window's logical size.
  ///
  /// A square or empty window counts as portrait, so this never fails during
  /// startup frames that report a zero size.
  static ViewportOrientation fromLogicalSize({
    required double width,
    required double height,
  }) => width > height ? landscape : portrait;
}

/// The orientation of a template's output page, independent of any screen.
enum PageOrientation {
  portrait,
  landscape,
  square;

  /// Derives the orientation from output pixel dimensions, e.g. 1200x1800
  /// (4x6 portrait at 300 DPI) or 1200x1200 (4x4).
  static PageOrientation fromPixelSize({
    required int width,
    required int height,
  }) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('Page size must be positive, got ${width}x$height.');
    }
    if (width == height) return square;
    return width > height ? landscape : portrait;
  }
}
