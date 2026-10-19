import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../../domain/gallery/gallery_models.dart';
import '../../domain/gallery/print_file_facts.dart';
import '../../domain/models/booth_event.dart';
import '../../domain/services/finished_photos.dart';
import '../../domain/services/gallery_services.dart';
import '../../domain/services/print_service.dart';
import '../di/service_providers.dart';
import 'gallery_service.dart';

/// Gallery reads fail visibly with a Try again rather than retrying in the
/// background.
Duration? _noRetry(int count, Object error) => null;

/// Events with their session counts (S13 event selector).
final galleryEventsProvider =
    FutureProvider.autoDispose<List<GalleryEventSummary>>(
      (ref) => ref.watch(galleryRepositoryProvider).events(),
      retry: _noRetry,
    );

/// One event's sessions, newest first (S13 grid).
final gallerySessionsProvider = FutureProvider.autoDispose
    .family<List<GallerySession>, String>(
      (ref, eventId) => ref.watch(galleryRepositoryProvider).sessions(eventId),
      retry: _noRetry,
    );

/// One session in full (S14), or null if it no longer exists.
final sessionDetailProvider = FutureProvider.autoDispose
    .family<SessionDetail?, String>(
      (ref, sessionId) =>
          ref.watch(galleryRepositoryProvider).detail(sessionId),
      retry: _noRetry,
    );

/// Space photos use, for one event (its id) or all of them (null).
final storageUsageProvider = FutureProvider.autoDispose
    .family<StorageUsage, String?>(
      (ref, eventId) =>
          ref.watch(galleryRepositoryProvider).usage(eventId: eventId),
      retry: _noRetry,
    );

/// Free space on the tablet, or null when the platform cannot say.
final freeSpaceProvider = FutureProvider.autoDispose<int?>(
  (ref) => ref.watch(deviceStorageInfoProvider).freeBytes(),
  retry: _noRetry,
);

/// Bytes the stored thumbnails use.
final thumbnailCacheSizeProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(thumbnailStoreProvider).size(),
  retry: _noRetry,
);

/// A thumbnail, made on first use; dropped from memory when no tile shows
/// it.
final thumbnailProvider = FutureProvider.autoDispose
    .family<Uint8List, ThumbnailSource>(
      (ref, source) => ref.watch(thumbnailStoreProvider).thumbnail(source),
      retry: _noRetry,
    );

/// Which finished photo to check, and the page it should fill.
typedef OutputCheckKey = ({
  String relativePath,
  String sha256,
  OutputFormat format,
  int widthPx,
  int heightPx,
  int? pageWidthPx,
  int? pageHeightPx,
});

/// A finished photo read back from storage and checked (S14, AC-0807).
final class OutputCheck {
  const OutputCheck({required this.readiness, this.bytes, this.problem});

  final PrintReadiness readiness;

  /// The verified bytes, for display; null when they did not read back.
  final Uint8List? bytes;

  /// `missing` or `checksum` when the file did not read back intact.
  final String? problem;
}

/// Reads a finished photo back against its checksum and checks its
/// format, size and print resolution.
final outputCheckProvider = FutureProvider.autoDispose
    .family<OutputCheck, OutputCheckKey>((ref, key) async {
      Uint8List? bytes;
      String? problem;
      try {
        bytes = await ref
            .watch(finishedPhotosProvider)
            .read(relativePath: key.relativePath, sha256: key.sha256);
      } on FinishedPhotoUnreadable catch (error) {
        problem = error.reason;
      }
      return OutputCheck(
        bytes: bytes,
        problem: problem,
        readiness: PrintReadiness.check(
          bytes: bytes,
          intact: bytes != null,
          format: key.format,
          widthPx: key.widthPx,
          heightPx: key.heightPx,
          pageWidthPx: key.pageWidthPx,
          pageHeightPx: key.pageHeightPx,
        ),
      );
    }, retry: _noRetry);

/// Ids of an event's sessions past its retention now, oldest first (S13
/// retention review); empty when the event keeps photos until deleted.
final pastRetentionProvider = FutureProvider.autoDispose
    .family<List<String>, ({String eventId, RetentionPolicy retention})>((
      ref,
      key,
    ) {
      final summary = GalleryEventSummary(
        eventId: key.eventId,
        title: '',
        status: EventStatus.active,
        retention: key.retention,
        sessionCount: 0,
        finishedCount: 0,
      );
      return ref
          .watch(galleryServiceProvider)
          .pastRetention(summary, ref.watch(clockProvider).now());
    }, retry: _noRetry);

/// What the configured printer can do; never configured in release 1.
final printCapabilitiesProvider = FutureProvider<PrintCapabilities>(
  (ref) => ref.watch(printServiceProvider).capabilities(),
  retry: _noRetry,
);

final galleryServiceProvider = Provider<GalleryService>(
  (ref) => GalleryService(
    gallery: ref.watch(galleryRepositoryProvider),
    sessions: ref.watch(sessionRepositoryProvider),
    renderer: ref.watch(sessionRendererProvider),
    cleanup: ref.watch(storageCleanupProvider),
  ),
);

/// Forgets every gallery read, after anything changed the records. Pass
/// `ref.invalidate`.
void invalidateGallery(
  void Function(ProviderOrFamily provider, {bool asReload}) invalidate,
) {
  invalidate(galleryEventsProvider);
  invalidate(gallerySessionsProvider);
  invalidate(sessionDetailProvider);
  invalidate(storageUsageProvider);
  invalidate(pastRetentionProvider);
  invalidate(freeSpaceProvider);
  invalidate(thumbnailCacheSizeProvider);
}
