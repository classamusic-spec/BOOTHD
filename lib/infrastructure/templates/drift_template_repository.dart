import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:drift/drift.dart';

import '../../domain/models/template_revision_summary.dart';
import '../../domain/repositories/template_store.dart';
import '../../domain/template/document_issues.dart';
import '../../domain/template/template_document.dart';
import '../../domain/template/template_json.dart';
import '../../domain/template/template_tags.dart';
import '../../domain/value_objects/clock.dart';
import '../../domain/value_objects/entity_id.dart';
import '../database/booth_database.dart';
import '../database/drift_template_catalog.dart';
import '../database/persistence_guard.dart';
import '../file_store/atomic_file_writer.dart';
import '../file_store/file_system.dart';
import '../file_store/managed_storage.dart';

/// Immutable template revisions (A-05, A-11, A-15, ADR-0010).
///
/// Each revision's document is written once, canonically encoded, to
/// `templates/<templateId>/<revisionId>.json` through an atomic write; its
/// SHA-256 is recorded with the revision, its page size and slot count, and
/// the assets it uses, in one transaction after the file is in place. A
/// revision is never rewritten: changes are new revisions. Loading checks
/// the file against the recorded checksum. If the app ends between the file
/// and the transaction, the unrecorded manifest is simply never read.
final class DriftTemplateRepository implements TemplateRepository {
  DriftTemplateRepository(
    this._db, {
    required this.storage,
    required this.assets,
    required this.ids,
    required this.clock,
    this.operations = const FileOperations(),
  });

  final BoothDatabase _db;
  final FileManagedStorage storage;
  final AssetRepository assets;
  final IdGenerator ids;
  final Clock clock;
  final FileOperations operations;

  static const maxNameLength = 80;
  static const maxCategoryLength = 40;

  @override
  Stream<List<TemplateListing>> watchLibrary() => _db
      .customSelect(
        // The latest revision of every template, with how many events offer
        // any of its revisions and whether editor work is waiting.
        'SELECT t.id AS template_id, t.display_name, t.category, '
        't.updated_at, t.archived_at, r.id AS revision_id, '
        'r.revision_number, r.page_width_px, r.page_height_px, '
        'r.photo_slot_count, '
        '(SELECT count(DISTINCT et.event_id) FROM event_templates et '
        'JOIN template_revisions r2 ON r2.id = et.template_revision_id '
        'WHERE r2.template_id = t.id) AS event_count, '
        'EXISTS (SELECT 1 FROM template_drafts d '
        'WHERE d.template_id = t.id) AS has_draft '
        'FROM templates t JOIN template_revisions r ON r.template_id = t.id '
        'WHERE r.revision_number = (SELECT max(revision_number) '
        'FROM template_revisions WHERE template_id = t.id) '
        'ORDER BY t.display_name COLLATE NOCASE, t.id',
        readsFrom: {
          _db.templates,
          _db.templateRevisions,
          _db.eventTemplates,
          _db.templateDrafts,
        },
      )
      .watch()
      .map(
        (rows) => [
          for (final row in rows)
            TemplateListing(
              latest: TemplateRevisionSummary(
                revisionId: row.read<String>('revision_id'),
                templateId: row.read<String>('template_id'),
                templateName: row.read<String>('display_name'),
                revisionNumber: row.read<int>('revision_number'),
                pageWidthPx: row.read<int>('page_width_px'),
                pageHeightPx: row.read<int>('page_height_px'),
                photoSlotCount: row.read<int>('photo_slot_count'),
                templateArchived:
                    row.readNullable<DateTime>('archived_at') != null,
              ),
              category: row.readNullable<String>('category'),
              updatedAt: row.read<DateTime>('updated_at'),
              eventCount: row.read<int>('event_count'),
              hasDraft: row.read<bool>('has_draft'),
            ),
        ],
      );

  @override
  Future<void> rename(String templateId, String name) async {
    final displayName = name.trim();
    if (displayName.isEmpty || displayName.length > maxNameLength) {
      throw const TemplateStoreException(
        TemplateStoreErrorCode.invalidDocument,
        detail: 'the template name must be 1 to $maxNameLength characters',
      );
    }
    final changed =
        await (_db.update(
          _db.templates,
        )..where((t) => t.id.equals(templateId))).write(
          TemplatesCompanion(
            displayName: Value(displayName),
            updatedAt: Value(clock.now()),
          ),
        );
    if (changed == 0) {
      throw const TemplateStoreException(TemplateStoreErrorCode.notFound);
    }
  }

