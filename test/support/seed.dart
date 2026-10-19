import 'dart:io';

import 'package:porcelain_photo_booth/core/templates/starter_designs.dart';
import 'package:porcelain_photo_booth/core/templates/template_library.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/domain/services/event_service.dart';
import 'package:porcelain_photo_booth/domain/template/geometry.dart';
import 'package:porcelain_photo_booth/domain/template/page_spec.dart';
import 'package:porcelain_photo_booth/domain/template/template_assets.dart';
import 'package:porcelain_photo_booth/domain/template/template_document.dart';
import 'package:porcelain_photo_booth/domain/template/template_layers.dart';
import 'package:porcelain_photo_booth/domain/value_objects/appearance.dart';
import 'package:porcelain_photo_booth/domain/value_objects/calendar_date.dart';
import 'package:porcelain_photo_booth/domain/value_objects/orientation.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_booth_settings_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_event_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_template_catalog.dart';

import 'fakes.dart';
import 'memory_template_store.dart';
import 'test_database.dart';

/// Identifiers of the seeded events.
abstract final class SeedIds {
  static const active = '0000000e-0000-4000-8000-0000000000e1';
  static const draft = '0000000e-0000-4000-8000-0000000000e2';
  static const archived = '0000000e-0000-4000-8000-0000000000e3';

  /// The first id a [MemoryTemplateStore] issues: the template made by
  /// [seedStarterLibrary] from Floral Elegance.
  static const floralTemplate = '00000000-0000-4000-b000-000000000001';
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

/// Templates plus an active, a draft and an archived event; [active]
/// adjusts the active event before it is saved and activated.
Future<void> seedEvents(
  BoothDatabase db, {
  FakeClock? clock,
  BoothEvent Function(BoothEvent event)? active,
}) async {
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

  final wedding = base(SeedIds.active, 'Hannah & Theo’s wedding').copyWith(
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
  );
  await service.save(active?.call(wedding) ?? wedding);
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

/// Documents for the seeded templates, so their thumbnails render: the
/// page size and photo count each catalog row records, slots stacked on
/// ivory paper.
Future<void> seedTemplateDocuments(MemoryTemplateStore store) async {
  for (final (templateId, revisionId, name, width, height, slots) in const [
    (TestIds.templateA, TestIds.revisionA1, 'Two-up classic', 1200, 1800, 2),
    (TestIds.templateB, TestIds.revisionB1, 'Retro strip', 600, 1800, 2),
    (TestIds.templateC, TestIds.revisionC1, 'Three-up square', 1200, 1200, 3),
    (
      TestIds.templateD,
      TestIds.revisionD1,
      'Landscape postcard',
      1800,
      1200,
      2,
    ),
  ]) {
    final landscape = width > height;
    final page = PageSpec(
      width: width / 300,
      height: height / 300,
      unit: LengthUnit.inch,
      dpi: 300,
    );
    const margin = 0.06;
    final share = (1 - margin * (slots + 1)) / slots;
    store.templates.seedRevision(
      templateId: templateId,
      revisionId: revisionId,
      name: name,
      document: TemplateDocument(
        page: page,
        layers: [
          const BackgroundLayer(
            id: 'background',
            zIndex: 0,
            fill: SolidFill(ArgbColor(0xFFFBF8F3)),
          ),
          for (var i = 0; i < slots; i++)
            PhotoSlotLayer(
              id: 'photo-${i + 1}',
              zIndex: i + 1,
              slotIndex: i,
              frame: landscape
                  ? NormalizedRect(
                      x: margin + i * (share + margin),
                      y: margin,
                      width: share,
                      height: 1 - margin * 2,
                    )
                  : NormalizedRect(
                      x: margin,
                      y: margin + i * (share + margin),
                      width: 1 - margin * 2,
                      height: share,
                    ),
            ),
        ],
      ),
    );
  }
}

/// The template library of the Template Studio screens: the five
/// reference-board designs, Floral Elegance first (template id
/// [SeedIds.floralTemplate]).
Future<void> seedStarterLibrary(MemoryTemplateStore store) async {
  final library = TemplateLibrary(
    assets: store.assets,
    templates: store.templates,
    packages: store.packages,
    drafts: store.drafts,
    clock: store.clock,
    loadBundled: (path) async => File(path).readAsBytesSync(),
  );
  final designs = [
    for (final design in starterDesigns)
      if (design.id == 'floral-elegance') design,
    for (final design in starterDesigns)
      if (!design.blank && design.id != 'floral-elegance') design,
  ];
  for (final design in designs) {
    final created = await library.create(design, name: design.name);
    if (design.id == 'floral-elegance' &&
        created.templateId != SeedIds.floralTemplate) {
      throw StateError('the memory store issued ${created.templateId}');
    }
  }
}
