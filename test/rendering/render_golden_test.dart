// Golden comparisons (AC-0104, AC-0407). FIX-01's goldens date from the M01
// spike: the production renderer must still reproduce them. Regenerate
// after an intentional rendering change with:
//   flutter test --update-goldens test/rendering/
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/services/composition_renderer.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/render_checks.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/render_fixtures.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/render_lab_runner.dart';
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
  final renderer = DartUiCompositionRenderer();

  Future<void> expectMatchesGolden(RenderArtifact image, String name) async {
    // CoreText and FreeType rasterize bundled text differently. Keep a
    // reviewed macOS text reference; Linux CI and geometry tolerances
    // retain their existing baselines and limits.
    final platform = Platform.isMacOS && name == labGoldens['FIX-05']
        ? 'macos/'
        : '';
    final file = File('$_goldens/$platform$name');
    if (autoUpdateGoldenFiles) {
      file
        ..createSync(recursive: true)
        ..writeAsBytesSync(image.bytes);
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

  test('FIX-01 export still matches the M01 spike golden', () async {
    await expectMatchesGolden(
      await exportPixels(renderer, fix01()),
      labGoldens['FIX-01']!,
    );
  });

  test('FIX-01 workspace still matches the M01 spike golden', () async {
    await expectMatchesGolden(
      await renderer.renderPreview(
        fix01().render,
        maxWidthPx: 1440,
        maxHeightPx: 2160,
        workspaceMargin: 0.1,
        includePixels: true,
      ),
      labGoldens[workspaceGoldenKey]!,
    );
  });

  for (final fixture in labFixtures()) {
    final name = labGoldens[fixture.id];
    if (name == null || fixture.id == 'FIX-01') continue;
    test('$name matches its golden', () async {
      await expectMatchesGolden(await exportPixels(renderer, fixture), name);
    });
  }

  test('the tolerance rejects a visibly different image', () async {
    final good = await exportPixels(renderer, fix01());
    final shifted = await exportPixels(renderer, fix01(flowerBelowSlots: true));
    final diff = compareRgba(
      good.rgba!,
      shifted.rgba!,
      threshold: GoldenTolerance.threshold,
    );
    expect(GoldenTolerance.accepts(diff), isFalse, reason: '$diff');
  });
}
