import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:porcelain_photo_booth/domain/models/template_revision_summary.dart';
import 'package:porcelain_photo_booth/domain/repositories/template_store.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/render_fixtures.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/managed_storage.dart';
import 'package:porcelain_photo_booth/infrastructure/templates/drift_asset_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/templates/drift_template_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/templates/zip_template_packages.dart';

import 'fakes.dart';
import 'test_database.dart';

/// Managed storage in a temporary directory, an in-memory database and the
/// template store over them.
final class TemplateStoreHarness {
  TemplateStoreHarness._(this.root, this.db, this.storage, this.clock)
    : assets = DriftAssetRepository(db, storage: storage, clock: clock) {
    templates = DriftTemplateRepository(
      db,
      storage: storage,
      assets: assets,
      ids: SequentialIds('00000000-0000-4000-a000'),
      clock: clock,
    );
    packages = ZipTemplatePackages(assets: assets, templates: templates);
  }

  static Future<TemplateStoreHarness> create() async {
    final root = await Directory.systemTemp.createTemp('template_store');
    final storage = FileManagedStorage(root: () async => root);
    await storage.prepare();
    final clock = FakeClock();
    return TemplateStoreHarness._(
      root,
      memoryDatabase(clock: clock),
      storage,
      clock,
    );
  }

  final Directory root;
  final BoothDatabase db;
  final FileManagedStorage storage;
  final FakeClock clock;
  final DriftAssetRepository assets;
  late final DriftTemplateRepository templates;
  late final ZipTemplatePackages packages;

  Future<void> dispose() async {
    await db.close();
    await root.delete(recursive: true);
  }

  /// Stores [fixture]'s assets, then its document as a new template.
  Future<TemplateRevisionSummary> storeFixture(
    RenderFixture fixture, {
    String name = 'Fixture',
  }) async {
    for (final MapEntry(key: id, value: bytes) in fixture.assets.entries) {
      await assets.store(
        bytes,
        name: fixture.document.assets[id]!.name,
        origin: AssetOrigin.imported,
      );
    }
    return templates.createTemplate(name: name, document: fixture.document);
  }

  File file(String relativePath) => File('${root.path}/$relativePath');

  /// Every managed file but the database and staging, with its SHA-256.
  Map<String, String> snapshot() => {
    for (final entity in root.listSync(recursive: true))
      if (entity is File &&
          !entity.path.contains('/staging/') &&
          !entity.path.contains('/database/'))
        entity.path.substring(root.path.length + 1): crypto.sha256
            .convert(entity.readAsBytesSync())
            .toString(),
  };

  Future<({int templates, int revisions, int assets, int links})>
  rowCounts() async => (
    templates: (await db.select(db.templates).get()).length,
    revisions: (await db.select(db.templateRevisions).get()).length,
    assets: (await db.select(db.assets).get()).length,
    links: (await db.select(db.templateRevisionAssets).get()).length,
  );
}
