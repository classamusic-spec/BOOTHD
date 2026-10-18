import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart' as crypto;
import 'package:drift/drift.dart';

import '../../core/composition/scene_images.dart';
import '../../domain/repositories/template_store.dart';
import '../../domain/template/asset_formats.dart';
import '../../domain/template/geometry.dart';
import '../../domain/template/template_assets.dart';
import '../../domain/value_objects/clock.dart';
import '../database/booth_database.dart';
import '../database/persistence_guard.dart';
import '../file_store/atomic_file_writer.dart';
import '../file_store/managed_storage.dart';

/// Template assets in managed storage, content-addressed (A-11, ADR-0010).
///
/// A file is accepted on what its bytes are, never its name: the header is
/// parsed and checked against the limits before anything is decoded, and
/// images are then decoded in full (at a small size) by the platform
/// decoder that will draw them. Each file is stored once, at
/// `assets/<sha256>.<extension>`, through an atomic write, and recorded
/// only after it is in place. An interruption between the two leaves an
/// unrecorded file under its own content name, which the next store of the
/// same bytes reuses.
final class DriftAssetRepository implements AssetRepository {
  DriftAssetRepository(
    this._db, {
    required this.storage,
    required this.clock,
    this.operations = const FileOperations(),
  });

  final BoothDatabase _db;
  final FileManagedStorage storage;
  final Clock clock;
  final FileOperations operations;

  @override
  Future<StoredAsset> store(
    Uint8List bytes, {
    String? name,
    required AssetOrigin origin,
  }) async {
    final asset = await inspectAsset(bytes, name: name);
    final id = assetIdOf(bytes);
    final existing = await find(id);
    final file = await _file(id, asset.mediaType);
    if (existing != null && _intact(file, bytes.length)) return existing;

    if (file.existsSync() && !await _sameContent(file, id)) {
      // A damaged copy under this content's name: the right bytes for the
      // name are known, so replace it.
      await file.delete();
    }
    if (!file.existsSync()) {
      try {
        await (await storage.writer(operations: operations))
            .write(file, bytes, stagedPrefix: 'asset-');
      } on AtomicWriteException catch (error) {
        throw TemplateStoreException(
          TemplateStoreErrorCode.storageFailed,
          detail: error.reason.name,
        );
      }
    }
    if (existing != null) return existing;

    final stored = StoredAsset(
      id: id,
      asset: asset,
      origin: origin,
      createdAt: clock.now(),
    );
    try {
      await guardPersistence(
        () => _db
            .into(_db.assets)
            .insert(
              AssetsCompanion.insert(
                id: id,
                mediaType: asset.mediaType,
                relativePath: relativePathOf(id, asset.mediaType),
                byteLength: asset.byteLength,
                widthPx: Value(asset.widthPx),
                heightPx: Value(asset.heightPx),
                displayName: Value(asset.name),
                origin: origin,
                createdAt: stored.createdAt,
              ),
              mode: InsertMode.insertOrIgnore,
            ),
      );
    } on Object {
      throw const TemplateStoreException(TemplateStoreErrorCode.storageFailed);
    }
    // Another store of the same bytes may have recorded it first.
    return (await find(id))!;
  }

