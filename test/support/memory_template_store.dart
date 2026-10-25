import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:porcelain_photo_booth/domain/models/template_revision_summary.dart';
import 'package:porcelain_photo_booth/domain/repositories/template_store.dart';
import 'package:porcelain_photo_booth/domain/services/operator_files.dart';
import 'package:porcelain_photo_booth/domain/template/asset_formats.dart';
import 'package:porcelain_photo_booth/domain/template/template_assets.dart';
import 'package:porcelain_photo_booth/domain/template/template_document.dart';
import 'package:porcelain_photo_booth/domain/template/template_json.dart';
import 'package:porcelain_photo_booth/domain/template/template_tags.dart';
import 'package:porcelain_photo_booth/domain/value_objects/clock.dart';

/// The template store in memory, for widget tests: every future completes
/// without real I/O, so screens settle under the test's fake clock. The
/// file-backed stores have their own tests (test/infrastructure/templates).
///
/// Validation mirrors the real stores where screens can see it: documents
/// must be valid and list only stored assets, assets are recognised by
/// content, packages either import whole or not at all.
final class MemoryTemplateStore {
  MemoryTemplateStore({required this.clock}) {
    assets = MemoryAssets._(this);
    templates = MemoryTemplates._(this);
    packages = MemoryPackages._(this);
    drafts = MemoryDrafts._(this);
  }

  final Clock clock;
  late final MemoryAssets assets;
  late final MemoryTemplates templates;
  late final MemoryPackages packages;
  late final MemoryDrafts drafts;

  /// Told about every template created here, so a test can record it in
  /// the database too, where events refer to it (the app keeps both in
  /// one database).
  Future<void> Function(TemplateRevisionSummary created)? onCreated;

  /// Events offering each template, as the library shows them.
  final eventCounts = <String, int>{};

  /// While set, new revisions and drafts are refused with
  /// [TemplateStoreErrorCode.storageFailed], as on a full disk.
  var failWrites = false;

  void _checkWrite() {
    if (failWrites) {
      throw const TemplateStoreException(
        TemplateStoreErrorCode.storageFailed,
        detail: 'test: writes refused',
      );
    }
  }

  final _changes = StreamController<void>.broadcast(sync: true);
  void _changed() => _changes.add(null);

  var _ids = 0;
  String _newId() =>
      '00000000-0000-4000-b000-${(++_ids).toRadixString(16).padLeft(12, '0')}';
}

final class MemoryAssets implements AssetRepository {
  MemoryAssets._(this._store);

  final MemoryTemplateStore _store;
  final _bytes = <String, Uint8List>{};
  final _stored = <String, StoredAsset>{};

  /// How many assets are stored.
  int get count => _stored.length;

  @override
  Future<StoredAsset> store(
    Uint8List bytes, {
    String? name,
    required AssetOrigin origin,
  }) async {
    final sniffed = sniffAsset(bytes);
    final header = sniffed.asset;
    if (header == null) {
      throw TemplateStoreException(switch (sniffed.problem!) {
        AssetFormatProblem.unknownFormat =>
          TemplateStoreErrorCode.assetUnknownFormat,
        AssetFormatProblem.unsupportedVariant =>
          TemplateStoreErrorCode.assetUnsupportedVariant,
        _ => TemplateStoreErrorCode.assetDamaged,
      });
    }
    final id = assetIdOf(bytes);
    final existing = _stored[id];
    if (existing != null) return existing;
    final stored = StoredAsset(
      id: id,
      asset: TemplateAsset(
        mediaType: header.mediaType,
        byteLength: bytes.length,
        widthPx: header.widthPx,
        heightPx: header.heightPx,
        name: name?.split('/').last,
      ),
      origin: origin,
      createdAt: _store.clock.now(),
    );
    _bytes[id] = bytes;
    _stored[id] = stored;
    _store._changed();
    return stored;
  }

  @override
  Future<StoredAsset?> find(String assetId) async => _stored[assetId];

  @override
  Future<Uint8List> read(String assetId) async =>
      _bytes[assetId] ??
      (throw TemplateStoreException(
        TemplateStoreErrorCode.assetMissing,
        detail: assetId,
      ));

