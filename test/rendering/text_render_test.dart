// FIX-05: template text with packaged fonts lays out where the document
// says, at every alignment, wraps at the frame, and falls back
// deterministically when an imported font is missing or broken.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/services/composition_renderer.dart';
import 'package:porcelain_photo_booth/domain/template/geometry.dart';
import 'package:porcelain_photo_booth/domain/template/page_spec.dart';
import 'package:porcelain_photo_booth/domain/template/template_assets.dart';
import 'package:porcelain_photo_booth/domain/template/template_document.dart';
import 'package:porcelain_photo_booth/domain/template/template_layers.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/memory_render_source.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/render_checks.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/render_fixtures.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/render_lab_runner.dart';
import 'package:porcelain_photo_booth/infrastructure/composition/dart_ui_composition_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final renderer = DartUiCompositionRenderer();

  group('FIX-05 layout', () {
    late RenderArtifact export;
    setUpAll(() async => export = await exportPixels(renderer, fix05()));

    for (final probe in fix05Probes) {
      test('"${probe.layerId}" stays in its frame, aligned, on '
          '${probe.lines} line(s)', () {
        final result = evaluateTextProbe(probe, export.rgba!, 1200);
        expect(result.passed, isTrue, reason: '$result');
      });
    }

    test('text never reports problems when it fits', () {
      expect(export.warnings, isEmpty);
    });
  });

  TemplateDocument oneText(
    FontRef font, {
    NormalizedRect? frame,
    String? text,
  }) => TemplateDocument(
    page: const PageSpec(width: 3, height: 1, unit: LengthUnit.inch, dpi: 300),
    assets: switch (font) {
      AssetFont(:final assetId) => {
        assetId: const TemplateAsset(
          mediaType: AssetMediaType.ttf,
          byteLength: 1,
        ),
      },
      BundledFont() => const {},
    },
    layers: [
      const BackgroundLayer(
        id: 'background',
        zIndex: 0,
        fill: SolidFill(ArgbColor(0xFFFFFFFF)),
      ),
      TextLayer(
        id: 'words',
        zIndex: 1,
        frame:
            frame ??
            const NormalizedRect(x: 0.05, y: 0.1, width: 0.9, height: 0.8),
        text: text ?? 'Porcelain 2026',
        font: font,
        sizePt: 20,
        color: const ArgbColor(0xFF000000),
      ),
    ],
  );

  Future<RenderArtifact> render(
    TemplateDocument document,
    Map<String, Uint8List> assets,
  ) => renderer.renderExport(
    TemplateRender(
      document: document,
      photos: const {},
      source: MemoryRenderSource(assets: assets),
    ),
    output: const OutputProfile(format: OutputFormat.png),
    includePixels: true,
  );

  test(
    'an imported font file renders exactly like the same bundled font',
    () async {
      final bytes = File('assets/fonts/inter/Inter-Regular.ttf')
          .readAsBytesSync();
      final id = assetIdOf(bytes);
      final imported = await render(oneText(AssetFont(id)), {id: bytes});
      final bundled = await render(
        oneText(const BundledFont(BundledFontFamily.inter)),
        const {},
      );
      expect(imported.warnings, isEmpty);
      expect(compareRgba(imported.rgba!, bundled.rgba!).maxDelta, 0);
    },
  );

  test('a missing or broken font falls back to Inter, and says so', () async {
    final id = assetIdOf('not a font'.codeUnits);
    final bundled = await render(
      oneText(const BundledFont(BundledFontFamily.inter)),
      const {},
    );
    for (final assets in [
      <String, Uint8List>{},
      {id: Uint8List.fromList('not a font'.codeUnits)},
    ]) {
      final fallback = await render(oneText(AssetFont(id)), assets);
      expect(fallback.warnings.map((w) => w.code), [
        RenderWarningCode.fontFallback,
      ]);
      expect(fallback.warnings.single.layerId, 'words');
      expect(compareRgba(fallback.rgba!, bundled.rgba!).maxDelta, 0);
    }
  });

  test('text taller than its frame is still drawn, with a warning', () async {
    final image = await render(
      oneText(
        const BundledFont(BundledFontFamily.inter),
        frame: const NormalizedRect(x: 0.05, y: 0.4, width: 0.3, height: 0.2),
        text: 'Several words that wrap onto many lines',
      ),
      const {},
    );
    expect(image.warnings.map((w) => w.code), [RenderWarningCode.textOverflow]);
    final ink = inkIn(
      image.rgba!,
      900,
      left: 0,
      top: 0,
      right: 900,
      bottom: 300,
    )!;
    expect(ink.top, lessThan(120));
    expect(ink.bottom, greaterThan(180));
  });
}
