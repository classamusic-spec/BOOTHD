// The Template Studio's working state without its screen (A-08, AC-0506,
// AC-0507): autosave writes a draft a moment after each change and never
// in the middle of a drag; undoing back to the saved design removes the
// draft; a drag, a rotation or a slider is one undo step; save stores the
// next revision and history survives it; refused writes keep the work in
// memory and say so; a restored draft reopens editable; leaving keeps
// unsaved work.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/templates/starter_designs.dart';
import 'package:porcelain_photo_booth/core/templates/template_library.dart';
import 'package:porcelain_photo_booth/domain/repositories/template_store.dart';
import 'package:porcelain_photo_booth/domain/template/editing/document_edits.dart';
import 'package:porcelain_photo_booth/domain/template/editing/layer_copy.dart';
import 'package:porcelain_photo_booth/domain/template/geometry.dart';
import 'package:porcelain_photo_booth/domain/template/template_assets.dart';
import 'package:porcelain_photo_booth/domain/template/template_document.dart';
import 'package:porcelain_photo_booth/domain/template/template_layers.dart';
import 'package:porcelain_photo_booth/features/template_studio/editor_controller.dart';

import '../../support/fakes.dart';
import '../../support/memory_template_store.dart';

final class _Booth {
  _Booth(this.store, this.library, this.templateId);

  final MemoryTemplateStore store;
  final TemplateLibrary library;
  final String templateId;
  final _open = <TemplateEditorController>[];

  Future<TemplateDraft?> draft() => store.drafts.load(templateId);

  /// An editor on the template as it would open now. Unless [dispose] is
  /// false the test's end closes it.
  Future<TemplateEditorController> open({bool dispose = true}) async {
    final opened = await library.open(templateId);
    final controller = TemplateEditorController(
      library: library,
      assets: store.assets,
      revision: opened.revision,
      restoredDraft: opened.draft,
    );
    if (dispose) _open.add(controller);
    return controller;
  }

  /// Closes the editors, as leaving the screen does, before the test ends
  /// (their autosave timers must not outlive it).
  Future<void> close(WidgetTester tester) async {
    for (final controller in _open) {
      controller.dispose();
    }
    _open.clear();
    await tester.pump();
  }
}

/// A test with a fresh booth whose editors are closed at its end.
void _test(
  String description,
  Future<void> Function(WidgetTester tester, _Booth booth) body,
) => testWidgets(description, (tester) async {
  final booth = await _booth();
  await body(tester, booth);
  await booth.close(tester);
});

Future<_Booth> _booth() async {
  final store = MemoryTemplateStore(clock: FakeClock());
  final library = TemplateLibrary(
    assets: store.assets,
    templates: store.templates,
    packages: store.packages,
    drafts: store.drafts,
    clock: store.clock,
    loadBundled: (path) async => File(path).readAsBytesSync(),
  );
  final created = await library.create(
    starterDesigns.firstWhere((d) => d.id == 'classic-strip'),
    name: 'Garden party',
  );
  return _Booth(store, library, created.templateId);
}

PhotoSlotLayer _slot(TemplateEditorController controller, String id) =>
    controller.document.layers.firstWhere((l) => l.id == id) as PhotoSlotLayer;

