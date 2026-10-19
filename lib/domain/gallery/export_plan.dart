/// Exporting gallery files (P-12, AC-0803): what goes out, under which
/// names, in which parts, and what happened to each file.
library;

import 'package:meta/meta.dart';

import '../models/booth_event.dart';
import '../services/operator_files.dart';

/// What a batch export includes.
enum ExportContent {
  /// Each session's newest finished photo.
  finishedPhotos,

  /// The finished photo and every camera photo, retakes included.
  finishedAndOriginals,
}

enum ExportFileKind { finished, original }

/// Why one file did not go out; each maps to an `EXPORT_*` code (A-14).
enum ExportProblem {
  /// The session has no finished photo yet.
  noFinishedPhoto('EXPORT_NO_FINISHED_PHOTO'),

  /// The file is not in storage, or its record is gone.
  missing('EXPORT_FILE_MISSING'),

  /// The file no longer matches its recorded checksum.
  damaged('EXPORT_FILE_DAMAGED'),

  /// There was no room to prepare the copy.
  noSpace('EXPORT_NO_SPACE'),

  /// The copy could not be written or read back.
  copyFailed('EXPORT_COPY_FAILED');

  const ExportProblem(this.diagnostic);

  final String diagnostic;
}

/// One file to hand over.
@immutable
final class ExportItem {
  const ExportItem({
    required this.sessionId,
    required this.sessionNumber,
    required this.kind,
    required this.sourceId,
    required this.relativePath,
    required this.sha256,
    required this.byteLength,
    required this.fileName,
  });

  final String sessionId;
  final int sessionNumber;
  final ExportFileKind kind;

  /// The output id or original id.
  final String sourceId;

  /// Relative to managed storage.
  final String relativePath;
  final String sha256;
  final int byteLength;

  /// The name the destination sees.
  final String fileName;

  String get mimeType => fileName.endsWith('.png') ? 'image/png' : 'image/jpeg';
}

/// A file (or a session's missing file) that did not go out, and why.
@immutable
final class ExportFailureItem {
  const ExportFailureItem({
    required this.sessionNumber,
    required this.problem,
    this.kind,
    this.fileName,
  });

  final int sessionNumber;
  final ExportProblem problem;
  final ExportFileKind? kind;
  final String? fileName;
}

/// A finished photo of a session, as export needs it.
@immutable
final class ExportableOutput {
  const ExportableOutput({
    required this.id,
    required this.relativePath,
    required this.sha256,
    required this.byteLength,
    required this.format,
  });

  final String id;
  final String relativePath;
  final String sha256;
  final int byteLength;
  final OutputFormat format;
}

/// A camera photo of a session. [relativePath] is null when the
/// original's record is gone.
@immutable
final class ExportablePhoto {
  const ExportablePhoto({
    required this.shot,
    required this.attempt,
    required this.originalId,
    this.relativePath,
    this.sha256,
    this.byteLength,
  });

  final int shot;
  final int attempt;
  final String originalId;
  final String? relativePath;
  final String? sha256;
  final int? byteLength;
}

/// One session's files, as export needs them.
@immutable
final class SessionFiles {
  const SessionFiles({
    required this.sessionId,
    required this.number,
    required this.eventTitle,
    required this.startedAtUtc,
    required this.outputs,
    required this.photos,
  });

  final String sessionId;
  final int number;
  final String eventTitle;
  final DateTime startedAtUtc;

  /// Finished photos, oldest first.
  final List<ExportableOutput> outputs;

  /// Camera photos in taking order.
  final List<ExportablePhoto> photos;
}

/// File names for exported files: the event, the session number, then
/// when or which photo, so a folder of exports sorts by session.
abstract final class ExportNames {
  static const maxSlugLength = 32;

  /// [title] reduced to lowercase ASCII letters, digits and single hyphens.
  static String slug(String title) {
    final buffer = StringBuffer();
    var hyphen = false;
    for (final unit in title.toLowerCase().codeUnits) {
      final letter = unit >= 0x61 && unit <= 0x7A;
      final digit = unit >= 0x30 && unit <= 0x39;
      if (letter || digit) {
        buffer.writeCharCode(unit);
        hyphen = false;
      } else if (!hyphen && buffer.isNotEmpty) {
        buffer.write('-');
        hyphen = true;
      }
    }
    var slug = buffer.toString();
    if (slug.length > maxSlugLength) slug = slug.substring(0, maxSlugLength);
    while (slug.endsWith('-')) {
      slug = slug.substring(0, slug.length - 1);
    }
    return slug.isEmpty ? 'event' : slug;
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  static String _session(String eventTitle, int number) =>
      '${slug(eventTitle)}-${number.toString().padLeft(4, '0')}';

  /// A finished photo; [version] (from 2) marks a later render of the same
  /// session when it is exported on its own.
  static String finished({
    required String eventTitle,
    required int number,
    required DateTime localStart,
    required OutputFormat format,
    int version = 1,
  }) {
    final date =
        '${localStart.year}${_two(localStart.month)}${_two(localStart.day)}';
    final time = '${_two(localStart.hour)}${_two(localStart.minute)}';
    final suffix = version > 1 ? '-v$version' : '';
    final extension = format == OutputFormat.png ? 'png' : 'jpg';
    return '${_session(eventTitle, number)}-$date-$time$suffix.$extension';
  }

  /// A camera photo: its photo number and, for a retake, which one.
  static String original({
    required String eventTitle,
    required int number,
    required int shot,
    required int attempt,
  }) {
    final retake = attempt > 1 ? '-retake${attempt - 1}' : '';
    return '${_session(eventTitle, number)}-photo${shot + 1}$retake.jpg';
  }
}

/// A batch export split into share-sheet-sized parts, with the files that
/// cannot go out known before anything is copied.
@immutable
final class ExportPlan {
  const ExportPlan._(this.parts, this.failures);