  /// Simulates a file lost from managed storage.
  void loseFile(String assetId) => _bytes.remove(assetId);

  List<StoredAsset> _images() =>
      [
        for (final asset in _stored.values)
          if (asset.origin != AssetOrigin.bundled &&
              asset.asset.kind == AssetKind.image)
            asset,
      ]..sort((a, b) {
        final byTime = b.createdAt.compareTo(a.createdAt);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });

  @override
  Stream<List<StoredAsset>> watchImages() async* {
    yield _images();
    yield* _store._changes.stream.map((_) => _images());
  }

  @override
  Future<bool> isInUse(String assetId) async =>
      _store.templates._revisions.any(
        (r) => r.document.assets.containsKey(assetId),
      ) ||
      _store.drafts._drafts.values.any(
        (d) => d.document.assets.containsKey(assetId),
      );

  @override
  Future<void> rename(String assetId, String name) async {
    final stored = _stored[assetId];
    if (stored == null) {
      throw const TemplateStoreException(TemplateStoreErrorCode.notFound);
    }
    final a = stored.asset;
    _stored[assetId] = StoredAsset(
      id: stored.id,
      asset: TemplateAsset(
        mediaType: a.mediaType,
        byteLength: a.byteLength,
        widthPx: a.widthPx,
        heightPx: a.heightPx,
        name: name.trim(),
      ),
      origin: stored.origin,
      createdAt: stored.createdAt,
    );
    _store._changed();
  }

  @override
  Future<void> remove(String assetId) async {
    if (await isInUse(assetId)) {
      throw const TemplateStoreException(TemplateStoreErrorCode.assetInUse);
    }
    _stored.remove(assetId);
    _bytes.remove(assetId);
    _store._changed();
  }
}

final class _Template {
  _Template(
    this.id,
    this.name,
    this.category,
    this.updatedAt, {
    this.tags = const TemplateTags(),
  });

  final String id;
  String name;
  final String? category;
  final TemplateTags tags;
  DateTime updatedAt;
  bool archived = false;
}

final class MemoryTemplates implements TemplateRepository {
  MemoryTemplates._(this._store);

  final MemoryTemplateStore _store;
  final _templates = <String, _Template>{};
  final _revisions = <StoredTemplateRevision>[];

  StoredTemplateRevision _latest(String templateId) => _revisions
      .where((r) => r.summary.templateId == templateId)
      .reduce(
        (a, b) => a.summary.revisionNumber > b.summary.revisionNumber ? a : b,
      );

  List<TemplateListing> _listing() =>
      [
        for (final template in _templates.values)
          TemplateListing(
            latest: _summary(template, _latest(template.id).summary),
            category: template.category,
            updatedAt: template.updatedAt,
            eventCount: _store.eventCounts[template.id] ?? 0,
            hasDraft: _store.drafts._drafts.containsKey(template.id),
          ),
      ]..sort((a, b) {
        final byName = a.latest.templateName.toLowerCase().compareTo(
          b.latest.templateName.toLowerCase(),
        );
        return byName != 0 ? byName : a.templateId.compareTo(b.templateId);
      });

  TemplateRevisionSummary _summary(
    _Template template,
    TemplateRevisionSummary s,
  ) => TemplateRevisionSummary(
    revisionId: s.revisionId,
    templateId: s.templateId,
    templateName: template.name,
    revisionNumber: s.revisionNumber,
    pageWidthPx: s.pageWidthPx,
    pageHeightPx: s.pageHeightPx,
    photoSlotCount: s.photoSlotCount,
    templateArchived: template.archived,
    tags: template.tags,
  );

  @override
  Stream<List<TemplateListing>> watchLibrary() async* {
    yield _listing();
    yield* _store._changes.stream.map((_) => _listing());
  }

