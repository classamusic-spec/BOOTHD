// AC-0408: assets are accepted on their content (format, variant, limits,
// a full decode), stored once under their SHA-256 with the size they decode
// to, and read back only if unchanged. Refusals store nothing.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/templates/starter_designs.dart';
import 'package:porcelain_photo_booth/domain/repositories/template_store.dart';
import 'package:porcelain_photo_booth/domain/template/asset_formats.dart';
import 'package:porcelain_photo_booth/domain/template/editing/document_edits.dart';
import 'package:porcelain_photo_booth/domain/template/template_assets.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/fixture_images.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/png_encoder.dart';
import 'package:porcelain_photo_booth/infrastructure/codecs/crc32.dart';
import 'package:porcelain_photo_booth/infrastructure/codecs/jpeg_encoder.dart';

import '../../support/template_store_harness.dart';

Uint8List _png(int width, int height) => encodePngRgba(
  width: width,
  height: height,
  rgba: Uint8List(width * height * 4)..fillRange(0, width * height * 4, 200),
);

Uint8List _jpeg(int width, int height) => encodeJpeg(
  Uint8List(width * height * 4)..fillRange(0, width * height * 4, 90),
  width: width,
  height: height,
);

/// [jpeg] with an EXIF block saying "rotate 90° clockwise to display"
/// (orientation 6), as tablets write portrait photos.
Uint8List _rotatedJpeg(Uint8List jpeg) {
  final tiff = ByteData(26)
    ..setUint16(0, 0x4D4D) // "MM": big-endian
    ..setUint16(2, 42)
    ..setUint32(4, 8)
    ..setUint16(8, 1) // one entry
    ..setUint16(10, 0x0112) // Orientation
    ..setUint16(12, 3) // SHORT
    ..setUint32(14, 1)
    ..setUint16(18, 6)
    ..setUint32(22, 0); // no next IFD
  final payload = [...utf8.encode('Exif'), 0, 0, ...tiff.buffer.asUint8List()];
  final length = payload.length + 2;
  return Uint8List.fromList([
    0xFF, 0xD8, // SOI
    0xFF, 0xE1, length >> 8, length & 0xFF, ...payload,
    ...jpeg.sublist(2),
  ]);
}

/// A PNG signature and IHDR claiming [width] x [height], and nothing else.
Uint8List _pngHeaderOnly(int width, int height, {int colourType = 6}) {
  final ihdr = ByteData(17)
    ..setUint32(0, 0x49484452) // "IHDR"
    ..setUint32(4, width)
    ..setUint32(8, height)
    ..setUint8(12, 8)
    ..setUint8(13, colourType);
  final body = ihdr.buffer.asUint8List();
  return Uint8List.fromList([
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0,
    0,
    0,
    13,
    ...body,
    ...(ByteData(4)..setUint32(0, Crc32.of(body))).buffer.asUint8List(),
  ]);
}

