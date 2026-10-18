// AC-0510: the Template Studio shows what prints. Its canvas paints the
// template through the export's own scene painter, with images decoded at
// the size they show, as the renderer's preview decodes them. Here the
// live canvas is captured for every starter design, above all Floral
// Elegance, whose blossom vine crosses all three photo spaces and whose
// corner spray runs off the page:
// - at half and at quarter size, the canvas's page is the renderer's
//   preview, pixel for pixel;
// - at half size (target tablets show a page at 0.5 to 1 screen pixel per
//   print pixel) it is the full 300 dpi export box-filtered down, under
//   the preview tolerance of ADR-0010, with text compared by its ink.
// Only the editor's own aids are left out of the comparison: the slot
// numbers and the page's edge line (grid, print-safe margin and selection
// are off).
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/design_system/porcelain_theme_data.dart';
import 'package:porcelain_photo_booth/core/design_system/theme_profiles.dart';
import 'package:porcelain_photo_booth/core/templates/slot_placeholder.dart';
import 'package:porcelain_photo_booth/core/templates/starter_designs.dart';
import 'package:porcelain_photo_booth/core/templates/template_library.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/services/composition_renderer.dart';
import 'package:porcelain_photo_booth/domain/template/document_scene.dart';
import 'package:porcelain_photo_booth/domain/template/editing/document_edits.dart';
import 'package:porcelain_photo_booth/domain/template/editing/editor_geometry.dart';
import 'package:porcelain_photo_booth/domain/template/editing/layer_copy.dart';
import 'package:porcelain_photo_booth/domain/template/geometry.dart';
import 'package:porcelain_photo_booth/domain/template/template_document.dart';
import 'package:porcelain_photo_booth/domain/template/template_layers.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/preview_parity.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/render_checks.dart';
import 'package:porcelain_photo_booth/features/template_studio/editor_canvas.dart';
import 'package:porcelain_photo_booth/features/template_studio/editor_controller.dart';
import 'package:porcelain_photo_booth/features/template_studio/editor_viewport.dart';
import 'package:porcelain_photo_booth/infrastructure/composition/dart_ui_composition_renderer.dart';

import '../support/fakes.dart';
import '../support/memory_template_store.dart';

/// Where the page's top-left corner sits in the canvas, leaving room for
/// artwork beyond the page.
const _margin = Offset(48, 32);

/// The editor, open on a new template made from a design, with the canvas
/// showing the page at 1/[factor] size at [_margin] and every image
/// decoded as shown.
final class _OpenEditor {
  _OpenEditor(
    this.factor,
    this.store,
    this.controller,
    this.viewport,
    this.boundary,
  );

  /// Page pixels per canvas pixel.
  final int factor;
  final MemoryTemplateStore store;
  final TemplateEditorController controller;
  final EditorViewport viewport;
  final GlobalKey boundary;

  TemplateDocument get document => controller.document;
  int get pageWidth => document.page.widthPx;
  int get pageHeight => document.page.heightPx;
  int get width => pageWidth ~/ factor;
  int get height => pageHeight ~/ factor;
  Size get canvasSize => Size(width + _margin.dx * 2, height + _margin.dy * 2);

  /// The whole canvas, as straight RGBA, one pixel per logical pixel.
  Future<(Uint8List, int)> capture(WidgetTester tester) async {
    final rgba = (await tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage();
      final data = await image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      image.dispose();
      return data!.buffer.asUint8List();
    }))!;
    return (rgba, canvasSize.width.toInt());
  }

  /// The page's part of the canvas.
  Future<Uint8List> capturePage(WidgetTester tester) async {
    final (rgba, stride) = await capture(tester);
    final page = Uint8List(width * height * 4);
    final left = _margin.dx.toInt();
    final top = _margin.dy.toInt();
    for (var y = 0; y < height; y++) {
      final from = ((top + y) * stride + left) * 4;
      page.setRange(y * width * 4, (y + 1) * width * 4, rgba, from);
    }
    return page;
  }

  /// Pixels to compare: all but the page's outermost ring (the edge line)
  /// and the slot numbers drawn over each photo space's corner.
  Uint8List aidsMask() {
    final mask = Uint8List(width * height)..fillRange(0, width * height, 1);
    for (var x = 0; x < width; x++) {
      mask[x] = 0;
      mask[(height - 1) * width + x] = 0;
    }
    for (var y = 0; y < height; y++) {
      mask[y * width] = 0;
      mask[y * width + width - 1] = 0;
    }
    for (final slot in document.photoSlots) {
      if (!slot.visible) continue;
      final corner = viewport.toView(
        LayerGeometry.of(slot, document.page).corners.first,
      );
      // EditorOverlayPainter draws an 11-pixel badge 14 pixels in.
      final centre = corner + const Offset(14, 14) - _margin;
      _clearDisc(mask, width, height, centre, 13);
    }
    return mask;
  }

  /// [mask] without the frames of text layers (with a margin for
  /// overhanging glyphs): text is compared by its ink instead, as in the
  /// preview parity test (AC-0407).
  Uint8List withoutText(Uint8List mask) {
    final out = Uint8List.fromList(mask);
    for (final (left, top, right, bottom) in textBoxes()) {
      for (var y = top; y < bottom; y++) {
        out.fillRange(y * width + left, y * width + right, 0);
      }
    }
    return out;
  }

  /// Each text layer's frame at canvas size, with a two-pixel margin.
  List<(int, int, int, int)> textBoxes() => [
    for (final node in controller.scene.nodes.whereType<TextNode>())
      (
        ((node.placement.bounds.left - 2 * factor) / factor).floor().clamp(
          0,
          width,
        ),
        ((node.placement.bounds.top - 2 * factor) / factor).floor().clamp(
          0,
          height,
        ),
        ((node.placement.bounds.right + 2 * factor) / factor).ceil().clamp(
          0,
          width,
        ),
        ((node.placement.bounds.bottom + 2 * factor) / factor).ceil().clamp(
          0,
          height,
        ),
      ),
  ];
}

