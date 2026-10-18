// A-08, AC-0502..AC-0506: document edits, undo and redo with gesture
// coalescing, editor geometry (handles, resize under rotation, rotation
// snapping, hit testing) and snapping. Pure Dart.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/template/editing/document_edits.dart';
import 'package:porcelain_photo_booth/domain/template/editing/edit_history.dart';
import 'package:porcelain_photo_booth/domain/template/editing/editor_geometry.dart';
import 'package:porcelain_photo_booth/domain/template/editing/layer_copy.dart';
import 'package:porcelain_photo_booth/domain/template/editing/snapping.dart';
import 'package:porcelain_photo_booth/domain/template/geometry.dart';
import 'package:porcelain_photo_booth/domain/template/page_spec.dart';
import 'package:porcelain_photo_booth/domain/template/template_assets.dart';
import 'package:porcelain_photo_booth/domain/template/template_document.dart';
import 'package:porcelain_photo_booth/domain/template/template_layers.dart';

import '../../support/template_builders.dart';

TemplateDocument _blank([PageSpec page = PageSpec.fourBySixPortrait]) =>
    TemplateDocument(page: page, layers: const []);

List<String> _order(TemplateDocument d) => [
  for (final layer in d.paintOrder) layer.id,
];

void _expectCanonical(TemplateDocument d) {
  expect(
    [for (final l in d.layers) l.zIndex],
    [for (var i = 0; i < d.layers.length; i++) i],
    reason: 'dense z in paint order',
  );
  expect(
    [for (final s in d.photoSlots) s.slotIndex],
    [for (var i = 0; i < d.photoSlotCount; i++) i],
    reason: 'contiguous slots',
  );
  expect(d.assets.keys.toSet(), d.referencedAssetIds, reason: 'assets in use');
}