  @override
  Future<void> setArchived(String templateId, {required bool archived}) async {
    final now = clock.now();
    final changed =
        await (_db.update(
          _db.templates,
        )..where((t) => t.id.equals(templateId))).write(
          TemplatesCompanion(
            archivedAt: Value(archived ? now : null),
            updatedAt: Value(now),
          ),
        );
    if (changed == 0) {
      throw const TemplateStoreException(TemplateStoreErrorCode.notFound);
    }
  }

  @override
  Future<TemplateRevisionSummary> createTemplate({
    required String name,
    String? category,
    required TemplateDocument document,
    TemplateTags tags = const TemplateTags(),
  }) async {
    final displayName = name.trim();
    final trimmedCategory = category?.trim();
    if (displayName.isEmpty || displayName.length > maxNameLength) {
      throw const TemplateStoreException(
        TemplateStoreErrorCode.invalidDocument,
        detail: 'the template name must be 1 to $maxNameLength characters',
      );
    }
    if (trimmedCategory != null && trimmedCategory.length > maxCategoryLength) {
      throw const TemplateStoreException(
        TemplateStoreErrorCode.invalidDocument,
        detail: 'the category must be at most $maxCategoryLength characters',
      );
    }
    final templateId = ids.newId();
    final now = clock.now();
    return _storeRevision(
      templateId: templateId,
      document: document,
      record: (revision) async {
        await _db
            .into(_db.templates)
            .insert(
              TemplatesCompanion.insert(
                id: templateId,
                displayName: displayName,
                category: Value(
                  trimmedCategory == null || trimmedCategory.isEmpty
                      ? null
                      : trimmedCategory,
                ),
                tagsJson: Value(tags.isEmpty ? null : tags),
                createdAt: now,
                updatedAt: now,
              ),
            );
        return revision(1);
      },
    );
  }

  @override
  Future<TemplateRevisionSummary> addRevision(
    String templateId,
    TemplateDocument document,
  ) async {
    final template = await (_db.select(
      _db.templates,
    )..where((t) => t.id.equals(templateId))).getSingleOrNull();
    if (template == null) {
      throw const TemplateStoreException(TemplateStoreErrorCode.notFound);
    }
    return _storeRevision(
      templateId: templateId,
      document: document,
      record: (revision) async {
        final latest = _db.templateRevisions.revisionNumber.max();
        final number =
            await (_db.selectOnly(_db.templateRevisions)
                  ..addColumns([latest])
                  ..where(_db.templateRevisions.templateId.equals(templateId)))
                .map((row) => row.read(latest))
                .getSingle() ??
            0;
        await (_db.update(_db.templates)..where((t) => t.id.equals(templateId)))
            .write(TemplatesCompanion(updatedAt: Value(clock.now())));
        return revision(number + 1);
      },
    );
  }

  /// Validates [document], checks its assets, writes its manifest and
  /// records it. [record] runs inside the transaction: it creates or
  /// updates the template row, then calls its argument with the revision
  /// number to insert the revision.
  Future<TemplateRevisionSummary> _storeRevision({
    required String templateId,
    required TemplateDocument document,
    required Future<TemplateRevisionRow> Function(
      Future<TemplateRevisionRow> Function(int number) revision,
    )
    record,
  }) async {
    final errors = document.errors;
    if (errors.isNotEmpty) {
      throw TemplateStoreException(
        TemplateStoreErrorCode.invalidDocument,
        detail: errors.first.code.diagnostic,
        issues: errors,
      );
    }
    await _checkAssets(document);

    final revisionId = ids.newId();
    final manifestPath =
        '${ManagedArea.templates.directoryName}/$templateId/$revisionId.json';
    final bytes = TemplateJson.encodeBytes(document);
    final checksum = crypto.sha256.convert(bytes).toString();
    final manifest = await _manifestFile(manifestPath);
    try {
      await (await storage.writer(operations: operations)).write(
        manifest,
        bytes,
        stagedPrefix: 'manifest-',
        verify: (onDisk) async {
          if (TemplateJson.decode(utf8.decode(onDisk)) != document) {
            throw const FormatException('manifest does not read back');
          }
        },
      );
    } on AtomicWriteException catch (error) {
      throw TemplateStoreException(
        TemplateStoreErrorCode.storageFailed,
        detail: error.reason.name,
      );
    }

    try {
      final row = await guardPersistence(
        () => _db.transaction(() async {
          final row = await record((number) async {
            final row = TemplateRevisionRow(
              id: revisionId,
              templateId: templateId,
              revisionNumber: number,
              documentSchemaVersion: document.schemaVersion,
              manifestPath: manifestPath,
              checksum: checksum,
              pageWidthPx: document.page.widthPx,
              pageHeightPx: document.page.heightPx,
              photoSlotCount: document.photoSlotCount,
              createdAt: clock.now(),
            );
            await _db.into(_db.templateRevisions).insert(row);
            return row;
          });
          for (final assetId in document.assets.keys) {
            await _db
                .into(_db.templateRevisionAssets)
                .insert(
                  TemplateRevisionAssetsCompanion.insert(
                    templateRevisionId: revisionId,
                    assetId: assetId,
                  ),
                );
          }
          return row;
        }),
      );
      final template = await (_db.select(
        _db.templates,
      )..where((t) => t.id.equals(templateId))).getSingle();
      return templateRevisionSummaryOf(row, template);
    } on Object {
      // Nothing refers to the manifest; remove it.
      try {
        await manifest.delete();
      } on FileSystemException {
        // An unrecorded manifest is never read.
      }
      throw const TemplateStoreException(TemplateStoreErrorCode.storageFailed);
    }
  }

