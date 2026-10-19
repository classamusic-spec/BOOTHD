import 'package:meta/meta.dart';

import '../../domain/gallery/gallery_models.dart';
import '../../domain/gallery/retention.dart';
import '../../domain/repositories/gallery_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/services/composition_renderer.dart';
import '../../domain/services/export_service.dart';
import '../../domain/services/gallery_services.dart';
import '../booth/session_renderer.dart';

/// A gallery action did not happen; [code] is a diagnostic (A-14) for the
/// operator's details, never shown on its own.
final class GalleryActionFailure implements Exception {
  const GalleryActionFailure(this.code);

  final String code;

  @override
  String toString() => 'GalleryActionFailure($code)';
}

/// What a deletion did: the records it removed, and whether their files
/// are gone yet (they are removed again at the next start if not).
@immutable
final class DeletionOutcome {
  const DeletionOutcome(this.receipt, this.cleanup);

  final DeletionReceipt receipt;

  /// Null when the cleanup pass could not run at all.
  final CleanupResult? cleanup;

  bool get filesPending => cleanup == null || cleanup!.remaining > 0;
}

/// The operator's actions on gallery sessions (P-11): making a finished
/// photo from a session's records (AC-0804) and deleting sessions, events
/// or unassigned camera photos (AC-0805).
final class GalleryService {
  GalleryService({
    required this._gallery,
    required this._sessions,
    required this._renderer,
    required this._cleanup,
  });

  final GalleryRepository _gallery;
  final SessionRepository _sessions;
  final SessionRenderer _renderer;
  final StorageCleanup _cleanup;

  /// Makes a finished photo for [sessionId] from its unmodified originals
  /// and frozen template revision. A session still waiting for its
  /// finished photo is finished (as the booth would while idle); a
  /// completed, ended or failed session with a full set gets a re-render.
  /// Earlier finished photos and the session's record never change.
  /// Throws [GalleryActionFailure].
  Future<SessionOutput> render(String sessionId) async {
    try {
      final session = await _sessions.find(sessionId);
      if (session == null) {
        throw const GalleryActionFailure('SESSION_UNKNOWN');
      }
      if (session.status == SessionStatus.capturing ||
          session.status == SessionStatus.reviewing) {
        throw const GalleryActionFailure('GALLERY_SESSION_IN_PROGRESS');
      }
      if (!session.shots.isComplete) {
        throw const GalleryActionFailure('SESSION_SET_INCOMPLETE');
      }
      final finishing = session.status == SessionStatus.rendering;
      if (finishing) await _sessions.beginRender(sessionId);
      final (exported, _) = await _renderer.render(session.shots);
      try {
        return finishing
            ? await _sessions.complete(sessionId, exported)
            : await _sessions.addRerender(sessionId, exported);
      } on SessionStoreException {
        // The file is saved but unrecorded: nothing refers to it.
        await _gallery.discardFiles([exported.relativePath]);
        await _runCleanup();
        rethrow;
      }
    } on GalleryActionFailure {
      rethrow;
    } on RenderFailure catch (failure) {
      throw GalleryActionFailure(failure.code.diagnostic);
    } on ExportFailure catch (failure) {
      throw GalleryActionFailure(failure.code.diagnostic);
    } on SessionStoreException catch (error) {
      throw GalleryActionFailure(error.code);
    } on GalleryException catch (error) {
      throw GalleryActionFailure(error.code);
    }
  }

  /// Ids of [event]'s sessions past its retention at [nowUtc], oldest
  /// first; empty when the event keeps photos until they are deleted.
  Future<List<String>> pastRetention(
    GalleryEventSummary event,
    DateTime nowUtc,
  ) async {
    final cutoff = RetentionRules.cutoff(event.retention, nowUtc);
    if (cutoff == null) return const [];
    return _gallery.sessionsStartedBefore(event.eventId, cutoff);
  }

  /// Deletes [sessionIds] with every photo and file of them.
  Future<DeletionOutcome> deleteSessions(List<String> sessionIds) =>
      _delete(() => _gallery.deleteSessions(sessionIds));

  /// Deletes an archived event and all of its sessions.
  Future<DeletionOutcome> deleteEvent(String eventId) =>
      _delete(() => _gallery.deleteEvent(eventId));

  /// Deletes camera photos that belong to no session.
  Future<DeletionOutcome> deleteUnassignedOriginals() =>
      _delete(_gallery.deleteUnassignedOriginals);

  /// Tries again to remove files left by earlier deletions.
  Future<CleanupResult?> cleanUp() => _runCleanup();

  Future<DeletionOutcome> _delete(
    Future<DeletionReceipt> Function() records,
  ) async {
    final DeletionReceipt receipt;
    try {
      receipt = await records();
    } on GalleryException catch (error) {
      throw GalleryActionFailure(error.code);
    }
    return DeletionOutcome(receipt, await _runCleanup());
  }

  Future<CleanupResult?> _runCleanup() async {
    try {
      return await _cleanup.run();
    } on Object {
      return null;
    }
  }
}