  @override
  Future<StoredAsset?> find(String assetId) async {
    if (!isAssetId(assetId)) return null;
    final row = await (_db.select(
      _db.assets,
    )..where((a) => a.id.equals(assetId))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<Uint8List> read(String assetId) async {
    final stored = await find(assetId);
    if (stored == null) {
      throw TemplateStoreException(
        TemplateStoreErrorCode.assetMissing,
        detail: isAssetId(assetId) ? assetId : 'invalid asset id',
      );
    }
    final file = await _file(assetId, stored.asset.mediaType);
    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } on FileSystemException {
      throw TemplateStoreException(
        TemplateStoreErrorCode.assetMissing,
        detail: assetId,
      );
    }
    if (assetIdOf(bytes) != assetId) {
      throw TemplateStoreException(
        TemplateStoreErrorCode.assetMismatch,
        detail: assetId,
      );
    }
    return bytes;
  }

  @override
  Stream<List<StoredAsset>> watchImages() =>
      (_db.select(_db.assets)
            ..where(
              (a) =>
                  a.origin.equalsValue(AssetOrigin.bundled).not() &
                  a.mediaType.isInValues([
                    AssetMediaType.png,
                    AssetMediaType.jpeg,
                  ]),
            )
            ..orderBy([
              (a) => OrderingTerm.desc(a.createdAt),
              (a) => OrderingTerm.asc(a.id),
            ]))
          .watch()
          .map((rows) => [for (final row in rows) _toDomain(row)]);

  @override
  Future<bool> isInUse(String assetId) async {
    final row = await _db
        .customSelect(
          'SELECT EXISTS (SELECT 1 FROM template_revision_assets '
          'WHERE asset_id = ?1) OR EXISTS (SELECT 1 FROM template_drafts '
          'WHERE instr(document, ?1) > 0) AS used',
          variables: [Variable.withString(assetId)],
          readsFrom: {_db.templateRevisionAssets, _db.templateDrafts},
        )
        .getSingle();
    return row.read<bool>('used');
  }

  @override
  Future<void> rename(String assetId, String name) async {
    final plain = _plainName(name);
    if (plain == null) {
      throw const TemplateStoreException(
        TemplateStoreErrorCode.invalidDocument,
        detail:
            'the image name must be 1 to ${AssetLimits.maxNameLength} '
            'characters',
      );
    }
    final changed = await guardPersistence(
      () => (_db.update(_db.assets)..where((a) => a.id.equals(assetId))).write(
        AssetsCompanion(displayName: Value(plain)),
      ),
    );
    if (changed == 0) {
      throw TemplateStoreException(
        TemplateStoreErrorCode.notFound,
        detail: isAssetId(assetId) ? assetId : 'invalid asset id',
      );
    }
  }

  @override
  Future<void> remove(String assetId) async {
    final stored = await find(assetId);
    if (stored == null) {
      throw TemplateStoreException(
        TemplateStoreErrorCode.notFound,
        detail: isAssetId(assetId) ? assetId : 'invalid asset id',
      );
    }
    // The check and the delete share a transaction, so a revision or
    // draft saved meanwhile either sees the asset or blocks its removal.
    await guardPersistence(
      () => _db.transaction(() async {
        if (await isInUse(assetId)) {
          throw TemplateStoreException(
            TemplateStoreErrorCode.assetInUse,
            detail: assetId,
          );
        }
        await (_db.delete(_db.assets)..where((a) => a.id.equals(assetId))).go();
      }),
    );
    // The row is gone; a file left behind by a failed delete is harmless
    // (storing the same bytes again reuses it).
    try {
      await (await _file(assetId, stored.asset.mediaType)).delete();
    } on FileSystemException {
      // Already absent.
    }
  }

  /// `assets/<id>.<extension>`, relative to managed storage.
  static String relativePathOf(String id, AssetMediaType mediaType) =>
      '${ManagedArea.assets.directoryName}/$id.${mediaType.extension}';

  Future<File> _file(String id, AssetMediaType mediaType) async => File(
    '${(await storage.directory(ManagedArea.assets)).path}/'
    '$id.${mediaType.extension}',
  );

  static bool _intact(File file, int length) {
    try {
      return file.lengthSync() == length;
    } on FileSystemException {
      return false;
    }
  }

  static Future<bool> _sameContent(File file, String id) async {
    try {
      return crypto.sha256.convert(await file.readAsBytes()).toString() == id;
    } on FileSystemException {
      return false;
    }
  }

  static StoredAsset _toDomain(AssetRow row) => StoredAsset(
    id: row.id,
    asset: TemplateAsset(
      mediaType: row.mediaType,
      byteLength: row.byteLength,
      widthPx: row.widthPx,
      heightPx: row.heightPx,
      name: row.displayName,
    ),
    origin: row.origin,
    createdAt: row.createdAt,
  );
}

/// What [bytes] are as a template asset, judged by content alone: format
/// and variant from the header, the byte and pixel limits before decoding,
/// then (images) a full decode by the platform decoder, which also gives
/// the size with EXIF orientation applied. [name] is reduced to a plain
/// file name. Throws [TemplateStoreException].
Future<TemplateAsset> inspectAsset(Uint8List bytes, {String? name}) async {
  if (bytes.isEmpty) {
    throw const TemplateStoreException(
      TemplateStoreErrorCode.assetUnknownFormat,
    );
  }
  if (bytes.length > AssetLimits.maxImageBytes) {
    throw const TemplateStoreException(TemplateStoreErrorCode.assetTooLarge);
  }
  final sniffed = sniffAsset(bytes);
  final header = sniffed.asset;
  if (header == null) {
    throw TemplateStoreException(switch (sniffed.problem!) {
      AssetFormatProblem.unknownFormat =>
        TemplateStoreErrorCode.assetUnknownFormat,
      AssetFormatProblem.unsupportedVariant =>
        TemplateStoreErrorCode.assetUnsupportedVariant,
      AssetFormatProblem.truncated ||
      AssetFormatProblem.malformedHeader => TemplateStoreErrorCode.assetDamaged,
    });
  }
  final plainName = _plainName(name);
  if (header.mediaType.kind == AssetKind.font) {
    if (bytes.length > AssetLimits.maxFontBytes) {
      throw const TemplateStoreException(TemplateStoreErrorCode.assetTooLarge);
    }
    return TemplateAsset(
      mediaType: header.mediaType,
      byteLength: bytes.length,
      name: plainName,
    );
  }

  // Limits on the stored size come before any pixel is decoded.
  final width = header.widthPx!;
  final height = header.heightPx!;
  if (width > AssetLimits.maxImageSide ||
      height > AssetLimits.maxImageSide ||
      width * height > AssetLimits.maxImagePixels) {
    throw const TemplateStoreException(TemplateStoreErrorCode.assetTooLarge);
  }
  final PixelSize decoded;
  try {
    decoded = await probeImageSize(bytes);
    // Every row must decode; a small size bounds the memory.
    final scale = math.min(1.0, 256 / math.max(width, height));
    (await decodeImage(bytes, scale: scale)).dispose();
  } on ImageDecodeException {
    throw const TemplateStoreException(TemplateStoreErrorCode.assetDamaged);
  }
  final asset = TemplateAsset(
    mediaType: header.mediaType,
    byteLength: bytes.length,
    widthPx: decoded.width,
    heightPx: decoded.height,
    name: plainName,
  );
  if (asset.problems.isNotEmpty) {
    throw TemplateStoreException(
      TemplateStoreErrorCode.assetTooLarge,
      detail: asset.problems.first,
    );
  }
  return asset;
}

/// The last path segment of [name], trimmed and cut to the limit; null when
/// nothing usable is left.
String? _plainName(String? name) {
  if (name == null) return null;
  final base = name
      .split(RegExp(r'[/\\]'))
      .last
      .trim()
      .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
  if (base.isEmpty || base == '.' || base == '..') return null;
  return base.length > AssetLimits.maxNameLength
      ? base.substring(0, AssetLimits.maxNameLength)
      : base;
}
