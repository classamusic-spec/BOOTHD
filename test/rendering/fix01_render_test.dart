import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/services/composition_renderer.dart';
import 'package:porcelain_photo_booth/features/diagnostics/spikes/render/render_checks.dart';
import 'package:porcelain_photo_booth/features/diagnostics/spikes/render/render_fixtures.dart';
import 'package:porcelain_photo_booth/infrastructure/composition/dart_ui_composition_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const renderer = DartUiCompositionRenderer();
  late Map<String, Uint8List> assets;

  setUpAll(() => assets = fix01Assets());

  void expectChecks(List<PixelCheckResult> results) {
    final failures = results.where((r) => !r.passed).toList();
    expect(failures, isEmpty, reason: results.join('\n'));
  }

  group('FIX-01 export (AC-0101..AC-0103)', () {
    late RenderedImage export;

    setUpAll(() async {
      export = await renderer.renderExport(
        fix01(),
        slotAssets: fix01SlotAssets,
        assets: assets,
        includePixels: true,
      );
    });

    test('is exactly 1200x1800 and its PNG decodes at that size', () async {
      expect((export.widthPx, export.heightPx), (1200, 1800));
      final codec = await ui.instantiateImageCodec(export.png);
      final frame = await codec.getNextFrame();
      expect((frame.image.width, frame.image.height), (1200, 1800));
      frame.image.dispose();
      codec.dispose();
    });

    test('photos clip to their slots; overlays cross slot edges; marker '
        'rotates and is cropped at the page edge', () {
      expectChecks(evaluateChecks(fix01ExportChecks(), export.rgba!, 1200));
    });
  });

  test('global z-order: a flower under the slots is hidden only inside '
      'them', () async {
    final image = await renderer.renderExport(
      fix01(flowerBelowSlots: true),
      slotAssets: fix01SlotAssets,
      assets: assets,
      includePixels: true,
    );
    expectChecks(evaluateChecks(fix01FlowerBelowChecks(), image.rgba!, 1200));
  });

  test('editor workspace shows off-page artwork that export crops', () async {
    final image = await renderer.renderWorkspace(
      fix01(),
      slotAssets: fix01SlotAssets,
      assets: assets,
      includePixels: true,
    );
    expect((image.widthPx, image.heightPx), (1440, 2160));
    expectChecks(evaluateChecks(fix01WorkspaceChecks(), image.rgba!, 1440));
  });

  for (final whiteOnWhite in [true, false]) {
    test('FIX-04: no ${whiteOnWhite ? 'dark' : 'light'} halo around a '
        'scaled, rotated transparent edge', () async {
      final fixture = fix04Halo(whiteOnWhite: whiteOnWhite);
      final image = await renderer.renderExport(
        fixture.document,
        slotAssets: const {},
        assets: fixture.assets,
        includePixels: true,
      );
      final result = uniformity(image.rgba!, fixture.expected);
      expect(result.passed, isTrue, reason: '$result');
    });
  }
}
