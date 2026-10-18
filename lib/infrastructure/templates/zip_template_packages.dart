import 'dart:convert';
import 'dart:typed_data';

import '../../domain/models/template_revision_summary.dart';
import '../../domain/repositories/template_store.dart';
import '../../domain/template/document_issues.dart';
import '../../domain/template/template_assets.dart';
import '../../domain/template/template_document.dart';
import '../../domain/template/template_json.dart';
import 'drift_asset_repository.dart';
import 'zip_archive.dart';

/// The `.porcelain-template` package format, version 1 (ADR-0010): a ZIP
/// holding `template.json` and `assets/<sha256>.<extension>` for every
/// asset the document lists, and nothing else.
///
/// ```json
/// {
///   "format": "porcelain-template",
///   "formatVersion": 1,
///   "template": {"name": "Two-up classic", "category": null},
///   "document": { ...a template document... }
/// }
/// ```
abstract final class TemplatePackageFormat {
  static const format = 'porcelain-template';
  static const formatVersion = 1;
  static const fileExtension = 'porcelain-template';
  static const manifestName = 'template.json';
  static const assetsDirectory = 'assets/';

  static const limits = ZipLimits(
    maxArchiveBytes: 100 * 1024 * 1024,
    maxEntries: TemplateDocument.maxAssets + 16,
    maxEntryBytes: AssetLimits.maxImageBytes,
    maxTotalBytes: 200 * 1024 * 1024,
    maxRatio: 100,
  );

  /// The manifest holds a document (at most 1 MB) and a little more.
  static const maxManifestBytes = TemplateJson.maxDocumentBytes + 8 * 1024;
}

/// A package's contents after every structural check.
final class DecodedTemplatePackage {
  const DecodedTemplatePackage({
    required this.name,
    required this.category,
    required this.document,
    required this.assets,
  });

  final String name;
  final String? category;
  final TemplateDocument document;

  /// Bytes by asset id; exactly the document's assets, each matching its
  /// id.
  final Map<String, Uint8List> assets;
}

/// [TemplatePackages] over the asset and template repositories.
final class ZipTemplatePackages implements TemplatePackages {
  ZipTemplatePackages({required this.assets, required this.templates});

  final AssetRepository assets;
  final TemplateRepository templates;

