import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart' as crypto;
import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import '../../domain/services/camera_service.dart';
import '../../domain/value_objects/clock.dart';
import '../database/booth_database.dart';
import 'atomic_file_writer.dart';
import 'jpeg_exif.dart';

/// What the camera adapter knows about a still when committing it.
final class CaptureContext {
  const CaptureContext({
    required this.lens,
    required this.sensorOrientationDegrees,
    required this.mirrorPreviewRequested,
    required this.mirrorOutputRequested,
    required this.capturedAtUtc,
    this.deviceOrientation = CaptureOrientation.unknown,
    this.origin = CaptureOrigin.session,
  });

  final CameraLens lens;
  final int sensorOrientationDegrees;
  final bool mirrorPreviewRequested;
  final bool mirrorOutputRequested;
  final DateTime capturedAtUtc;
  final CaptureOrientation deviceOrientation;
  final CaptureOrigin origin;
}

/// An original could not be validated or committed; nothing was stored.
final class OriginalCommitException implements Exception {
  const OriginalCommitException(this.reason);

  /// A short code, never a path: `invalid-id`, `exists`, `not-jpeg`,
  /// `truncated`, `undecodable`, `no-space`, `write-failed`,
  /// `record-failed`.
  final String reason;

  @override
  String toString() => 'OriginalCommitException($reason)';
}

/// Managed, immutable storage for camera originals (A-11, ADR-0012).
///
/// A commit validates the bytes (a complete JPEG that fully decodes),
/// records its intent in `pending_original_commits`, writes the file with
/// [AtomicFileWriter] (staged, flushed, read back, decoded, renamed into
/// `originals/<id>.jpg`, never replacing anything), then adds the
/// original's row and removes the intent in one transaction. A crash at any
/// point leaves either nothing, a staged file (discarded at startup) or an
/// intent that [reconcile] finishes or undoes. Originals are never
/// overwritten, and never deleted by recovery: a file that fails its checks
/// is moved to `originals/.quarantine`.
final class OriginalStore implements CapturedStillStore {
  OriginalStore({
    required this._database,
    required this._root,
    required this._writer,
    required this._clock,
  });

  final BoothDatabase _database;
  final Future<Directory> Function() _root;
  final Future<AtomicFileWriter> Function() _writer;
  final Clock _clock;

  static const directoryName = 'originals';
  static const quarantineName = '.quarantine';
  static final _validId = RegExp(r'^[0-9A-Za-z-]{1,64}$');

  /// What the last [reconcile] did.
  OriginalsRecovery? lastRecovery;

  Future<Directory> _directory() async =>
      Directory('${(await _root()).path}/$directoryName');

  File _file(Directory root, String relativePath) =>
      File('${root.path}/$relativePath');

  /// Validates and stores [bytes] as original [id]. Never overwrites.
  /// Throws [OriginalCommitException]; nothing is stored then.
  Future<CapturedStill> commit({
    required String id,
    required Uint8List bytes,
    required CaptureContext context,
  }) async {
    if (!_validId.hasMatch(id)) {
      throw const OriginalCommitException('invalid-id');
    }
    checkCompleteJpeg(bytes);
    final (width, height) = await decodedSize(bytes);
    final still = CapturedStill(
      id: id,
      relativePath: '$directoryName/$id.jpg',
      widthPx: width,
      heightPx: height,
      byteLength: bytes.length,
      sha256: crypto.sha256.convert(bytes).toString(),
      lens: context.lens,
      sensorOrientationDegrees: _quarterTurns(context.sensorOrientationDegrees),
      mirrorPreviewRequested: context.mirrorPreviewRequested,
      mirrorOutputRequested: context.mirrorOutputRequested,
      capturedAtUtc: context.capturedAtUtc.toUtc(),
      exifOrientation: readJpegExifOrientation(bytes),
      deviceOrientation: context.deviceOrientation,
      origin: context.origin,
    );

    final root = await _root();
    final destination = _file(root, still.relativePath);
    if (destination.existsSync() || await _recorded(id)) {
      throw const OriginalCommitException('exists');
    }
    try {
      await _database
          .into(_database.pendingOriginalCommits)
          .insert(
            PendingOriginalCommitsCompanion.insert(
              id: id,
              sha256: still.sha256,
              byteLength: still.byteLength,
              metadata: journalEntry(still),
              startedAt: _clock.now(),
            ),
          );
    } on Object {
      throw const OriginalCommitException('record-failed');
    }

    try {
      await (await _writer()).write(
        destination,
        bytes,
        verify: (onDisk) async => decodedSize(onDisk),
        stagedPrefix: 'original-',
      );
    } on AtomicWriteException catch (error) {
      await _forget(id);
      throw OriginalCommitException(switch (error.reason) {
        AtomicWriteFailure.noSpace => 'no-space',
        AtomicWriteFailure.destinationExists => 'exists',
        _ => 'write-failed',
      });
    } on Object {
      await _forget(id);
      throw const OriginalCommitException('write-failed');
    }

    try {
      await _database.transaction(() async {
        await _database.into(_database.originalPhotos).insert(_row(still));
        await (_database.delete(
          _database.pendingOriginalCommits,
        )..where((p) => p.id.equals(id))).go();
      });
    } on Object {
      // The file is complete but unrecorded: take it back, so a failed
      // save never surfaces later. If even that fails, the intent is still
      // there for the next start to finish.
      try {
        await destination.delete();
        await _forget(id);
      } on Object {
        // Left for reconcile().
      }
      throw const OriginalCommitException('record-failed');
    }
    return still;
  }

