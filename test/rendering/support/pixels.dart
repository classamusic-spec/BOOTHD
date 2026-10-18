import 'dart:typed_data';
import 'dart:ui' as ui;

/// Decodes an encoded image to straight RGBA with its size.
Future<({int width, int height, Uint8List rgba})> decodeRgba(
  Uint8List bytes,
) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final data = await frame.image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  final result = (
    width: frame.image.width,
    height: frame.image.height,
    rgba: data!.buffer.asUint8List(),
  );
  frame.image.dispose();
  codec.dispose();
  return result;
}
