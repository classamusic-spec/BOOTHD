// Preview and export parity (AC-0407): a preview is the export's scene
// painted smaller, never a different layout. Each fixture's quarter-size
// preview is compared with its full-resolution export box-filtered down to
// the same size (ADR-0010 tolerance), and the on-screen ScenePreview widget
// with the renderer's own preview.
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/composition/scene_preparation.dart';
import 'package:porcelain_photo_booth/core/composition/template_fonts.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/preview_parity.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/render_checks.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/render_fixtures.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/render_lab_runner.dart';
import 'package:porcelain_photo_booth/infrastructure/composition/dart_ui_composition_renderer.dart';
import 'package:porcelain_photo_booth/shared/widgets/scene_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final renderer = DartUiCompositionRenderer();

  for (final fixture in labFixtures()) {
    test(
      '${fixture.id}: the quarter-size preview is the export, smaller',
      () async {
        final parity = await previewParity(renderer, fixture);
        // Recorded in CI logs as evidence.
        // ignore: avoid_print
        parity.summary().forEach(print);
        expect(parity.preview.widthPx, fixture.widthPx ~/ 4);
        expect(parity.preview.heightPx, fixture.heightPx ~/ 4);
        expect(
          PreviewTolerance.accepts(parity.diff),
          isTrue,
          reason: '${parity.diff}',
        );
        for (final result in parity.text) {
          expect(result.passed, isTrue, reason: '$result');
        }
        for (final check in parity.checks) {
          expect(check.passed, isTrue, reason: '$check');
        }
        expect(parity.passed, isTrue);
      },
    );
  }

  test('scaled checks cover most of each fixture', () async {
    for (final fixture in labFixtures()) {
      if (fixture.exportChecks.isEmpty) continue;
      final parity = await previewParity(renderer, fixture);
      expect(
        parity.checks.length,
        greaterThanOrEqualTo(fixture.exportChecks.length ~/ 2),
        reason:
            '${fixture.id}: ${parity.checks.length} of '
            '${fixture.exportChecks.length} checks apply at 1/4 size',
      );
    }
  });

  test('a preview one pixel out of place fails', () async {
    for (final fixture in [fix01(), fix03(), clipAndFit()]) {
      final parity = await previewParity(renderer, fixture, shiftPreview: 1);
      expect(
        PreviewTolerance.accepts(parity.diff),
        isFalse,
        reason: '${fixture.id}: ${parity.diff}',
      );
    }
    final text = await previewParity(renderer, fix05(), shiftPreview: 2);
    expect(text.text.every((result) => result.passed), isFalse);
  });

  testWidgets('the on-screen preview paints exactly what the renderer does', (
    tester,
  ) async {
    for (final fixture in [fix01(), fix03(), clipAndFit(), fix05()]) {
      final width = fixture.widthPx ~/ 4;
      final height = fixture.heightPx ~/ 4;
      final boundary = GlobalKey();
      final (expected, compiled, resources) = (await tester.runAsync(() async {
        final expected = await renderer.renderPreview(
          fixture.render,
          maxWidthPx: width,
          maxHeightPx: height,
          includePixels: true,
        );
        final compiled = await compileRender(fixture.render);
        final resources = await loadRenderResources(
          compiled,
          fonts: TemplateFontLoader(),
          scale: 0.25,
        );
        return (expected, compiled, resources);
      }))!;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: boundary,
              child: SizedBox(
                width: width.toDouble(),
                height: height.toDouble(),
                child: ScenePreview(
                  scene: compiled.scene,
                  resources: resources,
                ),
              ),
            ),
          ),
        ),
      );
      final actual = (await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage();
        final data = await image.toByteData(
          format: ui.ImageByteFormat.rawStraightRgba,
        );
        image.dispose();
        return data!.buffer.asUint8List();
      }))!;
      resources.dispose();
      final diff = compareRgba(actual, expected.rgba!);
      // ignore: avoid_print
      print('${fixture.id} widget vs renderer preview: $diff');
      expect(diff.maxDelta, lessThanOrEqualTo(1), reason: '$diff');
    }
  });

  test(
    'a render is reproducible: the same inputs give the same bytes',
    () async {
      for (final format in OutputFormat.values) {
        final output = OutputProfile(format: format);
        final first = await renderer.renderExport(
          fix01().render,
          output: output,
        );
        final second = await renderer.renderExport(
          fix01().render,
          output: output,
        );
        expect(second.bytes, first.bytes, reason: format.name);
      }
      final first = await renderer.renderPreview(
        fix05().render,
        maxWidthPx: 300,
        maxHeightPx: 450,
      );
      final second = await renderer.renderPreview(
        fix05().render,
        maxWidthPx: 300,
        maxHeightPx: 450,
      );
      expect(second.bytes, first.bytes);
    },
  );
}
