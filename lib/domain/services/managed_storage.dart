import 'booth_capabilities.dart';

/// The app's private file area (A-11, P-13): the database, originals,
/// outputs, template manifests and assets, and a staging area for atomic
/// writes. Paths never leave the infrastructure layer.
abstract interface class ManagedStorage {
  /// Creates the managed directories if needed and discards files that
  /// writes interrupted by the app ending left in the staging area. Runs at
  /// startup, before anything writes. Throws `ManagedStorageException` when
  /// the area cannot be used.
  Future<void> prepare();

  /// Writes a probe file in the staging area, reads it back, compares and
  /// deletes it.
  Future<CapabilityStatus> probeWrite();
}
