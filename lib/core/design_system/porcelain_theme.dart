import 'package:flutter/material.dart';

import 'porcelain_colors.dart';
import 'porcelain_typography.dart';
import 'theme_profiles.dart';

/// Which decorative line art a profile uses (UX-02: themes select
/// decorative graphics as well as colour).
enum OrnamentStyle {
  /// Gold botanical sprigs (Porcelain Studio).
  gildedBotanical,

  /// Sage eucalyptus sprigs (Light Oak).
  sageBotanical,

  /// Sparse brass sprigs on dark (Darkroom Walnut).
  brassBotanical,
}

/// The Porcelain token set for one profile, carried by [ThemeData] as an
/// extension so it animates with theme changes and reaches every widget.
@immutable
final class PorcelainTheme extends ThemeExtension<PorcelainTheme> {
  const PorcelainTheme({
    required this.profile,
    required this.highContrast,
    required this.colors,
    required this.text,
  });

  factory PorcelainTheme.resolve(
    PorcelainThemeProfile profile, {
    bool highContrast = false,
  }) {
    final colors = PorcelainPalettes.of(profile, highContrast: highContrast);
    return PorcelainTheme(
      profile: profile,
      highContrast: highContrast,
      colors: colors,
      text: PorcelainTypography.forColors(colors),
    );
  }

  /// The default profile, used when a subtree has no Porcelain theme.
  static final fallback = PorcelainTheme.resolve(
    PorcelainThemeProfile.porcelainStudio,
  );

  static PorcelainTheme of(BuildContext context) =>
      Theme.of(context).extension<PorcelainTheme>() ?? fallback;

  final PorcelainThemeProfile profile;
  final bool highContrast;
  final PorcelainColors colors;
  final PorcelainTypography text;

  OrnamentStyle get ornament => switch (profile) {
    PorcelainThemeProfile.porcelainStudio => OrnamentStyle.gildedBotanical,
    PorcelainThemeProfile.lightOak => OrnamentStyle.sageBotanical,
    PorcelainThemeProfile.darkroomWalnut => OrnamentStyle.brassBotanical,
  };

  @override
  PorcelainTheme copyWith({
    PorcelainThemeProfile? profile,
    bool? highContrast,
    PorcelainColors? colors,
    PorcelainTypography? text,
  }) => PorcelainTheme(
    profile: profile ?? this.profile,
    highContrast: highContrast ?? this.highContrast,
    colors: colors ?? this.colors,
    text: text ?? this.text,
  );

  @override
  PorcelainTheme lerp(covariant PorcelainTheme? other, double t) {
    if (other == null) return this;
    return PorcelainTheme(
      profile: t < 0.5 ? profile : other.profile,
      highContrast: t < 0.5 ? highContrast : other.highContrast,
      colors: PorcelainColors.lerp(colors, other.colors, t),
      text: PorcelainTypography.lerp(text, other.text, t),
    );
  }
}

extension PorcelainThemeContext on BuildContext {
  /// The Porcelain tokens in effect here.
  PorcelainTheme get porcelain => PorcelainTheme.of(this);
}
