// A-07 step 6 / AC-0406: the JPEG encoder produces standard files that the
// platform decoder reads back faithfully, at any size, deterministically,
// tagged with the print resolution.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/infrastructure/codecs/jpeg_encoder.dart';

Future<(int, int, Uint8List)> decode(Uint8List jpeg) async {
  final codec = await ui.instantiateImageCodec(jpeg);
  final frame = await codec.getNextFrame();
  final data = await frame.image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  final result = (
    frame.image.width,
    frame.image.height,
    data!.buffer.asUint8List(),
  );
  frame.image.dispose();
  codec.dispose();
  return result;
}

/// A smooth photo-like image: gradients, a disc and fine detail.
Uint8List sample(int width, int height, {int seed = 1}) {
  final random = math.Random(seed);
  final rgba = Uint8List(width * height * 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final p = (y * width + x) * 4;
      final dx = x - width / 2;
      final dy = y - height / 2;
      final inDisc = dx * dx + dy * dy < (width * height) / 16;
      rgba[p] = (255 * x / width).round();
      rgba[p + 1] = inDisc ? 200 : (255 * y / height).round();
      rgba[p + 2] = (128 + 60 * math.sin(x / 7) + random.nextInt(9) - 4)
          .round()
          .clamp(0, 255);
      rgba[p + 3] = 255;
    }
  }
  return rgba;
}

double psnr(Uint8List a, Uint8List b) {
  var squared = 0.0;
  var count = 0;
  for (var i = 0; i < a.length; i++) {
    if (i % 4 == 3) continue;
    final d = a[i] - b[i];
    squared += d * d;
    count++;
  }
  final mse = squared / count;
  return mse == 0
      ? double.infinity
      : 10 * math.log(255 * 255 / mse) / math.ln10;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'every size decodes at its size, including partial edge blocks',
    () async {
      for (final (w, h) in [(1, 1), (7, 13), (17, 9), (64, 64), (600, 1800)]) {
        final rgba = sample(w, h);
        final jpeg = encodeJpeg(rgba, width: w, height: h);
        final (dw, dh, pixels) = await decode(jpeg);
        expect((dw, dh), (w, h));
        if (w * h >= 64) {
          expect(psnr(rgba, pixels), greaterThan(30), reason: '${w}x$h');
        }
      }
    },
  );

  test('quality controls fidelity and size', () async {
    final rgba = sample(320, 240);
    final results = <int, (double, int)>{};
    for (final quality in [50, 80, 92, 100]) {
      final jpeg = encodeJpeg(rgba, width: 320, height: 240, quality: quality);
      final (_, _, pixels) = await decode(jpeg);
      results[quality] = (psnr(rgba, pixels), jpeg.length);
    }
    // ignore: avoid_print
    print('JPEG quality -> (PSNR dB, bytes): $results');
    expect(results[92]!.$1, greaterThan(38));
    expect(results[100]!.$1, greaterThan(45));
    expect(results[50]!.$1, lessThan(results[92]!.$1));
    expect(results[50]!.$2, lessThan(results[92]!.$2));
    expect(results[92]!.$2, lessThan(results[100]!.$2));
  });

  test('flat colours come back within 2 levels', () async {
    for (final colour in [
      [255, 255, 255],
      [0, 0, 0],
      [245, 240, 233],
      [200, 40, 40],
      [40, 70, 200],
    ]) {
      final rgba = Uint8List(32 * 24 * 4);
      for (var i = 0; i < rgba.length; i += 4) {
        rgba
          ..[i] = colour[0]
          ..[i + 1] = colour[1]
          ..[i + 2] = colour[2]
          ..[i + 3] = 255;
      }
      final (_, _, pixels) = await decode(
        encodeJpeg(rgba, width: 32, height: 24, quality: 92),
      );
      for (var i = 0; i < pixels.length; i += 4) {
        for (var c = 0; c < 3; c++) {
          expect((pixels[i + c] - colour[c]).abs(), lessThanOrEqualTo(2));
        }
      }
    }
  });

  test('the file is baseline JFIF tagged with the print resolution', () {
    final jpeg = encodeJpeg(sample(16, 16), width: 16, height: 16, dpi: 300);
    expect(jpeg.sublist(0, 4), [0xFF, 0xD8, 0xFF, 0xE0]);
    expect(String.fromCharCodes(jpeg, 6, 10), 'JFIF');
    // Units 1 (dots per inch), then 300 x 300.
    expect(jpeg.sublist(13, 18), [1, 0x01, 0x2C, 0x01, 0x2C]);
    expect(jpeg.sublist(jpeg.length - 2), [0xFF, 0xD9]);
    final sof = jpeg.indexOf(0xC0, 2);
    expect(jpeg[sof - 1], 0xFF);
  });

  test('the same pixels always encode to the same bytes', () {
    final rgba = sample(100, 70, seed: 9);
    expect(
      encodeJpeg(rgba, width: 100, height: 70),
      encodeJpeg(rgba, width: 100, height: 70),
    );
  });

  test('bad arguments are refused', () {
    expect(
      () => encodeJpeg(Uint8List(4), width: 2, height: 2),
      throwsArgumentError,
    );
    expect(
      () => encodeJpeg(Uint8List(4), width: 1, height: 1, quality: 0),
      throwsArgumentError,
    );
    expect(
      () => encodeJpeg(Uint8List(0), width: 0, height: 0),
      throwsArgumentError,
    );
  });
}
