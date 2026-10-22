import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import '../../domain/delivery/delivery_intent.dart';
import '../../domain/experience/experience_configuration.dart';
import '../../domain/gallery/export_plan.dart';
import '../../domain/models/booth_event.dart';
import '../../domain/models/booth_profile.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/repositories/storage_errors.dart';
import '../../domain/repositories/template_store.dart';
import '../../domain/services/camera_service.dart';
import '../../domain/services/operator_files.dart';
import '../../domain/template/template_assets.dart';
import '../../domain/template/template_tags.dart';
import '../../domain/value_objects/appearance.dart';
import '../../domain/value_objects/calendar_date.dart';
import '../../domain/value_objects/clock.dart';
import '../../domain/value_objects/entity_id.dart';
import '../../domain/value_objects/orientation.dart';
import 'booth_database.steps.dart';
import 'converters.dart';

part 'booth_database.g.dart';

/// The experiences schema v8 gives existing events (EP01), spelled out as
/// `EventExperienceConfiguration.toJson` version 1 wrote them so the step
/// never depends on today's codec. A test checks they still read back.
@visibleForTesting
const v8PorcelainExperience =
    '{"schemaVersion":1,"packId":"porcelain-classic","packVersion":1,'
    '"soundVolume":70,"celebrationEnabled":true,"cameraStage":"fullTemplate",'
    '"recommendedTemplateIds":[],"childrenMayBeGuests":false,"revision":1}';
@visibleForTesting
const v8VintageOakExperience =
    '{"schemaVersion":1,"packId":"vintage-oak","packVersion":1,'
    '"soundVolume":70,"celebrationEnabled":true,"cameraStage":"fullTemplate",'
    '"recommendedTemplateIds":[],"childrenMayBeGuests":false,"revision":1}';
@visibleForTesting
const v8DarkroomExperience =
    '{"schemaVersion":1,"packId":"porcelain-classic","packVersion":1,'
    '"variantId":"darkroom","soundVolume":70,"celebrationEnabled":true,'
    '"cameraStage":"fullTemplate","recommendedTemplateIds":[],'
    '"childrenMayBeGuests":false,"revision":1}';

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
  static const currentSchemaVersion = 8;

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
    // M05: editor drafts; assets may also be the app's own ("bundled"),
    // which changes a CHECK, so the table is rebuilt with its rows. Its
    // trigger now lets the shown name change (S08); the rebuild does not
    // carry triggers over, so the old one is dropped and the new created.
    from2To3: (migrator, schema) async {
      await migrator.alterTable(TableMigration(schema.assets));
      await migrator.database.customStatement(
        'DROP TRIGGER IF EXISTS assets_are_immutable',
      );
      await migrator.create(schema.assetContentIsImmutable);
      await migrator.createTable(schema.templateDrafts);
    },
    // M06: camera originals and the journal of commits in progress.
    from3To4: (migrator, schema) async {
      await migrator.createTable(schema.originalPhotos);
      await migrator.create(schema.originalPhotosByTime);
      await migrator.create(schema.originalPhotosAreImmutable);
      await migrator.createTable(schema.pendingOriginalCommits);
    },
    // M07: guest sessions, their photos and finished photos.
    from4To5: (migrator, schema) async {
      await migrator.createTable(schema.captureSessions);
      await migrator.create(schema.captureSessionsByEvent);
      await migrator.create(schema.captureSessionPlansAreImmutable);
      await migrator.create(schema.finishedSessionsAreImmutable);
      await migrator.createTable(schema.sessionPhotos);
      await migrator.create(schema.sessionPhotosAreImmutable);
      await migrator.createTable(schema.sessionOutputs);
      await migrator.create(schema.sessionOutputsBySession);
      await migrator.create(schema.sessionOutputsAreImmutable);
    },
    // M08: session numbers (existing sessions are numbered per event in
    // the order they started), the origin of finished photos, the export
    // history and the journal of files to delete. The rebuilds keep each
    // table's indexes and triggers; the plan trigger is replaced so it
    // also freezes the number.
    from5To6: (migrator, schema) async {
      final sessions = schema.captureSessions;
      await migrator.alterTable(
        TableMigration(
          sessions,
          newColumns: [sessions.sequence],
          columnTransformer: {
            sessions.sequence: const CustomExpression<int>(
              '(SELECT COUNT(*) FROM capture_sessions AS earlier '
              'WHERE earlier.event_id = capture_sessions.event_id '
              'AND (earlier.started_at < capture_sessions.started_at '
              'OR (earlier.started_at = capture_sessions.started_at '
              'AND earlier.id <= capture_sessions.id)))',
            ),
          },
        ),
      );
      await migrator.database.customStatement(
        'DROP TRIGGER IF EXISTS capture_session_plans_are_immutable',
      );
      await migrator.create(schema.captureSessionPlansAreImmutable);
      await migrator.alterTable(
        TableMigration(
          schema.sessionOutputs,
          newColumns: [schema.sessionOutputs.origin],
        ),
      );
      await migrator.createTable(schema.exportBatches);
      await migrator.createTable(schema.exportBatchItems);
      await migrator.create(schema.exportBatchItemsBySession);
      await migrator.createTable(schema.pendingFileDeletions);
    },
    // M09: phone delivery. New tables only; events without settings keep
    // delivery off.
    from6To7: (migrator, schema) async {
      await migrator.createTable(schema.eventDeliveryOptions);
      await migrator.createTable(schema.deliveryPairings);
      await migrator.createTable(schema.deliveryIntents);
      await migrator.create(schema.deliveryIntentsBySession);
      await migrator.create(schema.deliveryIntentsByState);
      await migrator.create(schema.deliveryIntentsByEvent);
      await migrator.createTable(schema.deliveryRemoteRevocations);
    },
    // EP01: an event's guest experience replaces its theme override, so
    // nothing a guest sees changes (EP00 decision 4.2): an override keeps
    // its look, no override takes the booth's look. Templates gain
    // optional recommendation tags.
    from7To8: (migrator, schema) async {
      final events = schema.events;
      await migrator.alterTable(
        TableMigration(
          events,
          newColumns: [events.experienceJson],
          columnTransformer: {
            events.experienceJson: const CustomExpression<String>(
              'CASE COALESCE(events.theme_override, '
              '(SELECT theme_profile FROM booth_profiles '
              'WHERE booth_profiles.id = events.booth_profile_id)) '
              "WHEN 'lightOak' THEN '$v8VintageOakExperience' "
              "WHEN 'darkroomWalnut' THEN '$v8DarkroomExperience' "
              "ELSE '$v8PorcelainExperience' END",
            ),
          },
        ),
      );
      await migrator.alterTable(
        TableMigration(
          schema.templates,
          newColumns: [schema.templates.tagsJson],
        ),
      );
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
