/// Ports the operator gallery uses for files (P-11, P-12, A-11): export
/// through the platform share sheet, thumbnails and the removal of files
/// whose records were deleted.
library;

import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../gallery/export_plan.dart';
import 'operator_files.dart';

/// Hands verified copies of gallery files to the platform share sheet.
abstract interface class GalleryExporter {
  /// Checks free space for copies of [items], copies each one under its
  /// export name while checking it against its checksum, then offers the
  /// copies to the share sheet anchored at [anchor]. A file that is
  /// missing, damaged or cannot be copied is reported and left out; the
  /// rest still go. Nothing in managed storage changes.
  Future<ExportPartReport> export(
    List<ExportItem> items, {
    required ShareAnchor anchor,
    int part = 1,
    int parts = 1,
  });

  /// Removes copies prepared for earlier exports. Never called while a
  /// share sheet is open.
  Future<void> discardPrepared();
}

/// What a thumbnail is made from.
enum ThumbnailKind { output, original }

@immutable
final class ThumbnailSource {
  const ThumbnailSource({
    required this.kind,
    required this.id,
    required this.relativePath,
  });

  final ThumbnailKind kind;

  /// The output or original id; both are immutable, so a thumbnail never
  /// goes stale.
  final String id;
  final String relativePath;

  @override
  bool operator ==(Object other) =>
      other is ThumbnailSource && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);
}

/// The thumbnail could not be made (the source file is missing or does not
/// decode).
final class ThumbnailUnavailable implements Exception {
  const ThumbnailUnavailable(this.reason);

  final String reason;

  @override
  String toString() => 'ThumbnailUnavailable($reason)';
}

/// Small JPEG copies of finished photos and camera photos for the gallery
/// grid (S13: "efficiently thumbnailized"). Derived data: made on first
/// use, kept in managed storage, safe to clear at any time.
abstract interface class ThumbnailStore {
  /// The thumbnail of [source] (at most [ThumbnailStore.maxSide] pixels on
  /// its long side), made now if needed. Throws [ThumbnailUnavailable].
  Future<Uint8List> thumbnail(ThumbnailSource source);

  /// Removes every stored thumbnail; returns the bytes freed.
  Future<int> clear();

  /// Bytes the stored thumbnails use.
  Future<int> size();

  static const maxSide = 480;
}

/// What a cleanup pass did.
@immutable
final class CleanupResult {
  const CleanupResult({required this.removed, required this.remaining});

  /// Files removed (or already gone).
  final int removed;

  /// Files that could not be removed yet; tried again next time.
  final int remaining;
}

/// What a startup sweep did with files no record refers to (M10,
/// AC-1004).
@immutable
final class OrphanSweepResult {
  const OrphanSweepResult({required this.removed, required this.quarantined});

  /// Finished photos, template files and images removed.
  final int removed;

  /// Camera photos moved aside, never deleted.
  final int quarantined;
}

/// Removes the files of deleted records from the deletion journal (A-11).
/// Runs after every deletion and at startup.
abstract interface class StorageCleanup {
  Future<CleanupResult> run();

  /// At startup only, before anything writes: files in the managed areas
  /// that no record refers to, left by a crash between a file's rename
  /// and its record, are removed; camera photos are moved aside to
  /// `originals/.quarantine`, never deleted (M10, AC-1004).
  Future<OrphanSweepResult> sweepOrphans();
}
