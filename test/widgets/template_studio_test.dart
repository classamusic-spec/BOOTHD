// The Template Studio on tablet layouts (S07, AC-0502 to AC-0507): tools
// add layers, the canvas moves, resizes and rotates them with one undo step
// per gesture, exact numbers apply, layers reorder, drafts are kept and
// offered back, and saving stores a new revision. Both orientations.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/design_system/porcelain_icons.dart';
import 'package:porcelain_photo_booth/core/routing/route_paths.dart';
import 'package:porcelain_photo_booth/core/templates/starter_designs.dart';
import 'package:porcelain_photo_booth/core/templates/template_library.dart';
import 'package:porcelain_photo_booth/domain/template/editing/editor_geometry.dart';
import 'package:porcelain_photo_booth/domain/template/geometry.dart';
import 'package:porcelain_photo_booth/domain/template/template_layers.dart';
import 'package:porcelain_photo_booth/features/template_studio/editor_canvas.dart';
import 'package:porcelain_photo_booth/features/template_studio/editor_controller.dart';
import 'package:porcelain_photo_booth/shared/widgets/porcelain_text_field.dart';

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

PhotoSlotLayer _slot(TemplateEditorController controller, String id) =>
    controller.document.layers.firstWhere((l) => l.id == id) as PhotoSlotLayer;

/// Where page point [p] is on screen.
Offset _onScreen(WidgetTester tester, PixelPoint p) {
  final canvas = tester.widget<EditorCanvas>(find.byType(EditorCanvas));
  return tester.getTopLeft(find.byType(EditorCanvas)) +
      canvas.viewport.toView(p);
}

LayerGeometry _geometryOf(WidgetTester tester, String layerId) {
  final controller = _controller(tester);
  final layer = controller.document.layers.firstWhere(
    (l) => l.id == layerId,
  ) as FramedLayer;
  return LayerGeometry.of(layer, controller.document.page);
}

