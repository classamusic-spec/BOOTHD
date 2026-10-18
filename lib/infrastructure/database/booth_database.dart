import 'package:drift/drift.dart';

import '../../domain/models/booth_event.dart';
import '../../domain/models/booth_profile.dart';
import '../../domain/repositories/storage_errors.dart';
import '../../domain/repositories/template_store.dart';
import '../../domain/services/camera_service.dart';
import '../../domain/template/template_assets.dart';
import '../../domain/value_objects/appearance.dart';
import '../../domain/value_objects/calendar_date.dart';
import '../../domain/value_objects/clock.dart';
import '../../domain/value_objects/entity_id.dart';
import '../../domain/value_objects/orientation.dart';
import 'booth_database.steps.dart';
import 'converters.dart';

part 'booth_database.g.dart';

/// The booth's relational store (A-11, ADR-0009). The schema is defined in
/// `booth_schema.drift`; generated code is committed and checked by
/// `tool/check.sh`.
@DriftDatabase(include: {'booth_schema.drift'})
final class BoothDatabase extends _$BoothDatabase {
  BoothDatabase(super.executor, {required this._ids, required this._clock});

  final IdGenerator _ids;
  final Clock _clock;

  /// Bump together with a migration step, a schema dump
  /// (`dart run drift_dev make-migrations`) and a seeded fixture.
  static const currentSchemaVersion = 2;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _seed();
    },
    onUpgrade: (migrator, from, to) async {
      // Never touch data written by a newer app: refuse before any change.
      if (from > to) {
        throw StoredDataTooNewException(
          foundVersion: from,
          supportedVersion: to,
        );
      }
      if (from < 1) throw StoredDataUnsupportedException(from);
      // The steps run with foreign keys off (table rebuilds need it) in one
      // transaction that commits only if every link still holds.
      await customStatement('PRAGMA foreign_keys = OFF');
      try {
        await transaction(() async {
          await _steps(migrator, from, to);
          final orphans = await customSelect('PRAGMA foreign_key_check').get();
          if (orphans.isNotEmpty) {
            throw StateError('the upgrade left ${orphans.length} broken links');
          }
        });
      } finally {
        await customStatement('PRAGMA foreign_keys = ON');
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// One step per schema version (generated shapes in
  /// booth_database.steps.dart, so a step never depends on today's tables).
  static final _steps = stepByStep(
    // M04: template assets and the assets each revision uses.
    from1To2: (migrator, schema) async {
      await migrator.createTable(schema.assets);
      await migrator.create(schema.assetsAreImmutable);
      await migrator.createTable(schema.templateRevisionAssets);
      await migrator.create(schema.templateRevisionAssetsByAsset);
    },
  );

  /// The rows every database starts with: a default booth profile, the app
  /// settings row (setup not yet done) and the operator access row.
  Future<void> _seed() async {
    final now = _clock.now();
    final profileId = _ids.newId();
    const defaults = EventDefaults();
    const appearance = AppearanceSettings();
    await into(boothProfiles).insert(
      BoothProfilesCompanion.insert(
        id: profileId,
        name: BoothProfile.defaultName,
        themeProfile: appearance.profile,
        contrastPreference: appearance.contrast,
        motionPreference: appearance.motion,
        defaultLens: defaults.lens,
        defaultMirrorPreview: defaults.mirrorPreview,
        defaultMirrorOutput: defaults.mirrorOutput,
        defaultOrientation: defaults.orientation,
        defaultOutputFormat: defaults.output.format,
        defaultJpegQuality: defaults.output.jpegQuality,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await into(appSettings).insert(
      AppSettingsCompanion.insert(
        id: const Value(1),
        boothProfileId: profileId,
      ),
    );
    await into(operatorAccess)
        .insert(OperatorAccessCompanion.insert(id: const Value(1)));
  }
}