  /// Every asset the document lists must be stored exactly as described.
  Future<void> _checkAssets(TemplateDocument document) async {
    for (final MapEntry(key: id, value: described) in document.assets.entries) {
      final stored = await assets.find(id);
      if (stored == null) {
        throw TemplateStoreException(
          TemplateStoreErrorCode.assetMissing,
          detail: id,
        );
      }
      final actual = stored.asset;
      if (actual.mediaType != described.mediaType ||
          actual.byteLength != described.byteLength ||
          actual.widthPx != described.widthPx ||
          actual.heightPx != described.heightPx) {
        throw TemplateStoreException(
          TemplateStoreErrorCode.assetMismatch,
          detail: id,
        );
      }
    }
  }

  @override
  Future<StoredTemplateRevision> loadLatest(String templateId) async {
    final latest =
        await (_db.select(_db.templateRevisions)
              ..where((r) => r.templateId.equals(templateId))
              ..orderBy([(r) => OrderingTerm.desc(r.revisionNumber)])
              ..limit(1))
            .getSingleOrNull();
    if (latest == null) {
      throw const TemplateStoreException(TemplateStoreErrorCode.notFound);
    }
    return loadRevision(latest.id);
  }

  @override
  Future<StoredTemplateRevision> loadRevision(String revisionId) async {
    final query = _db.select(_db.templateRevisions).join([
      innerJoin(
        _db.templates,
        _db.templates.id.equalsExp(_db.templateRevisions.templateId),
      ),
    ])..where(_db.templateRevisions.id.equals(revisionId));
    final row = await query.getSingleOrNull();
    if (row == null) {
      throw const TemplateStoreException(TemplateStoreErrorCode.notFound);
    }
    final revision = row.readTable(_db.templateRevisions);
    final template = row.readTable(_db.templates);

    final Uint8List bytes;
    try {
      bytes = await (await _manifestFile(revision.manifestPath)).readAsBytes();
    } on Object {
      throw TemplateStoreException(
        TemplateStoreErrorCode.manifestDamaged,
        detail: 'revision ${revision.revisionNumber} has no manifest',
      );
    }
    if (crypto.sha256.convert(bytes).toString() != revision.checksum) {
      throw TemplateStoreException(
        TemplateStoreErrorCode.manifestDamaged,
        detail: 'revision ${revision.revisionNumber} fails its checksum',
      );
    }
    final TemplateDocument document;
    try {
      document = TemplateJson.decodeValid(utf8.decode(bytes));
    } on TemplateDocumentException catch (error) {
      final newer = error.issues.any(
        (issue) => issue.code == DocumentIssueCode.newerVersion,
      );
      throw TemplateStoreException(
        newer
            ? TemplateStoreErrorCode.newerVersion
            : TemplateStoreErrorCode.manifestDamaged,
        issues: error.issues,
      );
    } on FormatException {
      throw const TemplateStoreException(
        TemplateStoreErrorCode.manifestDamaged,
      );
    }
    return StoredTemplateRevision(
      summary: templateRevisionSummaryOf(revision, template),
      category: template.category,
      document: document,
      checksum: revision.checksum,
    );
  }

  static final _segment = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,99}$');

  /// The manifest file for a stored relative path, refusing anything that
  /// could leave the templates area.
  Future<File> _manifestFile(String relativePath) async {
    final segments = relativePath.split('/');
    if (segments.length != 3 ||
        segments.first != ManagedArea.templates.directoryName ||
        !segments.skip(1).every(_segment.hasMatch) ||
        segments.contains('..')) {
      throw const TemplateStoreException(
        TemplateStoreErrorCode.manifestDamaged,
        detail: 'unsafe manifest path',
      );
    }
    final directory = await storage.directory(ManagedArea.templates);
    return fileIn(directory, '${segments[1]}/${segments[2]}');
  }
}