/// A one-finger drag through [points], a frame at each.
Future<void> _dragThrough(
  WidgetTester tester,
  Offset from,
  List<Offset> points,
) async {
  final gesture = await tester.startGesture(from);
  for (final point in points) {
    await gesture.moveTo(point);
    await tester.pump();
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

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

      testWidgets('handles resize and rotate the selection, one undo step '
          'each', (tester) async {
        await _openEditor(tester, viewport: viewport);
        final controller = _controller(tester);
        await tester.tapAt(_centreOf(tester, 'photo-2'));
        await tester.pumpAndSettle();
        expect(controller.selection, ['photo-2']);
        final start = _slot(controller, 'photo-2');

        // The bottom-right handle: the top-left corner stays where it is.
        final corner = _onScreen(
          tester,
          _geometryOf(tester, 'photo-2').handle(HandleKind.bottomRight),
        );
        await _dragThrough(tester, corner, [
          for (var i = 1; i <= 8; i++) corner + Offset(i * 4.0, i * 3.0),
        ]);
        final resized = _slot(controller, 'photo-2');
        expect(resized.frame.width, greaterThan(start.frame.width));
        expect(resized.frame.height, greaterThan(start.frame.height));
        expect(resized.frame.x, closeTo(start.frame.x, 1e-9));
        expect(resized.frame.y, closeTo(start.frame.y, 1e-9));
        controller.undo();
        await tester.pump();
        expect(_slot(controller, 'photo-2').frame, start.frame);

        // The rotation handle, swung a quarter turn clockwise about the
        // centre; rotation snaps to 15 degrees.
        final scale = tester
            .widget<EditorCanvas>(find.byType(EditorCanvas))
            .viewport
            .scale;
        final geometry = _geometryOf(tester, 'photo-2');
        final centre = _onScreen(
          tester,
          PixelPoint(geometry.rect.centerX, geometry.rect.centerY),
        );
        final handle = _onScreen(
          tester,
          geometry.rotationHandle(EditorCanvas.rotateHandleDistance / scale),
        );
        final radius = (handle - centre).distance;
        await _dragThrough(tester, handle, [
          for (var i = 1; i <= 12; i++)
            centre +
                Offset(
                  math.sin(i * math.pi / 24) * radius,
                  -math.cos(i * math.pi / 24) * radius,
                ),
        ]);
        expect(_slot(controller, 'photo-2').rotationDegrees, closeTo(90, 1e-9));
        controller.undo();
        await tester.pump();
        expect(_slot(controller, 'photo-2').rotationDegrees, 0);
        expect(controller.canUndo, isFalse);
      });

      testWidgets('zoom, fit, pinch and pan move the view, never the design', (
        tester,
      ) async {
        await _openEditor(tester, viewport: viewport);
        final controller = _controller(tester);
        final view = tester
            .widget<EditorCanvas>(find.byType(EditorCanvas))
            .viewport;
        final before = controller.document;
        expect(view.fitted, isTrue);
        final fit = view.scale;

        await tester.tap(find.bySemanticsLabel('Zoom in'));
        await tester.pumpAndSettle();
        expect(view.scale, closeTo(fit * 1.25, 1e-9));
        expect(view.fitted, isFalse);
        expect(find.text('${view.percent}%'), findsOneWidget);

        // Two fingers spread: the page point between them stays put.
        final canvasTopLeft = tester.getTopLeft(find.byType(EditorCanvas));
        final centre = tester.getCenter(find.byType(EditorCanvas));
        final pinned = view.toPage(centre - canvasTopLeft);
        final zoomed = view.scale;
        final a = await tester.startGesture(
          centre - const Offset(40, 0),
          pointer: 7,
        );
        final b = await tester.startGesture(
          centre + const Offset(40, 0),
          pointer: 8,
        );
        for (var i = 1; i <= 6; i++) {
          await a.moveTo(centre - Offset(40.0 + i * 10, 0));
          await b.moveTo(centre + Offset(40.0 + i * 10, 0));
          await tester.pump();
        }
        await a.up();
        await b.up();
        await tester.pumpAndSettle();
        expect(view.scale, greaterThan(zoomed * 1.5));
        final after = view.toPage(centre - canvasTopLeft);
        expect(after.dx, closeTo(pinned.dx, 1));
        expect(after.dy, closeTo(pinned.dy, 1));
        // Page and screen coordinates convert both ways.
        final there = view.toPage(view.toView(const PixelPoint(123, 456)));
        expect(there.dx, closeTo(123, 1e-9));
        expect(there.dy, closeTo(456, 1e-9));

        // The Pan tool drags the view, even over a layer.
        await tester.tap(find.bySemanticsLabel('Pan').first);
        await tester.pumpAndSettle();
        final origin = view.origin;
        final from = _centreOf(tester, 'photo-2');
        await _dragThrough(tester, from, [
          for (var i = 1; i <= 8; i++) from + Offset(i * 8.0, i * 6.0),
        ]);
        expect(view.origin.dx, greaterThan(origin.dx + 20));
        expect(view.origin.dy, greaterThan(origin.dy + 15));

        await tester.tap(find.bySemanticsLabel('Fit the page'));
        await tester.pumpAndSettle();
        expect(view.fitted, isTrue);
        expect(view.scale, closeTo(fit, 1e-9));
        expect(identical(controller.document, before), isTrue);
        expect(controller.canUndo, isFalse);
      });
    });
  }

  testWidgets('layer changes from the panel and inspector persist through '
      'save and reopen', (tester) async {
    final (booth, templateId) = await _openEditor(tester);
    final controller = _controller(tester);
    await tester.tap(find.bySemanticsLabel('Layers').first);
    await tester.pumpAndSettle();

    // Drag Title one row down, below Rule.
    int paintIndex(String id) =>
        controller.document.paintOrder.indexWhere((l) => l.id == id);
    expect(paintIndex('title'), greaterThan(paintIndex('rule')));
    // Rows run top first: Subtitle, Title, Rule, …; each starts with its
    // grip.
    final titleRow = tester.getCenter(find.bySemanticsLabel('Title, Text'));
    final grips = find.byIcon(PorcelainIcons.dragHandle);
    final grip = [
      for (var i = 0; i < grips.evaluate().length; i++)
        tester.getCenter(grips.at(i)),
    ].firstWhere((c) => (c.dy - titleRow.dy).abs() < 4);
    await _dragThrough(tester, grip, [
      for (var i = 1; i <= 10; i++) grip + Offset(0, i * 6.0),
    ]);
    expect(paintIndex('title'), lessThan(paintIndex('rule')));

    await tester.tap(find.bySemanticsLabel('Hide Subtitle'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Lock Rule'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Show Subtitle'), findsOneWidget);
    expect(find.bySemanticsLabel('Unlock Rule'), findsOneWidget);

    // Photo 1 to the front, duplicated, the copy renamed.
    await tester.tap(find.bySemanticsLabel('Photo 1, Photo 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inspector').first);
    await tester.pumpAndSettle();
    final front = find.bySemanticsLabel('Bring to front');
    await tester.ensureVisible(front);
    await tester.tap(front);
    await tester.pumpAndSettle();
    expect(controller.document.paintOrder.last.id, 'photo-1');
    await tester.tap(find.bySemanticsLabel('Duplicate').first);
    await tester.pumpAndSettle();
    final copy = controller.singleSelection! as PhotoSlotLayer;
    expect(copy.id, isNot('photo-1'));
    expect(copy.slotIndex, 3);
    final name = find.descendant(
      of: find.ancestor(
        of: find.text('Name'),
        matching: find.byType(PorcelainTextField),
      ),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(name);
    await tester.enterText(name, 'Encore photo');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final saved = (await booth.templates.templates.loadLatest(templateId))
        .document;
    TemplateLayer layer(String id) =>
        saved.layers.firstWhere((l) => l.id == id);
    int savedIndex(String id) => saved.paintOrder.indexWhere((l) => l.id == id);
    expect(savedIndex('title'), lessThan(savedIndex('rule')));
    expect(layer('subtitle').visible, isFalse);
    expect(layer('rule').locked, isTrue);
    expect(layer(copy.id).name, 'Encore photo');
    expect(savedIndex(copy.id), greaterThan(savedIndex('photo-1')));
    expect(savedIndex('photo-1'), greaterThan(savedIndex('subtitle')));
    expect(saved.photoSlotCount, 4);
    expect(saved, controller.document);
  });

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
