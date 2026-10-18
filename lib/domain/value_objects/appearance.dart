/// Appearance choices a booth stores (UX-02, S17). Identifiers only: the
/// palettes and type that realise them live in `core/design_system`.
library;

import 'package:meta/meta.dart';

/// The named appearance profiles (UX-02). Porcelain Studio is the complete
/// default; Light Oak and Darkroom Walnut use the same colour roles, so
/// switching profile changes no feature code (AC-0206).
enum PorcelainThemeProfile { porcelainStudio, lightOak, darkroomWalnut }

/// Whether to follow the platform's increased-contrast setting or override
/// it (S17).
enum ContrastPreference { system, standard, high }

/// Whether to follow the platform's reduced-motion setting or always reduce
/// motion (S17). There is deliberately no "always animate": the platform
/// setting is an accessibility need the app must not override.
enum MotionPreference { system, reduced }

/// A booth's appearance choices (UX-02, S17), stored with its profile.
@immutable
final class AppearanceSettings {
  const AppearanceSettings({
    this.profile = PorcelainThemeProfile.porcelainStudio,
    this.contrast = ContrastPreference.system,
    this.motion = MotionPreference.system,
  });

  final PorcelainThemeProfile profile;
  final ContrastPreference contrast;
  final MotionPreference motion;

  bool useHighContrast({required bool platformHighContrast}) =>
      switch (contrast) {
        ContrastPreference.system => platformHighContrast,
        ContrastPreference.standard => false,
        ContrastPreference.high => true,
      };

  bool reduceMotion({required bool platformReducesMotion}) =>
      platformReducesMotion || motion == MotionPreference.reduced;

  AppearanceSettings copyWith({
    PorcelainThemeProfile? profile,
    ContrastPreference? contrast,
    MotionPreference? motion,
  }) => AppearanceSettings(
    profile: profile ?? this.profile,
    contrast: contrast ?? this.contrast,
    motion: motion ?? this.motion,
  );

  @override
  bool operator ==(Object other) =>
      other is AppearanceSettings &&
      other.profile == profile &&
      other.contrast == contrast &&
      other.motion == motion;

  @override
  int get hashCode => Object.hash(profile, contrast, motion);
}
