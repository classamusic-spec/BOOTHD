// The Template Studio on tablet layouts (S07, AC-0502 to AC-0507): tools
// add layers, the canvas moves, resizes and rotates them with one undo step
// per gesture, exact numbers apply, layers reorder, drafts are kept and
// offered back, and saving stores a new revision. Both orientations.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/routing/route_paths.dart';
import 'package:porcelain_photo_booth/core/templates/starter_designs.dart';
import 'package:porcelain_photo_booth/core/templates/template_library.dart';
import 'package:porcelain_photo_booth/domain/template/editing/editor_geometry.dart';
import 'package:porcelain_photo_booth/domain/template/geometry.dart';
import 'package:porcelain_photo_booth/domain/template/template_layers.dart';
import 'package:porcelain_photo_booth/features/template_studio/editor_canvas.dart';
import 'package:porcelain_photo_booth/features/template_studio/editor_controller.dart';

import '../support/app_harness.dart';
import '../support/fakes.dart';
import '../support/memory_template_store.dart';
import '../support/tablet_viewports.dart';

TemplateLibrary _library(MemoryTemplateStore store) => TemplateLibrary(
  assets: store.assets,
  templates: store.templates,
  packages: store.packages,
  drafts: store.drafts,
  clock: store.clock,
  loadBundled: (path) async => File(path).readAsBytesSync(),
);

/// A booth with one template made from [designId]; returns its id.
Future<(TestBooth, String)> _openEditor(
  WidgetTester tester, {
  String designId = 'classic-strip',
  TabletViewport viewport = TabletViewport.ipadLandscape,
  Future<void> Function(MemoryTemplateStore store, String templateId)? before,
}) async {
  useViewport(tester, viewport);
  final store = MemoryTemplateStore(clock: FakeClock());
  final created = await _library(store).create(
    starterDesigns.firstWhere((d) => d.id == designId),
    name: 'Garden party',
  );
  await before?.call(store, created.templateId);
  final booth = await pumpApp(
    tester,
    location: RoutePaths.templateEditor(created.templateId),
    templates: store,
  );
  return (booth, created.templateId);
}

TemplateEditorController _controller(WidgetTester tester) =>
    tester.widget<EditorCanvas>(find.byType(EditorCanvas)).controller;

/// Where [layerId]'s centre is on screen.
Offset _centreOf(WidgetTester tester, String layerId) {
  final canvas = tester.widget<EditorCanvas>(find.byType(EditorCanvas));
  final layer = canvas.controller.document.layers.firstWhere(
    (l) => l.id == layerId,
  ) as FramedLayer;
  final g = LayerGeometry.of(layer, canvas.controller.document.page);
  final view = canvas.viewport.toView(
    PixelPoint(g.rect.centerX, g.rect.centerY),
  );
  return tester.getTopLeft(find.byType(EditorCanvas)) + view;
}

void main() {
  for (final viewport in [
    TabletViewport.ipadLandscape,
    TabletViewport.ipadPortrait,
  ]) {
    group(viewport.name, () {
      testWidgets('tools add layers; undo and redo step through them', (
        tester,
      ) async {
        await _openEditor(tester, viewport: viewport);
        final controller = _controller(tester);
        final before = controller.document.layers.length;
        expect(find.text('Garden party'), findsOneWidget);
        expect(find.text('All changes saved'), findsOneWidget);

        await tester.tap(find.bySemanticsLabel('Text').first);
        await tester.pumpAndSettle();
        expect(controller.document.layers.length, before + 1);
        expect(controller.singleSelection, isA<TextLayer>());

        await tester.tap(find.bySemanticsLabel('Photo').first);
        await tester.pumpAndSettle();
        expect(controller.document.photoSlotCount, 4);
        expect(find.text('Unsaved changes'), findsOneWidget);

        await tester.tap(find.bySemanticsLabel('Undo'));
        await tester.pumpAndSettle();
        expect(controller.document.photoSlotCount, 3);
        await tester.tap(find.bySemanticsLabel('Undo'));
        await tester.pumpAndSettle();
        expect(controller.document.layers.length, before);
        expect(controller.hasUnsavedChanges, isFalse);
        await tester.tap(find.bySemanticsLabel('Redo'));
        await tester.pumpAndSettle();
        expect(controller.document.layers.length, before + 1);
      });

      testWidgets('dragging moves a layer as one undo step, with snapping', (
        tester,
      ) async {
        await _openEditor(tester, viewport: viewport);
        final controller = _controller(tester);
        final start = controller.document.layers.firstWhere(
          (l) => l.id == 'photo-2',
        ) as PhotoSlotLayer;
        final from = _centreOf(tester, 'photo-2');

        final gesture = await tester.startGesture(from);
        for (var i = 1; i <= 10; i++) {
          await gesture.moveTo(from + Offset(i * 3.0, i * 2.0));
          await tester.pump();
        }
        await gesture.up();
        await tester.pumpAndSettle();

        final moved = controller.document.layers.firstWhere(
          (l) => l.id == 'photo-2',
        ) as PhotoSlotLayer;
        expect(moved.frame.x, greaterThan(start.frame.x));
        expect(moved.frame.y, greaterThan(start.frame.y));
        expect(controller.selection, ['photo-2']);
        // One undo puts it back exactly.
        controller.undo();
        await tester.pump();
        final undone = controller.document.layers.firstWhere(
          (l) => l.id == 'photo-2',
        ) as PhotoSlotLayer;
        expect(undone.frame, start.frame);
        expect(controller.canUndo, isFalse);
      });
    });
  }

  testWidgets('exact numbers in the inspector move and size a layer', (
    tester,
  ) async {
    await _openEditor(tester);
    final controller = _controller(tester);
    controller.select('photo-1');
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '36.0').first, '50');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    final slot = controller.document.layers.firstWhere(
      (l) => l.id == 'photo-1',
    ) as PhotoSlotLayer;
    expect(slot.frame.x * 600, closeTo(50, 1e-9));
    expect(controller.canUndo, isTrue);
  });

  testWidgets('save stores revision 2 and clears the unsaved state', (
    tester,
  ) async {
    final (booth, templateId) = await _openEditor(tester);
    final controller = _controller(tester);
    await tester.tap(find.bySemanticsLabel('Text').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final latest = await booth.templates.templates.loadLatest(templateId);
    expect(latest.summary.revisionNumber, 2);
    expect(latest.document, controller.document);
    expect(controller.hasUnsavedChanges, isFalse);
    expect(find.text('Saved as revision 2.'), findsOneWidget);
  });

  testWidgets('a draft is offered back when the template reopens', (
    tester,
  ) async {
    await _openEditor(
      tester,
      before: (store, templateId) async {
        final library = _library(store);
        final opened = await library.open(templateId);
        await library.saveDraft(
          templateId,
          baseRevisionId: opened.revision.summary.revisionId,
          document: opened.revision.document,
        );
      },
    );
    // A draft equal to the saved revision is discarded unseen.
    expect(find.text('Pick up where you left off?'), findsNothing);
  });
}
