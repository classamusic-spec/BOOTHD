// M05 stress: a template of 30 layers of every kind (photo spaces, text,
// shapes, transparent PNG decorations, background) takes 150 random edits
// through the editor (moves, resizes, rotations, opacity, reorders,
// visibility, locks, renames, duplicates, deletions) and stays valid after
// every one; undo walks back its 100 kept steps exactly and redo forward;
// the result saves, reopens equal and editable, renders at 300 dpi with
// every layer, and the Template Studio lists all of its layers.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/routing/route_paths.dart';
import 'package:porcelain_photo_booth/core/templates/bundled_decorations.dart';
import 'package:porcelain_photo_booth/core/templates/slot_placeholder.dart';
import 'package:porcelain_photo_booth/core/templates/starter_designs.dart';
import 'package:porcelain_photo_booth/core/templates/template_library.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/template/editing/document_edits.dart';
import 'package:porcelain_photo_booth/domain/template/editing/edit_history.dart';
import 'package:porcelain_photo_booth/domain/template/editing/layer_copy.dart';
import 'package:porcelain_photo_booth/domain/template/geometry.dart';
import 'package:porcelain_photo_booth/domain/template/template_layers.dart';
import 'package:porcelain_photo_booth/features/template_studio/editor_canvas.dart';
import 'package:porcelain_photo_booth/features/template_studio/editor_controller.dart';
import 'package:porcelain_photo_booth/features/template_studio/layers_panel.dart';
import 'package:porcelain_photo_booth/infrastructure/composition/dart_ui_composition_renderer.dart';

import '../support/app_harness.dart';
import '../support/fakes.dart';
import '../support/memory_template_store.dart';
import '../support/tablet_viewports.dart';

const _layerCount = 30;

TemplateLibrary _library(MemoryTemplateStore store) => TemplateLibrary(
  assets: store.assets,
  templates: store.templates,
  packages: store.packages,
  drafts: store.drafts,
  clock: store.clock,
  loadBundled: (path) async => File(path).readAsBytesSync(),
);

/// A 4x6 template with [_layerCount] layers, saved as its revision 2;
/// returns its id.
Future<String> _stressTemplate(MemoryTemplateStore store) async {
  final library = _library(store);
  final created = await library.create(
    starterDesigns.firstWhere((d) => d.id == 'blank-4x6'),
    name: 'Thirty layers',
  );
  final opened = await library.open(created.templateId);
  final controller = TemplateEditorController(
    library: library,
    assets: store.assets,
    revision: opened.revision,
  );
  for (var i = 0; i < 6; i++) {
    controller.addPhotoSlot();
  }
  for (var i = 0; i < 8; i++) {
    controller.addText();
  }
  for (var i = 0; i < 7; i++) {
    controller.addShape(ShapeKind.values[i % ShapeKind.values.length]);
  }
  for (final (i, decoration) in [
    ...bundledDecorations,
    ...bundledDecorations,
  ].take(8).indexed) {
    final stored = await library.storeDecoration(decoration);
    controller.apply(
      (document) => DocumentEdits.add(
        document,
        NewLayers.image(document, 'art-$i', stored.id, stored.asset),
        assets: {stored.id: stored.asset},
      ),
    );
  }
  expect(controller.document.layers, hasLength(_layerCount));
  await controller.save();
  controller.dispose();
  return created.templateId;
}

/// One random edit through [controller], as the canvas, inspector and
/// layers panel make them. Returns whether the document changed.
bool _randomEdit(TemplateEditorController controller, math.Random random) {
  final document = controller.document;
  final framed = document.layers.whereType<FramedLayer>().toList();
  final layer = framed[random.nextInt(framed.length)];
  final before = controller.document;
  double jitter(double by) => (random.nextDouble() - 0.5) * by;
  try {
    switch (random.nextInt(11)) {
      case 0: // A drag: many steps, one undo step.
        controller.beginGesture();
        for (var step = 0; step < 6; step++) {
          controller.updateGesture(
            DocumentEdits.translate(
              controller.document,
              {layer.id},
              jitter(0.04),
              jitter(0.04),
            ),
          );
        }
        controller.endGesture();
      case 1: // Resize.
        controller.updateLayer(
          layer.id,
          (l) => copyLayer(
            l,
            frame: NormalizedRect(
              x: (l as FramedLayer).frame.x,
              y: l.frame.y,
              width: (l.frame.width * (0.8 + random.nextDouble() * 0.4)).clamp(
                0.02,
                1.5,
              ),
              height: (l.frame.height * (0.8 + random.nextDouble() * 0.4))
                  .clamp(0.02, 1.5),
            ),
          ),
        );
      case 2: // A rotation gesture.
        controller.beginGesture();
        for (var step = 1; step <= 4; step++) {
          controller.updateLayerInGesture(
            layer.id,
            (l) => copyLayer(
              l,
              rotationDegrees: ((l as FramedLayer).rotationDegrees + 7.5)
                  .remainder(360),
            ),
          );
        }
        controller.endGesture();
      case 3: // The opacity slider.
        controller.beginGesture();
        controller.updateLayerInGesture(
          layer.id,
          (l) => copyLayer(l, opacity: 0.3 + random.nextDouble() * 0.7),
        );
        controller.endGesture();
      case 4:
        controller.bringForward(layer.id);
      case 5:
        controller.sendBackward(layer.id);
      case 6:
        controller.moveLayer(layer.id, random.nextInt(document.layers.length));
      case 7:
        controller.setVisible(layer.id, visible: !layer.visible);
      case 8:
        controller.setLocked(layer.id, locked: !layer.locked);
      case 9:
        controller.renameLayer(layer.id, 'Layer ${random.nextInt(1000)}');
      case 10: // Duplicate or delete, keeping between 24 and 40 layers.
        controller.select(layer.id);
        final count = document.layers.length;
        final canCopy =
            layer is! PhotoSlotLayer ||
            document.photoSlotCount < PhotoSlotLayer.maxSlots;
        if ((count < 40 && random.nextBool() && canCopy) || count <= 24) {
          if (canCopy) controller.duplicateSelected();
        } else {
          controller.deleteSelected();
        }
    }
  } on EditRefused {
    // A refusal (a locked layer, the top already reached) changes nothing.
    expect(controller.document, before);
  }
  return !identical(controller.document, before);
}

