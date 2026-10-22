// AC-0302, AC-0304: offline persistence across restarts, atomic saves and
// the referential-integrity rules the schema enforces on its own.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_configuration.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/models/booth_profile.dart';
import 'package:porcelain_photo_booth/domain/repositories/storage_errors.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/domain/services/event_service.dart';
import 'package:porcelain_photo_booth/domain/value_objects/appearance.dart';
import 'package:porcelain_photo_booth/domain/value_objects/calendar_date.dart';
import 'package:porcelain_photo_booth/domain/value_objects/orientation.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_booth_settings_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_event_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_template_catalog.dart';

import '../support/fakes.dart';
import '../support/test_database.dart';

typedef Stack = ({
  BoothDatabase db,
  DriftEventRepository events,
  DriftBoothSettingsRepository booth,
  EventService service,
  FakeClock clock,
});

Stack stackFor(BoothDatabase db, FakeClock clock) {
  final events = DriftEventRepository(db);
  return (
    db: db,
    events: events,
    booth: DriftBoothSettingsRepository(db, clock: clock),
    service: EventService(
      events: events,
      templates: DriftTemplateCatalog(db),
      clock: clock,
      ids: SequentialIds(),
    ),
    clock: clock,
  );
}

/// A fully specified event, for round trips.
BoothEvent sampleEvent(BoothProfile booth, String id, FakeClock clock) =>
    BoothEvent(
      id: id,
      title: 'Garden party',
      date: CalendarDate(2026, 12, 31),
      venue: 'Rose garden',
      notes: 'Power by the gazebo.',
      status: EventStatus.draft,
      boothProfileId: booth.id,
      createdAt: clock.now(),
      updatedAt: clock.now(),
      capture: const CaptureSettings(
        lens: CameraLens.back,
        mirrorPreview: false,
        mirrorOutput: true,
        orientation: GuestOrientationPreference.landscape,
        shotCount: 2,
        countdownSeconds: 7,
        shotIntervalSeconds: 2,
        retakePolicy: RetakePolicy.wholeSession,
        retakeLimit: 3,
      ),
      guest: const GuestSettings(
        welcomeTitle: 'Hello!',
        welcomeMessage: 'Two photos.',
        consentText: 'Kept for the host.',
        guestChoosesTemplate: true,
        finishTimeoutSeconds: 60,
      ),
      experience: const EventExperienceConfiguration(
        packId: 'retro-game-quest',
        variantId: 'arcade',
        countdownPresetId: 'arcade-start',
        soundEnabled: true,
        soundVolume: 40,
        childrenMayBeGuests: true,
      ),
      output: const OutputProfile(format: OutputFormat.png, jpegQuality: 90),
      retention: const RetentionPolicy.deleteAfterDays(14),
      templates: const TemplateSelection(
        revisionIds: [TestIds.revisionB1, TestIds.revisionA1],
        defaultRevisionId: TestIds.revisionA1,
      ),
    );

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('booth_db_test');
  });

  tearDown(() async {
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  test('a new database starts with a default booth, not yet set up', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    final state = await DriftBoothSettingsRepository(
      db,
      clock: FakeClock(),
    ).load();
    expect(state.setupComplete, isFalse);
    expect(state.boothEventId, isNull);
    expect(state.profile.name, BoothProfile.defaultName);
    expect(state.profile.appearance, const AppearanceSettings());
    expect(state.profile.defaults, const EventDefaults());
  });

  test('foreign keys are on, and the file uses a write-ahead log', () async {
    final db = fileDatabase(File('${temp.path}/booth.sqlite'));
    addTearDown(db.close);
    final keys = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(keys.data.values.single, 1);
    final journal = await db.customSelect('PRAGMA journal_mode').getSingle();
    expect(journal.data.values.single, 'wal');
    final synchronous = await db.customSelect('PRAGMA synchronous').getSingle();
    expect(synchronous.data.values.single, 2, reason: 'FULL');
  });

  test('events, settings and setup survive closing and reopening', () async {
    final file = File('${temp.path}/booth.sqlite');
    final clock = FakeClock();
    final first = stackFor(fileDatabase(file, clock: clock), clock);
    await insertTemplate(
      first.db,
      templateId: TestIds.templateA,
      revisionId: TestIds.revisionA1,
    );
    await insertTemplate(
      first.db,
      templateId: TestIds.templateB,
      revisionId: TestIds.revisionB1,
      name: 'Strip',
      slots: 2,
      width: 600,
    );
    final booth = (await first.booth.load()).profile;
    final event = sampleEvent(booth, first.service.newDraft(booth).id, clock);
    final saved = await first.service.save(event);
    final activated = await first.service.activate(saved.id);
    clock.advance(const Duration(minutes: 5));
    final copy = await first.service.duplicate(saved.id, copySuffix: '(copy)');
    final archivedCopy = await first.service.archive(copy.id);
    await first.booth.saveAppearance(
      const AppearanceSettings(
        profile: PorcelainThemeProfile.darkroomWalnut,
        motion: MotionPreference.reduced,
      ),
    );
    await first.booth.renameBooth('  Foyer booth ');
    await first.booth.completeSetup(
      boothName: 'Foyer booth',
      theme: PorcelainThemeProfile.darkroomWalnut,
      recoveryVerifier: 'verifier',
    );
    await first.booth.setBoothEvent(saved.id);
    await first.db.close();

    // A new database object on the same file: what a restart sees.
    final second = stackFor(fileDatabase(file, clock: clock), clock);
    addTearDown(second.db.close);
    final reopened = await second.booth.load();
    expect(reopened.setupComplete, isTrue);
    expect(reopened.boothEventId, saved.id);
    expect(reopened.profile.name, 'Foyer booth');
    expect(
      reopened.profile.appearance.profile,
      PorcelainThemeProfile.darkroomWalnut,
    );
    expect(reopened.profile.appearance.motion, MotionPreference.reduced);

    expect(await second.events.findById(saved.id), activated);
    expect(await second.events.findById(copy.id), archivedCopy);
    final all = await second.events.watchAll().first;
    expect(all.map((e) => e.id), [copy.id, saved.id]);
  });

  group('the schema itself refuses bad data', () {
    late Stack stack;
    late BoothProfile booth;

    setUp(() async {
      final clock = FakeClock();
      stack = stackFor(memoryDatabase(clock: clock), clock);
      booth = (await stack.booth.load()).profile;
      await insertTemplate(
        stack.db,
        templateId: TestIds.templateA,
        revisionId: TestIds.revisionA1,
      );
      await insertTemplate(
        stack.db,
        templateId: TestIds.templateB,
        revisionId: TestIds.revisionB1,
      );
    });

    tearDown(() => stack.db.close());

    BoothEvent valid() =>
        sampleEvent(booth, '00000000-0000-4000-8000-0000000000ee', stack.clock);

    Future<void> expectRefused(BoothEvent event, {String? because}) async {
      await expectLater(
        stack.events.save(event),
        throwsA(isA<PersistenceRuleException>()),
        reason: because,
      );
      expect(
        await stack.events.findById(event.id),
        isNull,
        reason: 'nothing stored',
      );
    }

    test('values outside the event limits', () async {
      final event = valid();
      await expectRefused(event.copyWith(title: '   '), because: 'title');
      await expectRefused(
        event.copyWith(title: 'x' * 81),
        because: 'title length',
      );
      for (final shots in [0, 5]) {
        await expectRefused(
          event.copyWith(capture: event.capture.copyWith(shotCount: shots)),
          because: '$shots shots',
        );
      }
      for (final seconds in [1, 11]) {
        await expectRefused(
          event.copyWith(
            capture: event.capture.copyWith(countdownSeconds: seconds),
          ),
          because: 'countdown $seconds',
        );
      }
      await expectRefused(
        event.copyWith(
          capture: event.capture.copyWith(
            retakePolicy: RetakePolicy.none,
            retakeLimit: 1,
          ),
        ),
        because: 'retake limit without retakes',
      );
      await expectRefused(
        event.copyWith(capture: event.capture.copyWith(retakeLimit: 6)),
        because: 'retake limit',
      );
      await expectRefused(
        event.copyWith(output: const OutputProfile(jpegQuality: 79)),
        because: 'jpeg quality',
      );
      await expectRefused(
        event.copyWith(retention: const RetentionPolicy.deleteAfterDays(0)),
        because: 'retention days',
      );
      await expectRefused(
        event.copyWith(guest: event.guest.copyWith(finishTimeoutSeconds: 9)),
        because: 'finish timeout',
      );
      await expectRefused(
        event.copyWith(guest: event.guest.copyWith(consentText: 'x' * 401)),
        because: 'consent text',
      );
    });

    test('archived status and archive time go together', () async {
      final event = valid();
      await expectRefused(
        event.copyWith(status: EventStatus.archived),
        because: 'archived without a time',
      );
      await expectRefused(
        event.copyWith(archivedAt: stack.clock.now()),
        because: 'a time without archiving',
      );
    });

    test(
      'an event and its templates are saved together or not at all',
      () async {
        final unknown = valid().copyWith(
          templates: const TemplateSelection(
            revisionIds: [TestIds.revisionA1, TestIds.revisionC1],
            defaultRevisionId: TestIds.revisionA1,
          ),
        );
        await expectRefused(unknown, because: 'unknown template revision');
      },
    );

    test('at most one default template per event', () async {
      await stack.events.save(valid());
      await expectLater(
        stack.db.customStatement('UPDATE event_templates SET is_default = 1'),
        throwsA(anything),
      );
    });

    test('a template revision used by an event cannot be deleted; '
        'deleting an event removes only its own links', () async {
      final event = valid();
      await stack.events.save(event);
      await expectLater(
        stack.db.customStatement(
          "DELETE FROM template_revisions WHERE id = '${TestIds.revisionA1}'",
        ),
        throwsA(anything),
      );
      await stack.booth.setBoothEvent(event.id);
      await stack.db.customStatement(
        "DELETE FROM events WHERE id = '${event.id}'",
      );
      final links = await stack.db.select(stack.db.eventTemplates).get();
      expect(links, isEmpty, reason: 'cascade');
      expect(
        (await stack.booth.load()).boothEventId,
        isNull,
        reason: 'Booth Mode cannot point at a deleted event',
      );
      final revisions = await stack.db.select(stack.db.templateRevisions).get();
      expect(revisions, hasLength(2), reason: 'templates untouched');
    });

    test('template revisions are immutable', () async {
      await expectLater(
        stack.db.customStatement(
          'UPDATE template_revisions SET photo_slot_count = 3',
        ),
        throwsA(anything),
      );
      final revision = await (stack.db.select(
        stack.db.templateRevisions,
      )..where((row) => row.id.equals(TestIds.revisionA1))).getSingle();
      expect(revision.photoSlotCount, 2);
    });

    test('manifest paths stay relative and inside managed storage', () async {
      for (final path in ['/etc/passwd', '../outside.json', r'a\b.json']) {
        await expectLater(
          stack.db
              .into(stack.db.templateRevisions)
              .insert(
                TemplateRevisionsCompanion.insert(
                  id: '00000000-0000-4000-8000-00000000ffff',
                  templateId: TestIds.templateA,
                  revisionNumber: 9,
                  documentSchemaVersion: 1,
                  manifestPath: path,
                  checksum: 'b' * 64,
                  pageWidthPx: 1200,
                  pageHeightPx: 1800,
                  photoSlotCount: 2,
                  createdAt: DateTime.utc(2026),
                ),
              ),
          throwsA(anything),
          reason: path,
        );
      }
    });

    test('enumerations only accept known names', () async {
      await stack.events.save(valid());
      for (final statement in [
        "UPDATE events SET status = 'deleted'",
        "UPDATE events SET lens = 'side'",
        "UPDATE events SET experience_json = ''",
        "UPDATE booth_profiles SET theme_profile = '1'",
        'UPDATE booth_profiles SET default_mirror_preview = 2',
      ]) {
        await expectLater(
          stack.db.customStatement(statement),
          throwsA(anything),
          reason: statement,
        );
      }
    });

    test('settings and access tables hold exactly one row', () async {
      await expectLater(
        stack.db.customStatement(
          'INSERT INTO app_settings (id, booth_profile_id) '
          "VALUES (2, '${booth.id}')",
        ),
        throwsA(anything),
      );
      await expectLater(
        stack.db.customStatement('INSERT INTO operator_access (id) VALUES (2)'),
        throwsA(anything),
      );
    });

    test('the booth name is trimmed and limited', () async {
      await expectLater(
        stack.booth.renameBooth('   '),
        throwsA(isA<PersistenceRuleException>()),
      );
      await expectLater(
        stack.booth.renameBooth('x' * 41),
        throwsA(isA<PersistenceRuleException>()),
      );
      await stack.booth.renameBooth('  Lobby  ');
      expect((await stack.booth.load()).profile.name, 'Lobby');
    });
  });

  test('event streams update when an event or its templates change', () async {
    final clock = FakeClock();
    final stack = stackFor(memoryDatabase(clock: clock), clock);
    addTearDown(stack.db.close);
    final booth = (await stack.booth.load()).profile;
    await insertTemplate(
      stack.db,
      templateId: TestIds.templateA,
      revisionId: TestIds.revisionA1,
    );
    final draft = stack.service.newDraft(booth).copyWith(title: 'Gala');
    final emitted = <List<BoothEvent>>[];
    final subscription = stack.events.watchAll().listen(emitted.add);
    addTearDown(subscription.cancel);
    await pumpEventQueue();
    await stack.service.save(draft);
    await pumpEventQueue();
    await stack.service.save(
      draft.copyWith(
        templates: const TemplateSelection().add(TestIds.revisionA1),
      ),
    );
    await pumpEventQueue();
    expect(emitted.first, isEmpty);
    expect(emitted.last.single.templates.revisionIds, [TestIds.revisionA1]);
  });
}
