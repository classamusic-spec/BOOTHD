// AC-0408 and FIX-06: template packages move a revision and its assets
// between booths unchanged, and every damaged, hostile or unsupported
// package is refused with its own code before anything is stored.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/repositories/template_store.dart';
import 'package:porcelain_photo_booth/domain/template/document_issues.dart';
import 'package:porcelain_photo_booth/domain/template/geometry.dart';
import 'package:porcelain_photo_booth/domain/template/page_spec.dart';
import 'package:porcelain_photo_booth/domain/template/template_assets.dart';
import 'package:porcelain_photo_booth/domain/template/template_document.dart';
import 'package:porcelain_photo_booth/domain/template/template_layers.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/fixture_images.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/png_encoder.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/render_fixtures.dart';
import 'package:porcelain_photo_booth/infrastructure/templates/zip_archive.dart';
import 'package:porcelain_photo_booth/infrastructure/templates/zip_template_packages.dart';

import '../../support/template_store_harness.dart';
import 'support/raw_zip.dart';

Matcher _refused(TemplateStoreErrorCode code) =>
    throwsA(isA<TemplateStoreException>().having((e) => e.code, 'code', code));

/// The entries of [package], changed by [edit], zipped again.
Uint8List _repack(
  Uint8List package,
  void Function(Map<String, Uint8List> entries) edit,
) {
  final entries = Map.of(
    readZip(package, limits: TemplatePackageFormat.limits).files,
  );
  edit(entries);
  return writeZip([
    for (final MapEntry(key: name, value: bytes) in entries.entries)
      (name: name, bytes: bytes),
  ]);
}

/// [package] with its template.json changed by [edit].
Uint8List _editManifest(
  Uint8List package,
  void Function(Map<String, Object?> manifest) edit,
) => _repack(package, (entries) {
  final manifest = jsonDecode(
    utf8.decode(entries['template.json']!),
  ) as Map<String, Object?>;
  edit(manifest);
  entries['template.json'] = utf8.encode(jsonEncode(manifest));
});

Map<String, Object?> _document(Map<String, Object?> manifest) =>
    manifest['document']! as Map<String, Object?>;

