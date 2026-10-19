import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// What a backup holds (AC-1006).
enum BackupContents {
  /// Settings, events, templates, assets and every session's photos.
  everything,

  /// Settings, events, templates and assets: no guest photos or sessions.
  setupOnly,
}

/// Why a backup cannot be made or restored. Codes only (guest data never
/// appears in them).
enum BackupProblem {
  /// Not enough free space for the backup file (or for a restore).
  noSpace,

  /// A file the database names is missing or does not match its checksum.
  sourceDamaged,

  /// Not a backup this app wrote, or one that was cut short or changed.
  invalidArchive,

  /// Names, links or sizes that could reach outside the restore folder.
  unsafeArchive,

  /// Over the size or entry limits.
  tooLarge,

  /// Written by a newer app (a newer database or format version).
  newerVersion,

  /// The archive is fine but its database fails its own checks.
  databaseDamaged,

  /// Restore needs an empty booth (first run).
  notEmpty,

  /// The tablet's storage failed while writing.
  storageFailed,
}

final class BackupException implements Exception {
  const BackupException(this.problem, [this.detail = '']);

  final BackupProblem problem;

  /// Which entry or step, never contents.
  final String detail;

  @override
  String toString() =>
      'BackupException(${problem.name}${detail.isEmpty ? '' : ': $detail'})';
}

/// One file in a backup: where it goes back to, its size and SHA-256.
@immutable
final class BackupFile {
  const BackupFile(this.path, this.bytes, this.sha256);

  /// Relative to the archive root, e.g. `files/originals/x/y.jpg`.
  final String path;
  final int bytes;
  final String sha256;

  Map<String, Object?> toJson() => {
    'path': path,
    'bytes': bytes,
    'sha256': sha256,
  };
}

/// What a backup says about itself (`manifest.json`, the archive's last
/// entry): format and versions, when and what it holds, and every file
/// with its checksum, so a restore can prove nothing is missing or
/// changed before it touches the booth.
@immutable
final class BackupManifest {
  const BackupManifest({
    required this.formatVersion,
    required this.createdAtUtc,
    required this.appVersion,
    required this.schemaVersion,
    required this.contents,
    required this.boothName,
    required this.counts,
    required this.files,
  });

  static const format = 'porcelain-booth-backup';
  static const currentFormatVersion = 1;
  static const root = 'porcelain-backup';
  static const manifestPath = 'manifest.json';
  static const databasePath = 'database.sqlite';
  static const readmePath = 'README.txt';

  final int formatVersion;
  final DateTime createdAtUtc;
  final String appVersion;
  final int schemaVersion;
  final BackupContents contents;
  final String boothName;

  /// Events, sessions, photos (originals), finished photos, templates and
  /// assets, as counted when the backup was made.
  final Map<String, int> counts;

  /// Every file, the database included.
  final List<BackupFile> files;

  int get totalBytes => files.map((file) => file.bytes).sum;

  String encode() => const JsonEncoder.withIndent('  ').convert({
    'format': format,
    'formatVersion': formatVersion,
    'createdAt': createdAtUtc.toUtc().toIso8601String(),
    'appVersion': appVersion,
    'schemaVersion': schemaVersion,
    'contents': contents.name,
    'boothName': boothName,
    'counts': counts,
    'files': [for (final file in files) file.toJson()],
  });

  /// Parses [text]; throws [BackupException] for anything malformed and
  /// for versions newer than [maxSchemaVersion].
  static BackupManifest decode(String text, {required int maxSchemaVersion}) {
    const invalid = BackupException(BackupProblem.invalidArchive, 'manifest');
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      throw invalid;
    }
    if (json is! Map || json['format'] != format) throw invalid;
    final formatVersion = json['formatVersion'];
    final schemaVersion = json['schemaVersion'];
    final created = DateTime.tryParse('${json['createdAt']}');
    final contentsName = json['contents'];
    final contents = BackupContents.values.firstWhereOrNull(
      (value) => value.name == contentsName,
    );
    final counts = json['counts'];
    final files = json['files'];
    if (formatVersion is! int ||
        schemaVersion is! int ||
        created == null ||
        contents == null ||
        counts is! Map ||
        files is! List ||
        json['appVersion'] is! String ||
        json['boothName'] is! String) {
      throw invalid;
    }
    if (formatVersion > currentFormatVersion ||
        schemaVersion > maxSchemaVersion) {
      throw const BackupException(BackupProblem.newerVersion);
    }
    if (formatVersion < 1 || schemaVersion < 1) throw invalid;
    final parsed = <BackupFile>[];
    final seen = <String>{};
    for (final file in files) {
      if (file is! Map) throw invalid;
      final path = file['path'];
      final bytes = file['bytes'];
      final sha256 = file['sha256'];
      if (path is! String ||
          bytes is! int ||
          bytes < 0 ||
          sha256 is! String ||
          !RegExp(r'^[0-9a-f]{64}$').hasMatch(sha256) ||
          !seen.add(path)) {
        throw invalid;
      }
      parsed.add(BackupFile(path, bytes, sha256));
    }
    if (!seen.contains(databasePath)) throw invalid;
    return BackupManifest(
      formatVersion: formatVersion,
      createdAtUtc: created.toUtc(),
      appVersion: json['appVersion'] as String,
      schemaVersion: schemaVersion,
      contents: contents,
      boothName: json['boothName'] as String,
      counts: {
        for (final MapEntry(:key, :value) in counts.entries)
          if (key is String && value is int) key: value,
      },
      files: List.unmodifiable(parsed),
    );
  }
}
