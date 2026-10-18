/// Baseline JPEG encoder for print output (A-07 step 6, ADR-0010).
///
/// `dart:ui` encodes PNG only. This encoder is plain Dart, so it runs on a
/// background isolate on both platforms with identical output: baseline
/// sequential DCT, 8-bit, YCbCr without chroma subsampling (4:4:4, which
/// keeps coloured edges and small text sharp in print), the standard
/// ITU-T T.81 Annex K quantisation tables scaled by quality as libjpeg
/// does, the standard Huffman tables, and a JFIF header carrying the print
/// resolution. Alpha is ignored: callers flatten deliberately first.
library;

import 'dart:typed_data';

/// Encodes straight-alpha RGBA [rgba] ([width] x [height], row-major) at
/// [quality] (1 to 100), tagged as [dpi] dots per inch.
Uint8List encodeJpeg(
  Uint8List rgba, {
  required int width,
  required int height,
  int quality = 92,
  int dpi = 300,
}) {
  if (width < 1 || height < 1 || width > 65535 || height > 65535) {
    throw ArgumentError('JPEG sides must be 1 to 65535, got ${width}x$height');
  }
  if (rgba.length != width * height * 4) {
    throw ArgumentError('Expected ${width * height * 4} RGBA bytes');
  }
  if (quality < 1 || quality > 100) {
    throw ArgumentError.value(quality, 'quality', 'must be 1 to 100');
  }
  return _JpegEncoder(quality).encode(rgba, width, height, dpi);
}

// Natural (row-major) index -> zig-zag position.
const _zigZag = [
  0, 1, 5, 6, 14, 15, 27, 28, //
  2, 4, 7, 13, 16, 26, 29, 42,
  3, 8, 12, 17, 25, 30, 41, 43,
  9, 11, 18, 24, 31, 40, 44, 53,
  10, 19, 23, 32, 39, 45, 52, 54,
  20, 22, 33, 38, 46, 51, 55, 60,
  21, 34, 37, 47, 50, 56, 59, 61,
  35, 36, 48, 49, 57, 58, 62, 63,
];

// ITU-T T.81 Annex K.1, natural order.
const _lumaQuant = [
  16, 11, 10, 16, 24, 40, 51, 61, //
  12, 12, 14, 19, 26, 58, 60, 55,
  14, 13, 16, 24, 40, 57, 69, 56,
  14, 17, 22, 29, 51, 87, 80, 62,
  18, 22, 37, 56, 68, 109, 103, 77,
  24, 35, 55, 64, 81, 104, 113, 92,
  49, 64, 78, 87, 103, 121, 120, 101,
  72, 92, 95, 98, 112, 100, 103, 99,
];

const _chromaQuant = [
  17, 18, 24, 47, 99, 99, 99, 99, //
  18, 21, 26, 66, 99, 99, 99, 99,
  24, 26, 56, 99, 99, 99, 99, 99,
  47, 66, 99, 99, 99, 99, 99, 99,
  99, 99, 99, 99, 99, 99, 99, 99,
  99, 99, 99, 99, 99, 99, 99, 99,
  99, 99, 99, 99, 99, 99, 99, 99,
  99, 99, 99, 99, 99, 99, 99, 99,
];

// ITU-T T.81 Annex K.3: code counts for lengths 1 to 16, then values.
const _dcLumaCounts = [0, 1, 5, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0];
const _dcChromaCounts = [0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0];
const _dcValues = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

const _acLumaCounts = [0, 2, 1, 3, 3, 2, 4, 3, 5, 5, 4, 4, 0, 0, 1, 0x7d];
const _acLumaValues = [
  0x01, 0x02, 0x03, 0x00, 0x04, 0x11, 0x05, 0x12, //
  0x21, 0x31, 0x41, 0x06, 0x13, 0x51, 0x61, 0x07,
  0x22, 0x71, 0x14, 0x32, 0x81, 0x91, 0xa1, 0x08,
  0x23, 0x42, 0xb1, 0xc1, 0x15, 0x52, 0xd1, 0xf0,
  0x24, 0x33, 0x62, 0x72, 0x82, 0x09, 0x0a, 0x16,
  0x17, 0x18, 0x19, 0x1a, 0x25, 0x26, 0x27, 0x28,
  0x29, 0x2a, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
  0x3a, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49,
  0x4a, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59,
  0x5a, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69,
  0x6a, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79,
  0x7a, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89,
  0x8a, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98,
  0x99, 0x9a, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7,
  0xa8, 0xa9, 0xaa, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6,
  0xb7, 0xb8, 0xb9, 0xba, 0xc2, 0xc3, 0xc4, 0xc5,
  0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xd2, 0xd3, 0xd4,
  0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xe1, 0xe2,
  0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea,
  0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8,
  0xf9, 0xfa,
];

