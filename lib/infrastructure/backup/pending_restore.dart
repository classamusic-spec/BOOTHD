import 'dart:convert';
import 'dart:io';

/// A restore waiting to be swapped in at the next start of the booth's
/// storage (M10, AC-1006, ADR-0016).
///
/// A validated backup is extracted below `restore/incoming/` and only then
/// marked ready (`restore/ready.json`). The next start, before anything
/// opens the database, moves every file into its managed area, then the
/// database, and marks the restore applied (`restore/applied.json`) for
/// the clean-up that runs once the database is open. Each step is a
/// rename on the same volume and can be repeated: a start interrupted
/// half-way finishes the move at the next start. Anything in the restore
/// area that was never marked ready (an extraction cut short) is
/// discarded.
final class PendingRestore {
  PendingRestore(this.root);

  /// The managed storage root.
  final Directory root;

  Directory get area => Directory('${root.path}/restore');
  Directory get incoming => Directory('${area.path}/incoming');
  File get readyMarker => File('${area.path}/ready.json');
  File get appliedMarker => File('${area.path}/applied.json');

  /// Swaps a ready restore in, or discards an unfinished one. Returns the
  /// summary written when the restore was staged, if one was applied now
  /// or earlier and its clean-up has not run yet. Throws
  /// [FileSystemException] when a file cannot be moved (the next start
  /// tries again).
  Future<Map<String, Object?>?> applyIfReady({
    required String databaseRelativePath,
  }) async {
    if (!area.existsSync()) return null;
    if (!readyMarker.existsSync()) {
      await for (final entry in area.list(followLinks: false)) {
        if (entry.path == appliedMarker.path) continue;
        await entry.delete(recursive: true);
      }
      return _applied();
    }
    final summary = _decode(await readyMarker.readAsString());
    final files = Directory('${incoming.path}/files');
    if (files.existsSync()) {
      final entries = await files
          .list(recursive: true, followLinks: false)
          .where((entry) => entry is File)
          .cast<File>()
          .toList();
      for (final file in entries) {
        final relative = file.path.substring(files.path.length + 1);
        final target = File('${root.path}/$relative');
        await target.parent.create(recursive: true);
        if (target.existsSync()) await target.delete();
        await file.rename(target.path);
      }
    }
    final database = File('${incoming.path}/database.sqlite');
    if (database.existsSync()) {
      final target = File('${root.path}/$databaseRelativePath');
      await target.parent.create(recursive: true);
      for (final suffix in ['', '-wal', '-shm', '-journal']) {
        final old = File('${target.path}$suffix');
        if (old.existsSync()) await old.delete();
      }
      await database.rename(target.path);
    }
    await appliedMarker.writeAsString(jsonEncode(summary), flush: true);
    await readyMarker.delete();
    if (incoming.existsSync()) await incoming.delete(recursive: true);
    return summary;
  }

  Future<Map<String, Object?>?> _applied() async => appliedMarker.existsSync()
      ? _decode(await appliedMarker.readAsString())
      : null;

  static Map<String, Object?> _decode(String text) {
    try {
      final json = jsonDecode(text);
      return json is Map<String, Object?> ? json : const {};
    } on FormatException {
      return const {};
    }
  }

  /// The post-restore clean-up is done.
  Future<void> finished() async {
    if (appliedMarker.existsSync()) await appliedMarker.delete();
  }
}