void _clearDisc(
  Uint8List mask,
  int width,
  int height,
  Offset centre,
  double radius,
) {
  for (var y = (centre.dy - radius).floor(); y <= centre.dy + radius; y++) {
    for (var x = (centre.dx - radius).floor(); x <= centre.dx + radius; x++) {
      if (x < 0 || y < 0 || x >= width || y >= height) continue;
      if ((Offset(x + 0.5, y + 0.5) - centre).distance <= radius) {
        mask[y * width + x] = 0;
      }
    }
  }
}

TemplateLibrary _library(MemoryTemplateStore store) => TemplateLibrary(
  assets: store.assets,
  templates: store.templates,
  packages: store.packages,
  drafts: store.drafts,
  clock: store.clock,
  loadBundled: (path) async => File(path).readAsBytesSync(),
);

Future<_OpenEditor> _open(
  WidgetTester tester,
  StarterDesign design, {
  int factor = 2,
}) async {
  final store = MemoryTemplateStore(clock: FakeClock());
  final library = _library(store);
  final created = await library.create(design, name: design.name);
  final opened = await library.open(created.templateId);
  final controller = TemplateEditorController(
    library: library,
    assets: store.assets,
    revision: opened.revision,
  )..showSafeArea = false;
  final page = opened.revision.document.page;
  final viewport = EditorViewport(
    pageWidth: page.widthPx.toDouble(),
    pageHeight: page.heightPx.toDouble(),
  );
  final boundary = GlobalKey();
  final editor = _OpenEditor(factor, store, controller, viewport, boundary);
  addTearDown(() {
    controller.dispose();
    viewport.dispose();
  });

  final size = editor.canvasSize;
  tester.view
    ..physicalSize = Size(size.width + 40, size.height + 40)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    Theme(
      data: porcelainThemeData(PorcelainThemeProfile.porcelainStudio),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: boundary,
            child: SizedBox.fromSize(
              size: size,
              child: EditorCanvas(
                controller: controller,
                viewport: viewport,
                onRefused: (_) {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  // The page at exactly 1/factor, its corner on a whole pixel.
  viewport.pinch(page: Offset.zero, view: _margin, scale: 1 / factor);
  await _settle(tester, controller);
  expect(
    viewport.pageRect,
    _margin & Size(editor.width.toDouble(), editor.height.toDouble()),
  );
  return editor;
}

/// Lets the view settle and images decode (in real time) at the size they
/// show, then paints.
Future<void> _settle(
  WidgetTester tester,
  TemplateEditorController controller,
) async {
  for (var i = 0; i < 200 && !controller.sharp; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(controller.sharp, isTrue, reason: 'images decoded as shown');
  await tester.pump();
}

/// The renderer's preview and its 300 dpi export of what the editor holds,
/// with the placeholder in every photo space.
Future<(RenderArtifact, RenderArtifact)> _rendered(
  WidgetTester tester,
  _OpenEditor editor, {
  TemplateDocument? document,
}) async {
  final render = placeholderRender(
    document ?? editor.document,
    editor.store.assets,
  );
  // Made in real time: its export queue is a future, and one made under
  // the test's fake clock would never let a real-time export start.
  final renderer = (await tester.runAsync(
    () async => DartUiCompositionRenderer(),
  ))!;
  return (await tester.runAsync(
    () async => (
      await renderer.renderPreview(
        render,
        maxWidthPx: editor.width,
        maxHeightPx: editor.height,
        includePixels: true,
      ),
      await renderer.renderExport(
        render,
        output: const OutputProfile(format: OutputFormat.png),
        includePixels: true,
      ),
    ),
  ))!;
}

ImageDiff _diff(Uint8List a, Uint8List b, Uint8List mask) =>
    compareRgba(a, b, threshold: PreviewTolerance.threshold, mask: mask);

void main() {
  for (final design in starterDesigns) {
    testWidgets('${design.name}: the canvas shows the 300 dpi export', (
      tester,
    ) async {
      final editor = await _open(tester, design);
      final page = await editor.capturePage(tester);
      final (preview, export) = await _rendered(tester, editor);

      // The export is the print: 300 dpi, the page's full pixel size.
      expect(design.page.dpi, 300);
      expect(export.widthPx, editor.pageWidth);
      expect(export.heightPx, editor.pageHeight);
      expect(preview.widthPx, editor.width);
      expect(preview.heightPx, editor.height);

      final mask = editor.aidsMask();
      final reference = downscale(
        export.rgba!,
        export.widthPx,
        export.heightPx,
        editor.factor,
      );
      final vsPreview = _diff(page, preview.rgba!, mask);
      final vsExport = _diff(page, reference, editor.withoutText(mask));
      // Recorded in CI logs as evidence.
      // ignore: avoid_print
      print(
        '${design.id} canvas 1/${editor.factor} vs preview: $vsPreview; '
        'vs 300 dpi export reduced: $vsExport',
      );
      expect(vsPreview.maxDelta, lessThanOrEqualTo(1), reason: '$vsPreview');
      expect(PreviewTolerance.accepts(vsExport), isTrue, reason: '$vsExport');

      for (final (i, (left, top, right, bottom))
          in editor.textBoxes().indexed) {
        InkBounds? ink(Uint8List rgba) => inkIn(
          rgba,
          editor.width,
          left: left,
          top: top,
          right: right,
          bottom: bottom,
        );
        final result = TextParityResult('text $i', ink(page), ink(reference));
        // ignore: avoid_print
        print('  $result');
        expect(result.passed, isTrue, reason: '$result');
      }
    });

    // A quarter is smaller than target tablets show a fitted page. The
    // export comparison is recorded, not held to ADR-0010: previews decode
    // at most twice the size they show, to bound memory, and the densest
    // artwork then loses detail the print keeps (ADR-0011).
    testWidgets('${design.name}: at a quarter, the canvas is the preview', (
      tester,
    ) async {
      final editor = await _open(tester, design, factor: 4);
      final page = await editor.capturePage(tester);
      final (preview, export) = await _rendered(tester, editor);
      final mask = editor.aidsMask();
      final vsPreview = _diff(page, preview.rgba!, mask);
      final vsExport = _diff(
        page,
        downscale(export.rgba!, export.widthPx, export.heightPx, 4),
        editor.withoutText(mask),
      );
      // ignore: avoid_print
      print(
        '${design.id} canvas 1/4 vs preview: $vsPreview; '
        'vs 300 dpi export reduced: $vsExport',
      );
      expect(vsPreview.maxDelta, lessThanOrEqualTo(1), reason: '$vsPreview');
    });
  }

  group('Floral Elegance: artwork beyond the photo spaces', () {
    final floral = starterDesigns.firstWhere((d) => d.id == 'floral-elegance');

    testWidgets('the vine crossing every photo space shows in canvas and '
        'export', (tester) async {
      final editor = await _open(tester, floral);
      final document = editor.document;
      final vine =
          document.layers.firstWhere((l) => l.id == 'vine') as ImageLayer;
      final vineRect = LayerGeometry.of(vine, document.page).rect;
      // It starts beyond the page's left edge, and crosses into every
      // photo space without being clipped by it.
      expect(vineRect.left, lessThan(0));
      for (final slot in document.photoSlots) {
        final slotRect = LayerGeometry.of(slot, document.page).rect;
        expect(vineRect.left, lessThan(slotRect.left));
        expect(vineRect.right, greaterThan(slotRect.left));
        expect(vineRect.top, lessThan(slotRect.bottom));
        expect(vineRect.bottom, greaterThan(slotRect.top));
      }

      final page = await editor.capturePage(tester);
      final withoutVine = DocumentEdits.update(
        document,
        'vine',
        (layer) => copyLayer(layer, visible: false),
      );
      final (bare, _) = await _rendered(tester, editor, document: withoutVine);

      // Where the vine lies over a photo space, and where it lies on the
      // paper beside it, the canvas differs from the page without it.
      Uint8List region({required bool insideSlots}) {
        final mask = editor.aidsMask();
        for (var y = 0; y < editor.height; y++) {
          for (var x = 0; x < editor.width; x++) {
            final p = PixelPoint(
              (x + 0.5) * editor.factor,
              (y + 0.5) * editor.factor,
            );
            final inVine = _contains(vineRect, p);
            final inSlot = document.photoSlots.any(
              (s) => _contains(LayerGeometry.of(s, document.page).rect, p),
            );
            if (!inVine || inSlot != insideSlots) {
              mask[y * editor.width + x] = 0;
            }
          }
        }
        return mask;
      }

      final overPhotos = _diff(page, bare.rgba!, region(insideSlots: true));
      final besidePhotos = _diff(page, bare.rgba!, region(insideSlots: false));
      // ignore: avoid_print
      print('vine over photos: $overPhotos; vine beside photos: $besidePhotos');
      expect(overPhotos.pixelsOverThreshold, greaterThan(100));
      expect(besidePhotos.pixelsOverThreshold, greaterThan(100));
    });

    testWidgets('a vine two canvas pixels out of place fails the check', (
      tester,
    ) async {
      final editor = await _open(tester, floral);
      final page = await editor.capturePage(tester);
      final document = editor.document;
      final shifted = DocumentEdits.update(document, 'vine', (layer) {
        final frame = (layer as ImageLayer).frame;
        return copyLayer(
          layer,
          frame: NormalizedRect(
            x: frame.x + 2 * editor.factor / editor.pageWidth,
            y: frame.y + 2 * editor.factor / editor.pageHeight,
            width: frame.width,
            height: frame.height,
          ),
        );
      });
      final (preview, _) = await _rendered(tester, editor, document: shifted);
      final diff = _diff(page, preview.rgba!, editor.aidsMask());
      // ignore: avoid_print
      print('vine moved by 2 canvas pixels: $diff');
      expect(diff.maxDelta, greaterThan(1), reason: '$diff');
      expect(PreviewTolerance.accepts(diff), isFalse, reason: '$diff');
    });

    testWidgets('the spray beyond the page shows faded on the canvas; the '
        'export stops at the page edge', (tester) async {
      final editor = await _open(tester, floral);
      final document = editor.document;
      final spray = document.layers.firstWhere(
        (l) => l.id == 'blossoms-top',
      ) as ImageLayer;
      final sprayRect = LayerGeometry.of(spray, document.page).rect;
      expect(sprayRect.left, lessThan(0));
      expect(sprayRect.top, lessThan(0));

      // Hide the spray, and the margin beside and above the page loses the
      // spray's off-page part, drawn faded.
      final (withSpray, stride) = await editor.capture(tester);
      editor.controller.setVisible('blossoms-top', visible: false);
      await _settle(tester, editor.controller);
      final (withoutSpray, _) = await editor.capture(tester);
      editor.controller.undo();
      await _settle(tester, editor.controller);

      final f = editor.factor;
      final left = (_margin.dx + sprayRect.left / f).ceil();
      final top = (_margin.dy + sprayRect.top / f).ceil();
      final right = (_margin.dx + sprayRect.right / f).floor();
      final bottom = (_margin.dy + sprayRect.bottom / f).floor();
      var changed = 0;
      var pixels = 0;
      for (var y = top; y < bottom; y++) {
        for (var x = left; x < right; x++) {
          // Only the margin: one pixel clear of the page and its edge line.
          if (x >= _margin.dx - 1 && y >= _margin.dy - 1) continue;
          pixels++;
          final i = (y * stride + x) * 4;
          var delta = 0;
          for (var c = 0; c < 4; c++) {
            final d = (withSpray[i + c] - withoutSpray[i + c]).abs();
            if (d > delta) delta = d;
          }
          if (delta > 8) changed++;
        }
      }
      // ignore: avoid_print
      print('off-page spray: $changed of $pixels margin pixels differ');
      expect(changed, greaterThan(pixels ~/ 50));

      // The export is exactly the page: what lies beyond is clipped.
      final (_, export) = await _rendered(tester, editor);
      expect(export.widthPx, editor.pageWidth);
      expect(export.heightPx, editor.pageHeight);
    });
  });
}

bool _contains(PixelRect rect, PixelPoint p) =>
    p.x >= rect.left &&
    p.x < rect.right &&
    p.y >= rect.top &&
    p.y < rect.bottom;
