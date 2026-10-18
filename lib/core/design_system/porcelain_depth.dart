import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'porcelain_colors.dart';

/// The elevation model (CR-001 item 6): one directional key shadow from a
/// light above the screen plus a tight ambient shadow. Shadows are
/// presentation aids only; every control also has a boundary or label that
/// meets contrast on its own (UX-01).
abstract final class PorcelainDepth {
  /// Flat, pressed or disabled.
  static const double flat = 0;

  /// Resting cards.
  static const double resting = 1;

  /// Raised controls.
  static const double raised = 1.6;

  /// Hovered or focused controls.
  static const double lifted = 2.2;

  /// Sheets, dialogs and toasts.
  static const double overlay = 3.5;

  /// Shadows for a continuous [elevation], so pressing and releasing can
  /// animate smoothly between levels.
  static List<BoxShadow> shadows(PorcelainColors colors, double elevation) {
    if (elevation <= 0) return const [];
    final e = math.min(elevation, 4.0);
    final strength = math.min(e, 1.0);
    return [
      BoxShadow(
        color: colors.shadowAmbient.withValues(
          alpha: colors.shadowAmbient.a * strength,
        ),
        offset: Offset(0, 0.5 + 0.5 * e),
        blurRadius: 1.5 + 1.5 * e,
      ),
      BoxShadow(
        color: colors.shadowKey.withValues(
          alpha: colors.shadowKey.a * strength,
        ),
        offset: Offset(0, 1 + 3.5 * e),
        blurRadius: 4 + 9 * e,
        spreadRadius: -1 - 1.5 * e,
      ),
    ];
  }
}
