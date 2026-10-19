import 'dart:io';

/// The working files a backup or a restore keeps in the staging area while
/// it runs, named so the next start can discard any a crash left behind
/// (M10, AC-1004). Nothing runs before startup, so each one found then
/// belongs to a backup or restore that never finished.
abstract final class BackupStaging {
  /// The database snapshot of backup [id].
  static String snapshot(String id) => 'backup-$id.sqlite';

  /// The archive of backup [id], before it is moved out to be shared.
  static String archive(String id) => 'backup-$id.tar';

  /// The copy of a chosen backup file, while it is checked and restored.
  static String restoreCopy(String id) => 'restore-$id.tar';

  /// Also SQLite's own files beside a snapshot being cleaned.
  static final _leftover = RegExp(
    r'^(?:backup-[0-9a-f]{16}\.(?:sqlite|tar)|restore-[0-9a-f]{16}\.tar)'
    r'(?:-journal|-wal|-shm)?$',
  );

  /// Removes from [staging] what a backup or restore cut off by a crash
  /// left there. Anything it cannot remove is tried again next time.
  static Future<int> discard(Directory staging) async {
    if (!staging.existsSync()) return 0;
    var removed = 0;
    for (final entry in staging.listSync(followLinks: false)) {
      if (entry is! File || !_leftover.hasMatch(entry.uri.pathSegments.last)) {
        continue;
      }
      try {
        await entry.delete();
        removed++;
      } on FileSystemException {
        // Tried again at the next start.
      }
    }
    return removed;
  }
}
