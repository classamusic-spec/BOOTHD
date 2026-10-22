import 'package:flutter/material.dart';

import '../../domain/experience/experience_configuration.dart';
import '../../domain/experience/experience_registry.dart';
import '../design_system/porcelain_colors.dart';
import '../design_system/porcelain_theme.dart';
import '../design_system/porcelain_theme_data.dart';
import '../design_system/porcelain_typography.dart';
import '../design_system/theme_profiles.dart';
import 'guest_experience.dart';

/// The theme guest screens wear for an experience (EP06): every existing
/// guest screen reads Porcelain tokens, so a pack becomes a Porcelain
/// token set and the same screens follow it. No screen is duplicated.
///
/// Packs that are an original appearance (Porcelain Classic in ivory or
/// darkroom, Vintage Light Wood) use that appearance's audited palette, so
/// events from before packs look exactly as they did. Other packs map
/// their palette onto the roles, choosing each text colour so it stays at
/// the role's contrast (7:1 for guest gold on the canvas, 4.5:1 for text,
/// 3:1 for boundaries), falling back to the pack's ink where the pack's
/// own colour would not.
abstract final class GuestTheme {
  /// The original appearance [experience] still is, or null: Porcelain
  /// Classic (ivory or darkroom) and Vintage Light Wood, while the
  /// operator has not changed their colours.
  static PorcelainThemeProfile? originalAppearance(
    ResolvedExperience experience,
  ) {
    final plain = EventExperienceConfiguration(
      packId: experience.packId,
      packVersion: experience.packVersion,
      variantId: experience.variantId,
    );
    final profile = ExperienceRegistry.legacyAppearance(plain);
    if (profile == null) return null;
    final own = ExperienceRegistry.bundled.resolve(plain).palette;
    return own == experience.palette ? profile : null;
  }

  /// The theme guest screens wear for [experience].
  static ThemeData of(
    ResolvedExperience experience, {
    bool highContrast = false,
  }) {
    final original = originalAppearance(experience);
    if (original != null) {
      return porcelainThemeData(original, highContrast: highContrast);
    }
    final base = porcelainThemeData(
      PorcelainThemeProfile.porcelainStudio,
      highContrast: highContrast,
    );
    final tokens = GuestTokens.of(experience);
    final colors = colorsFor(tokens);
    return base.copyWith(
      scaffoldBackgroundColor: colors.canvas,
      extensions: [
        PorcelainTheme(
          profile: PorcelainThemeProfile.porcelainStudio,
          highContrast: highContrast,
          colors: colors,
          text: typographyFor(tokens, colors),
        ),
      ],
    );
  }