  void _check(TemplateDocument document) {
    final errors = document.errors;
    if (errors.isNotEmpty) {
      throw TemplateStoreException(
        TemplateStoreErrorCode.invalidDocument,
        issues: errors,
      );
    }
    for (final MapEntry(key: id, value: asset) in document.assets.entries) {
      final stored = _store.assets._stored[id];
      if (stored == null) {
        throw TemplateStoreException(
          TemplateStoreErrorCode.assetMissing,
          detail: id,
        );
      }
      if (stored.asset.mediaType != asset.mediaType ||
          stored.asset.byteLength != asset.byteLength) {
        throw TemplateStoreException(
          TemplateStoreErrorCode.assetMismatch,
          detail: id,
        );
      }
    }
  }

  StoredTemplateRevision _add(
    _Template template,
    TemplateDocument document,
    int number,
  ) {
    final revision = StoredTemplateRevision(
      summary: TemplateRevisionSummary(
        revisionId: _store._newId(),
        templateId: template.id,
        templateName: template.name,
        revisionNumber: number,
        pageWidthPx: document.page.widthPx,
        pageHeightPx: document.page.heightPx,
        photoSlotCount: document.photoSlotCount,
        templateArchived: template.archived,
        tags: template.tags,
      ),
      category: template.category,
      document: document,
      checksum: 'f' * 64,
    );
    _revisions.add(revision);
    template.updatedAt = _store.clock.now();
    _store._changed();
    return revision;
  }

  /// Adds [document] as revision 1 of [templateId] under the given ids,
  /// as rows seeded straight into the catalog have them (tests only).
  void seedRevision({
    required String templateId,
    required String revisionId,
    required String name,
    required TemplateDocument document,
  }) {
    final template = _Template(templateId, name, null, _store.clock.now());
    _templates[templateId] = template;
    _revisions.add(
      StoredTemplateRevision(
        summary: TemplateRevisionSummary(
          revisionId: revisionId,
          templateId: templateId,
          templateName: name,
          revisionNumber: 1,
          pageWidthPx: document.page.widthPx,
          pageHeightPx: document.page.heightPx,
          photoSlotCount: document.photoSlotCount,
        ),
        category: null,
        document: document,
        checksum: 'f' * 64,
      ),
    );
    _store._changed();
  }

  @override
  Future<TemplateRevisionSummary> createTemplate({
    required String name,
    String? category,
    required TemplateDocument document,
    TemplateTags tags = const TemplateTags(),
  }) async {
    _check(document);
    final template = _Template(
      _store._newId(),
      name.trim(),
      category,
      _store.clock.now(),
      tags: tags,
    );
    _templates[template.id] = template;
    final summary = _add(template, document, 1).summary;
    await _store.onCreated?.call(summary);
    return summary;
  }

  @override
  Future<TemplateRevisionSummary> addRevision(
    String templateId,
    TemplateDocument document,
  ) async {
    final template = _templates[templateId];
    if (template == null) {
      throw const TemplateStoreException(TemplateStoreErrorCode.notFound);
    }
    _check(document);
    _store._checkWrite();
    final number = _latest(templateId).summary.revisionNumber + 1;
    return _add(template, document, number).summary;
  }

  @override
  Future<StoredTemplateRevision> loadRevision(String revisionId) async {
    final revision = _revisions
        .where((r) => r.summary.revisionId == revisionId)
        .firstOrNull;
    if (revision == null) {
      throw const TemplateStoreException(TemplateStoreErrorCode.notFound);
    }
    final template = _templates[revision.summary.templateId]!;
    return StoredTemplateRevision(
      summary: _summary(template, revision.summary),
      category: revision.category,
      document: revision.document,
      checksum: revision.checksum,
    );
  }

  @override
  Future<StoredTemplateRevision> loadLatest(String templateId) async {
    if (!_templates.containsKey(templateId)) {
      throw const TemplateStoreException(TemplateStoreErrorCode.notFound);
    }
    return loadRevision(_latest(templateId).summary.revisionId);
  }

  @override
  Future<void> rename(String templateId, String name) async {
    final template = _templates[templateId];
    if (template == null) {
      throw const TemplateStoreException(TemplateStoreErrorCode.notFound);
    }
    template.name = name.trim();
    _store._changed();
  }