Matcher _refused(TemplateStoreErrorCode code) =>
    throwsA(isA<TemplateStoreException>().having((e) => e.code, 'code', code));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TemplateStoreHarness harness;

  setUp(() async => harness = await TemplateStoreHarness.create());
  tearDown(() => harness.dispose());

  test('PNG, JPEG and font files are stored once, by content', () async {
    final png = _png(40, 30);
    final jpeg = _jpeg(64, 48);
    final font = File('assets/fonts/inter/Inter-Regular.ttf').readAsBytesSync();
    final stored = [
      await harness.assets.store(
        png,
        name: 'leaf.png',
        origin: AssetOrigin.imported,
      ),
      await harness.assets.store(jpeg, origin: AssetOrigin.package),
      await harness.assets.store(
        font,
        name: 'Inter.ttf',
        origin: AssetOrigin.package,
      ),
    ];
    expect(
      [for (final s in stored) s.id],
      [assetIdOf(png), assetIdOf(jpeg), assetIdOf(font)],
    );
    expect(
      stored[0].asset,
      TemplateAsset(
        mediaType: AssetMediaType.png,
        byteLength: png.length,
        widthPx: 40,
        heightPx: 30,
        name: 'leaf.png',
      ),
    );
    expect(stored[1].asset.mediaType, AssetMediaType.jpeg);
    expect((stored[1].asset.widthPx, stored[1].asset.heightPx), (64, 48));
    expect(stored[2].asset.mediaType, AssetMediaType.ttf);
    expect(stored[2].asset.widthPx, isNull);
    for (final asset in stored) {
      final file = harness.file(
        'assets/${asset.id}.${asset.asset.mediaType.extension}',
      );
      expect(file.existsSync(), isTrue);
      expect(await harness.assets.read(asset.id), file.readAsBytesSync());
    }

    // The same bytes again: the same asset, no new file or row.
    final before = harness.snapshot();
    final again = await harness.assets.store(
      png,
      name: 'other-name.png',
      origin: AssetOrigin.package,
    );
    expect(again.id, stored[0].id);
    expect(again.asset.name, 'leaf.png');
    expect(harness.snapshot(), before);
    expect((await harness.rowCounts()).assets, 3);
  });

  test('a rotated camera JPEG is recorded at the size it displays', () async {
    final rotated = _rotatedJpeg(_jpeg(64, 48));
    final stored = await harness.assets.store(
      rotated,
      origin: AssetOrigin.imported,
    );
    expect((stored.asset.widthPx, stored.asset.heightPx), (48, 64));
  });

  test('names are reduced to a plain file name', () async {
    final stored = await harness.assets.store(
      _png(4, 4),
      name: r'..\..\Users\ops/Desktop/../flower.png',
      origin: AssetOrigin.imported,
    );
    expect(stored.asset.name, 'flower.png');
  });

  group('refused, and nothing stored:', () {
    final cases = <String, (Uint8List Function(), TemplateStoreErrorCode)>{
      'text': (
        () => Uint8List.fromList(utf8.encode('not an image')),
        TemplateStoreErrorCode.assetUnknownFormat,
      ),
      'an empty file': (
        () => Uint8List(0),
        TemplateStoreErrorCode.assetUnknownFormat,
      ),
      'a font collection': (
        () =>
            Uint8List.fromList([...utf8.encode('ttcf'), ...List.filled(60, 0)]),
        TemplateStoreErrorCode.assetUnsupportedVariant,
      ),
      'a web font': (
        () =>
            Uint8List.fromList([...utf8.encode('wOF2'), ...List.filled(60, 0)]),
        TemplateStoreErrorCode.assetUnsupportedVariant,
      ),
      'a truncated PNG': (
        () => Uint8List.sublistView(_png(64, 64), 0, 60),
        TemplateStoreErrorCode.assetDamaged,
      ),
      'a PNG with its pixel data cut off': (
        () {
          final png = flowerPng();
          return Uint8List.sublistView(png, 0, png.length ~/ 2);
        },
        TemplateStoreErrorCode.assetDamaged,
      ),
      'a PNG wider than 12000 pixels': (
        () => _pngHeaderOnly(12001, 10),
        TemplateStoreErrorCode.assetTooLarge,
      ),
      'a PNG over 50 megapixels': (
        () => _pngHeaderOnly(8000, 8000),
        TemplateStoreErrorCode.assetTooLarge,
      ),
    };
    for (final MapEntry(key: name, value: (bytes, code)) in cases.entries) {
      test(name, () async {
        await expectLater(
          harness.assets.store(bytes(), origin: AssetOrigin.imported),
          _refused(code),
        );
        expect(harness.snapshot(), isEmpty);
        expect((await harness.rowCounts()).assets, 0);
      });
    }
  });

  test('reading checks the file is still the one stored', () async {
    final png = _png(8, 8);
    final stored = await harness.assets.store(
      png,
      origin: AssetOrigin.imported,
    );
    final file = harness.file('assets/${stored.id}.png');

    file.writeAsBytesSync(Uint8List.fromList(png)..[png.length - 20] ^= 1);
    await expectLater(
      harness.assets.read(stored.id),
      _refused(TemplateStoreErrorCode.assetMismatch),
    );
    file.deleteSync();
    await expectLater(
      harness.assets.read(stored.id),
      _refused(TemplateStoreErrorCode.assetMissing),
    );
    await expectLater(
      harness.assets.read('0' * 64),
      _refused(TemplateStoreErrorCode.assetMissing),
    );
    await expectLater(
      harness.assets.read('../../database/porcelain_booth.sqlite'),
      _refused(TemplateStoreErrorCode.assetMissing),
    );

    // Storing the same bytes again repairs the file.
    await harness.assets.store(png, origin: AssetOrigin.imported);
    expect(await harness.assets.read(stored.id), png);
  });

  test('a file left by an interrupted import is reused', () async {
    final png = _png(8, 8);
    final id = assetIdOf(png);
    harness.file('assets/$id.png').writeAsBytesSync(png);
    final stored = await harness.assets.store(
      png,
      origin: AssetOrigin.imported,
    );
    expect(stored.id, id);
    expect(await harness.assets.read(id), png);
  });

  group('asset browser (S08)', () {
    test('lists imported and package images, newest first', () async {
      final font = File('assets/fonts/inter/Inter-Regular.ttf')
          .readAsBytesSync();
      await harness.assets.store(font, origin: AssetOrigin.imported);
      await harness.assets.store(_png(4, 4), origin: AssetOrigin.bundled);
      final first = await harness.assets.store(
        _png(5, 5),
        origin: AssetOrigin.imported,
      );
      harness.clock.advance(const Duration(minutes: 1));
      final second = await harness.assets.store(
        _jpeg(16, 16),
        origin: AssetOrigin.package,
      );
      expect(
        [for (final a in await harness.assets.watchImages().first) a.id],
        [second.id, first.id],
      );
    });

    test('rename changes the shown name only', () async {
      final stored = await harness.assets.store(
        _png(6, 6),
        name: 'scan.png',
        origin: AssetOrigin.imported,
      );
      await harness.assets.rename(stored.id, '  Gold leaf.png ');
      expect(
        (await harness.assets.find(stored.id))!.asset.name,
        'Gold leaf.png',
      );
      await expectLater(
        harness.assets.rename(stored.id, '  '),
        _refused(TemplateStoreErrorCode.invalidDocument),
      );
      await expectLater(
        harness.assets.rename('f' * 64, 'x.png'),
        _refused(TemplateStoreErrorCode.notFound),
      );
    });

    test('only an image nothing uses can be removed', () async {
      final png = _png(7, 7);
      final stored = await harness.assets.store(
        png,
        origin: AssetOrigin.imported,
      );
      final file = harness.file('assets/${stored.id}.png');

      // Used by a saved revision.
      final template = await harness.library.create(
        starterDesigns.firstWhere((d) => d.id == 'blank-4x4'),
        name: 'Uses it',
      );
      var document = (await harness.templates.loadRevision(template.revisionId))
          .document;
      document = DocumentEdits.add(
        document,
        NewLayers.image(document, 'art', stored.id, stored.asset),
        assets: {stored.id: stored.asset},
      );
      final saved = await harness.library.save(template.templateId, document);
      expect(await harness.assets.isInUse(stored.id), isTrue);
      await expectLater(
        harness.assets.remove(stored.id),
        _refused(TemplateStoreErrorCode.assetInUse),
      );

      // Used only by an unsaved draft.
      final other = await harness.assets.store(
        _png(9, 9),
        origin: AssetOrigin.imported,
      );
      await harness.library.saveDraft(
        template.templateId,
        baseRevisionId: saved.summary.revisionId,
        document: DocumentEdits.add(
          document,
          NewLayers.image(document, 'more', other.id, other.asset),
          assets: {other.id: other.asset},
        ),
      );
      expect(await harness.assets.isInUse(other.id), isTrue);
      await expectLater(
        harness.assets.remove(other.id),
        _refused(TemplateStoreErrorCode.assetInUse),
      );
      await harness.library.discardDraft(template.templateId);
      expect(await harness.assets.isInUse(other.id), isFalse);
      await harness.assets.remove(other.id);
      expect(await harness.assets.find(other.id), isNull);
      expect(harness.file('assets/${other.id}.png').existsSync(), isFalse);

      // The used one is untouched.
      expect(file.existsSync(), isTrue);
      expect(await harness.assets.read(stored.id), png);
    });

    test('PNG transparency is read from the header', () {
      expect(pngHasTransparency(flowerPng()), isTrue);
      expect(pngHasTransparency(_jpeg(8, 8)), isFalse);
      // RGB without a transparency chunk; RGB with one.
      final rgb = _pngHeaderOnly(4, 4, colourType: 2);
      expect(pngHasTransparency(rgb), isFalse);
      final trns = [0, 0, 0, 6, ...'tRNS'.codeUnits, 0, 0, 0, 0, 0, 0];
      expect(
        pngHasTransparency(Uint8List.fromList([...rgb, ...trns, 0, 0, 0, 0])),
        isTrue,
      );
    });
  });
}

/// A real, compressed PNG (FIX-01's flower).
Uint8List flowerPng() {
  final image = flower(size: 200);
  return encodePngRgba(
    width: image.width,
    height: image.height,
    rgba: image.pixels,
  );
}
