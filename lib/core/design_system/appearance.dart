import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/value_objects/appearance.dart';
import '../booth/booth_providers.dart';
import '../di/service_providers.dart';

// The appearance values are stored with the booth profile (M03), so they live
// in the domain; re-exported for the design system's users.
export '../../domain/value_objects/appearance.dart'
    show AppearanceSettings, ContrastPreference, MotionPreference;

/// The appearance in effect for the whole app (S17).
///
/// Starts from the booth's stored appearance and saves every change back to
/// the booth profile, so choices survive restarts (M03). [initial] lets a
/// test start from a known appearance without a stored booth.
final class AppearanceController extends Notifier<AppearanceSettings> {
  AppearanceController([this.initial]);

  final AppearanceSettings? initial;

  @override
  AppearanceSettings build() => initial ?? ref.watch(storedAppearanceProvider);

  /// Applies [profile] now and stores it. The returned future fails if the
  /// choice could not be saved; the theme stays applied for this run.
  Future<void> setProfile(PorcelainThemeProfile profile) =>
      _apply(state.copyWith(profile: profile));

  Future<void> setContrast(ContrastPreference contrast) =>
      _apply(state.copyWith(contrast: contrast));

  Future<void> setMotion(MotionPreference motion) =>
      _apply(state.copyWith(motion: motion));

  Future<void> _apply(AppearanceSettings next) {
    state = next;
    return ref.read(boothSettingsRepositoryProvider).saveAppearance(next);
  }
}

/// The appearance in effect for the whole app.
final appearanceProvider =
    NotifierProvider<AppearanceController, AppearanceSettings>(
      AppearanceController.new,
    );
