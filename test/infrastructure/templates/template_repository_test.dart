// A-15, AC-0401: template revisions are immutable, stored as canonical
// manifests with checksums and linked to their assets; loading checks the
// manifest, and a template rendered from the store matches its golden.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/composition/store_render_source.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/repositories/template_store.dart';
import 'package:porcelain_photo_booth/domain/services/composition_renderer.dart';
import 'package:porcelain_photo_booth/domain/template/document_issues.dart';
import 'package:porcelain_photo_booth/domain/template/template_assets.dart';
import 'package:porcelain_photo_booth/domain/template/template_document.dart';
import 'package:porcelain_photo_booth/domain/template/template_json.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/render_checks.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/render_fixtures.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/render_lab_runner.dart';
import 'package:porcelain_photo_booth/infrastructure/composition/dart_ui_composition_renderer.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_template_catalog.dart';

import '../../support/template_store_harness.dart';

Matcher _refused(TemplateStoreErrorCode code) =>
    throwsA(isA<TemplateStoreException>().having((e) => e.code, 'code', code));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TemplateStoreHarness harness;

  setUp(() async => harness = await TemplateStoreHarness.create());
  tearDown(() => harness.dispose());

  test('a new template is revision 1: manifest, checksum, links', () async {
    final fixture = fix01();
    final summary = await harness.storeFixture(fixture, name: '  Two-up  ');
    expect(summary.templateName, 'Two-up');
    expect(summary.revisionNumber, 1);
    expect((summary.pageWidthPx, summary.pageHeightPx), (1200, 1800));
    expect(summary.photoSlotCount, 2);

    final row = await (harness.db.select(
      harness.db.templateRevisions,
    )..where((r) => r.id.equals(summary.revisionId))).getSingle();
    expect(
      row.manifestPath,
      'templates/${summary.templateId}/${summary.revisionId}.json',
    );
    final manifest = harness.file(row.manifestPath).readAsBytesSync();
    expect(manifest, TemplateJson.encodeBytes(fixture.document));
    expect(row.checksum, TemplateJson.checksumOf(fixture.document));
    expect(row.documentSchemaVersion, TemplateDocument.currentSchemaVersion);

    final links = await harness.db
        .select(harness.db.templateRevisionAssets)
        .get();
    expect(
      links.map((l) => l.assetId).toSet(),
      fixture.document.assets.keys.toSet(),
    );

    final loaded = await harness.templates.loadRevision(summary.revisionId);
    expect(loaded.document, fixture.document);
    expect(loaded.summary, summary);
    expect(loaded.checksum, row.checksum);

    // Events see it in the catalog.
    final selectable = await DriftTemplateCatalog(harness.db)
        .watchSelectable()
        .first;
    expect(selectable, [summary]);
  });

  test('a new revision never changes the earlier one', () async {
    final first = await harness.storeFixture(fix01());
    final before = harness.snapshot();
    final changed = TemplateDocument(
      page: fix01().document.page,
      assets: fix01().document.assets,
      layers: [
        for (final layer in fix01().document.layers)
          if (layer.id != 'marker') layer,
      ],
    );
    harness.clock.advance(const Duration(minutes: 5));
    final second = await harness.templates.addRevision(
      first.templateId,
      changed,
    );
    expect(second.revisionNumber, 2);
    expect(second.templateId, first.templateId);
    expect(second.revisionId, isNot(first.revisionId));
    final after = harness.snapshot();
    for (final MapEntry(:key, :value) in before.entries) {
      expect(after[key], value, reason: key);
    }
    expect(
      (await harness.templates.loadRevision(first.revisionId)).document,
      fix01().document,
    );
    expect(
      (await harness.templates.loadRevision(second.revisionId)).document,
      changed,
    );
    final selectable = await DriftTemplateCatalog(harness.db)
        .watchSelectable()
        .first;
    expect(selectable.single.revisionId, second.revisionId);
    await expectLater(
      harness.db.customStatement(
        "UPDATE template_revisions SET checksum = '${'0' * 64}'",
      ),
      throwsA(anything),
      reason: 'revisions are immutable in the database too',
    );
  });

  test('documents with problems or unstored assets are refused', () async {
    final fixture = fix01();
    final flowerId = fixture.document.assets.keys.firstWhere(
      (id) => fixture.document.assets[id]!.name == 'flower.png',
    );
    // Not stored yet.
    await expectLater(
      harness.templates.createTemplate(name: 'T', document: fixture.document),
      _refused(TemplateStoreErrorCode.assetMissing),
    );
    for (final bytes in fixture.assets.values) {
      await harness.assets.store(bytes, origin: AssetOrigin.imported);
    }
    // Stored, but the document describes the flower differently.
    final wrongSize = TemplateDocument(
      page: fixture.document.page,
      layers: fixture.document.layers,
      assets: {
        ...fixture.document.assets,
        flowerId: const TemplateAsset(
          mediaType: AssetMediaType.png,
          byteLength: 10,
          widthPx: 800,
          heightPx: 800,
        ),
      },
    );
    await expectLater(
      harness.templates.createTemplate(name: 'T', document: wrongSize),
      _refused(TemplateStoreErrorCode.assetMismatch),
    );
    final invalid = TemplateDocument(
      page: fixture.document.page,
      assets: fixture.document.assets,
      layers: [...fixture.document.layers, fixture.document.layers.last],
    );
    await expectLater(
      harness.templates.createTemplate(name: 'T', document: invalid),
      throwsA(
        isA<TemplateStoreException>()
            .having(
              (e) => e.code,
              'code',
              TemplateStoreErrorCode.invalidDocument,
            )
            .having(
              (e) => e.issues.map((i) => i.code),
              'issues',
              contains(DocumentIssueCode.duplicateLayerId),
            ),
      ),
    );
    await expectLater(
      harness.templates.createTemplate(name: ' ', document: fixture.document),
      _refused(TemplateStoreErrorCode.invalidDocument),
    );
    await expectLater(
      harness.templates.addRevision(
        'a0000000-0000-4000-8000-00000000ffff',
        fixture.document,
      ),
      _refused(TemplateStoreErrorCode.notFound),
    );
    final counts = await harness.rowCounts();
    expect((counts.templates, counts.revisions, counts.links), (0, 0, 0));
    expect(
      harness.snapshot().keys.where((path) => path.startsWith('templates/')),
      isEmpty,
    );
  });

  test('a changed or missing manifest is reported, never half-read', () async {
    final summary = await harness.storeFixture(fix01());
    final row = await harness.db
        .select(harness.db.templateRevisions)
        .getSingle();
    final file = harness.file(row.manifestPath);
    final original = file.readAsStringSync();

    // Same JSON meaning, different bytes: still not the recorded revision.
    file.writeAsStringSync(original.replaceFirst('"dpi": 300', '"dpi": 301'));
    await expectLater(
      harness.templates.loadRevision(summary.revisionId),
      _refused(TemplateStoreErrorCode.manifestDamaged),
    );
    file.deleteSync();
    await expectLater(
      harness.templates.loadRevision(summary.revisionId),
      _refused(TemplateStoreErrorCode.manifestDamaged),
    );
    await expectLater(
      harness.templates.loadRevision('a0000000-0000-4000-8000-00000000ffff'),
      _refused(TemplateStoreErrorCode.notFound),
    );
    expect(jsonDecode(original), isA<Map<String, Object?>>());
  });

  test(
    'a template rendered from the store exactly matches the source render',
    () async {
      final fixture = fix01();
      final summary = await harness.storeFixture(fixture);
      final revision = await harness.templates.loadRevision(summary.revisionId);
      final export = await DartUiCompositionRenderer().renderExport(
        TemplateRender(
          document: revision.document,
          photos: fixture.selections,
          source: StoreRenderSource(
            assets: harness.assets,
            photos: (id) async => fixture.photos[id]!,
          ),
        ),
        output: const OutputProfile(format: OutputFormat.png),
        includePixels: true,
      );
      // Persistence must preserve every pixel on the current renderer.
      // Platform-to-golden comparisons belong to render_golden_test.dart;
      // exact equality to a Linux image also measures OS rasterization.
      final direct = await exportPixels(DartUiCompositionRenderer(), fixture);
      expect(compareRgba(export.rgba!, direct.rgba!).maxDelta, 0);
    },
  );

  test('a store asset that changed on disk stops the render', () async {
    final fixture = fix01();
    final summary = await harness.storeFixture(fixture);
    final revision = await harness.templates.loadRevision(summary.revisionId);
    final flowerId = revision.document.assets.keys.firstWhere(
      (id) => revision.document.assets[id]!.name == 'flower.png',
    );
    harness
        .file('assets/$flowerId.png')
        .writeAsBytesSync(fixture.photos['photo-a']!);
    await expectLater(
      DartUiCompositionRenderer().renderExport(
        TemplateRender(
          document: revision.document,
          photos: fixture.selections,
          source: StoreRenderSource(
            assets: harness.assets,
            photos: (id) async => fixture.photos[id]!,
          ),
        ),
      ),
      throwsA(
        isA<RenderFailure>().having(
          (f) => f.code,
          'code',
          RenderFailureCode.missingAsset,
        ),
      ),
    );
  });
}