  @override
  Future<TemplateRevisionSummary> importPackage(Uint8List package) async {
    final decoded = decodeTemplatePackage(package);
    // Every asset is inspected before any is stored.
    for (final MapEntry(key: id, value: described)
        in decoded.document.assets.entries) {
      final actual = await inspectAsset(decoded.assets[id]!);
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
    for (final MapEntry(key: id, value: bytes) in decoded.assets.entries) {
      await assets.store(
        bytes,
        name: decoded.document.assets[id]!.name,
        origin: AssetOrigin.package,
      );
    }
    return templates.createTemplate(
      name: decoded.name,
      category: decoded.category,
      document: decoded.document,
    );
  }

  @override
  Future<Uint8List> exportPackage(String revisionId) async {
    final revision = await templates.loadRevision(revisionId);
    return encodeTemplatePackage(
      name: revision.summary.templateName,
      category: revision.category,
      document: revision.document,
      assets: {
        for (final id in revision.document.assets.keys)
          id: await assets.read(id),
      },
    );
  }
}

/// [document] and its [assets] (bytes by id) as package bytes: the
/// manifest first, then assets by id, so equal inputs give equal bytes.
Uint8List encodeTemplatePackage({
  required String name,
  String? category,
  required TemplateDocument document,
  required Map<String, Uint8List> assets,
}) {
  final manifest = {
    'format': TemplatePackageFormat.format,
    'formatVersion': TemplatePackageFormat.formatVersion,
    'template': {'name': name, 'category': category},
    'document': TemplateJson.toJson(document),
  };
  return writeZip([
    (
      name: TemplatePackageFormat.manifestName,
      bytes: utf8.encode(
        '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
      ),
    ),
    for (final id in document.assets.keys.toList()..sort())
      (
        name:
            '${TemplatePackageFormat.assetsDirectory}$id.'
            '${document.assets[id]!.mediaType.extension}',
        bytes: assets[id]!,
      ),
  ]);
}

/// Reads and checks a package: the archive (strictly; see [readZip]), the
/// manifest, the document, and that the asset entries are exactly the
/// document's assets with matching content ids and file types. Throws
/// [TemplateStoreException].
DecodedTemplatePackage decodeTemplatePackage(Uint8List package) {
  final ({List<String> names, Map<String, Uint8List> files}) archive;
  try {
    archive = readZip(
      package,
      limits: TemplatePackageFormat.limits,
      wanted: (name) => !_ignored(name),
    );
  } on ZipException catch (error) {
    throw TemplateStoreException(switch (error.problem) {
      ZipProblem.invalid => TemplateStoreErrorCode.packageInvalid,
      ZipProblem.unsafe => TemplateStoreErrorCode.packageUnsafe,
      ZipProblem.tooLarge => TemplateStoreErrorCode.packageTooLarge,
      ZipProblem.unsupported => TemplateStoreErrorCode.packageUnsupported,
    }, detail: error.detail);
  }

  final assetEntries = <String, ({AssetMediaType type, Uint8List bytes})>{};
  for (final name in archive.names) {
    if (_ignored(name) ||
        name == TemplatePackageFormat.manifestName ||
        name == TemplatePackageFormat.assetsDirectory) {
      continue;
    }
    final match = _assetEntry.firstMatch(name);
    final type = match == null ? null : _byExtension[match.group(2)];
    if (match == null || type == null) {
      throw TemplateStoreException(
        TemplateStoreErrorCode.packageInvalid,
        detail: 'unexpected entry $name',
      );
    }
    final id = match.group(1)!;
    if (assetEntries.containsKey(id)) {
      throw TemplateStoreException(
        TemplateStoreErrorCode.packageInvalid,
        detail: 'asset $id appears twice',
      );
    }
    assetEntries[id] = (type: type, bytes: archive.files[name]!);
  }

  final manifestBytes = archive.files[TemplatePackageFormat.manifestName];
  if (manifestBytes == null) {
    throw const TemplateStoreException(
      TemplateStoreErrorCode.packageInvalid,
      detail: 'no template.json',
    );
  }
  if (manifestBytes.length > TemplatePackageFormat.maxManifestBytes) {
    throw const TemplateStoreException(
      TemplateStoreErrorCode.packageTooLarge,
      detail: 'template.json too large',
    );
  }
  final (:name, :category, :documentJson) = _manifest(manifestBytes);

  final TemplateDocument document;
  try {
    document = TemplateJson.fromJson(documentJson);
  } on TemplateDocumentException catch (error) {
    final newer = error.issues.any(
      (issue) => issue.code == DocumentIssueCode.newerVersion,
    );
    throw TemplateStoreException(
      newer
          ? TemplateStoreErrorCode.newerVersion
          : TemplateStoreErrorCode.invalidDocument,
      detail: error.issues.first.code.diagnostic,
      issues: error.issues,
    );
  }
  final errors = document.errors;
  if (errors.isNotEmpty) {
    throw TemplateStoreException(
      TemplateStoreErrorCode.invalidDocument,
      detail: errors.first.code.diagnostic,
      issues: errors,
    );
  }

  final assets = <String, Uint8List>{};
  for (final MapEntry(key: id, value: described) in document.assets.entries) {
    final entry = assetEntries.remove(id);
    if (entry == null) {
      throw TemplateStoreException(
        TemplateStoreErrorCode.assetMissing,
        detail: id,
      );
    }
    if (entry.type != described.mediaType || assetIdOf(entry.bytes) != id) {
      throw TemplateStoreException(
        TemplateStoreErrorCode.assetMismatch,
        detail: id,
      );
    }
    assets[id] = entry.bytes;
  }
  if (assetEntries.isNotEmpty) {
    throw TemplateStoreException(
      TemplateStoreErrorCode.packageInvalid,
      detail: 'asset ${assetEntries.keys.first} is not in the document',
    );
  }
  return DecodedTemplatePackage(
    name: name,
    category: category,
    document: document,
    assets: assets,
  );
}

final _assetEntry = RegExp(r'^assets/([0-9a-f]{64})\.([a-z]{3})$');

final _byExtension = {
  for (final type in AssetMediaType.values) type.extension: type,
};

/// Entries that macOS adds when it zips a folder; skipped, never read.
bool _ignored(String name) =>
    name.startsWith('__MACOSX/') ||
    name == '.DS_Store' ||
    name.endsWith('/.DS_Store');

({String name, String? category, Object? documentJson}) _manifest(
  Uint8List bytes,
) {
  Never invalid(String detail) => throw TemplateStoreException(
    TemplateStoreErrorCode.packageInvalid,
    detail: detail,
  );
  final Object? json;
  try {
    json = jsonDecode(utf8.decode(bytes));
  } on FormatException {
    invalid('template.json is not JSON');
  }
  if (json is! Map<String, Object?>) invalid('template.json is not an object');
  const keys = {'format', 'formatVersion', 'template', 'document'};
  for (final key in json.keys) {
    if (!keys.contains(key)) invalid('unknown field $key');
  }
  if (json['format'] != TemplatePackageFormat.format) {
    invalid('not a template package');
  }
  final version = json['formatVersion'];
  if (version is! int || version < 1) invalid('bad formatVersion');
  if (version > TemplatePackageFormat.formatVersion) {
    throw const TemplateStoreException(
      TemplateStoreErrorCode.newerVersion,
      detail: 'package made by a newer app',
    );
  }
  final template = json['template'];
  if (template is! Map<String, Object?>) invalid('no template details');
  for (final key in template.keys) {
    if (key != 'name' && key != 'category') invalid('unknown field $key');
  }
  final name = template['name'];
  final category = template['category'];
  if (name is! String) invalid('no template name');
  if (category != null && category is! String) invalid('bad category');
  if (!json.containsKey('document')) invalid('no document');
  return (
    name: name,
    category: category as String?,
    documentJson: json['document'],
  );
}
