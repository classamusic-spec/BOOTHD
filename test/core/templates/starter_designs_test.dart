// AC-0501: new templates start from a blank page in each print format or a
// finished design; every design is a valid document that the store accepts
// and that renders at its print size without warnings.
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/templates/slot_placeholder.dart';
import 'package:porcelain_photo_booth/core/templates/starter_designs.dart';
import 'package:porcelain_photo_booth/domain/repositories/template_store.dart';
import 'package:porcelain_photo_booth/domain/template/editing/editor_geometry.dart';
import 'package:porcelain_photo_booth/domain/template/page_spec.dart';
import 'package:porcelain_photo_booth/domain/template/template_layers.dart';
import 'package:porcelain_photo_booth/infrastructure/composition/dart_ui_composition_renderer.dart';

import '../../support/template_store_harness.dart';

void main() {
  late TemplateStoreHarness harness;

  setUp(() async => harness = await TemplateStoreHarness.create());
  tearDown(() => harness.dispose());

  test('ids are unique and every print format has a blank page', () {
    expect(
      {for (final design in starterDesigns) design.id}.length,
      starterDesigns.length,
    );
    final blanks = starterDesigns.where((design) => design.blank);
    expect(
      {for (final design in blanks) design.page},
      {
        PageSpec.twoBySix,
        PageSpec.fourBySixPortrait,
        PageSpec.fourBySixLandscape,
        PageSpec.fourByFour,
      },
    );
    for (final design in blanks) {
      final document = design.build(const {});
      expect(document.layers.single, isA<BackgroundLayer>());
      expect(design.photoSlots, 0);
    }
  });

  test('the reference board designs are offered (CR-002)', () {
    expect(
      [
        // The packs' own designs (EP04, EP05) aside.
        for (final design in starterDesigns)
          if (!design.blank &&
              !const {'Kid Party', 'Retro Game'}.contains(design.category))
            design.name,
      ],
      [
        'Classic Strip',
        'Floral Elegance',
        'Modern Minimal',
        'Retro Film',
        'Gold Celebration',
      ],
    );
  });

  for (final design in starterDesigns) {
    test(
      '${design.name}: stored, reopened and rendered at print size',
      () async {
        final summary = await harness.library.create(design, name: design.name);
        expect(
          (summary.pageWidthPx, summary.pageHeightPx),
          (design.page.widthPx, design.page.heightPx),
        );
        expect(summary.photoSlotCount, design.photoSlots);

        final stored = await harness.templates.loadRevision(summary.revisionId);
        expect(stored.document.errors, isEmpty);
        expect(stored.category, design.category);
        for (final id in stored.document.assets.keys) {
          expect((await harness.assets.find(id))!.origin, AssetOrigin.bundled);
        }

        final artifact = await DartUiCompositionRenderer().renderExport(
          placeholderRender(stored.document, harness.assets),
        );
        expect(
          (artifact.widthPx, artifact.heightPx),
          (design.page.widthPx, design.page.heightPx),
        );
        expect(artifact.warnings, isEmpty, reason: 'text fits its frames');
      },
    );
  }

  test('Floral Elegance blossoms cross the first photo edge', () async {
    final design = starterDesigns.firstWhere((d) => d.id == 'floral-elegance');
    final summary = await harness.library.create(design, name: design.name);
    final document = (await harness.templates.loadRevision(summary.revisionId))
        .document;
    final page = document.page;
    final slot = LayerGeometry.of(document.photoSlots.first, page).bounds;
    final blossoms = LayerGeometry.of(
      document.layers.firstWhere((layer) => layer.id == 'blossoms-top')
          as ImageLayer,
      page,
    ).bounds;
    // Overlaps the slot, reaches outside it and past the page edge, and
    // paints above it: decorations are never clipped by slots (AC-0404,
    // AC-0510).
    expect(
      blossoms.right > slot.left &&
          blossoms.bottom > slot.top &&
          blossoms.left < slot.left &&
          blossoms.top < slot.top,
      isTrue,
    );
    expect(blossoms.left < 0 && blossoms.top < 0, isTrue);
    final paintOrder = document.paintOrder;
    expect(
      paintOrder.indexWhere((layer) => layer.id == 'blossoms-top'),
      greaterThan(paintOrder.indexOf(document.photoSlots.first)),
    );
  });
}
