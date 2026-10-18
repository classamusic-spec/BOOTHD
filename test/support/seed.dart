import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/domain/services/event_service.dart';
import 'package:porcelain_photo_booth/domain/value_objects/appearance.dart';
import 'package:porcelain_photo_booth/domain/value_objects/calendar_date.dart';
import 'package:porcelain_photo_booth/domain/value_objects/orientation.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_booth_settings_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_event_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_template_catalog.dart';

import 'fakes.dart';
import 'test_database.dart';

/// Identifiers of the seeded events.
abstract final class SeedIds {
  static const active = '0000000e-0000-4000-8000-0000000000e1';
  static const draft = '0000000e-0000-4000-8000-0000000000e2';
  static const archived = '0000000e-0000-4000-8000-0000000000e3';
}

/// Four templates in the library (two-up, strip, three-up square and a
/// landscape postcard).
Future<void> seedTemplates(BoothDatabase db) async {
  await insertTemplate(
    db,
    templateId: TestIds.templateA,
    revisionId: TestIds.revisionA1,
    name: 'Two-up classic',
  );
  await insertTemplate(
    db,
    templateId: TestIds.templateB,
    revisionId: TestIds.revisionB1,
    name: 'Retro strip',
    width: 600,
  );
  await insertTemplate(
    db,
    templateId: TestIds.templateC,
    revisionId: TestIds.revisionC1,
    name: 'Three-up square',
    slots: 3,
    height: 1200,
  );
  await insertTemplate(
    db,
    templateId: TestIds.templateD,
    revisionId: TestIds.revisionD1,
    name: 'Landscape postcard',
    width: 1800,
    height: 1200,
  );
}

/// Templates plus an active, a draft and an archived event.
Future<void> seedEvents(BoothDatabase db, {FakeClock? clock}) async {
  final time = clock ?? FakeClock();
  await seedTemplates(db);
  final booth = (await DriftBoothSettingsRepository(
    db,
    clock: time,
  ).load()).profile;
  final events = DriftEventRepository(db);
  final service = EventService(
    events: events,
    templates: DriftTemplateCatalog(db),
    clock: time,
    ids: SequentialIds(),
  );
  BoothEvent base(String id, String title) =>
      service.newDraft(booth).copyWith(id: id, title: title);

  await service.save(
    base(SeedIds.active, 'Hannah & Theo’s wedding').copyWith(
      date: CalendarDate(2026, 11, 14),
      venue: 'The Orangery',
      capture: const CaptureSettings(
        lens: CameraLens.front,
        mirrorPreview: true,
        mirrorOutput: false,
        orientation: GuestOrientationPreference.portrait,
        shotCount: 2,
      ),
      guest: const GuestSettings(
        welcomeTitle: 'Welcome, friends',
        welcomeMessage: 'Two photos, a little sparkle, and you are done.',
        themeOverride: PorcelainThemeProfile.darkroomWalnut,
      ),
      templates: const TemplateSelection(
        revisionIds: [TestIds.revisionA1, TestIds.revisionB1],
        defaultRevisionId: TestIds.revisionA1,
      ),
    ),
  );
  await service.activate(SeedIds.active);
  time.advance(const Duration(minutes: 1));
  await service.save(
    base(SeedIds.draft, 'Spring fair').copyWith(venue: 'Market hall'),
  );
  time.advance(const Duration(minutes: 1));
  await service.save(
    base(
      SeedIds.archived,
      'Office party',
    ).copyWith(date: CalendarDate(2025, 12, 19)),
  );
  await service.archive(SeedIds.archived);
}
