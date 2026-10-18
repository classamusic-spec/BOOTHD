import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Semantic colour roles of one theme profile (UX-01, UX-02).
///
/// Features and shared widgets use these roles only, never raw colour
/// values (AC-0201). Every text and boundary pairing is checked against the
/// CR-001 thresholds by `test/design_system/contrast_test.dart` (AC-0207).
@immutable
final class PorcelainColors {
  const PorcelainColors({
    required this.brightness,
    required this.canvas,
    required this.rail,
    required this.surface,
    required this.raised,
    required this.raisedShade,
    required this.inset,
    required this.selected,
    required this.scrim,
    required this.ink,
    required this.inkMuted,
    required this.inkDisabled,
    required this.accentText,
    required this.guestAccentText,
    required this.accentIcon,
    required this.ornament,
    required this.onPrimary,
    required this.primaryTop,
    required this.primaryBottom,
    required this.primaryEdge,
    required this.disabledFill,
    required this.outline,
    required this.hairline,
    required this.divider,
    required this.focusRing,
    required this.success,
    required this.successSurface,
    required this.warning,
    required this.warningSurface,
    required this.danger,
    required this.dangerSurface,
    required this.shadowKey,
    required this.shadowAmbient,
    required this.highlight,
    required this.insetShadow,
  });

  final Brightness brightness;

  /// Page background behind everything.
  final Color canvas;

  /// Navigation rail and sidebar background.
  final Color rail;

  /// Cards, sheets and dialogs.
  final Color surface;

  /// Top and bottom of the porcelain glaze on raised controls.
  final Color raised;
  final Color raisedShade;

  /// Wells: text fields, switch tracks, segmented-control tracks.
  final Color inset;

  /// Fill of a selected item; always paired with a >=3:1 indicator.
  final Color selected;

  /// Behind modal sheets and dialogs (translucent).
  final Color scrim;

  /// Primary text: >=7:1 on every surface, so it also serves guest text.
  final Color ink;

  /// Secondary text: >=4.5:1 on every surface.
  final Color inkMuted;

  /// Labels of disabled controls: >=3:1 although WCAG exempts them.
  final Color inkDisabled;

  /// Gold text (links, eyebrows): >=4.5:1 on every surface.
  final Color accentText;

  /// Gold text on guest screens: >=7:1 on the canvas.
  final Color guestAccentText;

  /// Meaningful gold icons and indicators: >=3:1 on every surface.
  final Color accentIcon;

  /// Decorative line art only; carries no information.
  final Color ornament;

  /// Text and icons on the champagne-gold primary fill: >=7:1.
  final Color onPrimary;

  /// Champagne-gold gradient of primary actions, and its gilded edge
  /// (>=3:1 against the canvas, so the control boundary is visible).
  final Color primaryTop;
  final Color primaryBottom;
  final Color primaryEdge;

  /// Fill of disabled controls.
  final Color disabledFill;

  /// Boundaries of controls that need one to be identified: >=3:1.
  final Color outline;

  /// Decorative card edges.
  final Color hairline;

  /// Separators between rows and sections.
  final Color divider;

  /// Keyboard focus ring: >=3:1 against the canvas and every surface.
  final Color focusRing;

  /// Status tones: each tone colour is readable text on its surface and on
  /// every regular surface (>=4.5:1). Status is never shown by colour alone.
  final Color success;
  final Color successSurface;
  final Color warning;
  final Color warningSurface;
  final Color danger;
  final Color dangerSurface;

  /// Elevation model: a directional key shadow, a soft ambient shadow, a
  /// rim highlight on top edges and the shadow inside pressed and inset
  /// shapes (all translucent).
  final Color shadowKey;
  final Color shadowAmbient;
  final Color highlight;
  final Color insetShadow;

  bool get isDark => brightness == Brightness.dark;

  /// Every surface text may sit on, by name, for contrast checks.
  Map<String, Color> get textSurfaces => {
    'canvas': canvas,
    'rail': rail,
    'surface': surface,
    'raised': raised,
    'raisedShade': raisedShade,
    'inset': inset,
    'selected': selected,
  };

  static PorcelainColors lerp(PorcelainColors a, PorcelainColors b, double t) {
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    return PorcelainColors(
      brightness: t < 0.5 ? a.brightness : b.brightness,
      canvas: c(a.canvas, b.canvas),
      rail: c(a.rail, b.rail),
      surface: c(a.surface, b.surface),
      raised: c(a.raised, b.raised),
      raisedShade: c(a.raisedShade, b.raisedShade),
      inset: c(a.inset, b.inset),
      selected: c(a.selected, b.selected),
      scrim: c(a.scrim, b.scrim),
      ink: c(a.ink, b.ink),
      inkMuted: c(a.inkMuted, b.inkMuted),
      inkDisabled: c(a.inkDisabled, b.inkDisabled),
      accentText: c(a.accentText, b.accentText),
      guestAccentText: c(a.guestAccentText, b.guestAccentText),
      accentIcon: c(a.accentIcon, b.accentIcon),
      ornament: c(a.ornament, b.ornament),
      onPrimary: c(a.onPrimary, b.onPrimary),
      primaryTop: c(a.primaryTop, b.primaryTop),
      primaryBottom: c(a.primaryBottom, b.primaryBottom),
      primaryEdge: c(a.primaryEdge, b.primaryEdge),
      disabledFill: c(a.disabledFill, b.disabledFill),
      outline: c(a.outline, b.outline),
      hairline: c(a.hairline, b.hairline),
      divider: c(a.divider, b.divider),
      focusRing: c(a.focusRing, b.focusRing),
      success: c(a.success, b.success),
      successSurface: c(a.successSurface, b.successSurface),
      warning: c(a.warning, b.warning),
      warningSurface: c(a.warningSurface, b.warningSurface),
      danger: c(a.danger, b.danger),
      dangerSurface: c(a.dangerSurface, b.dangerSurface),
      shadowKey: c(a.shadowKey, b.shadowKey),
      shadowAmbient: c(a.shadowAmbient, b.shadowAmbient),
      highlight: c(a.highlight, b.highlight),
      insetShadow: c(a.insetShadow, b.insetShadow),
    );
  }
}
