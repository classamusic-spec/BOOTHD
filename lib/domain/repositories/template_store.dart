/// The template library's storage (A-05 Template, TemplateRevision, Asset;
/// A-11; A-15): content-addressed assets, immutable revisions and their
/// errors.
library;

import 'dart:typed_data';

import '../models/template_revision_summary.dart';
import '../template/document_issues.dart';
import '../template/template_assets.dart';
import '../template/template_document.dart';
import '../template/template_tags.dart';

/// Why a template, asset or package was not stored or loaded. Each maps to
/// a `TEMPLATE_*` diagnostic (A-14).
enum TemplateStoreErrorCode {
  /// The bytes are not a PNG, JPEG, TrueType or OpenType file.
  assetUnknownFormat('TEMPLATE_ASSET_UNKNOWN_FORMAT'),

  /// A recognised format in a variant the booth does not use (font
  /// collections, web fonts, progressive or 16-bit images and the like).
  assetUnsupportedVariant('TEMPLATE_ASSET_UNSUPPORTED_VARIANT'),

  /// Truncated, malformed or undecodable.
  assetDamaged('TEMPLATE_ASSET_DAMAGED'),

  /// Over the byte or pixel limits (AssetLimits).
  assetTooLarge('TEMPLATE_ASSET_TOO_LARGE'),

  /// The file is not what the document says it is (type, size, checksum).
  assetMismatch('TEMPLATE_ASSET_MISMATCH'),

  /// A file the document references is absent.
  assetMissing('TEMPLATE_ASSET_MISSING'),

  /// A saved revision or an editor draft still uses the asset.
  assetInUse('TEMPLATE_ASSET_IN_USE'),

  /// The document breaks the template rules; see the issues.
  invalidDocument('TEMPLATE_INVALID_DOCUMENT'),

  /// The document or package was made by a newer app version.
  newerVersion('TEMPLATE_NEWER_VERSION'),

  /// No such template or revision.
  notFound('TEMPLATE_NOT_FOUND'),

  /// A stored manifest is missing or no longer matches its checksum.
  manifestDamaged('TEMPLATE_MANIFEST_DAMAGED'),

  /// Writing to managed storage failed; nothing was stored.
  storageFailed('TEMPLATE_STORAGE_FAILED'),

  /// Not a template package, or a package with missing or unexpected parts.
  packageInvalid('TEMPLATE_PACKAGE_INVALID'),

  /// A package entry is unsafe: a path outside the package, a link, a
  /// duplicate name.
  packageUnsafe('TEMPLATE_PACKAGE_UNSAFE'),

  /// A package over the size, entry count or compression ratio limits.
  packageTooLarge('TEMPLATE_PACKAGE_TOO_LARGE'),

  /// Encrypted, ZIP64, split or compressed in an unsupported way.
  packageUnsupported('TEMPLATE_PACKAGE_UNSUPPORTED');

  const TemplateStoreErrorCode(this.diagnostic);

  final String diagnostic;
}

/// A template, asset or package was not stored or loaded. Nothing was
/// stored and nothing existing changed.
final class TemplateStoreException implements Exception {
  const TemplateStoreException(
    this.code, {
    this.detail,
    this.issues = const [],
  });

  final TemplateStoreErrorCode code;

  /// Sanitised detail for operators: entry names, asset ids, field paths;
  /// never device paths or file contents.
  final String? detail;

  /// The document's problems, for [TemplateStoreErrorCode.invalidDocument].
  final List<DocumentIssue> issues;

  @override
  String toString() =>
      'TemplateStoreException(${code.diagnostic}'
      '${detail == null ? '' : ': $detail'})';
}

/// Where a stored asset came from.
enum AssetOrigin {
  /// Chosen by the operator from a file (M05).
  imported,

  /// Unpacked from a template package.
  package,

  /// One of the app's own decorations or starter designs (M05).
  bundled,
}

/// An asset held in managed storage under its content id.
final class StoredAsset {
  const StoredAsset({
    required this.id,
    required this.asset,
    required this.origin,
    required this.createdAt,
  });

  /// Lowercase hex SHA-256 of the bytes.
  final String id;

  /// Type, size and (for images) decoded pixel size, as documents record
  /// them.
  final TemplateAsset asset;
  final AssetOrigin origin;
  final DateTime createdAt;
}

abstract interface class AssetRepository {
  /// Validates [bytes] by their content, never a name or claimed type:
  /// format and variant, the limits, and a full decode for images. Stores
  /// them once under their SHA-256; storing the same bytes again returns
  /// the stored asset. Throws [TemplateStoreException].
  Future<StoredAsset> store(
    Uint8List bytes, {
    String? name,
    required AssetOrigin origin,
  });

