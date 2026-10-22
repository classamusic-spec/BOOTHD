/// Decoding the images a scene draws (A-07 step 2, ADR-0010). Shared by
/// on-screen previews and the offscreen export renderer.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;

import '../../domain/template/geometry.dart';

/// An encoded image could not be read.
final class ImageDecodeException implements Exception {
  const ImageDecodeException(this.reason);

  final String reason;

  @override
  String toString() => 'ImageDecodeException($reason)';
}

/// A decoded image and the ratio between its decoded size and the size the
/// scene was compiled against (images may be decoded smaller than their
/// full size to bound memory).
final class DecodedImage {
  DecodedImage(this.image, {required PixelSize sourceSize})
    : _scaleX = image.width / sourceSize.width,
      _scaleY = image.height / sourceSize.height;

  final ui.Image image;
  final double _scaleX;
  final double _scaleY;

  /// [sourceRect], given in full-size source pixels, in decoded pixels.
  ui.Rect decodedRect(PixelRect sourceRect) => ui.Rect.fromLTWH(
    sourceRect.left * _scaleX,
    sourceRect.top * _scaleY,
    sourceRect.width * _scaleX,
    sourceRect.height * _scaleY,
  );

  ui.Rect get fullRect =>
      ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

  void dispose() => image.dispose();
}

/// The size of the encoded image in [bytes] as it will decode: with its
/// EXIF orientation applied (ADR-0007). Reads the header only.
Future<PixelSize> probeImageSize(Uint8List bytes) async {
  if (kIsWeb) {
    // Browsers cannot read the header alone (ADR-0018): the image is
    // decoded by the same decoder that draws it, so the sizes agree.
    final image = await decodeImage(bytes);
    final size = PixelSize(image.width, image.height);
    image.dispose();
    return size;
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  try {
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final size = PixelSize(descriptor.width, descriptor.height);
    descriptor.dispose();
    return size;
  } on Object {
    throw const ImageDecodeException('not a supported image');
  } finally {
    buffer.dispose();
  }
}

/// Decodes [bytes] at [scale] of its full size (at most 1), so a 12 MP
/// original drawn at a quarter of its width is never held at full size.
Future<ui.Image> decodeImage(Uint8List bytes, {double scale = 1}) async {
  if (kIsWeb) {
    // A browser's descriptor has no size before decoding, so the web test
    // build decodes at full size; the drawing scales it as on tablets.
    ui.Codec? codec;
    try {
      codec = await ui.instantiateImageCodec(bytes);
      return (await codec.getNextFrame()).image;
    } on Object {
      throw const ImageDecodeException('the image data is damaged');
    } finally {
      codec?.dispose();
    }
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    final shrink = scale > 0 && scale < 1;
    codec = await descriptor.instantiateCodec(
      targetWidth: shrink
          ? math.max(1, (descriptor.width * scale).ceil())
          : null,
      targetHeight: shrink
          ? math.max(1, (descriptor.height * scale).ceil())
          : null,
    );
    final frame = await codec.getNextFrame();
    return frame.image;
  } on Object {
    throw const ImageDecodeException('the image data is damaged');
  } finally {
    codec?.dispose();
    descriptor?.dispose();
    buffer.dispose();
  }
}
