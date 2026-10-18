// The template library over the real store: create from a design (AC-0501),
// duplicate, rename and archive (S06), drafts, save and reopen (AC-0507),
// images from the file picker (AC-0508) and package round trips (AC-0509).
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/templates/slot_placeholder.dart';
import 'package:porcelain_photo_booth/core/templates/starter_designs.dart';
import 'package:porcelain_photo_booth/core/templates/template_library.dart';
import 'package:porcelain_photo_booth/domain/repositories/template_store.dart';
import 'package:porcelain_photo_booth/domain/services/operator_files.dart';
import 'package:porcelain_photo_booth/domain/template/editing/document_edits.dart';
import 'package:porcelain_photo_booth/domain/template/template_assets.dart';
import 'package:porcelain_photo_booth/domain/template/template_layers.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/fixture_images.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/png_encoder.dart';
import 'package:porcelain_photo_booth/infrastructure/composition/dart_ui_composition_renderer.dart';

import '../../rendering/support/pixels.dart';
import '../../support/template_store_harness.dart';

StarterDesign _design(String id) =>
    starterDesigns.firstWhere((design) => design.id == id);

Matcher _refused(TemplateStoreErrorCode code) =>
    throwsA(isA<TemplateStoreException>().having((e) => e.code, 'code', code));

/// The platform picker as the app sees it: it copies the chosen file to a
/// temporary location, and the library reads the bytes from there.
final class _TemporaryCopyPicker implements OperatorFiles {
  _TemporaryCopyPicker(this.temporary);

  final File temporary;

  @override
  Future<PickedFile?> pick(PickableFile kind, {required int maxBytes}) async {
    if (temporary.lengthSync() > maxBytes) {
      throw FilePickException(FilePickFailure.tooLarge, limitBytes: maxBytes);
    }
    return PickedFile(
      name: temporary.uri.pathSegments.last,
      bytes: await temporary.readAsBytes(),
    );
  }

  @override
  Future<ShareOutcome> share(
    Uint8List bytes, {
    required String fileName,
    required String mimeType,
    required ShareAnchor anchor,
  }) async => ShareOutcome.shared;
}

