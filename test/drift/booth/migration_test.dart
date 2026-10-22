// AC-0304: schema dumps, migrations and referential integrity on seeded old
// and fresh databases. Every schema version ever shipped must have a dump
// (drift_schemas/booth) and a seed (fixtures/seed_v<N>.sql); each seeded
// version is opened by the current code and must keep every value.
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/delivery/delivery_intent.dart';
import 'package:porcelain_photo_booth/domain/delivery/delivery_settings.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_configuration.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_registry.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/repositories/session_repository.dart';
import 'package:porcelain_photo_booth/domain/repositories/storage_errors.dart';
import 'package:porcelain_photo_booth/domain/repositories/template_store.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/domain/services/operator_files.dart';
import 'package:porcelain_photo_booth/domain/template/template_assets.dart';
import 'package:porcelain_photo_booth/domain/template/template_tags.dart';
import 'package:porcelain_photo_booth/domain/value_objects/appearance.dart';
import 'package:porcelain_photo_booth/domain/value_objects/calendar_date.dart';
import 'package:porcelain_photo_booth/domain/value_objects/orientation.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';
import 'package:porcelain_photo_booth/infrastructure/database/database_connection.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_booth_settings_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_delivery_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_event_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_gallery_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_operator_access_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_session_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_template_catalog.dart';

import '../../support/fakes.dart';
import 'generated/schema.dart';

const _booth = 'b0000000-0000-4000-8000-000000000001';
const _draft = 'e0000000-0000-4000-8000-000000000001';
const _active = 'e0000000-0000-4000-8000-000000000002';
const _archived = 'e0000000-0000-4000-8000-000000000003';
const _revisionA1 = 'a1000000-0000-4000-8000-0000000000a1';
const _revisionA2 = 'a2000000-0000-4000-8000-0000000000a2';
const _revisionB1 = 'b1000000-0000-4000-8000-0000000000b1';
const _sessionOriginal = '20261114180500-0a1b2c3d';
const _completedSession = 'c0000000-0000-4000-8000-000000000001';
const _renderingSession = 'c0000000-0000-4000-8000-000000000002';
const _sessionOutput = 'd0000000-0000-4000-8000-000000000001';
const _rerenderOutput = 'd0000000-0000-4000-8000-000000000002';
const _legacyOriginal = 'm01-spike-still';

String seedFor(int version) =>
    File('test/drift/booth/fixtures/seed_v$version.sql').readAsStringSync();