  static double _contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final (hi, lo) = la > lb ? (la, lb) : (lb, la);
    return (hi + 0.05) / (lo + 0.05);
  }

  /// [preferred] when it keeps [ratio] against every ground, else [safe].
  static Color _readable(
    Color preferred,
    Color safe,
    List<Color> grounds,
    double ratio,
  ) =>
      grounds.every((g) => _contrast(preferred, g) >= ratio) ? preferred : safe;

  static Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  static PorcelainColors colorsFor(GuestTokens t) {
    final dark = t.backdrop.computeLuminance() < 0.25;
    final model = dark
        ? PorcelainPalettes.darkroomWalnut
        : PorcelainPalettes.porcelainStudio;
    final surfaces = [t.backdrop, t.panel];
    final raised = dark
        ? _mix(t.panel, t.highlight, 0.12)
        : _mix(t.panel, t.highlight, 0.5);
    final grounds = [t.backdrop, t.backdropAccent, t.panel, raised];
    final ink = _readable(
      t.ink,
      dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
      grounds,
      7,
    );
    final inkMuted = _readable(t.inkMuted, ink, grounds, 4.5);
    final accentText = _readable(t.accent, ink, grounds, 4.5);
    final edge = _readable(t.accentEdge, ink, [t.backdrop], 3);
    return PorcelainColors(
      brightness: dark ? Brightness.dark : Brightness.light,
      canvas: t.backdrop,
      rail: t.backdropAccent,
      surface: t.panel,
      raised: raised,
      raisedShade: t.panel,
      inset: _mix(t.panel, t.ink, 0.06),
      selected: _mix(t.panel, t.accent, 0.22),
      scrim: model.scrim,
      ink: ink,
      inkMuted: inkMuted,
      inkDisabled: _readable(
        _mix(t.inkMuted, t.panel, 0.25),
        inkMuted,
        surfaces,
        3,
      ),
      accentText: accentText,
      guestAccentText: _readable(t.accent, ink, [
        t.backdrop,
        t.backdropAccent,
      ], 7),
      accentIcon: _readable(t.accent, ink, grounds, 3),
      ornament: t.decorationA,
      onPrimary: t.onAccent,
      primaryTop: _mix(t.accent, t.highlight, 0.18),
      primaryBottom: t.accent,
      primaryEdge: edge,
      disabledFill: _mix(t.panel, t.backdrop, 0.5),
      outline: _readable(t.panelEdge, inkMuted, surfaces, 3),
      hairline: t.panelEdge,
      divider: t.panelEdge,
      focusRing: ink,
      success: _readable(model.success, ink, grounds, 4.5),
      successSurface: model.successSurface,
      warning: _readable(model.warning, ink, grounds, 4.5),
      warningSurface: model.warningSurface,
      danger: _readable(model.danger, ink, grounds, 4.5),
      dangerSurface: model.dangerSurface,
      shadowKey: model.shadowKey,
      shadowAmbient: model.shadowAmbient,
      highlight: t.highlight.withValues(alpha: dark ? 0.2 : 0.8),
      insetShadow: model.insetShadow,
    );
  }

  /// Porcelain's type scale with the pack's faces on the guest styles.
  static PorcelainTypography typographyFor(
    GuestTokens t,
    PorcelainColors colors,
  ) {
    final base = PorcelainTypography.forColors(colors);
    TextStyle face(TextStyle style, String font) {
      final pack = GuestFonts.style(
        font,
        weight: style.fontWeight ?? FontWeight.w500,
      );
      return style.copyWith(
        fontFamily: pack.fontFamily,
        fontVariations: pack.fontVariations,
      );
    }

    final display = t.displayFont;
    final body = GuestFonts.displayOnly.contains(t.bodyFont)
        ? 'inter'
        : t.bodyFont;
    return PorcelainTypography(
      displayLarge: base.displayLarge,
      displayMedium: base.displayMedium,
      displaySmall: base.displaySmall,
      headlineLarge: base.headlineLarge,
      headlineMedium: base.headlineMedium,
      headlineSmall: base.headlineSmall,
      titleLarge: base.titleLarge,
      titleMedium: base.titleMedium,
      titleSmall: base.titleSmall,
      bodyLarge: base.bodyLarge,
      bodyMedium: base.bodyMedium,
      bodySmall: base.bodySmall,
      labelLarge: base.labelLarge,
      labelMedium: base.labelMedium,
      labelSmall: base.labelSmall,
      eyebrow: base.eyebrow,
      numeric: base.numeric,
      guestDisplay: face(base.guestDisplay, display),
      guestTitle: face(base.guestTitle, display),
      guestBody: face(base.guestBody, body),
      guestLabel: face(base.guestLabel, body),
      guestAction: face(base.guestAction, body),
      guestCaption: face(base.guestCaption, body),
      countdown: face(base.countdown, display),
    );
  }
}

/// Shows [child] as guests see [experience]: its tokens and its theme.
/// Used by Booth Mode and every operator preview of guest screens.
class GuestExperienceScope extends StatelessWidget {
  const GuestExperienceScope({
    super.key,
    required this.experience,
    required this.child,
  });

  final ResolvedExperience experience;
  final Widget child;

  @override
  Widget build(BuildContext context) => GuestExperience(
    experience: experience,
    child: Theme(
      data: GuestTheme.of(
        experience,
        highContrast: PorcelainTheme.of(context).highContrast,
      ),
      child: child,
    ),
  );
}
