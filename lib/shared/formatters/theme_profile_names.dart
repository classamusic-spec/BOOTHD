import '../../domain/value_objects/appearance.dart';

/// Operator-facing names of the theme profiles.
extension ThemeProfileCopy on PorcelainThemeProfile {
  String get title => switch (this) {
    PorcelainThemeProfile.porcelainStudio => 'Porcelain Studio',
    PorcelainThemeProfile.lightOak => 'Light Oak',
    PorcelainThemeProfile.darkroomWalnut => 'Darkroom Walnut',
  };

  String get description => switch (this) {
    PorcelainThemeProfile.porcelainStudio =>
      'Warm ivory and champagne gold. The default.',
    PorcelainThemeProfile.lightOak =>
      'Pale oak, honey gold and sage, for light wood kiosks.',
    PorcelainThemeProfile.darkroomWalnut =>
      'Deep walnut and brass, for dim venues.',
  };
}
