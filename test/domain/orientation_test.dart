import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/value_objects/orientation.dart';

void main() {
  group('ViewportOrientation.fromLogicalSize', () {
    test('wider than tall is landscape', () {
      expect(
        ViewportOrientation.fromLogicalSize(width: 1180, height: 820),
        ViewportOrientation.landscape,
      );
    });

    test('taller than wide is portrait', () {
      expect(
        ViewportOrientation.fromLogicalSize(width: 820, height: 1180),
        ViewportOrientation.portrait,
      );
    });

    test('square and empty windows count as portrait', () {
      expect(
        ViewportOrientation.fromLogicalSize(width: 700, height: 700),
        ViewportOrientation.portrait,
      );
      expect(
        ViewportOrientation.fromLogicalSize(width: 0, height: 0),
        ViewportOrientation.portrait,
      );
    });
  });

  group('PageOrientation.fromPixelSize', () {
    test('4x6 at 300 DPI is portrait at 1200x1800', () {
      expect(
        PageOrientation.fromPixelSize(width: 1200, height: 1800),
        PageOrientation.portrait,
      );
    });

    test('4x6 landscape at 300 DPI is 1800x1200', () {
      expect(
        PageOrientation.fromPixelSize(width: 1800, height: 1200),
        PageOrientation.landscape,
      );
    });

    test('2x6 strip at 300 DPI is portrait', () {
      expect(
        PageOrientation.fromPixelSize(width: 600, height: 1800),
        PageOrientation.portrait,
      );
    });

    test('4x4 at 300 DPI is square', () {
      expect(
        PageOrientation.fromPixelSize(width: 1200, height: 1200),
        PageOrientation.square,
      );
    });

    test('rejects non-positive sizes', () {
      expect(
        () => PageOrientation.fromPixelSize(width: 0, height: 1800),
        throwsArgumentError,
      );
      expect(
        () => PageOrientation.fromPixelSize(width: 1200, height: -1),
        throwsArgumentError,
      );
    });
  });
}
