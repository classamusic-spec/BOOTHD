import '../../domain/backup/backup_manifest.dart';

/// Words operators read about backups and restores (M10, AC-1006).
abstract final class BackupCopy {
  /// What each problem means to the operator (codes stay in the detail).
  static String problem(BackupProblem problem) => switch (problem) {
    BackupProblem.noSpace =>
      'Not enough free space on this tablet for the backup file.',
    BackupProblem.sourceDamaged =>
      "A photo on this tablet doesn't match its record, so the backup "
          'would not be complete. Check Storage, then try again.',
    BackupProblem.storageFailed =>
      "This tablet's storage failed while writing the backup.",
    BackupProblem.invalidArchive =>
      "This file isn't a complete booth backup (it may have been cut "
          'short or changed).',
    BackupProblem.unsafeArchive =>
      'This file holds things a booth backup never does, so it was not '
          'opened.',
    BackupProblem.tooLarge => 'This file is larger than any booth backup.',
    BackupProblem.newerVersion =>
      'This backup was made by a newer version of the app. Update the app '
          'first.',
    BackupProblem.databaseDamaged =>
      "The backup's records are damaged, so it cannot be restored.",
    BackupProblem.notEmpty =>
      'A backup can only be restored on a booth with nothing on it yet.',
  };

  /// "3 events, 5 templates, 214 sessions with 461 photos", from a
  /// backup's counts.
  static String contents(Map<String, int> counts) {
    String count(String key, String one, String many) {
      final n = counts[key] ?? 0;
      return '$n ${n == 1 ? one : many}';
    }

    final sessions = counts['sessions'] ?? 0;
    return [
      count('events', 'event', 'events'),
      count('templates', 'template', 'templates'),
      if (sessions > 0)
        '${count('sessions', 'session', 'sessions')} with '
            '${count('photos', 'camera photo', 'camera photos')}'
      else
        'no guest photos',
    ].join(', ');
  }
}
