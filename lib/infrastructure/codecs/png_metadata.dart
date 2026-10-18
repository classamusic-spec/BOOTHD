import 'dart:typed_data';

import 'crc32.dart';

/// Adds print metadata to a PNG from `dart:ui` (ADR-0010): the intended
/// resolution (`pHYs`, so a 1200x1800 file prints as 4x6 inches) and that
/// the pixels are sRGB (`sRGB`). Existing chunks of those types are kept.
Uint8List withPrintMetadata(Uint8List png, {required int dpi}) {
  const signature = 8;
  const ihdrEnd = signature + 8 + 13 + 4;
  if (png.length < ihdrEnd) throw const FormatException('not a PNG');
  final present = _chunkTypes(png);
  final pixelsPerMetre = (dpi / 0.0254).round();
  final chunks = BytesBuilder(copy: false);
  if (!present.contains('pHYs')) {
    chunks.add(
      _chunk(
        'pHYs',
        (ByteData(9)
              ..setUint32(0, pixelsPerMetre)
              ..setUint32(4, pixelsPerMetre)
              ..setUint8(8, 1))
            .buffer
            .asUint8List(),
      ),
    );
  }
  if (!present.contains('sRGB') && !present.contains('iCCP')) {
    chunks.add(_chunk('sRGB', Uint8List.fromList([0])));
  }
  if (chunks.isEmpty) return png;
  return (BytesBuilder(copy: false)
        ..add(Uint8List.sublistView(png, 0, ihdrEnd))
        ..add(chunks.takeBytes())
        ..add(Uint8List.sublistView(png, ihdrEnd)))
      .takeBytes();
}

Set<String> _chunkTypes(Uint8List png) {
  final data = ByteData.sublistView(png);
  final types = <String>{};
  var offset = 8;
  while (offset + 8 <= png.length) {
    final length = data.getUint32(offset);
    types.add(String.fromCharCodes(png, offset + 4, offset + 8));
    offset += 12 + length;
  }
  return types;
}

Uint8List _chunk(String type, Uint8List payload) {
  final out = ByteData(12 + payload.length)..setUint32(0, payload.length);
  final bytes = out.buffer.asUint8List()
    ..setRange(4, 8, type.codeUnits)
    ..setRange(8, 8 + payload.length, payload);
  out.setUint32(
    8 + payload.length,
    Crc32.of(bytes, start: 4, end: 8 + payload.length),
  );
  return bytes;
}
