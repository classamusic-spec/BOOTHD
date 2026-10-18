import 'dart:typed_data';

/// Reads the EXIF orientation tag (1–8) from JPEG [bytes].
///
/// Returns null when the data is not a JPEG, has no EXIF block or no
/// orientation tag, or is malformed; it never throws. Used to record what
/// the camera wrote; the platform decoder applies the orientation itself
/// (ADR-0007), so the app must not rotate again.
int? readJpegExifOrientation(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  if (bytes.length < 4 || data.getUint16(0) != 0xFFD8) return null;
  var offset = 2;
  while (offset + 4 <= bytes.length) {
    if (bytes[offset] != 0xFF) return null;
    final marker = bytes[offset + 1];
    // Start of scan or end of image: no more metadata segments.
    if (marker == 0xDA || marker == 0xD9) return null;
    final length = data.getUint16(offset + 2);
    if (length < 2 || offset + 2 + length > bytes.length) return null;
    if (marker == 0xE1) {
      final orientation = _orientationFromApp1(data, offset + 4, length - 2);
      if (orientation != null) return orientation;
    }
    offset += 2 + length;
  }
  return null;
}

int? _orientationFromApp1(ByteData data, int start, int length) {
  // "Exif\0\0" then a TIFF header.
  const exifHeader = [0x45, 0x78, 0x69, 0x66, 0x00, 0x00];
  if (length < 14) return null;
  for (var i = 0; i < exifHeader.length; i++) {
    if (data.getUint8(start + i) != exifHeader[i]) return null;
  }
  final tiff = start + 6;
  final end = start + length;
  final Endian endian;
  switch (data.getUint16(tiff)) {
    case 0x4949:
      endian = Endian.little;
    case 0x4D4D:
      endian = Endian.big;
    default:
      return null;
  }
  if (data.getUint16(tiff + 2, endian) != 42) return null;
  final ifd0 = tiff + data.getUint32(tiff + 4, endian);
  if (ifd0 + 2 > end) return null;
  final entries = data.getUint16(ifd0, endian);
  for (var i = 0; i < entries; i++) {
    final entry = ifd0 + 2 + i * 12;
    if (entry + 12 > end) return null;
    // Tag 0x0112 Orientation, type 3 (SHORT), count 1, value inline.
    if (data.getUint16(entry, endian) == 0x0112 &&
        data.getUint16(entry + 2, endian) == 3) {
      final value = data.getUint16(entry + 8, endian);
      return value >= 1 && value <= 8 ? value : null;
    }
  }
  return null;
}
