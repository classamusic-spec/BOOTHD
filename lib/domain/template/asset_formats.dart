/// Recognising asset files from their bytes, never from names or claimed
/// MIME types (AC-0408, ADR-0010). Header parsing only: pixels are decoded
/// later by the platform decoder, once the header has passed the limits.
library;

import 'dart:typed_data';

import 'template_assets.dart';

/// What an asset file is, according to its header.
final class SniffedAsset {
  const SniffedAsset(this.mediaType, {this.widthPx, this.heightPx});

  final AssetMediaType mediaType;

  /// Stored image size (before any EXIF orientation); null for fonts.
  final int? widthPx;
  final int? heightPx;
}

/// Why bytes were not accepted as an asset.
enum AssetFormatProblem {
  unknownFormat,
  truncated,
  unsupportedVariant,
  malformedHeader,
}

/// The result of [sniffAsset]: an asset, or the problem with the bytes.
typedef SniffResult = ({SniffedAsset? asset, AssetFormatProblem? problem});

SniffResult _fail(AssetFormatProblem problem) =>
    (asset: null, problem: problem);

/// Identifies PNG, JPEG, TrueType and OpenType files.
SniffResult sniffAsset(Uint8List bytes) {
  if (_startsWith(bytes, _pngSignature)) return _png(bytes);
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return _jpeg(bytes);
  }
  if (bytes.length >= 4) {
    final tag = _u32(bytes, 0);
    if (tag == 0x00010000 || tag == _tag('true')) {
      return _font(bytes, AssetMediaType.ttf);
    }
    if (tag == _tag('OTTO')) return _font(bytes, AssetMediaType.otf);
    if (tag == _tag('ttcf') || tag == _tag('wOFF') || tag == _tag('wOF2')) {
      return _fail(AssetFormatProblem.unsupportedVariant);
    }
  }
  return _fail(AssetFormatProblem.unknownFormat);
}

const _pngSignature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

bool _startsWith(Uint8List bytes, List<int> prefix) {
  if (bytes.length < prefix.length) return false;
  for (var i = 0; i < prefix.length; i++) {
    if (bytes[i] != prefix[i]) return false;
  }
  return true;
}

int _u16(Uint8List b, int offset) => (b[offset] << 8) | b[offset + 1];

int _u32(Uint8List b, int offset) =>
    ((b[offset] << 24) |
        (b[offset + 1] << 16) |
        (b[offset + 2] << 8) |
        b[offset + 3]) &
    0xFFFFFFFF;

int _tag(String fourChars) => _u32(Uint8List.fromList(fourChars.codeUnits), 0);

SniffResult _png(Uint8List bytes) {
  // Signature, then the IHDR chunk: length 13, type, width, height, depth,
  // colour type.
  if (bytes.length < 33) return _fail(AssetFormatProblem.truncated);
  if (_u32(bytes, 8) != 13 || _u32(bytes, 12) != _tag('IHDR')) {
    return _fail(AssetFormatProblem.malformedHeader);
  }
  final width = _u32(bytes, 16);
  final height = _u32(bytes, 20);
  final depth = bytes[24];
  final colourType = bytes[25];
  const validDepths = {
    0: {1, 2, 4, 8, 16},
    2: {8, 16},
    3: {1, 2, 4, 8},
    4: {8, 16},
    6: {8, 16},
  };
  if (width == 0 ||
      height == 0 ||
      !(validDepths[colourType]?.contains(depth) ?? false)) {
    return _fail(AssetFormatProblem.malformedHeader);
  }
  return (
    asset: SniffedAsset(AssetMediaType.png, widthPx: width, heightPx: height),
    problem: null,
  );
}

SniffResult _jpeg(Uint8List bytes) {
  var offset = 2;
  while (offset + 4 <= bytes.length) {
    if (bytes[offset] != 0xFF) return _fail(AssetFormatProblem.malformedHeader);
    final marker = bytes[offset + 1];
    if (marker == 0xFF) {
      offset++; // Fill byte.
      continue;
    }
    if (marker == 0xD9 || marker == 0xDA) {
      // The image ended, or its data began, before any frame header.
      return _fail(AssetFormatProblem.malformedHeader);
    }
    if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) {
      offset += 2; // Markers without a length.
      continue;
    }
    final length = _u16(bytes, offset + 2);
    if (length < 2) return _fail(AssetFormatProblem.malformedHeader);
    final isFrame =
        marker >= 0xC0 &&
        marker <= 0xCF &&
        marker != 0xC4 &&
        marker != 0xC8 &&
        marker != 0xCC;
    if (isFrame) {
      if (offset + 9 > bytes.length) return _fail(AssetFormatProblem.truncated);
      // Baseline, extended and progressive Huffman frames only.
      if (marker > 0xC2) return _fail(AssetFormatProblem.unsupportedVariant);
      final height = _u16(bytes, offset + 5);
      final width = _u16(bytes, offset + 7);
      if (width == 0 || height == 0) {
        return _fail(AssetFormatProblem.malformedHeader);
      }
      return (
        asset: SniffedAsset(
          AssetMediaType.jpeg,
          widthPx: width,
          heightPx: height,
        ),
        problem: null,
      );
    }
    offset += 2 + length;
  }
  return _fail(AssetFormatProblem.truncated);
}

SniffResult _font(Uint8List bytes, AssetMediaType type) {
  if (bytes.length < 12) return _fail(AssetFormatProblem.truncated);
  final tables = _u16(bytes, 4);
  if (tables == 0 || tables > 100) {
    return _fail(AssetFormatProblem.malformedHeader);
  }
  if (12 + 16 * tables > bytes.length) {
    return _fail(AssetFormatProblem.truncated);
  }
  final found = <int>{};
  for (var i = 0; i < tables; i++) {
    final entry = 12 + 16 * i;
    final tableOffset = _u32(bytes, entry + 8);
    final tableLength = _u32(bytes, entry + 12);
    if (tableOffset + tableLength > bytes.length) {
      return _fail(AssetFormatProblem.truncated);
    }
    found.add(_u32(bytes, entry));
  }
  const required = ['cmap', 'head', 'hhea', 'hmtx', 'maxp'];
  final hasOutlines =
      found.contains(_tag('glyf')) ||
      found.contains(_tag('CFF ')) ||
      found.contains(_tag('CFF2'));
  if (!required.every((name) => found.contains(_tag(name))) || !hasOutlines) {
    return _fail(AssetFormatProblem.malformedHeader);
  }
  return (asset: SniffedAsset(type), problem: null);
}
