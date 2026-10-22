import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart' as crypto;

import '../../core/composition/scene_images.dart';
import '../../domain/services/delivery_api.dart';
import '../background/background_work.dart';
import '../codecs/jpeg_encoder.dart';

/// The MMS preview (PD-04, AC-0909): the finished photo decoded at reduced
/// size by the platform decoder and encoded as a JPEG on a background
/// isolate, stepping quality and then size down until it fits the
/// service's byte limit. Typical result: 1024 px on the long side, 150 to
/// 400 KB.
final class JpegPreviewMaker implements PreviewMaker {
  const JpegPreviewMaker();

  static const _qualities = [82, 74, 66, 58];

  @override
  Future<PreviewImage> make(
    Uint8List finished, {
    required int maxBytes,
    int maxSide = 1024,
  }) async {
    final size = await probeImageSize(finished);
    var side = maxSide;
    while (side >= 256) {
      final scale = math.min(1.0, side / math.max(size.width, size.height));
      final image = await decodeImage(finished, scale: scale);
      final width = image.width;
      final height = image.height;
      final ByteData? pixels;
      try {
        pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      } finally {
        image.dispose();
      }
      if (pixels == null) throw StateError('preview could not be decoded');
      final rgba = pixels.buffer.asUint8List(
        pixels.offsetInBytes,
        pixels.lengthInBytes,
      );
      for (final quality in _qualities) {
        final jpeg = await runInBackground(
          () => encodeJpeg(
            rgba,
            width: width,
            height: height,
            quality: quality,
            dpi: 72,
          ),
        );
        if (jpeg.length <= maxBytes) {
          return PreviewImage(
            jpeg,
            width,
            height,
            crypto.sha256.convert(jpeg).toString(),
          );
        }
      }
      side = (side * 0.75).floor();
    }
    throw StateError('preview does not fit the byte limit');
  }
}
