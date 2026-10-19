import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../../core/platform/app_info.dart';
import '../../domain/backup/backup_manifest.dart';
import '../../domain/services/backup_service.dart';
import '../../domain/services/booth_capabilities.dart';
import '../../domain/services/operator_files.dart';
import '../../domain/value_objects/clock.dart';
import '../database/booth_database.dart';
import '../file_store/managed_storage.dart';
import 'backup_staging.dart';
import 'pending_restore.dart';
import 'tar_archive.dart';

/// Backups as one tar file, restores swapped in at the next storage start
/// (AC-1006, ADR-0016).
///
/// A backup holds a consistent copy of the database (`VACUUM INTO`, taken
/// while the booth runs), the managed files it names and a manifest with
/// every file's size and SHA-256, written last and checked by reading the
/// whole archive back before it is offered. It never holds the PIN's
/// verifier (platform secure storage), the recovery code's verifier, the
/// texting credential or any phone number. A restore is accepted only on
/// an empty booth, only after the copy passes every check, and is applied
/// by renames at the next start, before the database opens.
final class FileBackupService implements BackupService {
  FileBackupService({
    required BoothDatabase database,
    required this._storage,
    required this._space,
    required this._clock,
    Random? random,
  }) : _db = database,
       _random = random ?? Random.secure();

  final BoothDatabase _db;
  final FileManagedStorage _storage;
  final DeviceStorageInfo _space;
  final Clock _clock;
  final Random _random;

  static const _top = BackupManifest.root;

  /// Limits for archives offered for restore: generous for a season of
  /// events, finite against hostile files.
  static const limits = TarLimits(
    root: BackupManifest.root,
    maxEntries: 400000,
    maxEntryBytes: 4 * 1024 * 1024 * 1024,
    maxTotalBytes: 512 * 1024 * 1024 * 1024,
  );

  static const _photoAreas = [ManagedArea.originals, ManagedArea.outputs];
  static const _setupAreas = [ManagedArea.templates, ManagedArea.assets];

  List<ManagedArea> _areas(BackupContents contents) => [
    ..._setupAreas,
    if (contents == BackupContents.everything) ..._photoAreas,
  ];

  String _id() =>
      List.generate(16, (_) => _random.nextInt(16).toRadixString(16)).join();

  // Making a backup.

  @override
  Future<BackupEstimate> estimate(BackupContents contents) async {
    var bytes = (await _storage.databaseFile()).existsSync()
        ? await (await _storage.databaseFile()).length()
        : 0;
    for (final area in _areas(contents)) {
      await for (final file in _files(await _storage.directory(area))) {
        bytes += await file.length() + 512;
      }
    }
    return BackupEstimate(
      contents: contents,
      bytes: bytes + 64 * 1024,
      freeBytes: await _space.freeBytes(),
      counts: await _counts(contents),
    );
  }

