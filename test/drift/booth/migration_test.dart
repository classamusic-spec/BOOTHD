// AC-0304: schema dumps, migrations and referential integrity on seeded old
// and fresh databases. Every schema version ever shipped must have a dump
// (drift_schemas/booth) and a seed (fixtures/seed_v<N>.sql); each seeded
// version is opened by the current code and must keep every value.
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/repositories/storage_errors.dart';
import 'package:porcelain_photo_booth/domain/repositories/template_store.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/domain/template/template_assets.dart';
import 'package:porcelain_photo_booth/domain/value_objects/appearance.dart';
import 'package:porcelain_photo_booth/domain/value_objects/calendar_date.dart';
import 'package:porcelain_photo_booth/domain/value_objects/orientation.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';
import 'package:porcelain_photo_booth/infrastructure/database/database_connection.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_booth_settings_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_event_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_operator_access_repository.dart';
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
          themeOverride: PorcelainThemeProfile.darkroomWalnut,
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
      expect(
        archived.guest.themeOverride,
        PorcelainThemeProfile.porcelainStudio,
      );

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
    });
  }

  test('asset content cannot be changed, mislabelled or orphaned', () async {
    final schema = await verifier.schemaAt(BoothDatabase.currentSchemaVersion);
    // seed_v2's rows, opened by the current code.
    final raw = schema.rawDatabase..execute(seedFor(2));
    final seeded = currentCode(schema.newConnection());
    addTearDown(seeded.close);
    await seeded.customSelect('SELECT 1').get();
    expect(raw.select('SELECT count(*) FROM assets').single.values.single, 3);

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
