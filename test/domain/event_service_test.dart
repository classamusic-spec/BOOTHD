// AC-0302, AC-0303: event create, edit, duplicate, archive and reopen, and
// the lifecycle rules, against the real repositories.
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_registry.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/models/booth_profile.dart';
import 'package:porcelain_photo_booth/domain/models/event_rules.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/domain/services/event_service.dart';
import 'package:porcelain_photo_booth/domain/value_objects/appearance.dart';
import 'package:porcelain_photo_booth/domain/value_objects/orientation.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_booth_settings_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_event_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_template_catalog.dart';

import '../support/fakes.dart';
import '../support/test_database.dart';

void main() {
  late BoothDatabase db;
  late FakeClock clock;
  late EventService service;
  late DriftEventRepository events;
  late BoothProfile booth;

  setUp(() async {
    clock = FakeClock();
    db = memoryDatabase(clock: clock);
    events = DriftEventRepository(db);
    service = EventService(
      events: events,
      templates: DriftTemplateCatalog(db),
      clock: clock,
      ids: SequentialIds(),
    );
    booth = (await DriftBoothSettingsRepository(
      db,
      clock: clock,
    ).load()).profile;
    await insertTemplate(
      db,
      templateId: TestIds.templateA,
      revisionId: TestIds.revisionA1,
    );
  });

  tearDown(() => db.close());

  Future<BoothEvent> savedDraft({String title = 'Gala'}) =>
      service.save(service.newDraft(booth).copyWith(title: title));

  test('a new draft starts from the booth defaults', () async {
    await DriftBoothSettingsRepository(db, clock: clock).saveEventDefaults(
      const EventDefaults(
        lens: CameraLens.back,
        mirrorPreview: false,
        mirrorOutput: true,
        orientation: GuestOrientationPreference.landscape,
        output: OutputProfile(format: OutputFormat.png),
      ),
    );
    booth = (await DriftBoothSettingsRepository(
      db,
      clock: clock,
    ).load()).profile;
    final draft = service.newDraft(booth);
    expect(draft.status, EventStatus.draft);
    expect(draft.capture.lens, CameraLens.back);
    expect(draft.capture.mirrorPreview, isFalse);
    expect(draft.capture.mirrorOutput, isTrue);
    expect(draft.capture.orientation, GuestOrientationPreference.landscape);
    expect(draft.output.format, OutputFormat.png);
    expect(await events.findById(draft.id), isNull, reason: 'not saved yet');
  });

  test(
    'save keeps creation time, stamps the update and trims the title',
    () async {
      final draft = await savedDraft(title: '  Gala  ');
      expect(draft.title, 'Gala');
      clock.advance(const Duration(hours: 1));
      final edited = await service.save(
        draft.copyWith(venue: 'Hall', status: EventStatus.active),
      );
      expect(edited.status, EventStatus.draft, reason: 'save never activates');
      expect(edited.createdAt, draft.createdAt);
      expect(edited.updatedAt, clock.now());
      expect(await events.findById(draft.id), edited);
    },
  );

  // EP01: guests keep the booth's look until the operator picks a pack,
  // and every change to the experience moves its revision on.
  test('a new draft takes the booth look; experience changes are '
      'counted', () async {
    for (final profile in PorcelainThemeProfile.values) {
      final draft = service.newDraft(
        BoothProfile(
          id: booth.id,
          name: booth.name,
          createdAt: booth.createdAt,
          updatedAt: booth.updatedAt,
          appearance: AppearanceSettings(profile: profile),
        ),
      );
      expect(
        draft.experience,
        ExperienceRegistry.forAppearance(profile),
        reason: profile.name,
      );
    }
    final first = await savedDraft();
    expect(first.experience.revision, 1);
    final retitled = await service.save(first.copyWith(title: 'Gala night'));
    expect(retitled.experience.revision, 1, reason: 'experience unchanged');
    final changed = await service.save(
      retitled.copyWith(
        experience: retitled.experience.switchPack('disco-nights', 1),
      ),
    );
    expect(changed.experience.revision, 2);
    expect(
      (await events.findById(first.id))!.experience.packId,
      'disco-nights',
    );
    // A stale copy cannot move the count backwards.
    final again = await service.save(
      changed.copyWith(
        experience: changed.experience.copyWith(
          soundEnabled: true,
          revision: 1,
        ),
      ),
    );
    expect(again.experience.revision, 3);
  });

  test('invalid settings are refused before anything is stored', () async {
    final draft = service.newDraft(booth);
    await expectLater(
      service.save(draft),
      throwsA(
        isA<EventRuleException>().having((e) => e.issues, 'issues', [
          const TitleRequired(),
        ]),
      ),
    );
    expect(await events.findById(draft.id), isNull);
  });

  test('activation needs a valid template; a draft without one stays a '
      'draft', () async {
    final draft = await savedDraft();
    await expectLater(
      service.activate(draft.id),
      throwsA(
        isA<EventRuleException>().having((e) => e.issues, 'issues', [
          const NoTemplates(),
        ]),
      ),
    );
    expect((await events.findById(draft.id))!.status, EventStatus.draft);

    final withTemplate = await service.save(
      draft.copyWith(
        capture: draft.capture.copyWith(shotCount: 2),
        templates: const TemplateSelection().add(TestIds.revisionA1),
      ),
    );
    final active = await service.activate(withTemplate.id);
    expect(active.status, EventStatus.active);
  });

  test('an active event cannot be saved into an invalid state', () async {
    final draft = await savedDraft();
    await service.save(
      draft.copyWith(
        capture: draft.capture.copyWith(shotCount: 2),
        templates: const TemplateSelection().add(TestIds.revisionA1),
      ),
    );
    final active = await service.activate(draft.id);
    await expectLater(
      service.save(
        active.copyWith(capture: active.capture.copyWith(shotCount: 3)),
      ),
      throwsA(isA<EventRuleException>()),
    );
    final back = await service.returnToDraft(active.id);
    expect(back.status, EventStatus.draft);
    final edited = await service.save(
      back.copyWith(capture: back.capture.copyWith(shotCount: 3)),
    );
    expect(edited.capture.shotCount, 3);
  });

  test('duplicate copies settings and templates as a new draft', () async {
    final draft = await savedDraft(title: 'Summer ball');
    final source = await service.save(
      draft.copyWith(
        venue: 'Terrace',
        capture: draft.capture.copyWith(shotCount: 2, countdownSeconds: 5),
        templates: const TemplateSelection().add(TestIds.revisionA1),
      ),
    );
    await service.activate(source.id);
    clock.advance(const Duration(minutes: 1));
    final copy = await service.duplicate(source.id, copySuffix: '(copy)');
    expect(copy.id, isNot(source.id));
    expect(copy.title, 'Summer ball (copy)');
    expect(copy.status, EventStatus.draft);
    expect(copy.venue, 'Terrace');
    expect(copy.capture, source.capture);
    expect(copy.templates, source.templates);
    expect(copy.createdAt, clock.now());
    expect((await events.findById(source.id))!.status, EventStatus.active);
  });

  test('a duplicate of a long title still fits', () async {
    final source = await savedDraft(title: 'x' * EventLimits.titleMaxLength);
    final copy = await service.duplicate(source.id, copySuffix: '(copy)');
    expect(copy.title.length, lessThanOrEqualTo(EventLimits.titleMaxLength));
    expect(copy.title, endsWith('(copy)'));
  });

  test('archive keeps the event; reopening returns it as a draft', () async {
    final draft = await savedDraft();
    final archived = await service.archive(draft.id);
    expect(archived.status, EventStatus.archived);
    expect(archived.archivedAt, clock.now());
    await expectLater(
      service.save(archived.copyWith(title: 'Edited')),
      throwsA(isA<EventLifecycleException>()),
      reason: 'archived events are read-only until reopened',
    );
    await expectLater(
      service.archive(draft.id),
      throwsA(isA<EventLifecycleException>()),
    );
    final reopened = await service.reopen(draft.id);
    expect(reopened.status, EventStatus.draft);
    expect(reopened.archivedAt, isNull);
    expect(reopened.title, 'Gala');
  });

  test('lifecycle changes from the wrong state are refused', () async {
    final draft = await savedDraft();
    await expectLater(
      service.returnToDraft(draft.id),
      throwsA(isA<EventLifecycleException>()),
    );
    await expectLater(
      service.reopen(draft.id),
      throwsA(isA<EventLifecycleException>()),
    );
    await expectLater(
      service.activate('00000000-0000-4000-8000-00000000dead'),
      throwsA(isA<EventNotFoundException>()),
    );
  });
}
