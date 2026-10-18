import 'dart:math' as math;
import 'dart:typed_data';

import '../../domain/template/document_scene.dart';
import '../../domain/template/geometry.dart';
import 'scene_images.dart';
import 'scene_painter.dart';
import 'template_fonts.dart';

/// An image did not decode to the size its document records.
final class ImageMismatchException implements Exception {
  const ImageMismatchException(this.source, this.expected, this.actual);

  final ImageSourceRef source;
  final PixelSize expected;
  final PixelSize actual;

  @override
  String toString() =>
      'ImageMismatchException($source: expected $expected, got $actual)';
}

/// A scene's image could not be read or decoded.
final class SceneImageException implements Exception {
  const SceneImageException(this.source, this.reason);

  final ImageSourceRef source;
  final String reason;

  @override
  String toString() => 'SceneImageException($source: $reason)';
}

/// Reads, decodes and resolves everything [scene] draws (A-07 steps 1-2).
///
/// Each image is decoded no larger than [outputScale] times the largest
/// size the scene draws it at (never above full size), which bounds memory
/// for full-resolution originals and makes previews cheap. Every image must
/// decode, with its orientation applied, to the size the scene was compiled
/// against; a different size means the file changed and the render stops.
Future<SceneResources> loadSceneResources(
  DocumentScene scene, {
  required Future<Uint8List> Function(ImageSourceRef source) readImage,
  required Future<Uint8List> Function(String assetId) readFont,
  required TemplateFontLoader fonts,
  double outputScale = 1,
}) async {
  final images = <ImageSourceRef, DecodedImage>{};
  try {
    for (final MapEntry(key: source, value: expected)
        in scene.imageSizes.entries) {
      final bytes = await readImage(source);
      final PixelSize actual;
      try {
        actual = await probeImageSize(bytes);
      } on ImageDecodeException catch (error) {
        throw SceneImageException(source, error.reason);
      }
      if (actual != expected) {
        throw ImageMismatchException(source, expected, actual);
      }
      final scale = math.min(1.0, scene.drawScale(source) * outputScale);
      try {
        images[source] = DecodedImage(
          await decodeImage(bytes, scale: scale),
          sourceSize: expected,
        );
      } on ImageDecodeException catch (error) {
        throw SceneImageException(source, error.reason);
      }
    }
    return SceneResources(
      images: images,
      fonts: {
        for (final font in scene.fonts)
          font: await fonts.resolve(font, readFont),
      },
    );
  } on Object {
    for (final image in images.values) {
      image.dispose();
    }
    rethrow;
  }
}
