import 'package:drift/drift.dart';

import '../../domain/models/booth_event.dart';
import '../../domain/models/booth_profile.dart';
import '../../domain/repositories/booth_settings_repository.dart';
import '../../domain/repositories/storage_errors.dart';
import '../../domain/value_objects/appearance.dart';
import '../../domain/value_objects/clock.dart';
import 'booth_database.dart';
import 'persistence_guard.dart';

/// The booth profile and app settings rows of the booth database.
final class DriftBoothSettingsRepository implements BoothSettingsRepository {
  DriftBoothSettingsRepository(this._db, {required this._clock});

  final BoothDatabase _db;
  final Clock _clock;

  @override
  Future<BoothState> load() async {
    final settings = await _db.select(_db.appSettings).getSingle();
    final profile = await (_db.select(
      _db.boothProfiles,
    )..where((row) => row.id.equals(settings.boothProfileId))).getSingle();
    return BoothState(
      profile: _toDomain(profile),
      setupCompletedAt: settings.setupCompletedAt,
      boothEventId: settings.boothEventId,
    );
  }

  @override
  Stream<BoothProfile> watchProfile() => _db
      .select(_db.boothProfiles)
      .join([
        innerJoin(
          _db.appSettings,
          _db.appSettings.boothProfileId.equalsExp(_db.boothProfiles.id),
        ),
      ])
      .watchSingle()
      .map((row) => _toDomain(row.readTable(_db.boothProfiles)));

  @override
  Future<void> saveAppearance(AppearanceSettings appearance) => _updateProfile(
    BoothProfilesCompanion(
      themeProfile: Value(appearance.profile),
      contrastPreference: Value(appearance.contrast),
      motionPreference: Value(appearance.motion),
    ),
  );

  @override
  Future<void> renameBooth(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > BoothProfile.nameMaxLength) {
      throw const PersistenceRuleException('booth name length');
    }
    await _updateProfile(BoothProfilesCompanion(name: Value(trimmed)));
  }

  @override
  Future<void> saveEventDefaults(EventDefaults defaults) => _updateProfile(
    BoothProfilesCompanion(
      defaultLens: Value(defaults.lens),
      defaultMirrorPreview: Value(defaults.mirrorPreview),
      defaultMirrorOutput: Value(defaults.mirrorOutput),
      defaultOrientation: Value(defaults.orientation),
      defaultOutputFormat: Value(defaults.output.format),
      defaultJpegQuality: Value(defaults.output.jpegQuality),
    ),
  );

  @override
  Future<void> completeSetup({
    required String boothName,
    required PorcelainThemeProfile theme,
    required String recoveryVerifier,
  }) => guardPersistence(
    () => _db.transaction(() async {
      final now = _clock.now();
      await _updateProfileRow(
        BoothProfilesCompanion(
          name: Value(boothName.trim()),
          themeProfile: Value(theme),
        ),
        now,
      );
      await _db
          .update(_db.operatorAccess)
          .write(
            OperatorAccessCompanion(
              recoveryVerifier: Value(recoveryVerifier),
              pinFailures: const Value(0),
              pinLastFailureAt: const Value(null),
              recoveryFailures: const Value(0),
              recoveryLastFailureAt: const Value(null),
            ),
          );
      await _db
          .update(_db.appSettings)
          .write(AppSettingsCompanion(setupCompletedAt: Value(now)));
    }),
  );

  @override
  Future<void> setBoothEvent(String? eventId) => guardPersistence(
    () => _db
        .update(_db.appSettings)
        .write(AppSettingsCompanion(boothEventId: Value(eventId))),
  );

  Future<void> _updateProfile(BoothProfilesCompanion changes) =>
      guardPersistence(
        () => _db.transaction(() => _updateProfileRow(changes, _clock.now())),
      );

  Future<void> _updateProfileRow(
    BoothProfilesCompanion changes,
    DateTime now,
  ) async {
    final settings = await _db.select(_db.appSettings).getSingle();
    await (_db.update(_db.boothProfiles)
          ..where((row) => row.id.equals(settings.boothProfileId)))
        .write(changes.copyWith(updatedAt: Value(now)));
  }

  BoothProfile _toDomain(BoothProfileRow row) => BoothProfile(
    id: row.id,
    name: row.name,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    appearance: AppearanceSettings(
      profile: row.themeProfile,
      contrast: row.contrastPreference,
      motion: row.motionPreference,
    ),
    defaults: EventDefaults(
      lens: row.defaultLens,
      mirrorPreview: row.defaultMirrorPreview,
      mirrorOutput: row.defaultMirrorOutput,
      orientation: row.defaultOrientation,
      output: OutputProfile(
        format: row.defaultOutputFormat,
        jpegQuality: row.defaultJpegQuality,
      ),
    ),
  );
}
