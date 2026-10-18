import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/services/composition_renderer.dart';
import 'package:porcelain_photo_booth/features/diagnostics/spikes/render/fixture_images.dart';
import 'package:porcelain_photo_booth/features/diagnostics/spikes/render/png_encoder.dart';
import 'package:porcelain_photo_booth/features/diagnostics/spikes/render/render_checks.dart';
import 'package:porcelain_photo_booth/features/diagnostics/spikes/render/render_fixtures.dart';
import 'package:porcelain_photo_booth/features/diagnostics/spikes/render/render_spike_runner.dart';
import 'package:porcelain_photo_booth/infrastructure/composition/dart_ui_composition_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the full spike passes on the host, failures included (AC-0105)',
    () async {
      final report = await runRenderSpike(
        const DartUiCompositionRenderer(),
        repeats: 2,
      );
      expect(report.passed, isTrue, reason: report.summary().join('\n'));
      expect(report.failureProbes.map((p) => p.actual), [
        RenderFailureCode.missingAsset,
        RenderFailureCode.assetDecodeFailed,
        RenderFailureCode.assetDecodeFailed,
        RenderFailureCode.invalidDocument,
      ]);
    },
  );

  test('an unbound photo slot fails as an invalid document', () async {
    await expectLater(
      const DartUiCompositionRenderer().renderExport(
        fix01(),
        slotAssets: const {0: FixtureAssets.photoA},
        assets: fix01Assets(),
      ),
      throwsA(
        isA<RenderFailure>().having(
          (f) => f.code,
          'code',
          RenderFailureCode.invalidDocument,
        ),
      ),
    );
  });

  test('the halo probe is sensitive: a wrongly coloured edge fails', () async {
    // Edge pixels that carry the hidden colour are a real dark fringe, so the
    // uniformity check must catch them.
    final bad = RgbaImage(500, 500);
    final good = haloDisc(
      size: 500,
      colour: FixtureColours.pureWhite,
      transparentRgb: FixtureColours.black,
    );
    for (var i = 0; i < good.pixels.length; i += 4) {
      final alpha = good.pixels[i + 3];
      final hidden = alpha < 255;
      bad.pixels
        ..[i] = hidden ? 0 : 255
        ..[i + 1] = hidden ? 0 : 255
        ..[i + 2] = hidden ? 0 : 255
        ..[i + 3] = alpha;
    }
    final fixture = fix04Halo(whiteOnWhite: true);
    final image = await const DartUiCompositionRenderer().renderExport(
      fixture.document,
      slotAssets: const {},
      assets: {
        FixtureAssets.haloWhite: encodePngRgba(
          width: 500,
          height: 500,
          rgba: bad.pixels,
        ),
      },
      includePixels: true,
    );
    expect(uniformity(image.rgba!, fixture.expected).passed, isFalse);
  });
}