BoothDatabase currentCode(DatabaseConnection connection) =>
    BoothDatabase(connection, ids: SequentialIds(), clock: FakeClock());

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper(), setup: configureConnection);
  });

  test('every schema version has a dump and a seed; the newest is the '
      "app's", () {
    expect(GeneratedHelper.versions.last, BoothDatabase.currentSchemaVersion);
    expect(
      GeneratedHelper.versions,
      List.generate(BoothDatabase.currentSchemaVersion, (i) => i + 1),
    );
    for (final version in GeneratedHelper.versions) {
      expect(
        File('test/drift/booth/fixtures/seed_v$version.sql').existsSync(),
        isTrue,
        reason: 'seed for v$version',
      );
    }
  });

  test('a fresh database matches the newest schema dump exactly', () async {
    final schema = await verifier.schemaAt(BoothDatabase.currentSchemaVersion);
    final fresh = currentCode(DatabaseConnection(openBoothDatabaseInMemory()));
    addTearDown(fresh.close);
    // Opening creates the schema from the code; it must equal the dump.
    await fresh.customSelect('SELECT 1').get();
    final fromDump = currentCode(schema.newConnection());
    addTearDown(fromDump.close);
    await verifier.migrateAndValidate(
      fromDump,
      BoothDatabase.currentSchemaVersion,
    );
    await fresh.validateDatabaseSchema();
  });

  for (final from in GeneratedHelper.versions) {
    test('a seeded v$from database opens with every value intact', () async {
      final schema = await verifier.schemaAt(from);
      schema.rawDatabase.execute(seedFor(from));

      final db = currentCode(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, BoothDatabase.currentSchemaVersion);

      final integrity = await db.customSelect('PRAGMA integrity_check').get();
      expect(integrity.single.data.values.single, 'ok');
      final orphans = await db.customSelect('PRAGMA foreign_key_check').get();
      expect(orphans, isEmpty);
      final foreignKeys = await db.customSelect('PRAGMA foreign_keys').get();
      expect(foreignKeys.single.data.values.single, 1);

      final booth = await DriftBoothSettingsRepository(
        db,
        clock: FakeClock(),
      ).load();
      expect(booth.profile.id, _booth);
      expect(booth.profile.name, 'Ballroom booth');
      expect(
        booth.profile.appearance,
        const AppearanceSettings(
          profile: PorcelainThemeProfile.lightOak,
          contrast: ContrastPreference.high,
          motion: MotionPreference.reduced,
        ),
      );
      expect(booth.profile.defaults.lens, CameraLens.back);
      expect(booth.profile.defaults.mirrorPreview, isFalse);
      expect(booth.profile.defaults.mirrorOutput, isTrue);
      expect(
        booth.profile.defaults.orientation,
        GuestOrientationPreference.landscape,
      );
      expect(
        booth.profile.defaults.output,
        const OutputProfile(format: OutputFormat.png, jpegQuality: 95),
      );
      expect(
        booth.profile.updatedAt,
        DateTime.utc(2026, 10, 17, 18, 45, 12, 345),
      );
      expect(booth.setupCompletedAt, DateTime.utc(2026, 10, 1, 8, 10));
      expect(booth.boothEventId, _active);

      final events = DriftEventRepository(db);
      final active = await events.findById(_active);
      expect(active, isNotNull);
      active!;
      expect(active.title, "Hannah & Theo's wedding");
      expect(active.date, CalendarDate(2026, 11, 14));
      expect(active.venue, 'The Orangery');
      expect(active.notes, 'Arrive 2 h early.');
      expect(active.status, EventStatus.active);
      expect(
        active.capture,
        const CaptureSettings(
          lens: CameraLens.back,
          mirrorPreview: false,
          mirrorOutput: true,
          orientation: GuestOrientationPreference.landscape,
          shotCount: 2,
          countdownSeconds: 5,
          shotIntervalSeconds: 4,
          retakePolicy: RetakePolicy.wholeSession,
          retakeLimit: 2,
        ),
      );
      expect(
        active.guest,
        const GuestSettings(
          welcomeTitle: 'Welcome, friends',
          welcomeMessage: "Two photos, then you're done.",
          consentText: 'Photos stay on this booth.',
          guestChoosesTemplate: true,
          finishTimeoutSeconds: 45,
        ),
      );
      expect(
        active.output,
        const OutputProfile(format: OutputFormat.png, jpegQuality: 95),
      );
      expect(active.retention, const RetentionPolicy.deleteAfterDays(30));
      expect(
        active.templates,
        const TemplateSelection(
          revisionIds: [_revisionA2, _revisionA1],
          defaultRevisionId: _revisionA1,
        ),
      );

      final draft = (await events.findById(_draft))!;
      expect(draft.status, EventStatus.draft);
      expect(draft.templates, const TemplateSelection());
      expect(draft.date, isNull);

      final archived = (await events.findById(_archived))!;
      expect(archived.status, EventStatus.archived);
      expect(archived.archivedAt, DateTime.utc(2026, 1, 5, 9));
      expect(archived.capture.retakePolicy, RetakePolicy.none);
      expect(archived.capture.retakeLimit, 0);
      // Version 8 (EP01): each event's theme became its guest experience,
      // keeping the look: an override its own, none the booth's.
      expect(
        active.experience,
        const EventExperienceConfiguration(variantId: 'darkroom'),
      );
      expect(archived.experience, const EventExperienceConfiguration());
      expect(active.experience.revision, from >= 8 ? 2 : 1);
      expect(
        draft.experience,
        const EventExperienceConfiguration(packId: 'vintage-oak'),
      );

      // Version 7 (M09): phone delivery, off for events from older versions.
      final deliveries = DriftDeliveryRepository(db);
      if (from >= 7) {
        expect(
          active.delivery,
          const EventDeliverySettings(
            enabled: true,
            offlineQueue: false,
            linkDays: 5,
            sendLimit: 150,
          ),
        );
        expect(draft.delivery, const EventDeliverySettings());
        final pairing = (await deliveries.pairing())!;
        expect(pairing.baseUrl, Uri.parse('https://photos.example.test'));
        expect(pairing.boothName, 'Ballroom booth');
        expect(pairing.paused, isFalse);
        expect(pairing.capabilities!.ready, isTrue);
        expect(pairing.capabilities!.linkDaysMax, 14);
        expect(pairing.capabilities!.previewMaxBytes, 600000);
        expect(pairing.checkedAtUtc, DateTime.utc(2026, 11, 14, 18));
        final intents = await deliveries.forSession(_completedSession);
        expect(intents.map((i) => i.phase), [
          DeliveryPhase.delivered,
          DeliveryPhase.queuedLocally,
        ]);
        final delivered = intents.first;
        expect(delivered.phoneLast4, '0147');
        expect(delivered.phoneStored, isFalse);
        expect(delivered.queueAllowed, isFalse);
        expect(delivered.remoteJobId, 'f2000000-0000-4000-8000-000000000001');
        expect(delivered.consentTextDigest, 'ab' * 32);
        expect(delivered.history.map((step) => step.phase), [
          DeliveryPhase.queuedLocally,
          DeliveryPhase.delivered,
        ]);
        final waiting = intents.last;
        expect(waiting.state, DeliveryIntentState.queued);
        expect(waiting.lastErrorCode, 'OFFLINE');
        expect(waiting.attemptCount, 2);
        expect(waiting.retryAtUtc, DateTime.utc(2026, 11, 14, 18, 13));
        expect(waiting.expiresAtUtc, DateTime.utc(2026, 11, 15, 18, 12));
        expect(await deliveries.pendingRevocations(), [
          'f2000000-0000-4000-8000-000000000009',
        ]);
      } else {
        expect(
          active.delivery,
          const EventDeliverySettings(),
          reason: 'delivery arrived with version 7, off',
        );
        expect(await deliveries.pairing(), isNull);
        expect(await deliveries.forSession(_completedSession), isEmpty);
        expect(await deliveries.pendingRevocations(), isEmpty);
      }

      final all = await events.watchAll().first;
      expect(all.map((event) => event.id), [_active, _draft, _archived]);

      final catalog = DriftTemplateCatalog(db);
      final selectable = await catalog.watchSelectable().first;
      expect(selectable.map((template) => template.revisionId), [
        _revisionA2,
      ], reason: 'latest revision of templates that are not archived');
      final referenced = await catalog.findRevisions([
        _revisionA1,
        _revisionB1,
      ]);
      expect(referenced[_revisionB1]!.templateArchived, isTrue);
      expect(referenced[_revisionB1]!.photoSlotCount, 3);
      expect(referenced[_revisionA1]!.pageHeightPx, 1800);
      // Version 8 (EP01): recommendation tags, none on older templates.
      final templateRows = await db.select(db.templates).get();
      final twoUp = templateRows.firstWhere(
        (row) => row.displayName == 'Two-up classic',
      );
      expect(
        twoUp.tagsJson,
        from >= 8
            ? const TemplateTags(
                categoryTags: ['wedding'],
                recommendedExperienceIds: ['porcelain-classic'],
                occasionTags: ['evening'],
                visualStyleTags: ['elegant'],
                defaultCaptureCount: 2,
              )
            : isNull,
      );
      expect(
        templateRows
            .firstWhere((row) => row.displayName == 'Retro strip')
            .tagsJson,
        isNull,
      );

      final access = await DriftOperatorAccessRepository(db).read();
      expect(access.recoveryVerifier, startsWith(r'pbkdf2-sha256$120000$'));
      expect(access.pinAttempts.failures, 2);
      expect(
        access.pinAttempts.lastFailureAt,
        DateTime.utc(2026, 10, 17, 18, 30),
      );
      expect(access.recoveryAttempts.failures, 0);

      if (from >= 2) {
        final assets = await db.select(db.assets).get();
        expect(assets, hasLength(from >= 3 ? 4 : 3));
        final flower = assets.firstWhere((a) => a.displayName == 'flower.png');
        expect(flower.mediaType, AssetMediaType.png);
        expect((flower.widthPx, flower.heightPx), (800, 800));
        expect(flower.byteLength, 48213);
        expect(flower.origin, AssetOrigin.package);
        expect(flower.relativePath, 'assets/${flower.id}.png');
        final font = assets.firstWhere(
          (a) => a.mediaType == AssetMediaType.ttf,
        );
        expect((font.widthPx, font.heightPx), (null, null));
        final links = await db.select(db.templateRevisionAssets).get();
        expect(
          links.where((l) => l.templateRevisionId == _revisionA2),
          hasLength(3),
        );
      } else {
        // Version 1 had no assets: the upgrade adds empty tables.
        expect(await db.select(db.assets).get(), isEmpty);
        expect(await db.select(db.templateRevisionAssets).get(), isEmpty);
      }

      final drafts = await db.select(db.templateDrafts).get();
      if (from >= 3) {
        final draft = drafts.single;
        expect(draft.templateId, 'a0000000-0000-4000-8000-00000000000a');
        expect(draft.baseRevisionId, _revisionA2);
        expect(draft.updatedAt, DateTime.utc(2026, 10, 18, 10, 15));
        final bundled = (await db.select(db.assets).get()).singleWhere(
          (a) => a.origin == AssetOrigin.bundled,
        );
        expect(bundled.displayName, 'Floral corner');
      } else {
        expect(drafts, isEmpty, reason: 'drafts arrived with version 3');
      }

      final originals = await (db.select(
        db.originalPhotos,
      )..orderBy([(o) => OrderingTerm.desc(o.capturedAt)])).get();
      final pending = await db.select(db.pendingOriginalCommits).get();
      if (from >= 4) {
        expect(
          originals.map((o) => o.id),
          containsAll([_sessionOriginal, _legacyOriginal]),
        );
        expect(originals, hasLength(from >= 5 ? 7 : 2));
        final session = originals.firstWhere((o) => o.id == _sessionOriginal);
        expect(session.relativePath, 'originals/$_sessionOriginal.jpg');
        expect((session.widthPx, session.heightPx), (4032, 3024));
        expect(session.byteLength, 3145728);
        expect(session.sha256, '1' * 64);
        expect(session.lens, CameraLens.back);
        expect(session.sensorOrientation, 90);
        expect(session.deviceOrientation, CaptureOrientation.landscapeLeft);
        expect(session.exifOrientation, 1);
        expect(session.mirrorPreview, isFalse);
        expect(session.mirrorOutput, isTrue);
        expect(session.origin, CaptureOrigin.session);
        expect(session.capturedAt, DateTime.utc(2026, 11, 14, 18, 5));
        expect(session.committedAt, DateTime.utc(2026, 11, 14, 18, 5, 1, 250));
        final legacy = originals.firstWhere((o) => o.id == _legacyOriginal);
        expect(legacy.lens, CameraLens.front);
        expect(legacy.deviceOrientation, CaptureOrientation.unknown);
        expect(legacy.exifOrientation, isNull);
        expect(legacy.mirrorPreview, isTrue);
        expect(legacy.origin, CaptureOrigin.legacy);
        final intent = pending.single;
        expect(intent.id, '20261114180900-4e5f6a7b');
        expect(intent.sha256, '3' * 64);
        expect(intent.byteLength, 1048576);
        expect(intent.startedAt, DateTime.utc(2026, 11, 14, 18, 9));
      } else {
        expect(originals, isEmpty, reason: 'originals arrived with version 4');
        expect(pending, isEmpty);
      }

      final sessions = DriftSessionRepository(db, clock: FakeClock());
      if (from >= 5) {
        final completed = (await sessions.find(_completedSession))!;
        expect(completed.status, SessionStatus.completed);
        expect(completed.plan.eventId, _active);
        expect(completed.plan.templateRevisionId, _revisionA1);
        expect(completed.plan.capture.lens, CameraLens.back);
        expect(completed.plan.capture.mirrorOutput, isTrue);
        expect(completed.plan.capture.retakePolicy, RetakePolicy.perShot);
        expect(completed.plan.output.format, OutputFormat.png);
        expect(completed.plan.finishTimeoutSeconds, 45);
        expect(completed.photos, hasLength(3));
        expect(completed.shots.slotBindings, {
          0: '20261114181000-00000001',
          1: '20261114181030-00000003',
        }, reason: 'the retake is used; the first attempt is kept');
        expect(completed.outputId, _sessionOutput);
        expect(completed.endedAtUtc, DateTime.utc(2026, 11, 14, 18, 11));
        final output = (await sessions.output(_sessionOutput))!;
        expect(output.relativePath, 'outputs/$_sessionOutput.png');
        expect((output.widthPx, output.heightPx), (1200, 1800));
        expect(output.renderVersion, 2);
        expect(output.origin, SessionOutputOrigin.session);
        final unfinished = await sessions.unfinished();
        expect(unfinished.single.id, _renderingSession);
        expect(unfinished.single.status, SessionStatus.rendering);
        expect(unfinished.single.renderAttempts, 1);
        expect(unfinished.single.shots.isComplete, isTrue);
        // Version 6 numbers sessions per event in the order they started.
        expect(completed.number, 1);
        expect(unfinished.single.number, 2);
        // Version 8 (EP01): a session keeps the experience it showed;
        // sessions from before experiences have none.
        expect(completed.plan.experience, isNull);
        expect(
          unfinished.single.plan.experience,
          from >= 8
              ? ExperienceRegistry.bundled.resolve(
                  const EventExperienceConfiguration(variantId: 'darkroom'),
                )
              : isNull,
        );

        final gallery = DriftGalleryRepository(
          db,
          clock: FakeClock(),
          templates: catalog,
        );
        final listed = await gallery.sessions(_active);
        expect(listed.map((s) => s.number), [2, 1]);
        final outputs = await sessions.outputs(_completedSession);
        final journal = await db.select(db.pendingFileDeletions).get();
        final detail = (await gallery.detail(_completedSession))!;
        if (from >= 6) {
          expect(outputs.map((o) => o.origin), [
            SessionOutputOrigin.session,
            SessionOutputOrigin.rerender,
          ]);
          expect(listed.last.latestOutput!.id, _rerenderOutput);
          final export = detail.exports.single;
          expect(export.outcome, ShareOutcome.shared);
          expect(
            export.destination,
            'com.apple.DocumentManagerUICore.SaveToFiles',
          );
          expect(export.fileNames, [
            'hannah-theo-s-wedding-0001-20261114-1809.png',
            'hannah-theo-s-wedding-0001-photo2-retake1.jpg',
          ]);
          expect(listed.last.lastExportedAtUtc, DateTime.utc(2026, 11, 20, 10));
          expect(
            journal.single.relativePath,
            'originals/20261101120000-deleted0.jpg',
          );
        } else {
          expect(outputs.single.origin, SessionOutputOrigin.session);
          expect(detail.exports, isEmpty);
          expect(journal, isEmpty, reason: 'the journal arrived with v6');
        }
      } else {
        expect(
          await db.select(db.captureSessions).get(),
          isEmpty,
          reason: 'sessions arrived with version 5',
        );
        expect(await db.select(db.sessionPhotos).get(), isEmpty);
        expect(await db.select(db.sessionOutputs).get(), isEmpty);
      }
    });
  }

  // EP01 (decision 4.2): every stored theme becomes the experience with
  // the same look, on every booth appearance.
  test('v7 themes become experiences that keep their look', () async {
    for (final booth in PorcelainThemeProfile.values) {
      for (final override in [null, ...PorcelainThemeProfile.values]) {
        final schema = await verifier.schemaAt(7);
        final raw = schema.rawDatabase..execute(seedFor(7));
        raw
          ..execute("UPDATE booth_profiles SET theme_profile = '${booth.name}'")
          ..execute(
            'UPDATE events SET theme_override = '
            "${override == null ? 'NULL' : "'${override.name}'"} "
            "WHERE id = '$_draft'",
          );
        final db = currentCode(schema.newConnection());
        await verifier.migrateAndValidate(
          db,
          BoothDatabase.currentSchemaVersion,
        );
        final draft = (await DriftEventRepository(db).findById(_draft))!;
        expect(
          draft.experience,
          ExperienceRegistry.forAppearance(override ?? booth),
          reason: 'booth ${booth.name}, override ${override?.name}',
        );
        expect(
          ExperienceRegistry.legacyAppearance(draft.experience),
          override ?? booth,
        );
        await db.close();
      }
    }
  });

  test('originals cannot be changed, misplaced or mislabelled', () async {
    final schema = await verifier.schemaAt(BoothDatabase.currentSchemaVersion);
    final raw = schema.rawDatabase
      ..execute(seedFor(BoothDatabase.currentSchemaVersion));
    final seeded = currentCode(schema.newConnection());
    addTearDown(seeded.close);
    await seeded.customSelect('SELECT 1').get();

    Future<void> rejects(String sql) => expectLater(
      seeded.customStatement(sql),
      throwsA(anything),
      reason: sql,
    );
    // An original is immutable once recorded (A-11).
    for (final change in [
      "relative_path = 'originals/other.jpg'",
      'width_px = 1',
      "sha256 = '${'4' * 64}'",
      "lens = 'front'",
      'mirror_output = 0',
      "origin = 'diagnostics'",
      "captured_at = '2026-11-14T18:06:00.000Z'",
    ]) {
      await rejects(
        "UPDATE original_photos SET $change WHERE id = '$_sessionOriginal'",
      );
    }
    String original({
      String id = 'new-original',
      String? path,
      String sha256 =
          '5555555555555555555555555555555555555555555555555555555555555555',
      String lens = 'back',
      int sensor = 90,
      String exif = 'NULL',
    }) =>
        "INSERT INTO original_photos VALUES ('$id', "
        "'${path ?? 'originals/$id.jpg'}', 4032, 3024, 1000, '$sha256', "
        "'$lens', $sensor, 'unknown', $exif, 0, 0, 'session', "
        "'2026-11-14T18:10:00.000Z', '2026-11-14T18:10:01.000Z')";
    await rejects(original(id: '../escape', path: 'originals/../escape.jpg'));
    await rejects(original(path: 'assets/new-original.jpg'));
    await rejects(original(path: 'originals/new-original.png'));
    await rejects(original(sha256: 'A' * 64));
    await rejects(original(sha256: 'a' * 63));
    await rejects(original(lens: 'side'));
    await rejects(original(sensor: 45));
    await rejects(original(exif: '9'));
    await seeded.customStatement(original());
    expect(
      raw.select('SELECT count(*) FROM original_photos').single.values.single,
      8,
      reason: "the seed's seven and the one accepted",
    );
  });

  test('session numbers are unique per event and never change; outputs '
      'name their origin', () async {
    final schema = await verifier.schemaAt(BoothDatabase.currentSchemaVersion);
    final raw = schema.rawDatabase
      ..execute(seedFor(BoothDatabase.currentSchemaVersion));
    final seeded = currentCode(schema.newConnection());
    addTearDown(seeded.close);
    await seeded.customSelect('SELECT 1').get();

    Future<void> rejects(String sql) => expectLater(
      seeded.customStatement(sql),
      throwsA(anything),
      reason: sql,
    );
    await rejects(
      "UPDATE capture_sessions SET sequence = 7 WHERE id = '$_renderingSession'",
    );
    await rejects(
      "UPDATE capture_sessions SET sequence = 1 WHERE id = '$_renderingSession'",
    );
    await rejects(
      "UPDATE session_outputs SET origin = 'session' "
      "WHERE id = '$_rerenderOutput'",
    );
    await rejects(
      "INSERT INTO session_outputs VALUES ('d0000000-0000-4000-8000-0000000000ff', "
      "'$_completedSession', "
      "'outputs/d0000000-0000-4000-8000-0000000000ff.png', '${'9' * 64}', "
      "10, 1200, 1800, 'png', 2, '2026-11-20T09:31:00.000Z', 'copied')",
    );
    await rejects(
      "INSERT INTO pending_file_deletions VALUES ('../outside.jpg', "
      "'2026-11-20T10:05:00.000Z')",
    );
    await rejects(
      "INSERT INTO export_batches VALUES ('f0000000-0000-4000-8000-000000000002', "
      "'dismissed', NULL, 1, 0, '2026-11-20T10:00:00.000Z')",
    );
    expect(
      raw
          .select('SELECT sequence FROM capture_sessions ORDER BY sequence')
          .map((row) => row.values.single),
      [1, 2],
    );
  });

  test('asset content cannot be changed, mislabelled or orphaned', () async {
    final schema = await verifier.schemaAt(BoothDatabase.currentSchemaVersion);
    // The latest seed's rows, opened by the current code.
    final raw = schema.rawDatabase
      ..execute(seedFor(BoothDatabase.currentSchemaVersion));
    final seeded = currentCode(schema.newConnection());
    addTearDown(seeded.close);
    await seeded.customSelect('SELECT 1').get();
    expect(raw.select('SELECT count(*) FROM assets').single.values.single, 4);

    Future<void> rejects(String sql) => expectLater(
      seeded.customStatement(sql),
      throwsA(anything),
      reason: sql,
    );
    const flower =
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    // What an asset is never changes (version 3: its shown name may).
    for (final change in [
      "id = '${'b' * 64}'",
      "media_type = 'jpeg'",
      "relative_path = 'assets/x.png'",
      'byte_length = 11',
      'width_px = 2',
      'height_px = 2',
      "origin = 'bundled'",
      "created_at = '2026-10-04T10:00:00.000Z'",
    ]) {
      await rejects("UPDATE assets SET $change WHERE id = '$flower'");
    }
    await seeded.customStatement(
      "UPDATE assets SET display_name = 'Flower.png' WHERE id = '$flower'",
    );
    expect(
      raw
          .select("SELECT display_name FROM assets WHERE id = '$flower'")
          .single
          .values
          .single,
      'Flower.png',
    );
    await rejects(
      "INSERT INTO assets VALUES ('${'d' * 64}', 'png', "
      "'assets/../evil.png', 10, 1, 1, NULL, 'imported', "
      "'2026-10-03T10:00:00.000Z')",
    );
    await rejects(
      "INSERT INTO assets VALUES ('${'D' * 64}', 'png', "
      "'assets/${'D' * 64}.png', 10, 1, 1, NULL, 'imported', "
      "'2026-10-03T10:00:00.000Z')",
    );
    await rejects(
      "INSERT INTO assets VALUES ('${'e' * 64}', 'png', "
      "'assets/${'e' * 64}.png', 10, NULL, NULL, NULL, 'imported', "
      "'2026-10-03T10:00:00.000Z')",
    );
    await rejects("DELETE FROM assets WHERE id = '$flower'");
    await rejects(
      "INSERT INTO assets VALUES ('${'9' * 64}', 'png', "
      "'assets/${'9' * 64}.png', 10, 1, 1, NULL, 'downloaded', "
      "'2026-10-03T10:00:00.000Z')",
    );
    await rejects(
      'INSERT INTO template_revision_assets VALUES '
      "('a1000000-0000-4000-8000-0000000000a1', '${'f' * 64}')",
    );
    expect(
      raw
          .select('SELECT count(*) FROM template_revision_assets')
          .single
          .values
          .single,
      4,
    );
  });

  test('data from a newer app version is refused and left untouched', () async {
    final schema = await verifier.schemaAt(BoothDatabase.currentSchemaVersion);
    schema.rawDatabase
      ..execute(seedFor(BoothDatabase.currentSchemaVersion))
      ..execute(
        'PRAGMA user_version = ${BoothDatabase.currentSchemaVersion + 1}',
      );

    final db = currentCode(schema.newConnection());
    addTearDown(db.close);
    await expectLater(
      db.customSelect('SELECT 1').get(),
      throwsA(
        isA<StoredDataTooNewException>()
            .having(
              (e) => e.foundVersion,
              'found',
              BoothDatabase.currentSchemaVersion + 1,
            )
            .having(
              (e) => e.supportedVersion,
              'supported',
              BoothDatabase.currentSchemaVersion,
            ),
      ),
    );

    final raw = schema.rawDatabase;
    expect(
      raw.select('PRAGMA user_version').single.values.single,
      BoothDatabase.currentSchemaVersion + 1,
    );
    expect(raw.select('SELECT count(*) FROM events').single.values.single, 3);
    expect(
      raw.select('SELECT name FROM booth_profiles').single.values.single,
      'Ballroom booth',
    );
  });
}
