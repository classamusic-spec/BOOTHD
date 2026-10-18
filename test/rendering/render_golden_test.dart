// Golden comparison for FIX-01 (AC-0104). Regenerate after an intentional
// rendering change with: flutter test --update-goldens test/rendering/
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/services/composition_renderer.dart';
import 'package:porcelain_photo_booth/features/diagnostics/spikes/render/render_checks.dart';
import 'package:porcelain_photo_booth/features/diagnostics/spikes/render/render_fixtures.dart';
import 'package:porcelain_photo_booth/infrastructure/composition/dart_ui_composition_renderer.dart';

const _goldens = 'test_assets/expected_renders';

Future<Uint8List> _decodeRgba(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  final frame = await codec.getNextFrame();
  final bytes = await frame.image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  frame.image.dispose();
  codec.dispose();
  return bytes!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const renderer = DartUiCompositionRenderer();

  Future<void> expectMatchesGolden(RenderedImage image, String name) async {
    final file = File('$_goldens/$name');
    if (autoUpdateGoldenFiles) {
      file
        ..createSync(recursive: true)
        ..writeAsBytesSync(image.png);
      return;
    }
    expect(
      file.existsSync(),
      isTrue,
      reason: 'missing golden; run flutter test --update-goldens',
    );
    final diff = compareRgba(
      image.rgba!,
      await _decodeRgba(file.readAsBytesSync()),
      threshold: GoldenTolerance.threshold,
    );
    // Recorded in CI logs: the host-to-host difference is evidence too.
    // ignore: avoid_print
    print('golden $name: $diff');
    expect(GoldenTolerance.accepts(diff), isTrue, reason: '$diff');
  }

  test('FIX-01 export matches its golden within tolerance', () async {
    final image = await renderer.renderExport(
      fix01(),
      slotAssets: fix01SlotAssets,
      assets: fix01Assets(),
      includePixels: true,
    );
    await expectMatchesGolden(image, 'fix01_export_1200x1800.png');
  });

  test('FIX-01 workspace matches its golden within tolerance', () async {
    final image = await renderer.renderWorkspace(
      fix01(),
      slotAssets: fix01SlotAssets,
      assets: fix01Assets(),
      includePixels: true,
    );
    await expectMatchesGolden(image, 'fix01_workspace_1440x2160.png');
  });

  test('the tolerance rejects a visibly different image', () async {
    final good = await renderer.renderExport(
      fix01(),
      slotAssets: fix01SlotAssets,
      assets: fix01Assets(),
      includePixels: true,
    );
    final shifted = await renderer.renderExport(
      fix01(flowerBelowSlots: true),
      slotAssets: fix01SlotAssets,
      assets: fix01Assets(),
      includePixels: true,
    );
    final diff = compareRgba(
      good.rgba!,
      shifted.rgba!,
      threshold: GoldenTolerance.threshold,
    );
    expect(GoldenTolerance.accepts(diff), isFalse, reason: '$diff');
  });
}
