import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/jpeg_exif.dart';

Uint8List _fixture(String name) =>
    File('test_assets/input_photos/$name').readAsBytesSync();

/// A minimal JPEG prefix with one big-endian ("MM") EXIF orientation tag.
Uint8List _bigEndianExif(int orientation) {
  final tiff = [
    0x4D, 0x4D, 0x00, 0x2A, 0x00, 0x00, 0x00, 0x08, // header, IFD0 at 8
    0x00, 0x01, // one entry
    0x01, 0x12, 0x00, 0x03, 0x00, 0x00, 0x00, 0x01, // Orientation SHORT x1
    0x00, orientation, 0x00, 0x00, // value
    0x00, 0x00, 0x00, 0x00, // no next IFD
  ];
  final app1 = [0x45, 0x78, 0x69, 0x66, 0x00, 0x00, ...tiff];
  final length = app1.length + 2;
  return Uint8List.fromList([
    0xFF, 0xD8, // SOI
    0xFF, 0xE1, length >> 8, length & 0xFF, ...app1,
    0xFF, 0xD9, // EOI
  ]);
}

void main() {
  test('reads orientation 1 and 6 from camera-style JPEGs', () {
    expect(
      readJpegExifOrientation(_fixture('exif_orientation_1_640x480.jpg')),
      1,
    );
    expect(
      readJpegExifOrientation(_fixture('exif_orientation_6_640x480.jpg')),
      6,
    );
  });

  test('reads big-endian EXIF blocks', () {
    expect(readJpegExifOrientation(_bigEndianExif(3)), 3);
  });

  test('returns null, never throws, for non-JPEG or malformed input', () {
    final jpeg = _fixture('exif_orientation_6_640x480.jpg');
    expect(readJpegExifOrientation(Uint8List(0)), isNull);
    expect(
      readJpegExifOrientation(Uint8List.fromList([0x89, 0x50, 0x4E, 0x47])),
      isNull,
    );
    expect(readJpegExifOrientation(Uint8List.sublistView(jpeg, 0, 30)), isNull);
    expect(readJpegExifOrientation(_bigEndianExif(9)), isNull);
  });
}
