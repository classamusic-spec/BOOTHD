/// The stored data was written by a newer version of the app. Nothing was
/// read or changed; the newer app version is needed (A-15).
final class StoredDataTooNewException implements Exception {
  const StoredDataTooNewException({
    required this.foundVersion,
    required this.supportedVersion,
  });

  final int foundVersion;
  final int supportedVersion;

  @override
  String toString() =>
      'StoredDataTooNewException(found $foundVersion, '
      'supported $supportedVersion)';
}

/// The stored data is at a version this app cannot migrate from.
final class StoredDataUnsupportedException implements Exception {
  const StoredDataUnsupportedException(this.foundVersion);

  final int foundVersion;

  @override
  String toString() => 'StoredDataUnsupportedException($foundVersion)';
}

/// Managed storage could not be prepared (e.g. not writable). [code] is a
/// diagnostic code (A-14); no paths or file contents are included.
final class ManagedStorageException implements Exception {
  const ManagedStorageException(this.code);

  final String code;

  @override
  String toString() => 'ManagedStorageException($code)';
}

/// A write broke a schema rule (CHECK constraint, foreign key or trigger)
/// and was rolled back; nothing was stored.
final class PersistenceRuleException implements Exception {
  const PersistenceRuleException(this.message);

  final String message;

  @override
  String toString() => 'PersistenceRuleException($message)';
}