  Future<StoredAsset?> find(String assetId);

  /// The bytes of [assetId], checked against the id. Throws
  /// [TemplateStoreException] ([TemplateStoreErrorCode.assetMissing] or
  /// [TemplateStoreErrorCode.assetMismatch]).
  Future<Uint8List> read(String assetId);

  /// Images the operator imported or that came with packages (the app's
  /// own decorations are listed from the bundle), newest first; emits
  /// again on change (S08).
  Stream<List<StoredAsset>> watchImages();

  /// Whether a saved revision or an editor draft uses [assetId].
  Future<bool> isInUse(String assetId);

  /// Changes the name the asset browser shows. Documents keep the name
  /// they recorded.
  Future<void> rename(String assetId, String name);

  /// Deletes [assetId] and its file. Throws [TemplateStoreException]
  /// ([TemplateStoreErrorCode.assetInUse]) while anything uses it.
  Future<void> remove(String assetId);
}

/// A stored revision with its document.
final class StoredTemplateRevision {
  const StoredTemplateRevision({
    required this.summary,
    required this.category,
    required this.document,
    required this.checksum,
  });

  final TemplateRevisionSummary summary;
  final String? category;
  final TemplateDocument document;

  /// SHA-256 of the canonical manifest bytes.
  final String checksum;
}

/// A template as the library lists it: its latest revision, whether it is
/// archived, and how many events offer it.
final class TemplateListing {
  const TemplateListing({
    required this.latest,
    required this.category,
    required this.updatedAt,
    required this.eventCount,
    required this.hasDraft,
  });

  final TemplateRevisionSummary latest;
  final String? category;
  final DateTime updatedAt;

  /// Events (of any status) that offer one of its revisions.
  final int eventCount;

  /// Unsaved editor changes are waiting (autosave).
  final bool hasDraft;

  String get templateId => latest.templateId;
  bool get archived => latest.templateArchived;
}

abstract interface class TemplateRepository {
  /// Every template, archived ones included, by name; emits again on
  /// change.
  Stream<List<TemplateListing>> watchLibrary();

  /// Renames [templateId]. Revisions keep their documents.
  Future<void> rename(String templateId, String name);

  /// Archives or restores [templateId]. Archived templates stay available
  /// to events that already offer them (A-15).
  Future<void> setArchived(String templateId, {required bool archived});

  /// Stores [document] as revision 1 of a new template. Every asset the
  /// document lists must already be stored, as the document describes it.
  /// Throws [TemplateStoreException].
  Future<TemplateRevisionSummary> createTemplate({
    required String name,
    String? category,
    required TemplateDocument document,
    TemplateTags tags = const TemplateTags(),
  });

  /// Stores [document] as the next revision of [templateId]. Earlier
  /// revisions never change (A-15).
  Future<TemplateRevisionSummary> addRevision(
    String templateId,
    TemplateDocument document,
  );

  /// Reads a revision's manifest, checked against its recorded checksum.
  /// Throws [TemplateStoreException].
  Future<StoredTemplateRevision> loadRevision(String revisionId);

  /// [loadRevision] for the newest revision of [templateId].
  Future<StoredTemplateRevision> loadLatest(String templateId);
}

/// Template packages (`.porcelain-template`): one revision and its assets
/// in a single file, for moving templates between booths (A-06).
abstract interface class TemplatePackages {
  /// Checks [package] completely, then stores its assets and its document
  /// as revision 1 of a new template. Nothing existing is replaced (A-15).
  /// Throws [TemplateStoreException].
  Future<TemplateRevisionSummary> importPackage(Uint8List package);

  /// Revision [revisionId] and every asset it lists, as a package.
  Future<Uint8List> exportPackage(String revisionId);
}

/// Unsaved editor work for one template (A-08 autosave): the document as
/// the operator left it and the revision it started from.
final class TemplateDraft {
  const TemplateDraft({
    required this.templateId,
    required this.baseRevisionId,
    required this.document,
    required this.savedAt,
  });

  final String templateId;
  final String baseRevisionId;
  final TemplateDocument document;
  final DateTime savedAt;
}

abstract interface class TemplateDraftRepository {
  /// The draft for [templateId], or null. A draft that no longer reads is
  /// discarded and reported as none.
  Future<TemplateDraft?> load(String templateId);

  /// Replaces the draft for its template.
  Future<void> save(TemplateDraft draft);

  Future<void> discard(String templateId);
}
