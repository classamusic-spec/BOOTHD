import 'package:meta/meta.dart';

import '../../domain/repositories/session_repository.dart';

/// What startup did with sessions the app never finished.
@immutable
final class SessionsRecovery {
  const SessionsRecovery({
    this.abandoned = 0,
    this.pendingRenders = 0,
    this.failed = 0,
  });

  /// Sessions cut off while photos were taken or reviewed.
  final int abandoned;

  /// Sessions whose finished photo will be made again.
  final int pendingRenders;

  /// Sessions whose finished photo kept failing.
  final int failed;
}

/// Startup reconciliation of guest sessions (A-10, AC-0707).
///
/// A session cut off while its photos were being taken or reviewed cannot
/// continue: its guest is gone. It ends as abandoned and its photos stay.
/// A session cut off while its finished photo was being made keeps its
/// checkpoint and is rendered again when the booth is idle, unless it has
/// been tried [maxRenderAttempts] times, when it is marked failed for the
/// operator. Nothing is deleted.
final class SessionRecovery {
  SessionRecovery(this._sessions);

  final SessionRepository _sessions;

  static const maxRenderAttempts = 3;

  Future<SessionsRecovery> reconcile() async {
    var abandoned = 0;
    var pending = 0;
    var failed = 0;
    for (final session in await _sessions.unfinished()) {
      switch (session.status) {
        case SessionStatus.capturing || SessionStatus.reviewing:
          await _sessions.end(
            session.id,
            status: SessionStatus.abandoned,
            reason: SessionEndReason.interrupted,
          );
          abandoned++;
        case SessionStatus.rendering
            when session.renderAttempts >= maxRenderAttempts:
          await _sessions.end(
            session.id,
            status: SessionStatus.failed,
            reason: SessionEndReason.renderFailed,
          );
          failed++;
        case SessionStatus.rendering:
          pending++;
        case SessionStatus.completed ||
            SessionStatus.abandoned ||
            SessionStatus.failed:
          break;
      }
    }
    return SessionsRecovery(
      abandoned: abandoned,
      pendingRenders: pending,
      failed: failed,
    );
  }
}
