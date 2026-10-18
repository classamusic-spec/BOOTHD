import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/template/document_scene.dart';
import 'package:porcelain_photo_booth/domain/template/geometry.dart';
import 'package:porcelain_photo_booth/domain/template/page_spec.dart';
import 'package:porcelain_photo_booth/domain/template/template_document.dart';

TemplateDocument _doc(List<TemplateLayer> layers) => TemplateDocument(
  id: 'test',
  page: PageSpec.fourBySixPortrait,
  backgroundArgb: 0xFFFFFFFF,
  layers: layers,
);

const _frame = NormalizedRect(x: 0.1, y: 0.1, width: 0.5, height: 0.25);
const _photo = SlotBinding(assetId: 'p', sourceSize: PixelSize(1600, 1200));

void main() {
  group('PageSpec', () {
    test('4x6 inch at 300 DPI is 1200x1800 px', () {
      expect(PageSpec.fourBySixPortrait.widthPx, 1200);
      expect(PageSpec.fourBySixPortrait.heightPx, 1800);
    });

    test('millimetres convert through inches', () {
      const a6 = PageSpec(
        width: 105,
        height: 148,
        unit: LengthUnit.millimetre,
        dpi: 300,
      );
      expect((a6.widthPx, a6.heightPx), (1240, 1748));
    });
  });

  group('TemplateDocument.validate', () {
    test('accepts a well-formed document', () {
      expect(
        _doc([
          const PhotoSlotLayer(id: 's', zIndex: 0, frame: _frame, slotIndex: 0),
          const ImageLayer(id: 'i', zIndex: 1, frame: _frame, assetId: 'a'),
        ]).validate(),
        isEmpty,
      );
    });

    test('reports duplicate ids, duplicate slots, bad sizes and opacity', () {
      final problems = _doc([
        const PhotoSlotLayer(id: 'x', zIndex: 0, frame: _frame, slotIndex: 0),
        const PhotoSlotLayer(id: 'x', zIndex: 1, frame: _frame, slotIndex: 0),
        const ImageLayer(
          id: 'y',
          zIndex: 2,
          frame: NormalizedRect(x: 0, y: 0, width: 0, height: 1),
          assetId: 'a',
          opacity: 1.5,
        ),
      ]).validate();
      expect(problems, hasLength(4));
    });
  });

  group('compileScene', () {
    test('converts normalised frames to page pixels, overflow included', () {
      final scene = compileScene(
        _doc([
          const ImageLayer(
            id: 'i',
            zIndex: 0,
            frame: NormalizedRect(x: -0.1, y: 0.9, width: 0.5, height: 0.2),
            assetId: 'a',
          ),
        ]),
        bindings: const {},
      );
      expect(
        scene.nodes.single.rect,
        const PixelRect(left: -120, top: 1620, width: 600, height: 360),
      );
    });

    test('orders by zIndex, keeping document order for ties', () {
      final scene = compileScene(
        _doc([
          const ImageLayer(id: 'top', zIndex: 9, frame: _frame, assetId: 'a'),
          const ImageLayer(id: 'tie-1', zIndex: 3, frame: _frame, assetId: 'a'),
          const PhotoSlotLayer(
            id: 'slot',
            zIndex: 1,
            frame: _frame,
            slotIndex: 0,
          ),
          const ImageLayer(id: 'tie-2', zIndex: 3, frame: _frame, assetId: 'a'),
        ]),
        bindings: const {0: _photo},
      );
      expect(scene.nodes.map((n) => n.layerId), [
        'slot',
        'tie-1',
        'tie-2',
        'top',
      ]);
    });

    test('omits hidden and fully transparent layers', () {
      final scene = compileScene(
        _doc([
          const ImageLayer(
            id: 'hidden',
            zIndex: 0,
            frame: _frame,
            assetId: 'a',
            visible: false,
          ),
          const ImageLayer(
            id: 'clear',
            zIndex: 1,
            frame: _frame,
            assetId: 'a',
            opacity: 0,
          ),
          const ImageLayer(id: 'shown', zIndex: 2, frame: _frame, assetId: 'a'),
        ]),
        bindings: const {},
      );
      expect(scene.nodes.map((n) => n.layerId), ['shown']);
    });

    test('photo slots become photo nodes with a cover crop and radius', () {
      final scene = compileScene(
        _doc([
          const PhotoSlotLayer(
            id: 'slot',
            zIndex: 0,
            frame: NormalizedRect(x: 0.1, y: 0.54, width: 0.8, height: 0.4),
            slotIndex: 0,
            cornerRadius: 40 / 1200,
            rotationDegrees: 90,
          ),
        ]),
        bindings: const {
          0: SlotBinding(assetId: 'b', sourceSize: PixelSize(1200, 1600)),
        },
      );
      final node = scene.nodes.single as PhotoNode;
      expect(node.assetId, 'b');
      expect(node.cornerRadiusPx, closeTo(40, 1e-9));
      expect(node.rotationRadians, closeTo(math.pi / 2, 1e-12));
      expect(node.sourceCrop.left, closeTo(0, 1e-9));
      expect(node.sourceCrop.top, closeTo(350, 1e-9));
      expect(node.sourceCrop.width, closeTo(1200, 1e-9));
      expect(node.sourceCrop.height, closeTo(900, 1e-9));
    });

    test('an unbound slot is a compile error, not a blank photo', () {
      expect(
        () => compileScene(
          _doc([
            const PhotoSlotLayer(
              id: 's',
              zIndex: 0,
              frame: _frame,
              slotIndex: 2,
            ),
          ]),
          bindings: const {},
        ),
        throwsA(isA<SceneCompileException>()),
      );
    });
  });

  group('coverCrop', () {
    test('same aspect ratio uses the whole photo', () {
      expect(
        coverCrop(
          source: const PixelSize(1600, 1200),
          targetWidth: 960,
          targetHeight: 720,
        ),
        const PixelRect(left: 0, top: 0, width: 1600, height: 1200),
      );
    });

    test('a wide slot crops a tall photo around the focal point', () {
      final crop = coverCrop(
        source: const PixelSize(1000, 2000),
        targetWidth: 1000,
        targetHeight: 500,
        focalY: 0.25,
      );
      expect(
        crop,
        const PixelRect(left: 0, top: 250, width: 1000, height: 500),
      );
    });

    test('focal points near an edge clamp the crop inside the photo', () {
      final crop = coverCrop(
        source: const PixelSize(2000, 1000),
        targetWidth: 500,
        targetHeight: 500,
        focalX: 0,
      );
      expect(crop.left, 0);
      expect(crop.width, 1000);
      final right = coverCrop(
        source: const PixelSize(2000, 1000),
        targetWidth: 500,
        targetHeight: 500,
        focalX: 1,
      );
      expect(right.right, 2000);
    });
  });
}
