import 'dart:io';

import 'package:drift/drift.dart';

import '../../domain/services/gallery_services.dart';
import '../database/booth_database.dart';

/// [StorageCleanup] for managed storage (A-11, AC-0805): removes the files
/// listed in `pending_file_deletions`, then their journal rows.
///
/// The records that owned the files were deleted in the transaction that
/// wrote the journal, so nothing refers to these files any more; removing
/// one that is already gone counts as done. Only paths in the photo,
/// output and thumbnail areas are touched. A file that cannot be removed
/// keeps its row and is tried again on the next run (after the next
/// deletion, and at every startup).
final class ManagedStorageCleanup implements StorageCleanup {
  ManagedStorageCleanup({
    required this._database,
    required this._root,
    this._delete = _deleteFile,
  });

  final BoothDatabase _database;
  final Future<Directory> Function() _root;
  final Future<void> Function(File file) _delete;

  static final _removable = RegExp(
    r'^(originals/[0-9A-Za-z-]{1,64}\.jpg'
    r'|outputs/[0-9a-f-]{36}\.(jpg|png)'
    r'|thumbnails/(output|original)-[0-9A-Za-z-]{1,64}\.jpg)$',
  );

  static Future<void> _deleteFile(File file) => file.delete();

  var _running = false;

  @override
  Future<CleanupResult> run() async {
    if (_running) return const CleanupResult(removed: 0, remaining: 0);
    _running = true;
    try {
      final root = await _root();
      var removed = 0;
      var remaining = 0;
      final pending = await (_database.select(
        _database.pendingFileDeletions,
      )..orderBy([(p) => OrderingTerm.asc(p.queuedAt)])).get();
      for (final entry in pending) {
        final path = entry.relativePath;
        if (_removable.hasMatch(path)) {
          final file = File('${root.path}/$path');
          try {
            if (file.existsSync()) await _delete(file);
          } on FileSystemException {
            remaining++;
            continue;
          }
        }
        // A path outside the removable areas is never touched; its entry
        // is dropped so it cannot linger.
        await (_database.delete(
          _database.pendingFileDeletions,
        )..where((p) => p.relativePath.equals(path))).go();
        removed++;
      }
      return CleanupResult(removed: removed, remaining: remaining);
    } finally {
      _running = false;
    }
  }
}