  @override
  Future<BackupResult> create(
    BackupContents contents, {
    void Function(double done)? onProgress,
  }) async {
    final estimate = await this.estimate(contents);
    if (!estimate.fits) throw const BackupException(BackupProblem.noSpace);
    final staging = await _storage.directory(ManagedArea.staging);
    final id = _id();
    final snapshot = File('${staging.path}/${BackupStaging.snapshot(id)}');
    final archive = File('${staging.path}/${BackupStaging.archive(id)}');
    try {
      await _db.customStatement('VACUUM INTO ?', [snapshot.path]);
      _scrub(snapshot, contents);
      final now = _clock.now().toUtc();
      final files = <BackupFile>[];
      final sink = archive.openWrite();
      final writer = TarWriter(sink);
      var done = 0;
      try {
        writer
          ..addDirectory(_top, modified: now)
          ..addBytes(
            '$_top/${BackupManifest.readmePath}',
            utf8.encode(_readme(contents, now)),
            modified: now,
          );
        files.add(
          BackupFile(
            BackupManifest.databasePath,
            await snapshot.length(),
            await writer.addFile(
              '$_top/${BackupManifest.databasePath}',
              snapshot,
              modified: now,
            ),
          ),
        );
        for (final area in _areas(contents)) {
          final directory = await _storage.directory(area);
          await for (final file in _files(directory)) {
            final relative =
                '${area.directoryName}/'
                '${file.path.substring(directory.path.length + 1)}';
            final size = await file.length();
            final sha = await writer.addFile(
              '$_top/files/$relative',
              file,
              modified: now,
            );
            files.add(BackupFile('files/$relative', size, sha));
            done += size;
            onProgress?.call(
              estimate.bytes == 0 ? 1 : (done / estimate.bytes).clamp(0, 0.95),
            );
          }
        }
        final manifest = BackupManifest(
          formatVersion: BackupManifest.currentFormatVersion,
          createdAtUtc: now,
          appVersion: AppInfo.version,
          schemaVersion: BoothDatabase.currentSchemaVersion,
          contents: contents,
          boothName: estimate.counts.isEmpty ? '' : await _boothName(),
          counts: estimate.counts,
          files: List.unmodifiable(files),
        );
        writer.addBytes(
          '$_top/${BackupManifest.manifestPath}',
          utf8.encode(manifest.encode()),
          modified: now,
        );
        await writer.close();
        await sink.close();

        // Read the whole archive back before offering it.
        await _verify(archive, maxSchemaVersion: manifest.schemaVersion);
        final outgoing = await _storage.directory(ManagedArea.outgoing);
        final name = _fileName(now);
        final target = await archive.rename('${outgoing.path}/$name');
        onProgress?.call(1);
        return BackupResult(
          path: target.path,
          fileName: name,
          bytes: await target.length(),
          sha256: await _sha256(target),
          manifest: manifest,
        );
      } on Object {
        await sink.close().catchError((_) {});
        rethrow;
      }
    } on BackupException {
      rethrow;
    } on TarException catch (error) {
      throw BackupException(BackupProblem.sourceDamaged, error.detail);
    } on FileSystemException catch (error) {
      throw BackupException(
        _noSpace(error) ? BackupProblem.noSpace : BackupProblem.storageFailed,
      );
    } finally {
      for (final leftover in [snapshot, archive]) {
        if (leftover.existsSync()) await leftover.delete();
      }
    }
  }

  // Restoring.

