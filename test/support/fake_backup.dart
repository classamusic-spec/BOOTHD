import 'package:porcelain_photo_booth/domain/backup/backup_manifest.dart';
import 'package:porcelain_photo_booth/domain/services/backup_service.dart';
import 'package:porcelain_photo_booth/domain/services/operator_files.dart';

/// Backups and restores scripted by tests (the real service is tested on
/// files: test/infrastructure/backup/backup_restore_test.dart).
final class FakeBackupService implements BackupService {
  /// Estimated sizes and free space, by contents.
  int everythingBytes = 1800 * 1024 * 1024;
  int setupBytes = 24 * 1024 * 1024;
  int? freeBytes = 64 * 1024 * 1024 * 1024;

  /// The next [create], [inspect] or [stage] fails with this.
  BackupException? nextFailure;

  /// What [finishRestore] reports at the next start.
  RestoreReport? pendingReport;

  final created = <BackupContents>[];
  final inspected = <String>[];
  final staged = <RestoreCandidate>[];
  final discarded = <RestoreCandidate>[];

  static final made = DateTime.utc(2026, 11, 14, 23, 41);

  static const counts = {
    'events': 3,
    'templates': 5,
    'assets': 4,
    'sessions': 214,
    'photos': 461,
    'finishedPhotos': 209,
  };

  BackupManifest manifest(BackupContents contents) => BackupManifest(
    formatVersion: BackupManifest.currentFormatVersion,
    createdAtUtc: made,
    appVersion: '0.1.0',
    schemaVersion: 7,
    contents: contents,
    boothName: 'Front entrance',
    counts: contents == BackupContents.everything
        ? counts
        : {...counts, 'sessions': 0, 'photos': 0, 'finishedPhotos': 0},
    files: const [BackupFile(BackupManifest.databasePath, 4096, _sha)],
  );

  static const _sha =
      '0f1e2d3c4b5a69788796a5b4c3d2e1f00f1e2d3c4b5a69788796a5b4c3d2e1f0';

  void _fail() {
    final failure = nextFailure;
    nextFailure = null;
    if (failure != null) throw failure;
  }

  @override
  Future<BackupEstimate> estimate(BackupContents contents) async =>
      BackupEstimate(
        contents: contents,
        bytes: contents == BackupContents.everything
            ? everythingBytes
            : setupBytes,
        freeBytes: freeBytes,
        counts: manifest(contents).counts,
      );

  @override
  Future<BackupResult> create(
    BackupContents contents, {
    void Function(double done)? onProgress,
  }) async {
    created.add(contents);
    onProgress?.call(0.5);
    _fail();
    onProgress?.call(1);
    return BackupResult(
      path: '/backups/porcelain-backup-20261114-2341.tar',
      fileName: 'porcelain-backup-20261114-2341.tar',
      bytes: contents == BackupContents.everything
          ? everythingBytes
          : setupBytes,
      sha256: _sha,
      manifest: manifest(contents),
    );
  }

  @override
  Future<RestoreCandidate> inspect(
    PickedStream file, {
    void Function(double done)? onProgress,
  }) async {
    inspected.add(file.name);
    onProgress?.call(0.5);
    _fail();
    return RestoreCandidate(
      id: '0123456789abcdef',
      manifest: manifest(BackupContents.everything),
    );
  }

  @override
  Future<void> stage(
    RestoreCandidate candidate, {
    void Function(double done)? onProgress,
  }) async {
    _fail();
    staged.add(candidate);
    onProgress?.call(1);
  }

  @override
  Future<void> discard(RestoreCandidate candidate) async =>
      discarded.add(candidate);

  @override
  Future<RestoreReport?> finishRestore() async {
    final report = pendingReport;
    pendingReport = null;
    return report;
  }
}
