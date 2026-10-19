import 'dart:typed_data';

/// A finished photo could not be read back as saved.
final class FinishedPhotoUnreadable implements Exception {
  const FinishedPhotoUnreadable(this.reason);

  /// `missing` or `checksum`; never a path.
  final String reason;

  @override
  String toString() => 'FinishedPhotoUnreadable($reason)';
}

/// Finished photos read back for display (S27) and, later, the gallery
/// (M08).
abstract interface class FinishedPhotos {
  /// The bytes of the finished photo stored at [relativePath] (under
  /// managed storage), checked against [sha256]. Throws
  /// [FinishedPhotoUnreadable].
  Future<Uint8List> read({
    required String relativePath,
    required String sha256,
  });
}