void main() {
  var counter = 0;
  String newId() => 'layer-${++counter}';

  group('edits', () {
    test('adding puts layers on top; a background goes to the bottom and '
        'replaces any other', () {
      var d = _blank();
      d = DocumentEdits.add(d, NewLayers.photoSlot(d, 'a'));
      d = DocumentEdits.add(d, NewLayers.text(d, 't'));
      d = DocumentEdits.add(
        d,
        NewLayers.background('bg', const SolidFill(ArgbColor(0xFFFFFFFF))),
      );
      expect(_order(d), ['bg', 'a', 't']);
      d = DocumentEdits.add(
        d,
        NewLayers.background('bg2', const SolidFill(ArgbColor(0xFF000000))),
      );
      expect(_order(d), ['bg2', 'a', 't']);
      _expectCanonical(d);
      expect(d.errors, isEmpty);
    });

    test('slots are numbered in order, at most eight', () {
      var d = _blank();
      for (var i = 0; i < PhotoSlotLayer.maxSlots; i++) {
        d = DocumentEdits.add(d, NewLayers.photoSlot(d, 's$i'));
      }
      expect(
        [for (final s in d.photoSlots) s.name],
        [for (var i = 1; i <= 8; i++) 'Photo $i'],
      );
      expect(
        () => DocumentEdits.add(d, NewLayers.photoSlot(d, 'nine')),
        throwsA(
          isA<EditRefused>().having(
            (e) => e.reason,
            'reason',
            EditRefusal.tooManySlots,
          ),
        ),
      );
    });

    test('removing renumbers slots and drops assets nobody uses', () {
      var d = _blank();
      d = DocumentEdits.add(d, NewLayers.photoSlot(d, 'a'));
      d = DocumentEdits.add(d, NewLayers.photoSlot(d, 'b'));
      d = DocumentEdits.add(d, NewLayers.photoSlot(d, 'c'));
      d = DocumentEdits.add(
        d,
        NewLayers.image(d, 'flower', TestAssets.flower, TestAssets.png),
        assets: {TestAssets.flower: TestAssets.png},
      );
      expect(d.assets.keys, [TestAssets.flower]);
      d = DocumentEdits.remove(d, {'b', 'flower'});
      expect(
        {for (final s in d.photoSlots) s.id: s.slotIndex},
        {'a': 0, 'c': 1},
      );
      expect(d.assets, isEmpty);
      _expectCanonical(d);
    });

    test('duplicates sit just above their originals, moved and unlocked, '
        'slots taking the next numbers', () {
      var d = _blank();
      d = DocumentEdits.add(d, NewLayers.photoSlot(d, 'a'));
      d = DocumentEdits.add(d, NewLayers.text(d, 't'));
      d = DocumentEdits.update(d, 'a', (l) => copyLayer(l, locked: true));
      final (copied, ids) = DocumentEdits.duplicate(d, ['a'], newId: newId);
      final copy =
          DocumentEdits.layerById(copied, ids.single) as PhotoSlotLayer;
      expect(_order(copied), ['a', ids.single, 't']);
      expect(copy.slotIndex, 1);
      expect(copy.locked, isFalse);
      expect(copy.name, 'Photo 1 copy');
      final original = DocumentEdits.layerById(copied, 'a') as PhotoSlotLayer;
      expect(copy.frame.x, closeTo(original.frame.x + 0.02, 1e-9));
      expect(copy.frame.y, closeTo(original.frame.y + 0.02, 1e-9));
      _expectCanonical(copied);
    });

    test('ordering: forward, backward, front, back; the background stays '
        'at the bottom', () {
      var d = _blank();
      d = DocumentEdits.add(
        d,
        NewLayers.background('bg', const SolidFill(ArgbColor(0xFFFFFFFF))),
      );
      for (final id in ['a', 'b', 'c']) {
        d = DocumentEdits.add(d, NewLayers.shape(d, id, ShapeKind.rect));
      }
      expect(_order(d), ['bg', 'a', 'b', 'c']);
      d = DocumentEdits.bringForward(d, 'a');
      expect(_order(d), ['bg', 'b', 'a', 'c']);
      d = DocumentEdits.bringToFront(d, 'b');
      expect(_order(d), ['bg', 'a', 'c', 'b']);
      d = DocumentEdits.sendToBack(d, 'b');
      expect(_order(d), [
        'bg',
        'b',
        'a',
        'c',
      ], reason: 'never below the background');
      d = DocumentEdits.sendBackward(d, 'c');
      expect(_order(d), ['bg', 'b', 'c', 'a']);
      expect(
        () => DocumentEdits.bringForward(d, 'bg'),
        throwsA(isA<EditRefused>()),
      );
      _expectCanonical(d);
    });

    test('a slot can take another number; the two swap', () {
      var d = _blank();
      for (final id in ['a', 'b', 'c']) {
        d = DocumentEdits.add(d, NewLayers.photoSlot(d, id));
      }
      d = DocumentEdits.renumberSlot(d, 'c', 0);
      expect(
        {for (final s in d.photoSlots) s.id: s.slotIndex},
        {'c': 0, 'b': 1, 'a': 2},
      );
    });

    test('translate moves only the chosen framed layers', () {
      var d = _blank();
      d = DocumentEdits.add(d, NewLayers.photoSlot(d, 'a'));
      d = DocumentEdits.add(d, NewLayers.text(d, 't'));
      final before = DocumentEdits.layerById(d, 't') as FramedLayer;
      d = DocumentEdits.translate(d, {'a'}, 0.1, -0.05);
      final a = DocumentEdits.layerById(d, 'a') as FramedLayer;
      expect(a.frame.x, closeTo(0.1 + 0.1, 1e-9));
      expect(
        (DocumentEdits.layerById(d, 't') as FramedLayer).frame,
        before.frame,
      );
    });

    test('new layers have sensible frames', () {
      final strip = _blank(PageSpec.twoBySix);
      final slot = NewLayers.photoSlot(strip, 's');
      final px = slot.frame.toPixels(pageWidthPx: 600, pageHeightPx: 1800);
      expect(px.width / px.height, closeTo(4 / 3, 1e-9));
      expect(px.width, closeTo(480, 1e-9));
      final image = NewLayers.image(
        strip,
        'i',
        TestAssets.flower,
        const TemplateAsset(
          mediaType: AssetMediaType.png,
          byteLength: 10,
          widthPx: 400,
          heightPx: 200,
        ),
      );
      final ipx = image.frame.toPixels(pageWidthPx: 600, pageHeightPx: 1800);
      expect(ipx.width / ipx.height, closeTo(2, 1e-9));
      expect(DocumentEdits.add(strip, slot).errors, isEmpty);
    });
  });

  group('history', () {
    final a = _blank();
    final b = DocumentEdits.add(a, NewLayers.photoSlot(a, 'a'));
    final c = DocumentEdits.add(b, NewLayers.text(b, 't'));

    test('commit, undo, redo; a new edit clears redo', () {
      final h = EditHistory(a)
        ..commit(b)
        ..commit(c);
      expect(h.current, c);
      expect(h.undo(), b);
      expect(h.undo(), a);
      expect(h.canUndo, isFalse);
      expect(h.redo(), b);
      h.commit(c);
      expect(h.canRedo, isFalse);
    });

    test('a gesture is one step, however many updates it makes', () {
      final h = EditHistory(a)..beginGesture();
      var d = b;
      for (var i = 0; i < 50; i++) {
        d = DocumentEdits.translate(d, {'a'}, 0.001, 0);
        h.commit(d);
      }
      expect(h.canUndo, isFalse, reason: 'no undo mid-gesture');
      h.endGesture();
      expect(h.current, d);
      expect(h.undo(), a);
      expect(h.canUndo, isFalse);
    });

    test('a cancelled gesture leaves no trace', () {
      final h = EditHistory(a)
        ..beginGesture()
        ..commit(b)
        ..cancelGesture();
      expect(h.current, a);
      expect(h.canUndo, isFalse);
    });

    test('history is capped; unsaved changes follow the saved document', () {
      final h = EditHistory(a, limit: 3);
      var d = b;
      for (var i = 0; i < 10; i++) {
        d = DocumentEdits.translate(d, {'a'}, 0.01, 0);
        h.commit(d);
      }
      var steps = 0;
      while (h.undo() != null) {
        steps++;
      }
      expect(steps, 3);
      h.markSaved();
      expect(h.hasUnsavedChanges, isFalse);
      h.redo();
      expect(h.hasUnsavedChanges, isTrue);
      h.undo();
      expect(h.hasUnsavedChanges, isFalse);
    });
  });

  group('geometry', () {
    const page = PageSpec.fourBySixPortrait; // 1200 x 1800

    test('hit testing respects rotation, visibility and paint order', () {
      var d = _blank();
      d = DocumentEdits.add(
        d,
        const ShapeLayer(
          id: 'below',
          zIndex: 0,
          frame: NormalizedRect(x: 0, y: 0, width: 1, height: 1),
          shape: ShapeKind.rect,
          fill: ArgbColor(0xFF000000),
        ),
      );
      d = DocumentEdits.add(
        d,
        const ShapeLayer(
          id: 'thin',
          zIndex: 0,
          // 600 x 60 px centred, turned 90°: now 60 wide and 600 tall.
          frame: NormalizedRect(
            x: 0.25,
            y: 0.48333,
            width: 0.5,
            height: 1 / 30,
          ),
          rotationDegrees: 90,
          shape: ShapeKind.rect,
          fill: ArgbColor(0xFF000000),
        ),
      );
      expect(layerAt(d, const PixelPoint(600, 700)), 'thin');
      expect(layerAt(d, const PixelPoint(850, 900)), 'below');
      d = DocumentEdits.update(d, 'thin', (l) => copyLayer(l, visible: false));
      expect(layerAt(d, const PixelPoint(600, 700)), 'below');
      d = DocumentEdits.update(d, 'below', (l) => copyLayer(l, locked: true));
      expect(
        layerAt(d, const PixelPoint(600, 700), includeLocked: false),
        isNull,
      );
    });

    for (final degrees in [0.0, 30.0, -135.0]) {
      test('resizing at $degrees° keeps the opposite corner in place', () {
        final g = LayerGeometry(
          rect: const PixelRect(left: 300, top: 400, width: 400, height: 300),
          rotationDegrees: degrees,
        );
        for (final handle in HandleKind.values) {
          final opposite = HandleKind.values.firstWhere(
            (h) => h.sx == -handle.sx && h.sy == -handle.sy,
          );
          final fixedBefore = g.handle(opposite);
          // Drag the handle 50 px outwards along the frame's own axes.
          final out = g.toPage(
            PixelPoint(
              g.rect.centerX + handle.sx * (g.rect.width / 2 + 50),
              g.rect.centerY + handle.sy * (g.rect.height / 2 + 50),
            ),
          );
          final r = g.resized(handle, out);
          final fixedAfter = r.handle(opposite);
          expect(fixedAfter.x, closeTo(fixedBefore.x, 1e-6), reason: '$handle');
          expect(fixedAfter.y, closeTo(fixedBefore.y, 1e-6), reason: '$handle');
          expect(r.rect.width, closeTo(400 + (handle.sx == 0 ? 0 : 50), 1e-6));
          expect(r.rect.height, closeTo(300 + (handle.sy == 0 ? 0 : 50), 1e-6));
          expect(r.rotationDegrees, degrees);
        }
      });
    }

    test('corner resize can keep the aspect ratio; sizes never collapse', () {
      const g = LayerGeometry(
        rect: PixelRect(left: 0, top: 0, width: 400, height: 200),
      );
      final r = g.resized(
        HandleKind.bottomRight,
        const PixelPoint(800, 250),
        keepAspect: true,
      );
      expect(r.rect.width / r.rect.height, closeTo(2, 1e-9));
      expect(r.rect.width, closeTo(800, 1e-9));
      final tiny = g.resized(HandleKind.right, const PixelPoint(-500, 100));
      expect(tiny.rect.width, 4);
      expect(tiny.rect.left, 0);
    });

    test('rotation follows the pointer about the pivot and snaps', () {
      const g = LayerGeometry(
        rect: PixelRect(left: 500, top: 800, width: 200, height: 200),
      );
      final pivot = g.pivot;
      PixelPoint at(double degrees) {
        final r = (degrees - 90) * math.pi / 180;
        return PixelPoint(
          pivot.x + 300 * math.cos(r),
          pivot.y + 300 * math.sin(r),
        );
      }

      final start = at(0);
      expect(g.rotatedTo(start, at(37)), closeTo(37, 1e-9));
      expect(g.rotatedTo(start, at(88)), closeTo(90, 1e-9), reason: 'snapped');
      expect(g.rotatedTo(start, at(-100)), closeTo(-100, 1e-9));
      expect(g.rotatedTo(start, at(200)), closeTo(-160, 1e-9));
      expect(normalizeDegrees(540), 180);
      expect(normalizeDegrees(-180), 180);
    });

    test('a frame converts to the page and back exactly', () {
      final g = LayerGeometry.of(
        const ShapeLayer(
          id: 's',
          zIndex: 0,
          frame: NormalizedRect(x: -0.1, y: 0.25, width: 0.5, height: 0.2),
          shape: ShapeKind.rect,
        ),
        page,
      );
      expect(
        g.rect,
        const PixelRect(left: -120, top: 450, width: 600, height: 360),
      );
      expect(
        g.frameOn(page),
        const NormalizedRect(x: -0.1, y: 0.25, width: 0.5, height: 0.2),
      );
    });
  });

  group('snapping', () {
    final d = DocumentEdits.add(
      _blank(),
      const ShapeLayer(
        id: 'other',
        zIndex: 0,
        frame: NormalizedRect(x: 0.1, y: 0.1, width: 0.2, height: 0.1),
        shape: ShapeKind.rect,
      ),
    );

    test('to the page centre, within the threshold only', () {
      final targets = SnapTargets.of(d, exclude: {'moving'});
      const box = PixelRect(left: 497, top: 1000, width: 200, height: 100);
      final near = snapBox(box, targets, 8);
      expect(near.dx, closeTo(3, 1e-9), reason: 'its centre to x = 600');
      expect(near.guides, contains(const SnapGuide(GuideAxis.vertical, 600)));
      const far = PixelRect(left: 470, top: 1000, width: 200, height: 100);
      expect(snapBox(far, targets, 8).dx, 0);
    });

    test("to another layer's edge", () {
      final targets = SnapTargets.of(d);
      // The other layer spans x 120..360, y 180..360.
      const box = PixelRect(left: 365, top: 700, width: 100, height: 100);
      final result = snapBox(box, targets, 8);
      expect(result.dx, closeTo(-5, 1e-9));
      expect(result.guides.single, const SnapGuide(GuideAxis.vertical, 360));
    });

    test('to a grid, and one edge at a time while resizing', () {
      final targets = SnapTargets.of(d, gridSpacing: 50);
      const box = PixelRect(left: 1003, top: 1046, width: 41, height: 41);
      final result = snapBox(box, targets, 8);
      expect(result.dx, closeTo(-3, 1e-9));
      expect(result.dy, closeTo(4, 1e-9));
      final (delta, guide) = snapEdge(1203, GuideAxis.vertical, targets, 8);
      expect(delta, closeTo(-3, 1e-9));
      expect(guide, const SnapGuide(GuideAxis.vertical, 1200));
    });
  });
}
