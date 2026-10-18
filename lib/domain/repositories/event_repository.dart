import '../models/booth_event.dart';

/// Persisted events (A-04 EventRepository). Implementations store an event
/// and its template selection in one transaction, so a save is all or
/// nothing.
abstract interface class EventRepository {
  /// Every event, most recently updated first; emits again on any change.
  Stream<List<BoothEvent>> watchAll();

  /// The event with [id], or null if there is none; emits on change.
  Stream<BoothEvent?> watchById(String id);

  Future<BoothEvent?> findById(String id);

  /// Inserts or replaces [event] together with its template selection.
  Future<void> save(BoothEvent event);
}
