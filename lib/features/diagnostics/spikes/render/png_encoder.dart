/// Minimal PNG encoder for procedurally generated M01 fixtures.
///
/// Pure Dart, 8-bit RGBA, straight alpha, uncompressed (stored) deflate
/// blocks: files are large but byte-exact and need no platform codec, so
/// fixtures reach the renderer through the same PNG decoder as real assets.
library;

import 'dart:typed_data';

Uint8List encodePngRgba({
  required int width,
  required int height,
  required Uint8List rgba,
}) {
  if (width <= 0 || height <= 0 || rgba.length != width * height * 4) {
    throw ArgumentError('expected ${width}x$height RGBA pixels');
  }
  final rowBytes = width * 4;
  final scanlines = Uint8List(height * (rowBytes + 1));
  for (var y = 0; y < height; y++) {
    // Each scanline starts with filter type 0 (none).
    scanlines.setRange(
      y * (rowBytes + 1) + 1,
      (y + 1) * (rowBytes + 1),
      rgba,
      y * rowBytes,
    );
  }

  final header = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, 6); // colour type: RGBA; compression, filter, interlace 0
  final out = BytesBuilder(copy: false)
    ..add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  _chunk(out, 'IHDR', header.buffer.asUint8List());
  _chunk(out, 'IDAT', _zlibStored(scanlines));
  _chunk(out, 'IEND', Uint8List(0));
  return out.takeBytes();
}

void _chunk(BytesBuilder out, String type, Uint8List data) {
  final typeBytes = Uint8List.fromList(type.codeUnits);
  final length = ByteData(4)..setUint32(0, data.length);
  final crc = ByteData(4)
    ..setUint32(0, _crc32(data, start: _crc32Update(0xFFFFFFFF, typeBytes)));
  out
    ..add(length.buffer.asUint8List())
    ..add(typeBytes)
    ..add(data)
    ..add(crc.buffer.asUint8List());
}

Uint8List _zlibStored(Uint8List data) {
  const maxBlock = 0xFFFF;
  // CMF 0x78 (deflate, 32K window), FLG 0x01 (check bits, no dictionary).
  final out = BytesBuilder(copy: false)..add(const [0x78, 0x01]);
  var offset = 0;
  do {
    final length = (data.length - offset).clamp(0, maxBlock);
    final last = offset + length >= data.length;
    out
      ..addByte(last ? 1 : 0)
      ..add([length & 0xFF, length >> 8, ~length & 0xFF, (~length >> 8) & 0xFF])
      ..add(Uint8List.sublistView(data, offset, offset + length));
    offset += length;
  } while (offset < data.length);
  final adler = ByteData(4)..setUint32(0, _adler32(data));
  out.add(adler.buffer.asUint8List());
  return out.takeBytes();
}

int _adler32(Uint8List data) {
  const modulus = 65521;
  var a = 1;
  var b = 0;
  var i = 0;
  while (i < data.length) {
    // 5552 is the largest run before the sums can overflow 32 bits.
    final end = (i + 5552).clamp(0, data.length);
    for (; i < end; i++) {
      a += data[i];
      b += a;
    }
    a %= modulus;
    b %= modulus;
  }
  return (b << 16) | a;
}

final Uint32List _crcTable = () {
  final table = Uint32List(256);
  for (var n = 0; n < 256; n++) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    table[n] = c;
  }
  return table;
}();

int _crc32Update(int crc, Uint8List bytes) {
  var c = crc;
  for (final byte in bytes) {
    c = _crcTable[(c ^ byte) & 0xFF] ^ (c >> 8);
  }
  return c;
}

int _crc32(Uint8List data, {required int start}) =>
    _crc32Update(start, data) ^ 0xFFFFFFFF;