void main() {
  testWidgets('150 random edits on 30 layers stay valid, undo and redo '
      'exactly, and save and reopen equal', (tester) async {
    final store = MemoryTemplateStore(clock: FakeClock());
    final templateId = await _stressTemplate(store);
    final library = _library(store);
    final opened = await library.open(templateId);
    final controller = TemplateEditorController(
      library: library,
      assets: store.assets,
      revision: opened.revision,
    );
    addTearDown(controller.dispose);

    final random = math.Random(5);
    final states = [controller.document];
    var refused = 0;
    for (var i = 0; i < 150; i++) {
      if (_randomEdit(controller, random)) {
        states.add(controller.document);
      } else {
        refused++;
      }
      final errors = controller.document.errors;
      expect(errors, isEmpty, reason: 'after edit $i: $errors');
      expect(controller.document.layers.length, greaterThanOrEqualTo(24));
    }
    // ignore: avoid_print
    print(
      'stress: ${states.length - 1} edits applied, $refused refused, '
      '${controller.document.layers.length} layers at the end',
    );
    expect(states.length - 1, greaterThan(EditHistory(states.first).limit));

    // Undo walks back the kept steps exactly, then stops.
    final kept = math.min(states.length - 1, controller.history.limit);
    for (var i = 1; i <= kept; i++) {
      controller.undo();
      expect(controller.document, states[states.length - 1 - i]);
    }
    expect(controller.canUndo, isFalse);
    for (var i = kept - 1; i >= 0; i--) {
      controller.redo();
      expect(controller.document, states[states.length - 1 - i]);
    }
    expect(controller.canRedo, isFalse);

    // Saved and reopened: equal, and still editable.
    await controller.save();
    final reopened = await library.open(templateId);
    expect(reopened.draft, isNull);
    expect(reopened.revision.document, states.last);
    final again = TemplateEditorController(
      library: library,
      assets: store.assets,
      revision: reopened.revision,
    );
    addTearDown(again.dispose);
    final first = again.document.layers.whereType<FramedLayer>().firstWhere(
      (l) => !l.locked,
    );
    again
      ..select(first.id)
      ..nudge(10, 10);
    expect(again.hasUnsavedChanges, isTrue);
    again.undo();
    expect(again.document, states.last);
  });

  testWidgets('the 30-layer template renders at 300 dpi with every layer', (
    tester,
  ) async {
    final store = MemoryTemplateStore(clock: FakeClock());
    final templateId = await _stressTemplate(store);
    final document = (await store.templates.loadLatest(templateId)).document;
    final export = (await tester.runAsync(() async {
      final renderer = DartUiCompositionRenderer();
      return renderer.renderExport(
        placeholderRender(document, store.assets),
        output: const OutputProfile(format: OutputFormat.png),
        includePixels: true,
      );
    }))!;
    // ignore: avoid_print
    print(
      'stress render: ${export.widthPx}x${export.heightPx}, '
      'paint ${export.stats.paint.inMilliseconds} ms, '
      'encode ${export.stats.encode.inMilliseconds} ms, '
      '${export.warnings.length} warning(s)',
    );
    expect((export.widthPx, export.heightPx), (1200, 1800));
    // Not a blank page: many colours from the artwork, text and shapes.
    final colours = <int>{};
    final rgba = export.rgba!;
    for (var i = 0; i < rgba.length; i += 4 * 97) {
      colours.add(rgba[i] << 16 | rgba[i + 1] << 8 | rgba[i + 2]);
    }
    expect(colours.length, greaterThan(50));
  });

  testWidgets('the Template Studio lists all 30 layers and draws them', (
    tester,
  ) async {
    useViewport(tester, TabletViewport.ipadLandscape);
    final store = MemoryTemplateStore(clock: FakeClock());
    final templateId = await _stressTemplate(store);
    await pumpApp(
      tester,
      location: RoutePaths.templateEditor(templateId),
      templates: store,
    );
    await settleRendering(tester);
    final controller = tester
        .widget<EditorCanvas>(find.byType(EditorCanvas))
        .controller;
    expect(controller.document.layers, hasLength(_layerCount));
    expect(controller.ready, isTrue);

    await tester.tap(find.bySemanticsLabel('Layers').first);
    await tester.pumpAndSettle();
    // Every layer but the background reorders; the background stays
    // last, below the list.
    final list = tester.widget<SliverReorderableList>(
      find.byType(SliverReorderableList),
    );
    expect(list.itemCount, _layerCount - 1);
    final background = find.bySemanticsLabel(RegExp('^Background, '));
    await tester.scrollUntilVisible(
      background,
      300,
      scrollable: find
          .descendant(
            of: find.byType(LayersPanel),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(background, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