  Future<bool> _recorded(String id) async =>
      await (_database.select(
        _database.originalPhotos,
      )..where((o) => o.id.equals(id))).getSingleOrNull() !=
      null;

  Future<void> _forget(String id) async {
    try {
      await (_database.delete(
        _database.pendingOriginalCommits,
      )..where((p) => p.id.equals(id))).go();
    } on Object {
      // Left for reconcile().
    }
  }

  @override
  Future<List<CapturedStill>> listCommitted({int? limit}) async {
    final query = _database.select(_database.originalPhotos)
      ..orderBy([
        (o) => OrderingTerm.desc(o.capturedAt),
        (o) => OrderingTerm.desc(o.id),
      ]);
    if (limit != null) query.limit(limit);
    return [for (final row in await query.get()) _still(row)];
  }

  @override
  Future<CapturedStill?> find(String id) async {
    final row = await (_database.select(
      _database.originalPhotos,
    )..where((o) => o.id.equals(id))).getSingleOrNull();
    return row == null ? null : _still(row);
  }

  @override
  Future<Uint8List> read(CapturedStill still) async {
    final file = _file(await _root(), still.relativePath);
    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } on FileSystemException {
      throw const CameraFailure(
        CameraFailureCode.originalNotPersisted,
        detail: 'missing',
      );
    }
    if (crypto.sha256.convert(bytes).toString() != still.sha256) {
      throw const CameraFailure(
        CameraFailureCode.originalNotPersisted,
        detail: 'checksum',
      );
    }
    return bytes;
  }

  /// At startup, before any capture (A-11): finishes commits whose file is
  /// complete, undoes the rest, and adopts originals the M01 spike saved
  /// with JSON sidecars. Files that fail their checks are moved aside,
  /// never deleted.
  @override
  Future<OriginalsRecovery> reconcile() async {
    var finished = 0;
    var undone = 0;
    var adopted = 0;
    var quarantined = 0;
    final root = await _root();
    final directory = await _directory();

    for (final pending
        in await _database.select(_database.pendingOriginalCommits).get()) {
      final still = _tryFromJson(pending.metadata);
      final file = still == null ? null : _file(root, still.relativePath);
      final matches =
          file != null &&
          file.existsSync() &&
          await _sha256Of(file) == pending.sha256;
      if (still != null && matches && !await _recorded(still.id)) {
        await _database.transaction(() async {
          await _database.into(_database.originalPhotos).insert(_row(still));
          await (_database.delete(
            _database.pendingOriginalCommits,
          )..where((p) => p.id.equals(pending.id))).go();
        });
        finished++;
        continue;
      }
      if (file != null && file.existsSync() && !matches) {
        if (await _quarantine(directory, file)) quarantined++;
      }
      await _forget(pending.id);
      undone++;
    }

    // The M01 spike: originals/<id>.jpg with <id>.json beside it, and its
    // own staging folder.
    if (directory.existsSync()) {
      final staging = Directory('${directory.path}/.staging');
      if (staging.existsSync()) await staging.delete(recursive: true);
      for (final entry in directory.listSync(followLinks: false)) {
        if (entry is! File || !entry.path.endsWith('.json')) continue;
        final still = _tryFromLegacyJson(entry);
        final image = still == null ? null : _file(root, still.relativePath);
        if (still != null &&
            image != null &&
            image.existsSync() &&
            await _sha256Of(image) == still.sha256) {
          if (!await _recorded(still.id)) {
            await _database.into(_database.originalPhotos).insert(_row(still));
            adopted++;
          }
          await entry.delete();
        } else {
          if (await _quarantine(directory, entry)) quarantined++;
          if (image != null &&
              image.existsSync() &&
              await _quarantine(directory, image)) {
            quarantined++;
          }
        }
      }
    }
    return lastRecovery = OriginalsRecovery(
      finished: finished,
      undone: undone,
      adopted: adopted,
      quarantined: quarantined,
    );
  }

  Future<bool> _quarantine(Directory directory, File file) async {
    try {
      final aside = Directory('${directory.path}/$quarantineName');
      await aside.create(recursive: true);
      final name = file.uri.pathSegments.last;
      await file.rename(
        '${aside.path}/${DateTime.now().microsecondsSinceEpoch}-$name',
      );
      return true;
    } on FileSystemException {
      return false;
    }
  }

  static Future<String?> _sha256Of(File file) async {
    try {
      return crypto.sha256.convert(await file.readAsBytes()).toString();
    } on FileSystemException {
      return null;
    }
  }

  /// Refuses bytes that are not a complete JPEG: the start-of-image marker
  /// first and the end-of-image marker last (some encoders pad with zeros
  /// after it). A truncated write fails here even if a lenient decoder
  /// would show its first rows.
  static void checkCompleteJpeg(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
      throw const OriginalCommitException('not-jpeg');
    }
    var end = bytes.length;
    while (end > 2 && bytes[end - 1] == 0) {
      end--;
    }
    if (bytes[end - 2] != 0xFF || bytes[end - 1] != 0xD9) {
      throw const OriginalCommitException('truncated');
    }
  }

  /// Fully decodes [bytes] (at a small size, to bound memory) and returns
  /// the oriented dimensions. Corrupt files fail here.
  static Future<(int, int)> decodedSize(Uint8List bytes) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final size = (descriptor.width, descriptor.height);
      codec = await descriptor.instantiateCodec(targetWidth: 64);
      (await codec.getNextFrame()).image.dispose();
      return size;
    } on Object {
      throw const OriginalCommitException('undecodable');
    } finally {
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }

  static int _quarterTurns(int degrees) => ((degrees / 90).round() % 4) * 90;

  OriginalPhotosCompanion _row(CapturedStill still) =>
      OriginalPhotosCompanion.insert(
        id: still.id,
        relativePath: still.relativePath,
        widthPx: still.widthPx,
        heightPx: still.heightPx,
        byteLength: still.byteLength,
        sha256: still.sha256,
        lens: still.lens,
        sensorOrientation: still.sensorOrientationDegrees,
        deviceOrientation: still.deviceOrientation,
        exifOrientation: Value(still.exifOrientation),
        mirrorPreview: still.mirrorPreviewRequested,
        mirrorOutput: still.mirrorOutputRequested,
        origin: still.origin,
        capturedAt: still.capturedAtUtc,
        committedAt: _clock.now(),
      );

  static CapturedStill _still(OriginalPhotoRow row) => CapturedStill(
    id: row.id,
    relativePath: row.relativePath,
    widthPx: row.widthPx,
    heightPx: row.heightPx,
    byteLength: row.byteLength,
    sha256: row.sha256,
    lens: row.lens,
    sensorOrientationDegrees: row.sensorOrientation,
    mirrorPreviewRequested: row.mirrorPreview,
    mirrorOutputRequested: row.mirrorOutput,
    capturedAtUtc: row.capturedAt.toUtc(),
    exifOrientation: row.exifOrientation,
    deviceOrientation: row.deviceOrientation,
    origin: row.origin,
  );

  /// What the journal records about a commit in progress: everything
  /// needed to finish it at the next start.
  @visibleForTesting
  static String journalEntry(CapturedStill still) => jsonEncode(_toJson(still));

  static Map<String, Object?> _toJson(CapturedStill still) => {
    'schemaVersion': 1,
    'id': still.id,
    'relativePath': still.relativePath,
    'widthPx': still.widthPx,
    'heightPx': still.heightPx,
    'byteLength': still.byteLength,
    'sha256': still.sha256,
    'lens': still.lens.name,
    'sensorOrientationDegrees': still.sensorOrientationDegrees,
    'deviceOrientation': still.deviceOrientation.name,
    'mirrorPreviewRequested': still.mirrorPreviewRequested,
    'mirrorOutputRequested': still.mirrorOutputRequested,
    'capturedAtUtc': still.capturedAtUtc.toIso8601String(),
    'exifOrientation': still.exifOrientation,
    'origin': still.origin.name,
  };

  static CapturedStill? _tryFromJson(String text) {
    try {
      return _fromJson(jsonDecode(text) as Map<String, Object?>);
    } on Object {
      return null;
    }
  }

  /// A sidecar the M01 spike wrote: the same fields, without device
  /// orientation or origin.
  static CapturedStill? _tryFromLegacyJson(File sidecar) {
    try {
      final json =
          jsonDecode(sidecar.readAsStringSync()) as Map<String, Object?>;
      final still = _fromJson({...json, 'origin': CaptureOrigin.legacy.name});
      return still.relativePath == '$directoryName/${still.id}.jpg' &&
              _validId.hasMatch(still.id)
          ? still
          : null;
    } on Object {
      return null;
    }
  }

  static CapturedStill _fromJson(Map<String, Object?> json) => CapturedStill(
    id: json['id']! as String,
    relativePath: json['relativePath']! as String,
    widthPx: json['widthPx']! as int,
    heightPx: json['heightPx']! as int,
    byteLength: json['byteLength']! as int,
    sha256: json['sha256']! as String,
    lens: CameraLens.values.byName(json['lens']! as String),
    sensorOrientationDegrees: _quarterTurns(
      json['sensorOrientationDegrees']! as int,
    ),
    mirrorPreviewRequested: json['mirrorPreviewRequested']! as bool,
    mirrorOutputRequested: json['mirrorOutputRequested']! as bool,
    capturedAtUtc: DateTime.parse(json['capturedAtUtc']! as String).toUtc(),
    exifOrientation: json['exifOrientation'] as int?,
    deviceOrientation: CaptureOrientation.values.byName(
      json['deviceOrientation'] as String? ?? CaptureOrientation.unknown.name,
    ),
    origin: CaptureOrigin.values.byName(json['origin']! as String),
  );
}
