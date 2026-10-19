import 'package:meta/meta.dart';

import '../models/booth_event.dart';
import '../services/export_service.dart';
import '../session/session_plan.dart';
import '../session/session_shots.dart';

/// Where a recorded session stands (A-05 CaptureSession.state, A-10).
enum SessionStatus {
  /// Photos are being taken.
  capturing,

  /// The set is complete and the guest is deciding.
  reviewing,

  /// The guest kept the photos; the finished photo is being made. Survives
  /// a restart: the photo is made again later (AC-0707).
  rendering,

  /// The finished photo is saved and recorded.
  completed,

  /// Ended without a finished photo; its photos stay in storage.
  abandoned,

  /// The finished photo could not be made after several attempts; it
  /// needs the operator (M08 gallery).
  failed,
}

/// Why a session ended without a finished photo.
enum SessionEndReason {
  /// The app stopped (crash, restart) during the session.
  interrupted,

  /// The guest walked away (a guest-safe timeout).
  timedOut,

  /// The operator left the guest screens.
  operatorExit,

  /// The camera or storage stopped the session.
  problem,

  /// Rendering kept failing.
  renderFailed,
}

/// How a finished photo came to be.
enum SessionOutputOrigin {
  /// The session's own finished photo: made while the guest waited, or
  /// later by the booth or the gallery finishing the session.
  session,

  /// Made again from the session's originals and template revision in the
  /// gallery (AC-0804). Earlier finished photos are kept.
  rerender,
}

/// A finished photo recorded against its session (A-05 RenderedOutput).
@immutable
final class SessionOutput {
  const SessionOutput({
    required this.id,
    required this.sessionId,
    required this.relativePath,
    required this.sha256,
    required this.byteLength,
    required this.widthPx,
    required this.heightPx,
    required this.format,
    required this.renderVersion,
    required this.createdAtUtc,
    this.origin = SessionOutputOrigin.session,
  });

  final String id;
  final String sessionId;

  /// Relative to managed storage, e.g. `outputs/<id>.jpg`.
  final String relativePath;
  final String sha256;
  final int byteLength;
  final int widthPx;
  final int heightPx;
  final OutputFormat format;
  final int renderVersion;
  final DateTime createdAtUtc;
  final SessionOutputOrigin origin;
}

/// A recorded guest session (A-05 CaptureSession) with its photos.
@immutable
final class SessionRecord {
  const SessionRecord({
    required this.id,
    required this.number,
    required this.plan,
    required this.status,
    required this.photos,
    required this.startedAtUtc,
    required this.updatedAtUtc,
    this.endedAtUtc,
    this.endReason,
    this.outputId,
    this.renderAttempts = 0,
  });

  final String id;

  /// The session's number within its event, from 1 (schema version 6).
  final int number;
  final SessionPlan plan;
  final SessionStatus status;

  /// Every photo taken, retakes included.
  final List<ShotPhoto> photos;
  final DateTime startedAtUtc;
  final DateTime updatedAtUtc;
  final DateTime? endedAtUtc;
  final SessionEndReason? endReason;

  /// The finished photo shown to the guest, once completed.
  final String? outputId;

  /// Times rendering was started; recovery stops retrying at a limit.
  final int renderAttempts;

  SessionShots get shots => SessionShots.restore(plan, photos);
}

/// A session operation broke the record's rules (unknown session, a
/// status that does not allow it).
final class SessionStoreException implements Exception {
  const SessionStoreException(this.code);

  /// A `SESSION_*` code.
  final String code;

  @override
  String toString() => 'SessionStoreException($code)';
}

/// Guest sessions, their photos and finished photos (A-04
/// SessionRepository): checkpoints that survive restarts (A-10, A-11).
abstract interface class SessionRepository {
  /// Records a new session [id] frozen to [plan], capturing, numbered after
  /// the event's latest session.
  Future<void> create({
    required String id,
    required SessionPlan plan,
    required DateTime startedAtUtc,
  });

  /// Records [photo] for session [sessionId]. Photos are never changed.
  Future<void> addPhoto(String sessionId, ShotPhoto photo);

  /// The guest is reviewing a complete set.
  Future<void> markReviewing(String sessionId);

  /// Starts (or restarts) rendering; returns the attempt number.
  Future<int> beginRender(String sessionId);

  /// Records [output] and completes the session, in one transaction.
  Future<SessionOutput> complete(String sessionId, ExportedFile output);

  /// Ends an unfinished session without a finished photo.
  Future<void> end(
    String sessionId, {
    required SessionStatus status,
    required SessionEndReason reason,
  });

  Future<SessionRecord?> find(String sessionId);

  /// Sessions not completed, abandoned or failed, oldest first.
  Future<List<SessionRecord>> unfinished();

  Future<SessionOutput?> output(String outputId);

  /// Every finished photo of [sessionId], oldest first.
  Future<List<SessionOutput>> outputs(String sessionId);

  /// Records [output], made again from a finished session's originals and
  /// template revision (AC-0804). The session and its earlier finished
  /// photos do not change. Refused for a session that is not finished or
  /// whose set of photos is incomplete.
  Future<SessionOutput> addRerender(String sessionId, ExportedFile output);
}
