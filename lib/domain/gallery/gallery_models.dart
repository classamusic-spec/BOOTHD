/// What the operator gallery shows (S13, S14, P-11): events with their
/// sessions, each session's photos and finished photos, and what storage
/// they use. Read-only views; the records they come from never change.
library;

import 'package:meta/meta.dart';

import '../models/booth_event.dart';
import '../models/template_revision_summary.dart';
import '../repositories/session_repository.dart';
import '../services/camera_service.dart';
import 'export_plan.dart';

/// An event as the gallery's event selector lists it.
@immutable
final class GalleryEventSummary {
  const GalleryEventSummary({
    required this.eventId,
    required this.title,
    required this.status,
    required this.retention,
    required this.sessionCount,
    required this.finishedCount,
    this.firstSessionAtUtc,
    this.lastSessionAtUtc,
  });

  final String eventId;
  final String title;
  final EventStatus status;
  final RetentionPolicy retention;
  final int sessionCount;

  /// Sessions with at least one finished photo.
  final int finishedCount;
  final DateTime? firstSessionAtUtc;
  final DateTime? lastSessionAtUtc;
}

/// A finished photo as listed: enough to show, verify and export it.
@immutable
final class GalleryOutput {
  const GalleryOutput({
    required this.id,
    required this.relativePath,
    required this.sha256,
    required this.byteLength,
    required this.widthPx,
    required this.heightPx,
    required this.format,
  });

  final String id;
  final String relativePath;
  final String sha256;
  final int byteLength;
  final int widthPx;
  final int heightPx;
  final OutputFormat format;
}

/// What a session amounts to, for its label and the filters (S13, S14).
enum GallerySessionState {
  /// It has a finished photo.
  finished,

  /// Its photos were kept and the finished photo is still to be made
  /// (the booth makes it while idle; the gallery can make it now).
  waitingToFinish,

  /// Its finished photo failed several times; the operator can try again.
  renderFailed,

  /// It ended before a finished photo was made.
  notFinished,

  /// A guest is taking or reviewing its photos.
  inProgress,
}

/// One session in the gallery grid.
@immutable
final class GallerySession {
  const GallerySession({
    required this.id,
    required this.eventId,
    required this.number,
    required this.status,
    required this.startedAtUtc,
    required this.plannedShots,
    required this.photoCount,
    required this.outputCount,
    required this.setComplete,
    this.endReason,
    this.endedAtUtc,
    this.latestOutput,
    this.coverOriginalId,
    this.lastExportedAtUtc,
  });

  final String id;
  final String eventId;

  /// The session's number within its event, from 1, never reused while
  /// the session exists.
  final int number;
  final SessionStatus status;
  final SessionEndReason? endReason;
  final DateTime startedAtUtc;
  final DateTime? endedAtUtc;
  final int plannedShots;

  /// Every photo taken, retakes included.
  final int photoCount;
  final int outputCount;

  /// Every photo space has a photo in the latest set, so a finished photo
  /// can be made.
  final bool setComplete;

  /// The newest finished photo, the one shown and exported.
  final GalleryOutput? latestOutput;

  /// The first photo used, shown when there is no finished photo.
  final String? coverOriginalId;

  /// When files of this session were last handed to a destination.
  final DateTime? lastExportedAtUtc;

  GallerySessionState get state => latestOutput != null
      ? GallerySessionState.finished
      : switch (status) {
          SessionStatus.capturing ||
          SessionStatus.reviewing => GallerySessionState.inProgress,
          SessionStatus.rendering => GallerySessionState.waitingToFinish,
          SessionStatus.failed => GallerySessionState.renderFailed,
          SessionStatus.completed ||
          SessionStatus.abandoned => GallerySessionState.notFinished,
        };

  /// A guest is still in it: the gallery leaves it alone.
  bool get inProgress =>
      status == SessionStatus.capturing || status == SessionStatus.reviewing;
}

/// The gallery's status filter (S13), with the states each one shows.
enum GalleryFilter {
  all({...GallerySessionState.values}),
  finished({GallerySessionState.finished}),
  needsAttention({
    GallerySessionState.waitingToFinish,
    GallerySessionState.renderFailed,
  }),
  notFinished({
    GallerySessionState.notFinished,
    GallerySessionState.inProgress,
  });

  const GalleryFilter(this.states);

  final Set<GallerySessionState> states;

  bool shows(GallerySession session) => states.contains(session.state);
}

/// A session with everything the operator may inspect (S14, AC-0802).
@immutable
final class SessionDetail {
  const SessionDetail({
    required this.session,
    required this.number,
    required this.eventTitle,
    required this.outputs,
    required this.originals,
    required this.exports,
    this.template,
  });

  final SessionRecord session;
  final int number;
  final String eventTitle;

  /// Every finished photo, oldest first.
  final List<SessionOutput> outputs;

  /// The committed original behind each photo, by original id. A photo
  /// whose record is missing has no entry.
  final Map<String, CapturedStill> originals;

  /// Exports that included this session, newest first.
  final List<ExportRecordSummary> exports;

  /// The session's template revision; null if its record cannot be read.
  final TemplateRevisionSummary? template;

  SessionOutput? get latestOutput => outputs.isEmpty ? null : outputs.last;
}

/// Space used by the booth's photos (S16 disk use, storage management).
@immutable
final class StorageUsage {
  const StorageUsage({
    required this.sessionCount,
    required this.finishedCount,
    required this.finishedBytes,
    required this.originalCount,
    required this.originalBytes,
    required this.unassignedCount,
    required this.unassignedBytes,
    required this.pendingCleanup,
  });

  final int sessionCount;

  /// Finished photos (all of them, re-renders included).
  final int finishedCount;
  final int finishedBytes;

  /// Camera photos that belong to sessions.
  final int originalCount;
  final int originalBytes;

  /// Camera photos in no session: camera tests and photos that arrived
  /// after a session gave up waiting for them.
  final int unassignedCount;
  final int unassignedBytes;

  /// Files of deleted records still to be removed.
  final int pendingCleanup;

  int get totalBytes => finishedBytes + originalBytes + unassignedBytes;
}

/// What a deletion removed from the records. Its files are removed
/// afterwards from a journal, so an interruption only delays them.
@immutable
final class DeletionReceipt {
  const DeletionReceipt({
    required this.sessions,
    required this.originals,
    required this.outputs,
    required this.files,
  });

  final int sessions;
  final int originals;
  final int outputs;

  /// Files queued for removal.
  final int files;
}
