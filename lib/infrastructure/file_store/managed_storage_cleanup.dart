import 'dart:io';

import 'package:drift/drift.dart';

import '../../domain/services/gallery_services.dart';
import '../database/booth_database.dart';
import 'original_store.dart';

/// [StorageCleanup] for managed storage (A-11, AC-0805): removes the files
/// listed in `pending_file_deletions`, then their journal rows; and at
/// startup sweeps away files no record refers to (M10, AC-1004).
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

  /// Every file the app writes to these areas is recorded in the database
  /// once its write is finished: a file nothing refers to was left by a
  /// crash between its rename and its record (or restored with a backup
  /// that held one). Removing it is safe only before anything writes, so
  /// this runs at startup alone, never after a deletion.
  @override
  Future<OrphanSweepResult> sweepOrphans() async {
    final root = await _root();
    final rows = await _database
        .customSelect(
          'SELECT relative_path AS path FROM original_photos '
          "UNION ALL SELECT 'originals/' || id || '.jpg' "
          'FROM pending_original_commits '
          'UNION ALL SELECT relative_path FROM session_outputs '
          'UNION ALL SELECT relative_path FROM assets '
          'UNION ALL SELECT manifest_path FROM template_revisions '
          'UNION ALL SELECT relative_path FROM pending_file_deletions',
        )
        .get();
    final referenced = {for (final row in rows) row.read<String>('path')};
    String relative(FileSystemEntity entry) =>
        entry.path.substring(root.path.length + 1).replaceAll(r'\', '/');

    var removed = 0;
    for (final area in _sweptAreas) {
      final directory = Directory('${root.path}/$area');
      if (!directory.existsSync()) continue;
      final files = directory
          .listSync(recursive: true, followLinks: false)
          .whereType<File>();
      for (final file in files) {
        if (referenced.contains(relative(file))) continue;
        try {
          await _delete(file);
          removed++;
        } on FileSystemException {
          // Tried again at the next start.
        }
      }
    }
    // Template folders the sweep emptied.
    final templates = Directory('${root.path}/templates');
    if (templates.existsSync()) {
      for (final folder
          in templates.listSync(followLinks: false).whereType<Directory>()) {
        try {
          if (folder.listSync().isEmpty) await folder.delete();
        } on FileSystemException {
          // Harmless; tried again at the next start.
        }
      }
    }

    // Camera photos are never deleted by a sweep: one nothing refers to is
    // moved aside, like a file that is not what its journal expected.
    var quarantined = 0;
    final originals = Directory('${root.path}/originals');
    if (originals.existsSync()) {
      final aside = Directory(
        '${originals.path}/${OriginalStore.quarantineName}',
      );
      final files = originals.listSync(followLinks: false).whereType<File>();
      for (final file in files) {
        if (referenced.contains(relative(file))) continue;
        try {
          await aside.create(recursive: true);
          await file.rename(
            '${aside.path}/${DateTime.now().microsecondsSinceEpoch}-'
            '${file.uri.pathSegments.last}',
          );
          quarantined++;
        } on FileSystemException {
          // Tried again at the next start.
        }
      }
    }
    return OrphanSweepResult(removed: removed, quarantined: quarantined);
  }

  /// Areas whose every file is recorded: finished photos, template images
  /// and template revisions.
  static const _sweptAreas = ['outputs', 'assets', 'templates'];
}
