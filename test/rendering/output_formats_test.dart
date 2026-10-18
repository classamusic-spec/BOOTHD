// AC-0406: PNG keeps alpha where the page is transparent; JPEG is flattened
// on purpose onto a chosen colour; neither shows an alpha fringe. Both
// carry the print resolution.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/fixture_images.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/render_checks.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/render_fixtures.dart';
import 'package:porcelain_photo_booth/infrastructure/composition/dart_ui_composition_renderer.dart';

import 'support/pixels.dart';

int alphaAt(Uint8List rgba, int width, (int, int) point) =>
    rgba[(point.$2 * width + point.$1) * 4 + 3];

Rgb rgbAt(Uint8List rgba, int width, (int, int) point) =>
    pixelAt(rgba, width, point.$1, point.$2);

Matcher near(Rgb expected, int tolerance) => predicate<Rgb>(
  (actual) =>
      (actual.r - expected.r).abs() <= tolerance &&
      (actual.g - expected.g).abs() <= tolerance &&
      (actual.b - expected.b).abs() <= tolerance,
  '$expected ± $tolerance',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final renderer = DartUiCompositionRenderer();
  final fixture = transparentPage();

  test('PNG keeps the page transparent and the petals translucent', () async {
    final export = await renderer.renderExport(
      fixture.render,
      output: const OutputProfile(format: OutputFormat.png),
    );
    expect(export.mimeType, 'image/png');
    final png = await decodeRgba(export.bytes);
    expect((png.width, png.height), (600, 600));
    expect(alphaAt(png.rgba, 600, transparentPageCorner), 0);
    expect(alphaAt(png.rgba, 600, transparentPageDisc), 255);
    expect(
      rgbAt(png.rgba, 600, transparentPageDisc),
      near(FixtureColours.gold, 2),
    );
    expect(alphaAt(png.rgba, 600, transparentPagePetal), closeTo(191, 3));
    expect(
      rgbAt(png.rgba, 600, transparentPagePetal),
      near(FixtureColours.pink, 3),
    );
  });

  test('PNG edges keep their colour: no dark or light fringe', () async {
    final export = await renderer.renderExport(
      fixture.render,
      output: const OutputProfile(format: OutputFormat.png),
    );
    final png = await decodeRgba(export.bytes);
    var edges = 0;
    for (var i = 0; i < png.rgba.length; i += 4) {
      final alpha = png.rgba[i + 3];
      if (alpha < 32 || alpha > 250) continue;
      edges++;
      // Petal pink and disc gold both have red >= 232: a fringe from
      // filtering unpremultiplied colours would pull it far lower.
      expect(png.rgba[i], greaterThanOrEqualTo(220), reason: 'pixel ${i ~/ 4}');
    }
    expect(edges, greaterThan(500));
  });

  test(
    'JPEG is flattened onto white by default, and onto any chosen colour',
    () async {
      for (final (flatten, page) in [
        (0xFFFFFFFF, FixtureColours.pureWhite),
        (FixtureColours.ivory.argb, FixtureColours.ivory),
      ]) {
        final export = await renderer.renderExport(
          fixture.render,
          flattenArgb: flatten,
        );
        expect(export.mimeType, 'image/jpeg');
        final jpeg = await decodeRgba(export.bytes);
        expect((jpeg.width, jpeg.height), (600, 600));
        expect(alphaAt(jpeg.rgba, 600, transparentPageCorner), 255);
        expect(rgbAt(jpeg.rgba, 600, transparentPageCorner), near(page, 2));
        expect(
          rgbAt(jpeg.rgba, 600, transparentPageDisc),
          near(FixtureColours.gold, 6),
        );
        expect(
          rgbAt(jpeg.rgba, 600, transparentPagePetal),
          near(FixtureColours.pink.over(page, petalAlpha), 6),
        );
      }
    },
  );

  test('a template background wins over the flatten colour', () async {
    final export = await renderer.renderExport(
      fix02().render,
      flattenArgb: 0xFF000000,
    );
    final jpeg = await decodeRgba(export.bytes);
    expect(
      pixelAt(jpeg.rgba, 600, 24, 288),
      isNot(near(FixtureColours.black, 20)),
    );
    expect(pixelAt(jpeg.rgba, 600, 24, 288), near(FixtureColours.ivory, 6));
  });

  test('JPEG quality follows the output profile', () async {
    final low = await renderer.renderExport(
      fix01().render,
      output: const OutputProfile(jpegQuality: 80),
    );
    final high = await renderer.renderExport(
      fix01().render,
      output: const OutputProfile(jpegQuality: 100),
    );
    expect(low.bytes.length, lessThan(high.bytes.length));
  });

  test('both formats carry 300 dpi; PNG also says sRGB', () async {
    final png = (await renderer.renderExport(
      fix01().render,
      output: const OutputProfile(format: OutputFormat.png),
    )).bytes;
    final data = ByteData.sublistView(png);
    final chunks = <String>[];
    for (var offset = 8; offset + 8 <= png.length;) {
      final length = data.getUint32(offset);
      final type = String.fromCharCodes(png, offset + 4, offset + 8);
      chunks.add(type);
      if (type == 'pHYs') {
        expect(data.getUint32(offset + 8), 11811); // 300 dpi in pixels/metre
        expect(data.getUint32(offset + 12), 11811);
        expect(png[offset + 16], 1); // unit: metre
      }
      offset += 12 + length;
    }
    // pHYs right after the header, sRGB from the engine, once each, both
    // before the image data.
    expect(chunks.first, 'IHDR');
    expect(chunks[1], 'pHYs');
    expect(chunks.where((c) => c == 'pHYs'), hasLength(1));
    expect(chunks.where((c) => c == 'sRGB'), hasLength(1));
    expect(chunks.indexOf('sRGB'), lessThan(chunks.indexOf('IDAT')));
    expect(chunks.last, 'IEND');
    expect((await decodeRgba(png)).width, 1200);

    final jpeg = (await renderer.renderExport(fix01().render)).bytes;
    expect(String.fromCharCodes(jpeg, 6, 10), 'JFIF');
    expect(jpeg.sublist(13, 18), [1, 0x01, 0x2C, 0x01, 0x2C]);
  });
}
