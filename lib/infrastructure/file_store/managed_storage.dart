import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../../core/diagnostics/safe_log.dart';
import '../../domain/repositories/storage_errors.dart';
import '../../domain/services/booth_capabilities.dart';
import '../../domain/services/managed_storage.dart';
import '../backup/backup_staging.dart';
import '../backup/pending_restore.dart';
import 'atomic_file_writer.dart';

/// Top-level directories of managed storage, under the app's private
/// support directory (never the user-visible Documents folder).
enum ManagedArea {
  database('database'),
  originals('originals'),
  outputs('outputs'),
  templates('templates'),
  assets('assets'),

  /// Gallery thumbnails (M08): derived from outputs and originals, safe to
  /// clear at any time.
  thumbnails('thumbnails'),

  /// Copies prepared for the share sheet (M08), under their export names.
  /// Replaced by each export and cleared at startup.
  outgoing('outgoing'),

  /// Files being written; renamed into place only once complete (A-11).
  staging('staging'),

  /// A validated backup waiting to be swapped in at the next start (M10).
  restore('restore');

  const ManagedArea(this.directoryName);

  final String directoryName;
}

/// Managed storage on the local file system (A-11). Everything lives below
/// one root; callers name areas, never paths.
final class FileManagedStorage implements ManagedStorage {
  FileManagedStorage({
    required this._root,
    Random? random,
    this._keepOutOfDeviceBackups,
  }) : _random = random ?? Random.secure();

  static const databaseFileName = 'porcelain_booth.sqlite';

  final Future<Directory> Function() _root;
  final Random _random;

  /// Marks the root so the tablet's own backups (iCloud, a computer) leave
  /// the booth's data out (ADR-0009, ADR-0016); Android does this through
  /// its manifest. Best effort: the booth works if it fails.
  final Future<void> Function(Directory root)? _keepOutOfDeviceBackups;

  Future<Directory> directory(ManagedArea area) async =>
      Directory('${(await _root()).path}/${area.directoryName}');

  /// The directory every area lives in.
  Future<Directory> rootDirectory() => _root();

  /// The booth database file.
  Future<File> databaseFile() async =>
      File('${(await directory(ManagedArea.database)).path}/$databaseFileName');

  @override
  Future<void> prepare() async {
    try {
      for (final area in ManagedArea.values) {
        await (await directory(area)).create(recursive: true);
      }
    } on FileSystemException {
      throw const ManagedStorageException('STORAGE_UNAVAILABLE');
    }
    try {
      await _keepOutOfDeviceBackups?.call(await _root());
    } on Exception catch (error, stack) {
      SafeLog.error(error, stack, context: 'device backup exclusion');
    }
    // A restore marked ready is swapped in before anything opens the
    // database; one never marked ready is discarded (M10, AC-1006).
    try {
      await PendingRestore(await _root()).applyIfReady(
        databaseRelativePath:
            '${ManagedArea.database.directoryName}/$databaseFileName',
      );
    } on FileSystemException {
      throw const ManagedStorageException('RESTORE_INCOMPLETE');
    }
    // Startup reconciliation (A-11): nothing writes before startup, so a
    // staged file now belongs to a write the app never finished, and a
    // backup or restore working file to one cut off (M10).
    final staging = await directory(ManagedArea.staging);
    await AtomicFileWriter.discardStaged(staging);
    await BackupStaging.discard(staging);
    // Copies prepared for an earlier export (M08) are never needed again.
    final outgoing = await directory(ManagedArea.outgoing);
    for (final entry in outgoing.listSync(followLinks: false)) {
      try {
        await entry.delete(recursive: true);
      } on FileSystemException {
        // Tried again at the next start.
      }
    }
  }

  /// A writer that stages in this storage's staging area.
  Future<AtomicFileWriter> writer({
    FileOperations operations = const FileOperations(),
  }) async => AtomicFileWriter(
    staging: await directory(ManagedArea.staging),
    operations: operations,
  );

  @override
  Future<CapabilityStatus> probeWrite() async {
    final staging = await directory(ManagedArea.staging);
    final name = List.generate(8, (_) => _random.nextInt(16).toRadixString(16));
    final probe = File('${staging.path}/probe-${name.join()}.tmp');
    final bytes = Uint8List.fromList(
      List.generate(4096, (_) => _random.nextInt(256)),
    );
    try {
      await staging.create(recursive: true);
      await probe.writeAsBytes(bytes, flush: true);
      final readBack = await probe.readAsBytes();
      var same = readBack.length == bytes.length;
      for (var i = 0; same && i < bytes.length; i++) {
        same = readBack[i] == bytes[i];
      }
      return same
          ? const CapabilityReady()
          : const CapabilityProblem('STORAGE_READBACK_MISMATCH');
    } on FileSystemException {
      return const CapabilityProblem('STORAGE_NOT_WRITABLE');
    } finally {
      try {
        if (probe.existsSync()) await probe.delete();
      } on FileSystemException {
        // Left for the staging clean-up (M10); never fails the check twice.
      }
    }
  }
}