const _acChromaCounts = [0, 2, 1, 2, 4, 4, 3, 4, 7, 5, 4, 4, 0, 1, 2, 0x77];
const _acChromaValues = [
  0x00, 0x01, 0x02, 0x03, 0x11, 0x04, 0x05, 0x21, //
  0x31, 0x06, 0x12, 0x41, 0x51, 0x07, 0x61, 0x71,
  0x13, 0x22, 0x32, 0x81, 0x08, 0x14, 0x42, 0x91,
  0xa1, 0xb1, 0xc1, 0x09, 0x23, 0x33, 0x52, 0xf0,
  0x15, 0x62, 0x72, 0xd1, 0x0a, 0x16, 0x24, 0x34,
  0xe1, 0x25, 0xf1, 0x17, 0x18, 0x19, 0x1a, 0x26,
  0x27, 0x28, 0x29, 0x2a, 0x35, 0x36, 0x37, 0x38,
  0x39, 0x3a, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48,
  0x49, 0x4a, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58,
  0x59, 0x5a, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68,
  0x69, 0x6a, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78,
  0x79, 0x7a, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87,
  0x88, 0x89, 0x8a, 0x92, 0x93, 0x94, 0x95, 0x96,
  0x97, 0x98, 0x99, 0x9a, 0xa2, 0xa3, 0xa4, 0xa5,
  0xa6, 0xa7, 0xa8, 0xa9, 0xaa, 0xb2, 0xb3, 0xb4,
  0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xc2, 0xc3,
  0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xd2,
  0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda,
  0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9,
  0xea, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8,
  0xf9, 0xfa,
];

// AAN DCT scale factors.
const _aan = [
  1.0, 1.387039845, 1.306562965, 1.175875602, //
  1.0, 0.785694958, 0.541196100, 0.275899379,
];

/// A canonical Huffman table: code and length per symbol.
final class _Huffman {
  _Huffman(List<int> counts, List<int> values)
    : codes = Int32List(256),
      lengths = Int32List(256) {
    var code = 0;
    var k = 0;
    for (var length = 1; length <= 16; length++) {
      for (var i = 0; i < counts[length - 1]; i++) {
        codes[values[k]] = code;
        lengths[values[k]] = length;
        code++;
        k++;
      }
      code <<= 1;
    }
  }

  final Int32List codes;
  final Int32List lengths;
}

final class _JpegEncoder {
  _JpegEncoder(int quality)
    : _lumaTable = _scaledTable(_lumaQuant, quality),
      _chromaTable = _scaledTable(_chromaQuant, quality) {
    _lumaDivisors = _divisors(_lumaTable);
    _chromaDivisors = _divisors(_chromaTable);
  }

  /// Quantisation tables in zig-zag order, as written to the file.
  final Uint8List _lumaTable;
  final Uint8List _chromaTable;
  late final Float64List _lumaDivisors;
  late final Float64List _chromaDivisors;

  final _dcLuma = _Huffman(_dcLumaCounts, _dcValues);
  final _acLuma = _Huffman(_acLumaCounts, _acLumaValues);
  final _dcChroma = _Huffman(_dcChromaCounts, _dcValues);
  final _acChroma = _Huffman(_acChromaCounts, _acChromaValues);

  final _out = _ByteWriter();
  var _bitBuffer = 0;
  var _bitCount = 0;

  static Uint8List _scaledTable(List<int> base, int quality) {
    final scale = quality < 50 ? 5000 ~/ quality : 200 - quality * 2;
    final table = Uint8List(64);
    for (var i = 0; i < 64; i++) {
      table[_zigZag[i]] = ((base[i] * scale + 50) ~/ 100).clamp(1, 255);
    }
    return table;
  }

