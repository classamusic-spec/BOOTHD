import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'porcelain_colors.dart';

/// Bundled font families (licences: `docs/ASSET_PROVENANCE.md`).
abstract final class PorcelainFonts {
  /// UI text: Inter, with tabular figures for counts and coordinates.
  static const sans = 'Inter';

  /// Display and headings only, never below 26 logical px: Cormorant
  /// Garamond.
  static const serif = 'Cormorant Garamond';
}

/// The written type scale (CR-001 item 5). Sizes are logical pixels for
/// tablets read at arm's length; guest styles are sized for reading from a
/// step or two away.
@immutable
final class PorcelainTypography {
  const PorcelainTypography({
    required this.displayLarge,
    required this.displayMedium,
    required this.displaySmall,
    required this.headlineLarge,
    required this.headlineMedium,
    required this.headlineSmall,
    required this.titleLarge,
    required this.titleMedium,
    required this.titleSmall,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.labelLarge,
    required this.labelMedium,
    required this.labelSmall,
    required this.eyebrow,
    required this.numeric,
    required this.guestDisplay,
    required this.guestTitle,
    required this.guestBody,
    required this.guestLabel,
    required this.guestAction,
    required this.guestCaption,
    required this.countdown,
  });

  factory PorcelainTypography.forColors(PorcelainColors colors) {
    TextStyle serif(double size, double lineHeight, double tracking) =>
        TextStyle(
          fontFamily: PorcelainFonts.serif,
          fontSize: size,
          height: lineHeight / size,
          fontWeight: FontWeight.w600,
          letterSpacing: tracking,
          color: colors.ink,
          leadingDistribution: TextLeadingDistribution.even,
          fontFeatures: const [FontFeature.liningFigures()],
        );
    TextStyle sans(
      double size,
      double lineHeight, {
      FontWeight weight = FontWeight.w400,
      double tracking = 0,
      Color? color,
    }) => TextStyle(
      fontFamily: PorcelainFonts.sans,
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      letterSpacing: tracking,
      color: color ?? colors.ink,
      leadingDistribution: TextLeadingDistribution.even,
    );

    return PorcelainTypography(
      displayLarge: serif(64, 70, -0.5),
      displayMedium: serif(52, 58, -0.4),
      displaySmall: serif(44, 50, -0.3),
      headlineLarge: serif(38, 44, -0.2),
      headlineMedium: serif(32, 38, -0.1),
      headlineSmall: serif(27, 33, 0),
      titleLarge: sans(21, 28, weight: FontWeight.w600, tracking: -0.2),
      titleMedium: sans(18, 24, weight: FontWeight.w600, tracking: -0.1),
      titleSmall: sans(16, 22, weight: FontWeight.w600),
      bodyLarge: sans(17, 26, tracking: -0.1),
      bodyMedium: sans(15, 22),
      bodySmall: sans(14, 20, color: colors.inkMuted),
      labelLarge: sans(16, 20, weight: FontWeight.w600, tracking: 0.1),
      labelMedium: sans(14, 18, weight: FontWeight.w500, tracking: 0.1),
      labelSmall: sans(12, 16, weight: FontWeight.w500, tracking: 0.2),
      eyebrow: sans(
        12,
        16,
        weight: FontWeight.w600,
        tracking: 1.8,
        color: colors.accentText,
      ),
      numeric: sans(
        15,
        20,
        weight: FontWeight.w500,
      ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      guestDisplay: serif(88, 92, -0.8),
      guestTitle: serif(56, 62, -0.4),
      guestBody: sans(24, 34, tracking: -0.2),
      guestLabel: sans(20, 26, weight: FontWeight.w600, tracking: 0.1),
      guestAction: sans(32, 36, weight: FontWeight.w600, tracking: 0.4),
      guestCaption: sans(17, 24, color: colors.inkMuted),
      countdown: serif(320, 320, -4),
    );
  }

  final TextStyle displayLarge;
  final TextStyle displayMedium;
  final TextStyle displaySmall;
  final TextStyle headlineLarge;
  final TextStyle headlineMedium;
  final TextStyle headlineSmall;
  final TextStyle titleLarge;
  final TextStyle titleMedium;
  final TextStyle titleSmall;
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;

  /// Captions; muted by default.
  final TextStyle bodySmall;
  final TextStyle labelLarge;
  final TextStyle labelMedium;
  final TextStyle labelSmall;

  /// Small spaced capitals above headings, in gold.
  final TextStyle eyebrow;

  /// Counts, sizes and coordinates: tabular figures so columns align.
  final TextStyle numeric;

  /// Guest screens (S20–S27). All in primary ink except the caption.
  final TextStyle guestDisplay;
  final TextStyle guestTitle;
  final TextStyle guestBody;
  final TextStyle guestLabel;
  final TextStyle guestAction;
  final TextStyle guestCaption;

  /// The 3-2-1 numeral (S23, M07).
  final TextStyle countdown;

  static PorcelainTypography lerp(
    PorcelainTypography a,
    PorcelainTypography b,
    double t,
  ) {
    TextStyle s(TextStyle x, TextStyle y) => TextStyle.lerp(x, y, t)!;
    return PorcelainTypography(
      displayLarge: s(a.displayLarge, b.displayLarge),
      displayMedium: s(a.displayMedium, b.displayMedium),
      displaySmall: s(a.displaySmall, b.displaySmall),
      headlineLarge: s(a.headlineLarge, b.headlineLarge),
      headlineMedium: s(a.headlineMedium, b.headlineMedium),
      headlineSmall: s(a.headlineSmall, b.headlineSmall),
      titleLarge: s(a.titleLarge, b.titleLarge),
      titleMedium: s(a.titleMedium, b.titleMedium),
      titleSmall: s(a.titleSmall, b.titleSmall),
      bodyLarge: s(a.bodyLarge, b.bodyLarge),
      bodyMedium: s(a.bodyMedium, b.bodyMedium),
      bodySmall: s(a.bodySmall, b.bodySmall),
      labelLarge: s(a.labelLarge, b.labelLarge),
      labelMedium: s(a.labelMedium, b.labelMedium),
      labelSmall: s(a.labelSmall, b.labelSmall),
      eyebrow: s(a.eyebrow, b.eyebrow),
      numeric: s(a.numeric, b.numeric),
      guestDisplay: s(a.guestDisplay, b.guestDisplay),
      guestTitle: s(a.guestTitle, b.guestTitle),
      guestBody: s(a.guestBody, b.guestBody),
      guestLabel: s(a.guestLabel, b.guestLabel),
      guestAction: s(a.guestAction, b.guestAction),
      guestCaption: s(a.guestCaption, b.guestCaption),
      countdown: s(a.countdown, b.countdown),
    );
  }
}
