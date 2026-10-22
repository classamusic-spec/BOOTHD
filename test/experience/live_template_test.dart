// EP06 (AC-EP09, AC-EP13): the live template is the export's own scene,
// split around the slot being taken: layers below it, the live picture,
// layers above it. Photos already taken fill their slots; a slot with an
// image mask is not attempted live and the booth falls back.
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/experience/live_template.dart';
import 'package:porcelain_photo_booth/core/templates/slot_placeholder.dart';
import 'package:porcelain_photo_booth/domain/session/session_shots.dart';
import 'package:porcelain_photo_booth/domain/template/document_scene.dart';
import 'package:porcelain_photo_booth/domain/template/geometry.dart';
import 'package:porcelain_photo_booth/domain/template/template_document.dart';
import 'package:porcelain_photo_booth/domain/template/template_layers.dart';

import '../support/fakes.dart';
import '../support/gallery_seed.dart';
import '../support/memory_template_store.dart';
import '../support/template_builders.dart';

TemplateDocument _document({SlotClip second = const RectClip()}) =>
    sampleDocument(
      assets: const {},
      layers: [
        const BackgroundLayer(id: 'bg', zIndex: 0, fill: SolidFill(ivory)),
        const PhotoSlotLayer(
          id: 'slot-1',
          zIndex: 10,
          slotIndex: 0,
          frame: NormalizedRect(x: 0.1, y: 0.06, width: 0.8, height: 0.4),
        ),
        PhotoSlotLayer(
          id: 'slot-2',
          zIndex: 11,
          slotIndex: 1,
          frame: const NormalizedRect(x: 0.1, y: 0.54, width: 0.8, height: 0.4),
          clip: second,
        ),
        const ShapeLayer(
          id: 'frame',
          zIndex: 40,
          frame: NormalizedRect(x: 0.02, y: 0.02, width: 0.96, height: 0.96),
          shape: ShapeKind.rect,
          stroke: Stroke(widthPt: 4, color: ink),
        ),
      ],
    );

void main() {
  final plan = galleryPlan('event');
  final store = MemoryTemplateStore(clock: FakeClock());
  final reads = <String>[];

  Future<LiveTemplate?> load(
    TemplateDocument document,
    SessionShots shots,
    int shot,
  ) => LiveTemplate.load(
    document: document,
    shots: shots,
    shot: shot,
    assets: store.assets,
    readOriginal: (id) {
      reads.add(id);
      return slotPlaceholderPng();
    },
  );

  testWidgets('the first shot: artwork below and above the live slot', (
    tester,
  ) async {
    final live = (await tester.runAsync(
      () => load(_document(), SessionShots.empty(plan), 0),
    ))!;
    addTearDown(live.dispose);
    final ids = [for (final node in live.scene.nodes) node.layerId];
    final active = live.activeNode;
    expect(ids[active], 'slot-1');
    expect(ids.indexOf('bg'), lessThan(active));
    expect(ids.indexOf('slot-2'), greaterThan(active));
    expect(ids.indexOf('frame'), greaterThan(active), reason: 'drawn over');
    // The slot, in page pixels (4x6 at 300 dpi).
    expect(live.slot.left, closeTo(120, 1));
    expect(live.slot.width, closeTo(960, 1));
    expect(reads, isEmpty, reason: 'nothing taken yet: placeholders');
  });

  testWidgets('the second shot shows the first photo in its slot', (
    tester,
  ) async {
    reads.clear();
    final shots = SessionShots.empty(plan).withPhoto(
      ShotPhoto(
        shot: 0,
        attempt: 1,
        round: 0,
        originalId: 'first',
        capturedAtUtc: DateTime.utc(2026, 11, 14, 18),
      ),
    );
    final live = (await tester.runAsync(() => load(_document(), shots, 1)))!;
    addTearDown(live.dispose);
    expect(live.scene.nodes[live.activeNode].layerId, 'slot-2');
    expect(reads, ['first']);
    final first = live.scene.nodes.whereType<PhotoNode>().first;
    expect(first.layerId, 'slot-1');
  });

  testWidgets('an image-masked slot is not attempted live', (tester) async {
    final masked = _document(second: MaskClip(TestAssets.mask));
    final shots = SessionShots.empty(plan).withPhoto(
      ShotPhoto(
        shot: 0,
        attempt: 1,
        round: 0,
        originalId: 'first',
        capturedAtUtc: DateTime.utc(2026, 11, 14, 18),
      ),
    );
    expect(await tester.runAsync(() => load(masked, shots, 1)), isNull);
  });
}
