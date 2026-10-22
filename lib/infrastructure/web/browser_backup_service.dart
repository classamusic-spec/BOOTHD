import '../../domain/backup/backup_manifest.dart';
import '../../domain/services/backup_service.dart';
import '../../domain/services/operator_files.dart';

/// The browser test build has no backup file (ADR-0018): its database is
/// not a file to copy. Settings and setup say so and offer no backup or
/// restore; startup finds no restore to finish.
final class BrowserBackupService implements BackupService {
  const BrowserBackupService();

  static const _unavailable = BackupException(
    BackupProblem.invalidArchive,
    'backups are made in the tablet app',
  );

  @override
  Future<BackupEstimate> estimate(BackupContents contents) async =>
      BackupEstimate(
        contents: contents,
        bytes: 0,
        freeBytes: null,
        counts: const {},
      );

  @override
  Future<BackupResult> create(
    BackupContents contents, {
    void Function(double done)? onProgress,
  }) async => throw _unavailable;

  @override
  Future<RestoreCandidate> inspect(
    PickedStream file, {
    void Function(double done)? onProgress,
  }) async => throw _unavailable;

  @override
  Future<void> stage(
    RestoreCandidate candidate, {
    void Function(double done)? onProgress,
  }) async => throw _unavailable;

  @override
  Future<void> discard(RestoreCandidate candidate) async {}

  @override
  Future<RestoreReport?> finishRestore() async => null;
}