void main() {
  group('autosave (A-08)', () {
    _test('a change is kept as a draft once the delay has passed', (
      tester,
      booth,
    ) async {
      final controller = await booth.open();
      expect(controller.draftState, DraftState.clean);

      controller.addText();
      expect(controller.draftState, DraftState.pending);
      await tester.pump(controller.autosaveDelay ~/ 2);
      expect(await booth.draft(), isNull);

      await tester.pump(controller.autosaveDelay);
      final draft = await booth.draft();
      expect(draft!.document, controller.document);
      expect(draft.baseRevisionId, controller.revision.summary.revisionId);
      expect(controller.draftState, DraftState.written);
      expect(controller.hasUnsavedChanges, isTrue);
    });

    _test('nothing is written in the middle of a drag', (tester, booth) async {
      final controller = await booth.open();
      controller.addText();
      controller.beginGesture();
      for (var i = 1; i <= 5; i++) {
        controller.updateGesture(
          DocumentEdits.translate(
            controller.document,
            {'photo-1'},
            0.002 * i,
            0,
          ),
        );
      }
      // The timer from the text fires mid-drag and waits instead.
      await tester.pump(controller.autosaveDelay * 3);
      expect(await booth.draft(), isNull);

      controller.endGesture();
      await tester.pump(controller.autosaveDelay);
      expect((await booth.draft())!.document, controller.document);
    });

    _test('undoing back to the saved design removes the draft', (
      tester,
      booth,
    ) async {
      final controller = await booth.open();
      controller.addText();
      await tester.pump(controller.autosaveDelay);
      expect(await booth.draft(), isNotNull);

      controller.undo();
      expect(controller.hasUnsavedChanges, isFalse);
      await tester.pump(controller.autosaveDelay);
      expect(await booth.draft(), isNull);
      expect(controller.draftState, DraftState.clean);
    });

    _test('a refused draft says so, keeps the work and retries', (
      tester,
      booth,
    ) async {
      final controller = await booth.open();
      booth.store.failWrites = true;
      controller.addText();
      await tester.pump(controller.autosaveDelay);
      expect(controller.draftState, DraftState.failed);
      expect(controller.hasUnsavedChanges, isTrue);
      expect(controller.document.layers.whereType<TextLayer>(), hasLength(3));

      booth.store.failWrites = false;
      controller.addShape(ShapeKind.rect);
      await tester.pump(controller.autosaveDelay);
      expect(controller.draftState, DraftState.written);
      expect((await booth.draft())!.document, controller.document);
    });

    _test('leaving with unsaved work keeps it at once', (tester, booth) async {
      final controller = await booth.open(dispose: false);
      controller.addText();
      final document = controller.document;
      controller.dispose();
      await tester.pump();
      expect((await booth.draft())!.document, document);
    });
  });

  group('undo steps (AC-0506)', () {
    _test('a drag of many steps is one undo step', (tester, booth) async {
      final controller = await booth.open();
      final start = _slot(controller, 'photo-2').frame;
      controller.beginGesture();
      for (var i = 1; i <= 30; i++) {
        controller.updateGesture(
          DocumentEdits.translate(
            controller.document,
            {'photo-2'},
            0.001,
            0.0005,
          ),
        );
      }
      controller.endGesture();
      expect(_slot(controller, 'photo-2').frame.x, greaterThan(start.x));

      controller.undo();
      expect(_slot(controller, 'photo-2').frame, start);
      expect(controller.canUndo, isFalse);
      controller.redo();
      expect(_slot(controller, 'photo-2').frame.x, greaterThan(start.x));
      expect(controller.canRedo, isFalse);
    });

    _test('a rotation or a slider is one undo step', (tester, booth) async {
      final controller = await booth.open();
      controller.beginGesture();
      for (var degrees = 1.0; degrees <= 45; degrees++) {
        controller.updateLayerInGesture(
          'photo-1',
          (layer) => copyLayer(layer, rotationDegrees: degrees),
        );
      }
      controller.endGesture();
      controller.beginGesture();
      for (var step = 1; step <= 10; step++) {
        controller.updateLayerInGesture(
          'photo-1',
          (layer) => copyLayer(layer, opacity: 1 - step * 0.05),
        );
      }
      controller.endGesture();
      expect(_slot(controller, 'photo-1').rotationDegrees, 45);
      expect(_slot(controller, 'photo-1').opacity, closeTo(0.5, 1e-9));

      controller.undo();
      expect(_slot(controller, 'photo-1').opacity, 1);
      expect(_slot(controller, 'photo-1').rotationDegrees, 45);
      controller.undo();
      expect(_slot(controller, 'photo-1').rotationDegrees, 0);
      expect(controller.canUndo, isFalse);
    });

    _test('a background colour, a gradient and removing it are one step '
        'each', (tester, booth) async {
      final controller = await booth.open();
      BackgroundFill? fill() => controller.document.background?.fill;
      final original = fill();
      const navy = SolidFill(ArgbColor(0xFF223344));
      const gradient = LinearGradientFill(
        angleDegrees: 90,
        stops: [
          GradientStop(0, ArgbColor(0xFFFFFFFF)),
          GradientStop(1, ArgbColor(0xFFE6CD9B)),
        ],
      );
      await controller.setBackground(navy);
      await controller.setBackground(gradient);
      expect(fill(), gradient);
      controller
        ..select('background')
        ..deleteSelected();
      expect(controller.document.background, isNull);

      controller.undo();
      expect(fill(), gradient);
      controller.undo();
      expect(fill(), navy);
      controller.undo();
      expect(fill(), original);
      expect(controller.canUndo, isFalse);
    });

    _test('an edit that breaks the rules changes nothing', (
      tester,
      booth,
    ) async {
      final controller = await booth.open();
      final before = controller.document;
      final x = _slot(controller, 'photo-1').frame.x;
      // Fifty pages to the right: beyond what a frame may be.
      TemplateDocument farAway(TemplateDocument document) =>
          DocumentEdits.update(
            document,
            'photo-1',
            (layer) => copyLayer(
              layer,
              frame: const NormalizedRect(x: 50, y: 0, width: 0.5, height: 0.2),
            ),
          );
      expect(() => controller.apply(farAway), throwsA(isA<InvalidEdit>()));
      expect(controller.document, before);
      expect(controller.canUndo, isFalse);

      // In a drag, such a step is skipped and the drag goes on.
      controller.beginGesture();
      controller.updateGesture(farAway(controller.document));
      controller.updateGesture(
        DocumentEdits.translate(controller.document, {'photo-1'}, 0.01, 0),
      );
      controller.endGesture();
      expect(_slot(controller, 'photo-1').frame.x, closeTo(x + 0.01, 1e-9));
      controller.undo();
      expect(controller.document, before);
    });
  });

  group('save and reopen (AC-0507)', () {
    _test('save stores the next revision; history survives it', (
      tester,
      booth,
    ) async {
      final controller = await booth.open();
      final first = controller.revision;
      controller.addText();
      await tester.pump(controller.autosaveDelay);
      await controller.save();

      final latest = await booth.store.templates.loadLatest(booth.templateId);
      expect(latest.summary.revisionNumber, 2);
      expect(latest.document, controller.document);
      expect(controller.revision.summary.revisionNumber, 2);
      expect(controller.hasUnsavedChanges, isFalse);
      expect(controller.draftState, DraftState.clean);
      expect(await booth.draft(), isNull);

      // Undo still goes back past the save; that is unsaved again, and
      // revision 1 is untouched.
      controller.undo();
      expect(controller.document, first.document);
      expect(controller.hasUnsavedChanges, isTrue);
      final stored = await booth.store.templates.loadRevision(
        first.summary.revisionId,
      );
      expect(stored.document, first.document);
    });

    _test('a refused save keeps the work, in memory and as a draft', (
      tester,
      booth,
    ) async {
      final controller = await booth.open();
      controller.addText();
      await tester.pump(controller.autosaveDelay);
      booth.store.failWrites = true;

      await expectLater(
        controller.save(),
        throwsA(
          isA<TemplateStoreException>().having(
            (e) => e.code,
            'code',
            TemplateStoreErrorCode.storageFailed,
          ),
        ),
      );
      expect(controller.saving, isFalse);
      expect(controller.hasUnsavedChanges, isTrue);
      final latest = await booth.store.templates.loadLatest(booth.templateId);
      expect(latest.summary.revisionNumber, 1);
      expect((await booth.draft())!.document, controller.document);
    });

    _test('a draft reopens editable; discarding returns to the save', (
      tester,
      booth,
    ) async {
      final first = await booth.open(dispose: false);
      final saved = first.document;
      first
        ..addText()
        ..select('photo-1')
        ..nudge(30, 0);
      final edited = first.document;
      first.dispose();
      await tester.pump();

      final reopened = await booth.open();
      expect(reopened.document, edited);
      expect(reopened.hasUnsavedChanges, isTrue);
      expect(reopened.draftState, DraftState.written);
      // Fully editable: the restored layers move and undo.
      reopened
        ..select('photo-1')
        ..nudge(0, 12);
      expect(
        _slot(reopened, 'photo-1').frame.y * reopened.document.page.heightPx,
        closeTo(
          (edited.layers.firstWhere(
                    (l) => l.id == 'photo-1',
                  ) as PhotoSlotLayer).frame.y *
                  edited.page.heightPx +
              12,
          1e-6,
        ),
      );
      reopened.undo();
      expect(reopened.document, edited);

      await reopened.discardChanges();
      expect(reopened.document, saved);
      expect(reopened.hasUnsavedChanges, isFalse);
      expect(await booth.draft(), isNull);
    });
  });
}
