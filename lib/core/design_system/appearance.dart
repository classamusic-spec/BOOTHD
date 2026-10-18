import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_profiles.dart';

/// Whether to follow the platform's increased-contrast setting or override
/// it (S17).
enum ContrastPreference { system, standard, high }

/// Whether to follow the platform's reduced-motion setting or always reduce
/// motion (S17). There is deliberately no "always animate": the platform
/// setting is an accessibility need the app must not override.
enum MotionPreference { system, reduced }

/// Booth appearance choices (UX-02, S17).
///
/// Held in memory until booth storage arrives (M03), which will persist it
/// per booth with an optional event override.
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

final class AppearanceController extends Notifier<AppearanceSettings> {
  /// [initial] lets tests (and, from M03, stored booth settings) start from
  /// a known appearance.
  AppearanceController([this.initial = const AppearanceSettings()]);

  final AppearanceSettings initial;

  @override
  AppearanceSettings build() => initial;

  void setProfile(PorcelainThemeProfile profile) =>
      state = state.copyWith(profile: profile);

  void setContrast(ContrastPreference contrast) =>
      state = state.copyWith(contrast: contrast);

  void setMotion(MotionPreference motion) =>
      state = state.copyWith(motion: motion);
}

/// The appearance in effect for the whole app.
final appearanceProvider =
    NotifierProvider<AppearanceController, AppearanceSettings>(
      AppearanceController.new,
    );