  /// Files per share sheet; a larger selection goes out in parts.
  static const maxFilesPerPart = 200;

  factory ExportPlan.build(
    List<SessionFiles> sessions,
    ExportContent content, {
    DateTime Function(DateTime utc) toLocal = _toLocal,
  }) {
    final items = <ExportItem>[];
    final failures = <ExportFailureItem>[];
    for (final session in sessions) {
      final latest = session.outputs.isEmpty ? null : session.outputs.last;
      if (latest == null) {
        failures.add(
          ExportFailureItem(
            sessionNumber: session.number,
            problem: ExportProblem.noFinishedPhoto,
            kind: ExportFileKind.finished,
          ),
        );
      } else {
        items.add(
          ExportItem(
            sessionId: session.sessionId,
            sessionNumber: session.number,
            kind: ExportFileKind.finished,
            sourceId: latest.id,
            relativePath: latest.relativePath,
            sha256: latest.sha256,
            byteLength: latest.byteLength,
            fileName: ExportNames.finished(
              eventTitle: session.eventTitle,
              number: session.number,
              localStart: toLocal(session.startedAtUtc),
              format: latest.format,
            ),
          ),
        );
      }
      if (content == ExportContent.finishedAndOriginals) {
        for (final photo in session.photos) {
          final name = ExportNames.original(
            eventTitle: session.eventTitle,
            number: session.number,
            shot: photo.shot,
            attempt: photo.attempt,
          );
          final path = photo.relativePath;
          final sha256 = photo.sha256;
          final length = photo.byteLength;
          if (path == null || sha256 == null || length == null) {
            failures.add(
              ExportFailureItem(
                sessionNumber: session.number,
                problem: ExportProblem.missing,
                kind: ExportFileKind.original,
                fileName: name,
              ),
            );
            continue;
          }
          items.add(
            ExportItem(
              sessionId: session.sessionId,
              sessionNumber: session.number,
              kind: ExportFileKind.original,
              sourceId: photo.originalId,
              relativePath: path,
              sha256: sha256,
              byteLength: length,
              fileName: name,
            ),
          );
        }
      }
    }
    return ExportPlan._([
      for (var start = 0; start < items.length; start += maxFilesPerPart)
        List.unmodifiable(
          items.sublist(
            start,
            start + maxFilesPerPart < items.length
                ? start + maxFilesPerPart
                : items.length,
          ),
        ),
    ], List.unmodifiable(failures));
  }

  static DateTime _toLocal(DateTime utc) => utc.toLocal();

  /// The files to hand over, in parts of at most [maxFilesPerPart].
  final List<List<ExportItem>> parts;

  /// Sessions or photos that cannot go out, known before copying.
  final List<ExportFailureItem> failures;

  int get fileCount => parts.fold(0, (sum, part) => sum + part.length);
}

/// What happened to one part of an export (AC-0803).
@immutable
final class ExportPartReport {
  const ExportPartReport({
    required this.part,
    required this.parts,
    required this.sent,
    required this.failures,
    this.share,
    this.requiredBytes,
    this.freeBytes,
  });

  /// 1-based.
  final int part;
  final int parts;

  /// Files verified, prepared and offered to the share sheet.
  final List<ExportItem> sent;

  /// Files that were not offered, each with its reason.
  final List<ExportFailureItem> failures;

  /// What the share sheet reported; null when nothing could be offered.
  final ShareReport? share;

  /// Set when the part did not start for lack of space: the space it
  /// needed and the space that was free.
  final int? requiredBytes;
  final int? freeBytes;

  bool get blockedBySpace => requiredBytes != null;

  /// The files left the share sheet for a destination the operator chose
  /// (or the platform did not say what happened).
  bool get handedOver =>
      sent.isNotEmpty &&
      (share?.outcome == ShareOutcome.shared ||
          share?.outcome == ShareOutcome.unknown);
}

/// An export recorded in the gallery's history (P-11 export status).
@immutable
final class ExportRecord {
  const ExportRecord({
    required this.id,
    required this.createdAtUtc,
    required this.outcome,
    required this.files,
    required this.failureCount,
    this.destination,
  });

  final String id;
  final DateTime createdAtUtc;

  /// [ShareOutcome.shared] or [ShareOutcome.unknown]; a dismissed sheet
  /// sent nothing and is not recorded.
  final ShareOutcome outcome;
  final String? destination;
  final List<ExportItem> files;
  final int failureCount;
}

/// One recorded export, as a session's history shows it.
@immutable
final class ExportRecordSummary {
  const ExportRecordSummary({
    required this.id,
    required this.createdAtUtc,
    required this.outcome,
    required this.fileNames,
    this.destination,
  });

  final String id;
  final DateTime createdAtUtc;
  final ShareOutcome outcome;
  final String? destination;

  /// The names this session's files went out under.
  final List<String> fileNames;
}
