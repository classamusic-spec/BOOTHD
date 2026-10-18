import 'dart:math' as math;
import 'dart:ui' show Color;

/// WCAG 2.2 relative luminance of an opaque [color] (alpha is ignored; use
/// [compositeOver] first for translucent colours).
double relativeLuminance(Color color) {
  double channel(double value) => value <= 0.04045
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// WCAG 2.2 contrast ratio between two opaque colours, from 1 to 21.
double contrastRatio(Color a, Color b) {
  final la = relativeLuminance(a);
  final lb = relativeLuminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Source-over composite of a translucent [foreground] on an opaque
/// [background], as the screen would show it.
Color compositeOver(Color foreground, Color background) {
  final alpha = foreground.a;
  double mix(double fg, double bg) => fg * alpha + bg * (1 - alpha);
  return Color.from(
    alpha: 1,
    red: mix(foreground.r, background.r),
    green: mix(foreground.g, background.g),
    blue: mix(foreground.b, background.b),
  );
}

/// Contrast thresholds of the premium quality bar (CR-001, AC-0207).
abstract final class ContrastTargets {
  /// Guest primary text and the countdown numeral (WCAG AAA).
  static const guestPrimaryText = 7.0;

  /// All other text (WCAG AA for normal-size text).
  static const text = 4.5;

  /// Focus rings, control boundaries and meaningful icons (WCAG 1.4.11).
  static const nonText = 3.0;

  /// Text on disabled controls. WCAG exempts inactive controls; Porcelain
  /// still keeps their labels readable.
  static const disabledText = 3.0;
}
