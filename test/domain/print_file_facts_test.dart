// AC-0807 (rules): a finished photo's file is read for its format, pixel
// size, print resolution and completeness without decoding, and the
// print-ready check fails for a damaged, truncated, mis-sized or untagged
// file.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/gallery/print_file_facts.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/png_encoder.dart';
import 'package:porcelain_photo_booth/infrastructure/codecs/jpeg_encoder.dart';
import 'package:porcelain_photo_booth/infrastructure/codecs/png_metadata.dart';

Uint8List _rgba(int width, int height) =>
    Uint8List(width * height * 4)..fillRange(0, width * height * 4, 200);

void main() {
  final jpeg = encodeJpeg(_rgba(120, 180), width: 120, height: 180, dpi: 300);
  final png = withPrintMetadata(
    encodePngRgba(width: 120, height: 180, rgba: _rgba(120, 180)),
    dpi: 300,
  );

  test('JPEG and PNG facts come from their headers', () {
    final j = PrintFileFacts.read(jpeg);
    expect(
      (j.format, j.widthPx, j.heightPx, j.dpi, j.complete),
      (OutputFormat.jpeg, 120, 180, 300, true),
    );
    final p = PrintFileFacts.read(png);
    expect(
      (p.format, p.widthPx, p.heightPx, p.dpi, p.complete),
      (OutputFormat.png, 120, 180, 300, true),
    );
    expect(PrintFileFacts.read(Uint8List.fromList([1, 2, 3])).format, isNull);
  });

  test('a cut-off file is incomplete', () {
    expect(
      PrintFileFacts.read(Uint8List.sublistView(jpeg, 0, jpeg.length - 40))
          .complete,
      isFalse,
    );
    expect(
      PrintFileFacts.read(Uint8List.sublistView(png, 0, png.length - 12))
          .complete,
      isFalse,
    );
  });

  test('a JPEG without a resolution tag has none', () {
    // JFIF density units 0 means "aspect ratio only".
    final untagged = Uint8List.fromList(jpeg);
    final app0 = untagged.indexOf(0xE0, 2) + 3;
    untagged[app0 + 7] = 0;
    expect(PrintFileFacts.read(untagged).dpi, isNull);
  });

  PrintReadiness check(
    Uint8List? bytes, {
    bool intact = true,
    int width = 120,
    int height = 180,
    int? pageWidth = 120,
    int? pageHeight = 180,
  }) => PrintReadiness.check(
    bytes: bytes,
    intact: intact,
    format: OutputFormat.jpeg,
    widthPx: width,
    heightPx: height,
    pageWidthPx: pageWidth,
    pageHeightPx: pageHeight,
  );

  test('a complete, tagged file of the page size is print-ready', () {
    final ready = check(jpeg);
    expect(ready.ready, isTrue);
    expect(ready.inches, (0.4, 0.6));
  });

  test('each problem fails its own check', () {
    expect(check(null, intact: false).failed, {
      PrintCheckId.intact,
      PrintCheckId.format,
      PrintCheckId.pixelSize,
      PrintCheckId.resolution,
    });
    expect(check(jpeg, width: 1200).failed, {PrintCheckId.pixelSize});
    expect(check(jpeg, pageWidth: 600).failed, {PrintCheckId.pixelSize});
    expect(check(Uint8List.sublistView(jpeg, 0, jpeg.length - 40)).failed, {
      PrintCheckId.format,
    });
    expect(check(png).failed, {
      PrintCheckId.format,
    }, reason: 'a PNG recorded as JPEG');
  });
}
