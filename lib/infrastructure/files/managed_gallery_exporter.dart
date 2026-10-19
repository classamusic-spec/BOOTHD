import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;

import '../../domain/gallery/export_plan.dart';
import '../../domain/services/booth_capabilities.dart';
import '../../domain/services/gallery_services.dart';
import '../../domain/services/operator_files.dart';
import '../../domain/value_objects/entity_id.dart';
import '../file_store/atomic_file_writer.dart';
import '../file_store/managed_storage.dart';

/// Offers [files] (absolute paths in managed storage, with their MIME
/// types) to the platform share sheet anchored at [anchor].
typedef ShareFilesSheet = Future<ShareReport> Function(
  List<({String path, String mimeType})> files,
  ShareAnchor anchor,
);

/// [GalleryExporter] over managed storage (P-12, AC-0803).
///
/// Each export first checks free space for the copies, then copies every
/// file into `outgoing/<batch>/` under its export name, checking the bytes
/// it read against the recorded checksum and the copy against its length,
/// and offers the copies to the share sheet. Sources are only read. A file
/// that is missing, damaged or cannot be copied is reported with its
/// reason and left out; once the volume is full the remaining files are
/// reported without trying. The copies stay until the next export or the
/// next start, so a destination still reading them never loses them.
final class ManagedGalleryExporter implements GalleryExporter {
  ManagedGalleryExporter({
    required this._storage,
    required this._space,
    required this._ids,
    required this._share,
    this.reserveBytes = 64 * 1024 * 1024,
    this._writeCopy = _write,
  });

  final FileManagedStorage _storage;
  final DeviceStorageInfo _space;
  final IdGenerator _ids;
  final ShareFilesSheet _share;

  /// Space left free beyond the copies, so the booth never fills up.
  final int reserveBytes;

  /// Writes one copy; tests make it fail.
  final Future<void> Function(File copy, List<int> bytes) _writeCopy;

  static Future<void> _write(File copy, List<int> bytes) =>
      copy.writeAsBytes(bytes, flush: true);

  static final _sourcePath = RegExp(
    r'^(outputs/[0-9a-f-]{36}\.(jpg|png)|originals/[0-9A-Za-z-]{1,64}\.jpg)$',
  );
  static final _fileName = RegExp(r'^[0-9a-z][0-9a-z.-]{3,118}$');

  @override
  Future<ExportPartReport> export(
    List<ExportItem> items, {
    required ShareAnchor anchor,
    int part = 1,
    int parts = 1,
  }) async {
    final needed =
        items.fold<int>(0, (sum, item) => sum + item.byteLength) + reserveBytes;
    int? free;
    try {
      free = await _space.freeBytes();
    } on Object {
      // Unknown: the copies themselves report a full volume.
    }
    if (free != null && free < needed) {
      return ExportPartReport(
        part: part,
        parts: parts,
        sent: const [],
        failures: [
          for (final item in items) _failure(item, ExportProblem.noSpace),
        ],
        requiredBytes: needed,
        freeBytes: free,
      );
    }

    await discardPrepared();
    final root = (await _storage.directory(ManagedArea.outgoing)).parent;
    final batch = Directory(
      '${(await _storage.directory(ManagedArea.outgoing)).path}/'
      '${_ids.newId()}',
    );
    final prepared = <ExportItem>[];
    final copies = <({String path, String mimeType})>[];
    final failures = <ExportFailureItem>[];
    final names = <String>{};
    var full = false;
    try {
      await batch.create(recursive: true);
    } on FileSystemException catch (error) {
      full = _isNoSpace(error);
      return ExportPartReport(
        part: part,
        parts: parts,
        sent: const [],
        failures: [
          for (final item in items)
            _failure(
              item,
              full ? ExportProblem.noSpace : ExportProblem.copyFailed,
            ),
        ],
      );
    }

    for (final item in items) {
      if (full) {
        failures.add(_failure(item, ExportProblem.noSpace));
        continue;
      }
      if (!_sourcePath.hasMatch(item.relativePath) ||
          !_fileName.hasMatch(item.fileName) ||
          !names.add(item.fileName)) {
        failures.add(_failure(item, ExportProblem.missing));
        continue;
      }
      final List<int> bytes;
      try {
        bytes = await File('${root.path}/${item.relativePath}').readAsBytes();
      } on FileSystemException {
        failures.add(_failure(item, ExportProblem.missing));
        continue;
      }
      if (bytes.length != item.byteLength ||
          crypto.sha256.convert(bytes).toString() != item.sha256) {
        failures.add(_failure(item, ExportProblem.damaged));
        continue;
      }
      final copy = File('${batch.path}/${item.fileName}');
      try {
        await _writeCopy(copy, bytes);
        if (await copy.length() != bytes.length) {
          throw const FileSystemException('short copy');
        }
      } on FileSystemException catch (error) {
        try {
          if (copy.existsSync()) await copy.delete();
        } on FileSystemException {
          // Removed with the batch.
        }
        full = _isNoSpace(error);
        failures.add(
          _failure(
            item,
            full ? ExportProblem.noSpace : ExportProblem.copyFailed,
          ),
        );
        continue;
      }
      prepared.add(item);
      copies.add((path: copy.path, mimeType: item.mimeType));
    }

    if (prepared.isEmpty) {
      return ExportPartReport(
        part: part,
        parts: parts,
        sent: const [],
        failures: failures,
      );
    }
    final share = await _share(copies, anchor);
    return ExportPartReport(
      part: part,
      parts: parts,
      sent: prepared,
      failures: failures,
      share: share,
    );
  }

  static ExportFailureItem _failure(ExportItem item, ExportProblem problem) =>
      ExportFailureItem(
        sessionNumber: item.sessionNumber,
        problem: problem,
        kind: item.kind,
        fileName: item.fileName,
      );

  static bool _isNoSpace(FileSystemException error) =>
      AtomicFileWriter.isNoSpace(error);

  @override
  Future<void> discardPrepared() async {
    final outgoing = await _storage.directory(ManagedArea.outgoing);
    if (!outgoing.existsSync()) return;
    for (final entry in outgoing.listSync(followLinks: false)) {
      try {
        await entry.delete(recursive: true);
      } on FileSystemException {
        // Removed at the next start.
      }
    }
  }
}