  /// Multipliers that fold the AAN scaling and the quantiser together,
  /// in natural order.
  static Float64List _divisors(Uint8List zigZagTable) {
    final divisors = Float64List(64);
    for (var row = 0, k = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++, k++) {
        divisors[k] =
            1.0 / (zigZagTable[_zigZag[k]] * _aan[row] * _aan[col] * 8.0);
      }
    }
    return divisors;
  }

  Uint8List encode(Uint8List rgba, int width, int height, int dpi) {
    _writeHeaders(width, height, dpi);

    final y = Float64List(64);
    final cb = Float64List(64);
    final cr = Float64List(64);
    final coefficients = Int32List(64);
    var previousY = 0;
    var previousCb = 0;
    var previousCr = 0;

    for (var blockY = 0; blockY < height; blockY += 8) {
      for (var blockX = 0; blockX < width; blockX += 8) {
        for (var row = 0; row < 8; row++) {
          // Edge blocks repeat the last row and column.
          final py = blockY + row < height ? blockY + row : height - 1;
          final rowStart = py * width;
          for (var col = 0; col < 8; col++) {
            final px = blockX + col < width ? blockX + col : width - 1;
            final p = (rowStart + px) * 4;
            final r = rgba[p].toDouble();
            final g = rgba[p + 1].toDouble();
            final b = rgba[p + 2].toDouble();
            final k = row * 8 + col;
            y[k] = 0.299 * r + 0.587 * g + 0.114 * b - 128;
            cb[k] = -0.168736 * r - 0.331264 * g + 0.5 * b;
            cr[k] = 0.5 * r - 0.418688 * g - 0.081312 * b;
          }
        }
        previousY = _encodeBlock(
          y,
          _lumaDivisors,
          coefficients,
          previousY,
          _dcLuma,
          _acLuma,
        );
        previousCb = _encodeBlock(
          cb,
          _chromaDivisors,
          coefficients,
          previousCb,
          _dcChroma,
          _acChroma,
        );
        previousCr = _encodeBlock(
          cr,
          _chromaDivisors,
          coefficients,
          previousCr,
          _dcChroma,
          _acChroma,
        );
      }
    }

    // Pad the last byte with 1 bits.
    if (_bitCount > 0) _writeBits((1 << (8 - _bitCount)) - 1, 8 - _bitCount);
    _out
      ..byte(0xFF)
      ..byte(0xD9);
    return _out.takeBytes();
  }

  void _writeHeaders(int width, int height, int dpi) {
    final density = dpi.clamp(1, 65535);
    _out
      // Start of image.
      ..byte(0xFF)
      ..byte(0xD8)
      // JFIF 1.01, density in dots per inch, no thumbnail.
      ..byte(0xFF)
      ..byte(0xE0)
      ..word(16)
      ..bytes('JFIF'.codeUnits)
      ..byte(0)
      ..byte(1)
      ..byte(1)
      ..byte(1)
      ..word(density)
      ..word(density)
      ..byte(0)
      ..byte(0)
      // Quantisation tables 0 (luma) and 1 (chroma), zig-zag order.
      ..byte(0xFF)
      ..byte(0xDB)
      ..word(2 + 2 * 65)
      ..byte(0)
      ..bytes(_lumaTable)
      ..byte(1)
      ..bytes(_chromaTable)
      // Baseline frame: 8-bit, three components, no subsampling.
      ..byte(0xFF)
      ..byte(0xC0)
      ..word(17)
      ..byte(8)
      ..word(height)
      ..word(width)
      ..byte(3)
      ..bytes([1, 0x11, 0, 2, 0x11, 1, 3, 0x11, 1])
      // Huffman tables.
      ..byte(0xFF)
      ..byte(0xC4)
      ..word(
        2 +
            (17 + _dcValues.length) * 2 +
            (17 + _acLumaValues.length) +
            (17 + _acChromaValues.length),
      )
      ..byte(0x00)
      ..bytes(_dcLumaCounts)
      ..bytes(_dcValues)
      ..byte(0x10)
      ..bytes(_acLumaCounts)
      ..bytes(_acLumaValues)
      ..byte(0x01)
      ..bytes(_dcChromaCounts)
      ..bytes(_dcValues)
      ..byte(0x11)
      ..bytes(_acChromaCounts)
      ..bytes(_acChromaValues)
      // Start of scan: all three components, full spectrum.
      ..byte(0xFF)
      ..byte(0xDA)
      ..word(12)
      ..byte(3)
      ..bytes([1, 0x00, 2, 0x11, 3, 0x11])
      ..byte(0)
      ..byte(63)
      ..byte(0);
  }

  /// Transforms, quantises and writes one 8x8 block; returns its DC value.
  int _encodeBlock(
    Float64List data,
    Float64List divisors,
    Int32List zigZagOut,
    int previousDc,
    _Huffman dc,
    _Huffman ac,
  ) {
    _forwardDct(data);
    for (var i = 0; i < 64; i++) {
      final value = data[i] * divisors[i];
      zigZagOut[_zigZag[i]] = value > 0
          ? (value + 0.5).toInt()
          : (value - 0.5).toInt();
    }

    final dcValue = zigZagOut[0];
    final diff = dcValue - previousDc;
    if (diff == 0) {
      _writeBits(dc.codes[0], dc.lengths[0]);
    } else {
      final category = diff.abs().bitLength;
      _writeBits(dc.codes[category], dc.lengths[category]);
      _writeBits(diff < 0 ? diff + (1 << category) - 1 : diff, category);
    }

    var last = 63;
    while (last > 0 && zigZagOut[last] == 0) {
      last--;
    }
    if (last == 0) {
      _writeBits(ac.codes[0x00], ac.lengths[0x00]);
      return dcValue;
    }
    var i = 1;
    while (i <= last) {
      final start = i;
      while (zigZagOut[i] == 0) {
        i++;
      }
      var zeros = i - start;
      while (zeros >= 16) {
        _writeBits(ac.codes[0xF0], ac.lengths[0xF0]);
        zeros -= 16;
      }
      final value = zigZagOut[i];
      final category = value.abs().bitLength;
      final symbol = (zeros << 4) | category;
      _writeBits(ac.codes[symbol], ac.lengths[symbol]);
      _writeBits(value < 0 ? value + (1 << category) - 1 : value, category);
      i++;
    }
    if (last != 63) _writeBits(ac.codes[0x00], ac.lengths[0x00]);
    return dcValue;
  }

  void _writeBits(int value, int count) {
    _bitBuffer = (_bitBuffer << count) | (value & ((1 << count) - 1));
    _bitCount += count;
    while (_bitCount >= 8) {
      _bitCount -= 8;
      final byte = (_bitBuffer >> _bitCount) & 0xFF;
      _out.byte(byte);
      if (byte == 0xFF) _out.byte(0); // Byte stuffing.
    }
    _bitBuffer &= (1 << _bitCount) - 1;
  }

  /// In-place AAN forward DCT on an 8x8 block (natural order).
  static void _forwardDct(Float64List d) {
    for (var pass = 0; pass < 2; pass++) {
      final stride = pass == 0 ? 1 : 8;
      final step = pass == 0 ? 8 : 1;
      for (var line = 0; line < 8; line++) {
        final base = line * step;
        final i0 = base;
        final i1 = base + stride;
        final i2 = base + 2 * stride;
        final i3 = base + 3 * stride;
        final i4 = base + 4 * stride;
        final i5 = base + 5 * stride;
        final i6 = base + 6 * stride;
        final i7 = base + 7 * stride;

        final tmp0 = d[i0] + d[i7];
        final tmp7 = d[i0] - d[i7];
        final tmp1 = d[i1] + d[i6];
        final tmp6 = d[i1] - d[i6];
        final tmp2 = d[i2] + d[i5];
        final tmp5 = d[i2] - d[i5];
        final tmp3 = d[i3] + d[i4];
        final tmp4 = d[i3] - d[i4];

        // Even part.
        var tmp10 = tmp0 + tmp3;
        final tmp13 = tmp0 - tmp3;
        var tmp11 = tmp1 + tmp2;
        var tmp12 = tmp1 - tmp2;
        d[i0] = tmp10 + tmp11;
        d[i4] = tmp10 - tmp11;
        final z1 = (tmp12 + tmp13) * 0.707106781;
        d[i2] = tmp13 + z1;
        d[i6] = tmp13 - z1;

        // Odd part.
        tmp10 = tmp4 + tmp5;
        tmp11 = tmp5 + tmp6;
        tmp12 = tmp6 + tmp7;
        final z5 = (tmp10 - tmp12) * 0.382683433;
        final z2 = 0.541196100 * tmp10 + z5;
        final z4 = 1.306562965 * tmp12 + z5;
        final z3 = tmp11 * 0.707106781;
        final z11 = tmp7 + z3;
        final z13 = tmp7 - z3;
        d[i5] = z13 + z2;
        d[i3] = z13 - z2;
        d[i1] = z11 + z4;
        d[i7] = z11 - z4;
      }
    }
  }
}

/// A growable byte buffer.
final class _ByteWriter {
  var _buffer = Uint8List(1 << 16);
  var _length = 0;

  void _ensure(int extra) {
    if (_length + extra <= _buffer.length) return;
    var capacity = _buffer.length * 2;
    while (capacity < _length + extra) {
      capacity *= 2;
    }
    _buffer = Uint8List(capacity)..setRange(0, _length, _buffer);
  }

  void byte(int value) {
    _ensure(1);
    _buffer[_length++] = value;
  }

  void word(int value) {
    _ensure(2);
    _buffer[_length++] = (value >> 8) & 0xFF;
    _buffer[_length++] = value & 0xFF;
  }

  void bytes(List<int> values) {
    _ensure(values.length);
    _buffer.setRange(_length, _length + values.length, values);
    _length += values.length;
  }

  Uint8List takeBytes() => Uint8List.sublistView(_buffer, 0, _length);
}
