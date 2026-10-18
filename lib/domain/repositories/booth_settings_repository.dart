import '../models/booth_profile.dart';
import '../value_objects/appearance.dart';

/// This device's booth profile and app state (A-05 BoothProfile,
/// AppSettings).
abstract interface class BoothSettingsRepository {
  /// The stored booth; a fresh database already holds a default profile.
  Future<BoothState> load();

  /// The booth profile; emits again whenever it changes.
  Stream<BoothProfile> watchProfile();

  Future<void> saveAppearance(AppearanceSettings appearance);

  Future<void> renameBooth(String name);

  Future<void> saveEventDefaults(EventDefaults defaults);

  /// Finishes first-run setup in one transaction: names the booth, sets its
  /// theme, stores the recovery verifier and clears any failed attempts.
  Future<void> completeSetup({
    required String boothName,
    required PorcelainThemeProfile theme,
    required String recoveryVerifier,
  });

  /// Starts (an event ID) or ends (null) Booth Mode. Stored, so the booth
  /// survives a restart.
  Future<void> setBoothEvent(String? eventId);
}
