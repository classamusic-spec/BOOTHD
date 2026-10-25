// UX-P1 (CR-003): the designs a new event can start with are ordered by
// how well they suit the chosen look, never limited by it; blank pages,
// ready-made designs the library already holds and photo counts an event
// cannot take are left out. EventRules.sharedSlotCount lets an event's
// photo count follow its designs.
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/templates/starter_designs.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_configuration.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_registry.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/models/event_rules.dart';
import 'package:porcelain_photo_booth/domain/models/template_revision_summary.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/domain/template/template_tags.dart';
import 'package:porcelain_photo_booth/domain/value_objects/orientation.dart';
import 'package:porcelain_photo_booth/features/events/create/quick_event_designs.dart';

TemplateRevisionSummary _template(
  String id,
  String name, {
  int slots = 2,
  int width = 1200,
  int height = 1800,
  bool archived = false,
  List<String> packs = const [],
}) => TemplateRevisionSummary(
  revisionId: 'r-$id',
  templateId: 't-$id',
  templateName: name,
  revisionNumber: 1,
  pageWidthPx: width,
  pageHeightPx: height,
  photoSlotCount: slots,
  templateArchived: archived,
  tags: TemplateTags(recommendedExperienceIds: packs),
);

BoothEvent _event(List<String> revisionIds) => BoothEvent(
  id: '00000000-0000-4000-8000-000000000001',
  title: 'Event',
  status: EventStatus.draft,
  boothProfileId: 'booth',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  capture: const CaptureSettings(
    lens: CameraLens.front,
    mirrorPreview: true,
    mirrorOutput: false,
    orientation: GuestOrientationPreference.portrait,
  ),
  templates: TemplateSelection(
    revisionIds: revisionIds,
    defaultRevisionId: revisionIds.firstOrNull,
  ),
);

void main() {
  final registry = ExperienceRegistry.bundled;
  final kids = registry.pack('kid-party-arcade')!;
  const kidsConfig = EventExperienceConfiguration(packId: 'kid-party-arcade');

  test('designs made for the look come first; nothing is removed', () {
    final designs = quickDesigns(
      library: [
        _template('a', 'Plain pair'),
        _template('b', 'Party pair', packs: ['kid-party-arcade']),
      ],
      starters: starterDesigns,
      pack: kids,
      config: kidsConfig,
    );
    // The library's own designs first, each group best suited first.
    expect(designs.take(2).map((d) => d.name), ['Party pair', 'Plain pair']);
    final starters = designs.whereType<StarterChoice>().toList();
    expect(designs.skip(2), orderedEquals(starters));
    final scores = <int>[
      for (final design in starters) quickDesignScore(design, kids, kidsConfig),
    ];
    final sorted = [...scores]..sort((a, b) => b.compareTo(a));
    expect(scores, orderedEquals(sorted));
    expect(starters.first.design.tags.recommendedExperienceIds, [
      'kid-party-arcade',
    ]);
    expect(designs.map((d) => d.name), contains('Plain pair'));
    expect(
      designs.whereType<StarterChoice>().map((d) => d.design.id),
      containsAll(['kid-superstar', 'classic-strip', 'retro-film']),
    );
  });

  test('blank pages, archived templates, unusable photo counts and '
      'ready-made designs already in the library are left out', () {
    final classic = starterDesigns.firstWhere((d) => d.id == 'classic-strip');
    final designs = quickDesigns(
      library: [
        _template('old', 'Archived', archived: true),
        _template('many', 'Eight up', slots: 8),
        // Made from Classic Strip: same name, page shape and photos.
        _template(
          'copy',
          'Classic Strip',
          slots: classic.photoSlots,
          width: 600,
          height: 1800,
        ),
      ],
      starters: starterDesigns,
      pack: kids,
      config: kidsConfig,
    );
    final names = designs.map((d) => d.name).toList();
    expect(names, isNot(contains('Archived')));
    expect(names, isNot(contains('Eight up')));
    expect(
      designs.whereType<StarterChoice>().where((d) => d.design.blank),
      isEmpty,
    );
    expect(
      designs.where((d) => d.name == 'Classic Strip'),
      hasLength(1),
      reason: 'the library copy stands in for the ready-made design',
    );
    expect(
      designs.where((d) => d.name == 'Classic Strip').single,
      isA<LibraryDesign>(),
    );
    for (final design in designs) {
      expect(EventLimits.shotCount.contains(design.photoSlots), isTrue);
    }
  });

  test('every occasion starts with a bundled look', () {
    for (final occasion in QuickOccasion.values) {
      expect(registry.pack(occasion.packId), isNotNull, reason: occasion.name);
      expect(occasion.titleHint, startsWith('e.g. '));
    }
  });

  test('an event follows the photo count its designs agree on', () {
    final library = {
      'r-a': _template('a', 'Two', slots: 2),
      'r-b': _template('b', 'Also two', slots: 2),
      'r-c': _template('c', 'Three', slots: 3),
      'r-x': _template('x', 'Too many', slots: 6),
    };
    expect(EventRules.sharedSlotCount(_event([]), library), isNull);
    expect(EventRules.sharedSlotCount(_event(['r-a', 'r-b']), library), 2);
    expect(EventRules.sharedSlotCount(_event(['r-a', 'r-c']), library), isNull);
    expect(
      EventRules.sharedSlotCount(_event(['r-a', 'r-gone']), library),
      isNull,
    );
    expect(
      EventRules.sharedSlotCount(_event(['r-x']), library),
      isNull,
      reason: 'outside the photos an event may take',
    );
  });
}