  @override
  Future<void> setArchived(String templateId, {required bool archived}) async {
    final template = _templates[templateId];
    if (template == null) {
      throw const TemplateStoreException(TemplateStoreErrorCode.notFound);
    }
    template.archived = archived;
    _store._changed();
  }
}

/// Packages as JSON: enough for the screens' import and export flows.
final class MemoryPackages implements TemplatePackages {
  MemoryPackages._(this._store);

  final MemoryTemplateStore _store;

  @override
  Future<Uint8List> exportPackage(String revisionId) async {
    final revision = await _store.templates.loadRevision(revisionId);
    return Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'name': revision.summary.templateName,
          'document': TemplateJson.encode(revision.document),
          'assets': {
            for (final id in revision.document.assets.keys)
              id: base64Encode(await _store.assets.read(id)),
          },
        }),
      ),
    );
  }

  @override
  Future<TemplateRevisionSummary> importPackage(Uint8List package) async {
    final Map<String, Object?> json;
    final TemplateDocument document;
    try {
      json = jsonDecode(utf8.decode(package)) as Map<String, Object?>;
      document = TemplateJson.decodeValid(json['document']! as String);
    } on Object {
      throw const TemplateStoreException(TemplateStoreErrorCode.packageInvalid);
    }
    for (final MapEntry(:value) in (json['assets']! as Map).entries) {
      await _store.assets.store(
        base64Decode(value as String),
        origin: AssetOrigin.package,
      );
    }
    return _store.templates.createTemplate(
      name: json['name']! as String,
      document: document,
    );
  }
}

final class MemoryDrafts implements TemplateDraftRepository {
  MemoryDrafts._(this._store);

  final MemoryTemplateStore _store;
  final _drafts = <String, TemplateDraft>{};

  @override
  Future<TemplateDraft?> load(String templateId) async => _drafts[templateId];

  @override
  Future<void> save(TemplateDraft draft) async {
    _store._checkWrite();
    _drafts[draft.templateId] = draft;
    _store._changed();
  }

  @override
  Future<void> discard(String templateId) async {
    if (_drafts.remove(templateId) != null) _store._changed();
  }
}

/// The document picker and share sheet, scripted by tests.
final class FakeOperatorFiles implements OperatorFiles {
  /// What the next [pick] returns (null: the operator cancelled).
  PickedFile? nextPick;
  FilePickException? nextPickError;
  final picks = <PickableFile>[];
  final shared = <({String fileName, String mimeType, Uint8List bytes})>[];
  ShareOutcome shareOutcome = ShareOutcome.shared;

  @override
  Future<PickedFile?> pick(PickableFile kind, {required int maxBytes}) async {
    picks.add(kind);
    final error = nextPickError;
    nextPickError = null;
    if (error != null) throw error;
    final file = nextPick;
    nextPick = null;
    if (file != null && file.bytes.length > maxBytes) {
      throw FilePickException(FilePickFailure.tooLarge, limitBytes: maxBytes);
    }
    return file;
  }

  @override
  Future<ShareOutcome> share(
    Uint8List bytes, {
    required String fileName,
    required String mimeType,
    required ShareAnchor anchor,
  }) async {
    shared.add((fileName: fileName, mimeType: mimeType, bytes: bytes));
    return shareOutcome;
  }

  /// What the next [pickStream] returns (null: the operator cancelled).
  PickedStream? nextStream;

  /// Files offered by path, with their contents when offered.
  final sharedFiles = <({String path, String mimeType, int bytes})>[];

  @override
  Future<PickedStream?> pickStream(PickableFile kind) async {
    picks.add(kind);
    final error = nextPickError;
    nextPickError = null;
    if (error != null) throw error;
    final file = nextStream;
    nextStream = null;
    return file;
  }

  @override
  Future<ShareReport> shareFile(
    String path, {
    required String mimeType,
    required ShareAnchor anchor,
  }) async {
    final file = File(path);
    sharedFiles.add((
      path: path,
      mimeType: mimeType,
      bytes: file.existsSync() ? file.lengthSync() : -1,
    ));
    return ShareReport(shareOutcome);
  }
}