void main() {
  late TemplateStoreHarness harness;
  late TemplateLibrary library;

  setUp(() async {
    harness = await TemplateStoreHarness.create();
    library = harness.library;
  });
  tearDown(() => harness.dispose());

  group('create, duplicate, rename, archive (S06)', () {
    test('a design stores its decorations once, as bundled art', () async {
      final design = _design('floral-elegance');
      await library.create(design, name: 'Garden party');
      await library.create(design, name: 'Garden party 2');
      final counts = await harness.rowCounts();
      expect((counts.templates, counts.assets), (2, design.decorations.length));
      final listing = await library.watch().first;
      expect(
        [for (final t in listing) t.latest.templateName],
        ['Garden party', 'Garden party 2'],
      );
      expect(listing.first.category, 'Floral');
    });

    test('a duplicate is a new template with the same document', () async {
      final original = await library.create(
        _design('classic-strip'),
        name: 'Classic',
      );
      final copy = await library.duplicate(
        original.revisionId,
        name: TemplateLibrary.copyName('Classic'),
      );
      expect(copy.templateId, isNot(original.templateId));
      expect(copy.templateName, 'Classic copy');
      expect(
        (await harness.templates.loadRevision(copy.revisionId)).document,
        (await harness.templates.loadRevision(original.revisionId)).document,
      );
    });

    test('rename and archive change the library listing', () async {
      final summary = await library.create(
        _design('blank-4x6'),
        name: 'Draft name',
      );
      await library.rename(summary.templateId, '  Final name ');
      await library.setArchived(summary.templateId, archived: true);
      var listing = (await library.watch().first).single;
      expect(listing.latest.templateName, 'Final name');
      expect(listing.archived, isTrue);
      await library.setArchived(summary.templateId, archived: false);
      listing = (await library.watch().first).single;
      expect(listing.archived, isFalse);

      await expectLater(
        library.rename(summary.templateId, '   '),
        _refused(TemplateStoreErrorCode.invalidDocument),
      );
      await expectLater(
        library.rename(summary.templateId, 'x' * 81),
        _refused(TemplateStoreErrorCode.invalidDocument),
      );
      expect(TemplateLibrary.copyName('y' * 80).length, maxTemplateNameLength);
    });
  });

  group('editing: drafts, save, reopen (AC-0507)', () {
    test('a draft survives until saved; saving adds a revision', () async {
      final first = await library.create(
        _design('modern-minimal'),
        name: 'Minimal',
      );
      var opened = await library.open(first.templateId);
      expect(opened.draft, isNull);
      final edited = DocumentEdits.add(
        opened.revision.document,
        NewLayers.shape(opened.revision.document, 'stripe', ShapeKind.rect),
      );
      await library.saveDraft(
        first.templateId,
        baseRevisionId: first.revisionId,
        document: edited,
      );
      expect((await library.watch().first).single.hasDraft, isTrue);

      // Reopening offers the draft, editable as it was left.
      opened = await library.open(first.templateId);
      expect(opened.draft!.document, edited);
      expect(opened.draft!.baseRevisionId, first.revisionId);

      final saved = await library.save(first.templateId, edited);
      expect(saved.summary.revisionNumber, 2);
      expect(saved.document, edited);
      expect((await library.watch().first).single.hasDraft, isFalse);
      // Revision 1 is unchanged (A-15).
      expect(
        (await harness.templates.loadRevision(first.revisionId)).document,
        isNot(edited),
      );
      opened = await library.open(first.templateId);
      expect(opened.revision.summary.revisionId, saved.summary.revisionId);
      expect(opened.draft, isNull);
    });

    test('a draft that repeats the saved revision is dropped', () async {
      final first = await library.create(_design('blank-2x6'), name: 'Strip');
      final opened = await library.open(first.templateId);
      await library.saveDraft(
        first.templateId,
        baseRevisionId: first.revisionId,
        document: opened.revision.document,
      );
      expect((await library.open(first.templateId)).draft, isNull);
      expect((await harness.rowCounts()).drafts, 0);
    });
  });

  group('images (S08, AC-0508)', () {
    test(
      'a picked PNG still renders after its temporary file is gone',
      () async {
        final temp = await Directory.systemTemp.createTemp('picker');
        final picked = File('${temp.path}/flower.png')
          ..writeAsBytesSync(
            encodePngRgba(
              width: 200,
              height: 200,
              rgba: flower(size: 200).pixels,
            ),
          );
        final file = await _TemporaryCopyPicker(picked)
            .pick(PickableFile.image, maxBytes: AssetLimits.maxImageBytes);
        final stored = await library.importImage(file!.bytes, name: file.name);
        await temp.delete(recursive: true);
        expect(picked.existsSync(), isFalse);

        final created = await library.create(
          _design('blank-4x4'),
          name: 'With art',
        );
        var document = (await library.open(created.templateId))
            .revision
            .document;
        document = DocumentEdits.add(
          document,
          NewLayers.image(document, 'art', stored.id, stored.asset),
          assets: {stored.id: stored.asset},
        );
        final saved = await library.save(created.templateId, document);
        final artifact = await DartUiCompositionRenderer().renderExport(
          placeholderRender(saved.document, harness.assets),
          includePixels: true,
        );
        expect((artifact.widthPx, artifact.heightPx), (1200, 1200));
        expect(stored.origin, AssetOrigin.imported);
        expect(stored.asset.name, 'flower.png');
        // The flower's opaque centre landed on the page.
        final image = await decodeRgba(artifact.bytes);
        final centre = (600 * image.width + 600) * 4;
        expect(image.rgba.sublist(centre, centre + 3), isNot([251, 248, 243]));
      },
    );

    test('fonts and unknown files are refused as images', () async {
      final font = File('assets/fonts/inter/Inter-Regular.ttf')
          .readAsBytesSync();
      await expectLater(
        library.importImage(font),
        _refused(TemplateStoreErrorCode.assetUnknownFormat),
      );
      await expectLater(
        library.importImage(Uint8List.fromList('not an image'.codeUnits)),
        _refused(TemplateStoreErrorCode.assetUnknownFormat),
      );
      expect((await harness.rowCounts()).assets, 0);
    });
  });

  group('packages (AC-0509)', () {
    test('export then import gives back the same document', () async {
      final original = await library.create(
        _design('gold-celebration'),
        name: 'Gold & Glitter!',
      );
      final exported = await library.exportPackage(original);
      expect(exported.fileName, 'Gold-Glitter-r1.porcelain-template');

      final target = await TemplateStoreHarness.create();
      addTearDown(target.dispose);
      final imported = await target.library.importPackage(exported.bytes);
      final a = await harness.templates.loadRevision(original.revisionId);
      final b = await target.templates.loadRevision(imported.revisionId);
      expect(b.document, a.document);
      expect(imported.templateName, original.templateName);

      final renderer = DartUiCompositionRenderer();
      final before = await renderer.renderExport(
        placeholderRender(a.document, harness.assets),
        includePixels: true,
      );
      final after = await renderer.renderExport(
        placeholderRender(b.document, target.assets),
        includePixels: true,
      );
      expect(after.rgba, before.rgba, reason: 'pixel-identical render');
    });

    test('a damaged or unknown file is refused and stores nothing', () async {
      final original = await library.create(
        _design('retro-film'),
        name: 'Film',
      );
      final package = (await library.exportPackage(original)).bytes;
      final target = await TemplateStoreHarness.create();
      addTearDown(target.dispose);
      for (final bytes in [
        Uint8List.fromList('PK not really a zip'.codeUnits),
        Uint8List.fromList(package.sublist(0, package.length ~/ 2)),
        File('assets/decorations/gold_frame.png').readAsBytesSync(),
      ]) {
        await expectLater(
          target.library.importPackage(bytes),
          throwsA(isA<TemplateStoreException>()),
        );
      }
      final counts = await target.rowCounts();
      expect((counts.templates, counts.revisions, counts.assets), (0, 0, 0));
    });
  });
}
