import 'package:meta/meta.dart';

import '../backup/backup_manifest.dart';
import 'operator_files.dart';

/// How big a backup would be, and whether the tablet has room to make it.
@immutable
final class BackupEstimate {
  const BackupEstimate({
    required this.contents,
    required this.bytes,
    required this.freeBytes,
    required this.counts,
  });

  final BackupContents contents;

  /// The backup file's size, near enough (the files plus the database).
  final int bytes;

  /// Free space now, or null when the platform cannot say.
  final int? freeBytes;

  /// Events, sessions, photos, finished photos, templates, assets.
  final Map<String, int> counts;

  /// Room for the file and a margin (the backup is written beside the
  /// booth's own files before it is shared).
  bool get fits => freeBytes == null || freeBytes! >= bytes + margin;

  static const margin = 256 * 1024 * 1024;
}

/// A finished, verified backup file, ready to hand to the share sheet.
@immutable
final class BackupResult {
  const BackupResult({
    required this.path,
    required this.fileName,
    required this.bytes,
    required this.sha256,
    required this.manifest,
  });

  /// In the app's outgoing area (removed at the next start).
  final String path;
  final String fileName;
  final int bytes;

  /// Of the whole file, for the operator's records.
  final String sha256;
  final BackupManifest manifest;
}

/// A backup chosen for restore, copied into the app and checked from end
/// to end; nothing on the booth has changed yet.
@immutable
final class RestoreCandidate {
  const RestoreCandidate({required this.id, required this.manifest});

  /// Names the copy in the app's staging area.
  final String id;
  final BackupManifest manifest;
}

/// What a restore brought back, reported once after the restart.
@immutable
final class RestoreReport {
  const RestoreReport({
    required this.createdAtUtc,
    required this.boothName,
    required this.counts,
    required this.closedDeliveries,
  });

  final DateTime createdAtUtc;
  final String boothName;
  final Map<String, int> counts;

  /// Texts that were waiting when the backup was made: their numbers were
  /// never in the backup, so they were closed.
  final int closedDeliveries;
}

/// Backups and restores (AC-1006, ADR-0016). Throws `BackupException`.
abstract interface class BackupService {
  Future<BackupEstimate> estimate(BackupContents contents);

  /// Writes, verifies and returns a backup. [onProgress] gets 0 to 1.
  Future<BackupResult> create(
    BackupContents contents, {
    void Function(double done)? onProgress,
  });

  /// Copies the chosen [file] into the app at once (the picker's copy may
  /// vanish) and checks it from end to end. Only an empty booth (first
  /// run, nothing recorded) can be restored into.
  Future<RestoreCandidate> inspect(
    PickedStream file, {
    void Function(double done)? onProgress,
  });

  /// Extracts [candidate] and marks it ready; the booth swaps it in at the
  /// next start of its storage (the caller restarts it).
  Future<void> stage(
    RestoreCandidate candidate, {
    void Function(double done)? onProgress,
  });

  /// Forgets an inspected or staged restore.
  Future<void> discard(RestoreCandidate candidate);

  /// After a restart that swapped a restore in: resets what must not come
  /// back (operator PIN state, texting pairing, waiting texts) and reports
  /// what returned. Null when no restore was applied.
  Future<RestoreReport?> finishRestore();
}