  @override
  Future<RestoreCandidate> inspect(
    PickedStream file, {
    void Function(double done)? onProgress,
  }) async {
    if (!await _empty()) throw const BackupException(BackupProblem.notEmpty);
    if (file.length > limits.maxTotalBytes) {
      throw const BackupException(BackupProblem.tooLarge);
    }
    final free = await _space.freeBytes();
    if (free != null && free < file.length * 2 + BackupEstimate.margin) {
      throw const BackupException(BackupProblem.noSpace);
    }
    final id = _id();
    final copy = File(
      '${(await _storage.directory(ManagedArea.staging)).path}/'
      '${BackupStaging.restoreCopy(id)}',
    );
    try {
      var copied = 0;
      final sink = copy.openWrite();
      try {
        await for (final chunk in file.open()) {
          copied += chunk.length;
          if (copied > limits.maxTotalBytes) {
            throw const BackupException(BackupProblem.tooLarge);
          }
          sink.add(chunk);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      onProgress?.call(0.4);
      final manifest = await _verify(
        copy,
        maxSchemaVersion: BoothDatabase.currentSchemaVersion,
      );
      onProgress?.call(1);
      return RestoreCandidate(id: id, manifest: manifest);
    } on Object {
      if (copy.existsSync()) await copy.delete();
      rethrow;
    }
  }

  @override
  Future<void> stage(
    RestoreCandidate candidate, {
    void Function(double done)? onProgress,
  }) async {
    if (!await _empty()) throw const BackupException(BackupProblem.notEmpty);
    final copy = await _candidateFile(candidate);
    final pending = PendingRestore(await _storage.rootDirectory());
    final unpack = Directory('${pending.area.path}/unpack-${candidate.id}');
    try {
      if (pending.incoming.existsSync()) {
        await pending.incoming.delete(recursive: true);
      }
      await unpack.create(recursive: true);
      final entries = await readTar(copy, limits: limits, extractTo: unpack);
      _match(entries, candidate.manifest);
      onProgress?.call(0.7);
      final inner = Directory('${unpack.path}/$_top');
      _checkDatabase(
        File('${inner.path}/${BackupManifest.databasePath}'),
        candidate.manifest,
        Directory('${inner.path}/files'),
      );
      await inner.rename(pending.incoming.path);
      await pending.readyMarker.writeAsString(
        jsonEncode({
          'createdAt': candidate.manifest.createdAtUtc.toIso8601String(),
          'boothName': candidate.manifest.boothName,
          'counts': candidate.manifest.counts,
        }),
        flush: true,
      );
      onProgress?.call(1);
    } on TarException catch (error) {
      throw BackupException(_problemOf(error), error.detail);
    } on FileSystemException catch (error) {
      throw BackupException(
        _noSpace(error) ? BackupProblem.noSpace : BackupProblem.storageFailed,
      );
    } finally {
      if (unpack.existsSync()) await unpack.delete(recursive: true);
      if (copy.existsSync()) await copy.delete();
    }
  }

  @override
  Future<void> discard(RestoreCandidate candidate) async {
    final copy = await _candidateFile(candidate);
    if (copy.existsSync()) await copy.delete();
  }

  @override
  Future<RestoreReport?> finishRestore() async {
    final pending = PendingRestore(await _storage.rootDirectory());
    if (!pending.appliedMarker.existsSync()) return null;
    final summary = jsonDecode(
      await pending.appliedMarker.readAsString(),
    ) as Map<String, Object?>;
    final closed = await _db.transaction(() async {
      await _db.customStatement(
        'UPDATE app_settings SET setup_completed_at = NULL, '
        'booth_event_id = NULL',
      );
      await _db.customStatement(
        'UPDATE operator_access SET recovery_verifier = NULL, '
        'pin_failures = 0, pin_last_failure_at = NULL, '
        'recovery_failures = 0, recovery_last_failure_at = NULL',
      );
      await _db.customStatement('DELETE FROM delivery_pairings');
      final open = await _db
          .customSelect(
            "SELECT count(*) AS n FROM delivery_intents WHERE state <> 'finished'",
          )
          .getSingle();
      await _db.customStatement(
        "UPDATE delivery_intents SET state = 'finished', "
        "local_outcome = 'canceled', phone_stored = 0, "
        "last_error_code = 'NOT_RESTORED', retry_at = NULL "
        "WHERE state <> 'finished'",
      );
      return open.read<int>('n');
    });
    await pending.finished();
    final counts = summary['counts'];
    return RestoreReport(
      createdAtUtc:
          DateTime.tryParse('${summary['createdAt']}')?.toUtc() ??
          _clock.now().toUtc(),
      boothName: '${summary['boothName'] ?? ''}',
      counts: {
        if (counts is Map)
          for (final MapEntry(:key, :value) in counts.entries)
            if (key is String && value is int) key: value,
      },
      closedDeliveries: closed,
    );
  }

  // Helpers.

  Future<File> _candidateFile(RestoreCandidate candidate) async {
    if (!RegExp(r'^[0-9a-f]{16}$').hasMatch(candidate.id)) {
      throw const BackupException(BackupProblem.invalidArchive);
    }
    final staging = await _storage.directory(ManagedArea.staging);
    return File('${staging.path}/${BackupStaging.restoreCopy(candidate.id)}');
  }

  /// Reads [archive] end to end: structure, names, limits, checksums,
  /// the manifest and that it lists exactly what is there.
  Future<BackupManifest> _verify(
    File archive, {
    required int maxSchemaVersion,
  }) async {
    final List<TarEntryInfo> entries;
    final String manifestText;
    try {
      final captured = <String, List<int>>{};
      entries = await readTar(
        archive,
        limits: limits,
        capture: {'$_top/${BackupManifest.manifestPath}'},
        captured: captured,
      );
      final bytes = captured['$_top/${BackupManifest.manifestPath}'];
      if (bytes == null) {
        throw const BackupException(
          BackupProblem.invalidArchive,
          'no manifest',
        );
      }
      manifestText = utf8.decode(bytes);
    } on TarException catch (error) {
      throw BackupException(_problemOf(error), error.detail);
    } on FormatException {
      throw const BackupException(BackupProblem.invalidArchive, 'manifest');
    }
    final manifest = BackupManifest.decode(
      manifestText,
      maxSchemaVersion: maxSchemaVersion,
    );
    _match(entries, manifest);
    return manifest;
  }

  /// Every file in [manifest] is in [entries] with the same size and
  /// checksum, and nothing else is (besides the readme and the manifest).
  void _match(List<TarEntryInfo> entries, BackupManifest manifest) {
    final files = {
      for (final entry in entries)
        if (!entry.directory) entry.name.substring(_top.length + 1): entry,
    };
    for (final file in manifest.files) {
      final entry = files.remove(file.path);
      if (entry == null ||
          entry.size != file.bytes ||
          entry.sha256 != file.sha256) {
        throw BackupException(BackupProblem.invalidArchive, file.path);
      }
    }
    files
      ..remove(BackupManifest.manifestPath)
      ..remove(BackupManifest.readmePath);
    if (files.isNotEmpty) {
      throw BackupException(BackupProblem.unsafeArchive, files.keys.first);
    }
    for (final file in manifest.files) {
      if (file.path == BackupManifest.databasePath) continue;
      if (!RegExp(
        r'^files/(originals|outputs|templates|assets)/[0-9A-Za-z._-]+(/[0-9A-Za-z._-]+)*$',
      ).hasMatch(file.path)) {
        throw BackupException(BackupProblem.unsafeArchive, file.path);
      }
    }
  }

  /// The database passes its own integrity check, is not newer than this
  /// app, and every file it names is in the backup with its checksum.
  void _checkDatabase(File file, BackupManifest manifest, Directory files) {
    final db = sqlite.sqlite3.open(file.path, mode: sqlite.OpenMode.readOnly);
    try {
      final integrity = db.select('PRAGMA integrity_check');
      if (integrity.length != 1 || integrity.first.values.first != 'ok') {
        throw const BackupException(BackupProblem.databaseDamaged);
      }
      final version = db.select('PRAGMA user_version').first.values.first;
      if (version is! int || version < 1) {
        throw const BackupException(BackupProblem.databaseDamaged);
      }
      if (version > BoothDatabase.currentSchemaVersion) {
        throw const BackupException(BackupProblem.newerVersion);
      }
      final listed = {
        for (final entry in manifest.files)
          if (entry.path.startsWith('files/'))
            entry.path.substring('files/'.length): entry.sha256,
      };
      for (final (table, hasSha) in [
        ('original_photos', true),
        ('session_outputs', true),
        ('assets', false),
      ]) {
        final exists = db.select(
          "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
          [table],
        );
        if (exists.isEmpty) continue;
        final rows = db.select(
          hasSha
              ? 'SELECT relative_path, sha256 FROM $table'
              : 'SELECT relative_path FROM $table',
        );
        for (final row in rows) {
          final path = row['relative_path'] as String;
          final sha = listed[path];
          if (sha == null ||
              (hasSha && sha != row['sha256'] as String) ||
              !File('${files.path}/$path').existsSync()) {
            if (manifest.contents == BackupContents.setupOnly &&
                table != 'assets') {
              throw BackupException(BackupProblem.databaseDamaged, table);
            }
            throw BackupException(BackupProblem.invalidArchive, path);
          }
        }
      }
    } on sqlite.SqliteException {
      throw const BackupException(BackupProblem.databaseDamaged);
    } finally {
      db.close();
    }
  }

  /// Removes from the snapshot what a backup never carries, and for a
  /// setup-only backup every guest session.
  void _scrub(File snapshot, BackupContents contents) {
    final db = sqlite.sqlite3.open(snapshot.path);
    try {
      db.execute('PRAGMA foreign_keys = OFF');
      db.execute('BEGIN');
      db.execute('DELETE FROM delivery_pairings');
      db.execute('UPDATE operator_access SET recovery_verifier = NULL');
      if (contents == BackupContents.setupOnly) {
        for (final table in [
          'delivery_remote_revocations',
          'delivery_intents',
          'export_batch_items',
          'export_batches',
          'session_outputs',
          'session_photos',
          'capture_sessions',
          'pending_original_commits',
          'original_photos',
          'pending_file_deletions',
        ]) {
          db.execute('DELETE FROM $table');
        }
      }
      db.execute('COMMIT');
      db.execute('VACUUM');
    } finally {
      db.close();
    }
  }

  Future<bool> _empty() async {
    final row = await _db
        .customSelect(
          'SELECT (SELECT count(*) FROM events) + '
          '(SELECT count(*) FROM capture_sessions) + '
          '(SELECT count(*) FROM original_photos) AS n',
        )
        .getSingle();
    return row.read<int>('n') == 0;
  }

  Future<Map<String, int>> _counts(BackupContents contents) async {
    Future<int> count(String table) async =>
        (await _db.customSelect('SELECT count(*) AS n FROM $table').getSingle())
            .read<int>('n');
    final photos = contents == BackupContents.everything;
    return {
      'events': await count('events'),
      'templates': await count('templates'),
      'assets': await count('assets'),
      'sessions': photos ? await count('capture_sessions') : 0,
      'photos': photos ? await count('original_photos') : 0,
      'finishedPhotos': photos ? await count('session_outputs') : 0,
    };
  }

  Future<String> _boothName() async {
    final row = await _db
        .customSelect('SELECT name FROM booth_profiles LIMIT 1')
        .getSingleOrNull();
    return row?.read<String>('name') ?? '';
  }

  String _fileName(DateTime now) {
    String two(int value) => value.toString().padLeft(2, '0');
    final local = now.toLocal();
    return 'porcelain-backup-${local.year}${two(local.month)}${two(local.day)}'
        '-${two(local.hour)}${two(local.minute)}.tar';
  }

  String _readme(BackupContents contents, DateTime now) => [
    'Porcelain Photo Booth backup',
    'Made ${now.toIso8601String()} by version ${AppInfo.version}.',
    contents == BackupContents.everything
        ? "Holds the booth's settings, events, templates and every "
              "guest session's photos."
        : "Holds the booth's settings, events and templates; no guest "
              'photos.',
    'It contains personal data (photos of guests): keep it safe and '
        'delete it when it is no longer needed.',
    'Restore it with Porcelain Photo Booth on a new installation: '
        '"Restore from a backup" on the first screen.',
    'It never holds the operator PIN, the recovery code, the texting '
        'credential or any phone number.',
  ].join('\n');

  static Stream<File> _files(Directory directory) async* {
    if (!directory.existsSync()) return;
    final entries =
        await directory.list(recursive: true, followLinks: false).toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final entry in entries) {
      if (entry is File) yield entry;
    }
  }

  static Future<String> _sha256(File file) async =>
      (await crypto.sha256.bind(file.openRead()).first).toString();

  static bool _noSpace(FileSystemException error) {
    final code = error.osError?.errorCode;
    return code == 28 || code == 112; // ENOSPC, ERROR_DISK_FULL
  }

  static BackupProblem _problemOf(TarException error) =>
      switch (error.problem) {
        TarProblem.invalid => BackupProblem.invalidArchive,
        TarProblem.unsafe => BackupProblem.unsafeArchive,
        TarProblem.tooLarge => BackupProblem.tooLarge,
      };
}
