import '../gallery/export_plan.dart';
import '../gallery/gallery_models.dart';

/// A gallery operation was refused (an event that is not archived, a
/// session a guest is still in).
final class GalleryException implements Exception {
  const GalleryException(this.code);

  /// A `GALLERY_*` code.
  final String code;

  @override
  String toString() => 'GalleryException($code)';
}

/// The operator gallery's view of sessions and storage (A-04
/// GalleryRepository, P-11, S13, S14).
///
/// Deletions remove records in one transaction and queue the files they
/// owned in a journal; [StorageCleanup] removes the files afterwards and
/// again at startup, so an interrupted deletion always finishes (AC-0805).
abstract interface class GalleryRepository {
  /// Every event with its session counts, latest session first; events
  /// without sessions follow, newest first.
  Future<List<GalleryEventSummary>> events();

  /// The sessions of [eventId], newest first: the gallery's index. Light
  /// rows only; images load as tiles scroll into view.
  Future<List<GallerySession>> sessions(String eventId);

  /// Everything about one session (S14), or null if it does not exist.
  Future<SessionDetail?> detail(String sessionId);

  /// The files of [sessionIds] in that order, for export. Unknown ids are
  /// left out.
  Future<List<SessionFiles>> files(List<String> sessionIds);

  /// Space used by photos, for one event or all of them.
  Future<StorageUsage> usage({String? eventId});

  /// Ids of [eventId]'s sessions that started before [beforeUtc] (its
  /// retention cutoff), oldest first. Sessions a guest is in are left out.
  Future<List<String>> sessionsStartedBefore(
    String eventId,
    DateTime beforeUtc,
  );

  /// Records an export whose files left for a destination.
  Future<void> recordExport(ExportRecord record);

  /// Deletes [sessionIds] with their photos, finished photos and export
  /// history. Refuses ([GalleryException]) if a guest is in one of them.
  Future<DeletionReceipt> deleteSessions(List<String> sessionIds);

  /// Deletes an archived event, every session of it and their files.
  Future<DeletionReceipt> deleteEvent(String eventId);

  /// Deletes camera photos that belong to no session.
  Future<DeletionReceipt> deleteUnassignedOriginals();

  /// Queues files that no record refers to (a finished photo saved but
  /// never recorded) for removal. Paths a record still refers to are left
  /// alone.
  Future<void> discardFiles(List<String> relativePaths);
}