/// A one-image template around [bytes], declared as [declared].
Uint8List _imagePackage(Uint8List bytes, TemplateAsset declared) {
  final id = assetIdOf(bytes);
  return encodeTemplatePackage(
    name: 'Probe',
    document: TemplateDocument(
      page: PageSpec.fourByFour,
      assets: {id: declared},
      layers: [
        ImageLayer(
          id: 'image',
          zIndex: 1,
          assetId: id,
          frame: const NormalizedRect(x: 0.1, y: 0.1, width: 0.5, height: 0.5),
        ),
      ],
    ),
    assets: {id: bytes},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = fix01();
  final flowerId = fixture.document.assets.keys.firstWhere(
    (id) => fixture.document.assets[id]!.name == 'flower.png',
  );
  late Uint8List package;
  late TemplateStoreHarness target;

  setUpAll(() async {
    final source = await TemplateStoreHarness.create();
    final summary = await source.storeFixture(fixture, name: 'Two-up');
    package = await source.packages.exportPackage(summary.revisionId);
    await source.dispose();
  });

  setUp(() async => target = await TemplateStoreHarness.create());
  tearDown(() => target.dispose());

  test('a package carries a revision to another booth unchanged', () async {
    final entries = readZip(package, limits: TemplatePackageFormat.limits);
    expect(entries.names.first, 'template.json');
    expect(entries.names.skip(1), [
      for (final id in fixture.document.assets.keys.toList()..sort())
        'assets/$id.png',
    ]);

    final imported = await target.packages.importPackage(package);
    expect(imported.templateName, 'Two-up');
    expect(imported.revisionNumber, 1);
    final revision = await target.templates.loadRevision(imported.revisionId);
    expect(revision.document, fixture.document);
    for (final MapEntry(key: id, value: bytes) in fixture.assets.entries) {
      expect(await target.assets.read(id), bytes);
    }
    // Exporting again gives the same bytes.
    expect(await target.packages.exportPackage(imported.revisionId), package);
  });

  test('importing twice adds a second template, replacing nothing', () async {
    final first = await target.packages.importPackage(package);
    final before = target.snapshot();
    final second = await target.packages.importPackage(package);
    expect(second.templateId, isNot(first.templateId));
    final after = target.snapshot();
    for (final MapEntry(:key, :value) in before.entries) {
      expect(after[key], value, reason: key);
    }
    final counts = await target.rowCounts();
    expect((counts.templates, counts.revisions), (2, 2));
    expect(counts.assets, fixture.assets.length, reason: 'stored once');
  });

  test('files macOS adds when zipping a folder are ignored', () async {
    final zipped = _repack(package, (entries) {
      entries['__MACOSX/._template.json'] = Uint8List.fromList([0, 5, 22]);
      entries['.DS_Store'] = Uint8List.fromList([1, 2, 3]);
    });
    final imported = await target.packages.importPackage(zipped);
    expect(
      (await target.templates.loadRevision(imported.revisionId)).document,
      fixture.document,
    );
  });

  group('FIX-06: refused, and nothing stored:', () {
    final cases = <String, (Uint8List Function(), TemplateStoreErrorCode)>{
      'a corrupt PNG': (
        () {
          final png = encodePngRgba(
            width: 200,
            height: 200,
            rgba: flower(size: 200).pixels,
          );
          final cut = Uint8List.sublistView(png, 0, png.length ~/ 2);
          return _imagePackage(
            cut,
            TemplateAsset(
              mediaType: AssetMediaType.png,
              byteLength: cut.length,
              widthPx: 200,
              heightPx: 200,
            ),
          );
        },
        TemplateStoreErrorCode.assetDamaged,
      ),
      'an image larger than its header limit': (
        () {
          final header = Uint8List.fromList([
            ...encodePngRgba(width: 1, height: 1, rgba: Uint8List(4)),
          ]);
          // Rewrite the IHDR width to 12001 (the CRC no longer matters:
          // the limit check comes before any decoding).
          ByteData.sublistView(header).setUint32(16, 12001);
          return _imagePackage(
            header,
            TemplateAsset(
              mediaType: AssetMediaType.png,
              byteLength: header.length,
              widthPx: 100,
              heightPx: 100,
            ),
          );
        },
        TemplateStoreErrorCode.assetTooLarge,
      ),
      'an unknown layer type': (
        () => _editManifest(package, (manifest) {
          final layers = _document(manifest)['layers']! as List<Object?>;
          (layers[1]! as Map<String, Object?>)['type'] = 'hologram';
        }),
        TemplateStoreErrorCode.invalidDocument,
      ),
      'a newer document version': (
        () => _editManifest(
          package,
          (manifest) => _document(manifest)['schemaVersion'] = 2,
        ),
        TemplateStoreErrorCode.newerVersion,
      ),
      'a newer package format': (
        () =>
            _editManifest(package, (manifest) => manifest['formatVersion'] = 2),
        TemplateStoreErrorCode.newerVersion,
      ),
      'a document version that never existed': (
        () => _editManifest(
          package,
          (manifest) => _document(manifest)['schemaVersion'] = 0,
        ),
        TemplateStoreErrorCode.invalidDocument,
      ),
      'a missing referenced asset': (
        () => _repack(
          package,
          (entries) =>
              entries.removeWhere((name, _) => name.contains(flowerId)),
        ),
        TemplateStoreErrorCode.assetMissing,
      ),
      'an asset that is not the file its name promises': (
        () => _repack(package, (entries) {
          final name = entries.keys.firstWhere((n) => n.contains(flowerId));
          entries[name] = Uint8List.fromList(entries[name]!)..[100] ^= 1;
        }),
        TemplateStoreErrorCode.assetMismatch,
      ),
      'an asset with the wrong file type': (
        () => _repack(package, (entries) {
          final name = entries.keys.firstWhere((n) => n.contains(flowerId));
          entries['assets/$flowerId.jpg'] = entries.remove(name)!;
        }),
        TemplateStoreErrorCode.assetMismatch,
      ),
      'oversized page dimensions': (
        () => _editManifest(package, (manifest) {
          (_document(manifest)['page']! as Map<String, Object?>)['width'] = 100;
        }),
        TemplateStoreErrorCode.invalidDocument,
      ),
      'a path that climbs out of the package': (
        () => rawZip([
          RawEntry('template.json', utf8.encode('{}')),
          RawEntry('assets/../../../evil.png', [1, 2, 3]),
        ]),
        TemplateStoreErrorCode.packageUnsafe,
      ),
      'an absolute path': (
        () => rawZip([RawEntry('/template.json', utf8.encode('{}'))]),
        TemplateStoreErrorCode.packageUnsafe,
      ),
      'a zip bomb': (
        () => rawZip([
          RawEntry('assets/${'a' * 64}.png', Uint8List(20 << 20), method: 8),
        ]),
        TemplateStoreErrorCode.packageTooLarge,
      ),
      'an encrypted entry': (
        () => rawZip([
          RawEntry('template.json', utf8.encode('{}'), flags: 0x0801),
        ]),
        TemplateStoreErrorCode.packageUnsupported,
      ),
      'an unexpected file': (
        () => _repack(
          package,
          (entries) => entries['notes.txt'] = utf8.encode('hello'),
        ),
        TemplateStoreErrorCode.packageInvalid,
      ),
      'an asset the document does not use': (
        () => _repack(package, (entries) {
          final extra = Uint8List.fromList([7, 7, 7]);
          entries['assets/${assetIdOf(extra)}.png'] = extra;
        }),
        TemplateStoreErrorCode.packageInvalid,
      ),
      'no template.json': (
        () => _repack(package, (entries) => entries.remove('template.json')),
        TemplateStoreErrorCode.packageInvalid,
      ),
      'a template.json that is not JSON': (
        () => _repack(
          package,
          (entries) => entries['template.json'] = utf8.encode('{nope'),
        ),
        TemplateStoreErrorCode.packageInvalid,
      ),
      'an unknown manifest field': (
        () => _editManifest(package, (manifest) => manifest['script'] = 'x'),
        TemplateStoreErrorCode.packageInvalid,
      ),
      'a file that is not a package at all': (
        () => Uint8List.fromList(utf8.encode('Not a ZIP, just some text.')),
        TemplateStoreErrorCode.packageInvalid,
      ),
    };
    for (final MapEntry(key: name, value: (bytes, code)) in cases.entries) {
      test(name, () async {
        await expectLater(
          target.packages.importPackage(bytes()),
          _refused(code),
        );
        expect(target.snapshot(), isEmpty);
        final counts = await target.rowCounts();
        expect(
          (counts.templates, counts.revisions, counts.assets, counts.links),
          (0, 0, 0, 0),
        );
      });
    }
  });

  test('an unknown layer type names the problem', () async {
    final changed = _editManifest(package, (manifest) {
      final layers = _document(manifest)['layers']! as List<Object?>;
      (layers[1]! as Map<String, Object?>)['type'] = 'hologram';
    });
    await expectLater(
      target.packages.importPackage(changed),
      throwsA(
        isA<TemplateStoreException>().having(
          (e) => e.issues.map((i) => i.code),
          'issues',
          contains(DocumentIssueCode.unknownLayerType),
        ),
      ),
    );
  });
}
