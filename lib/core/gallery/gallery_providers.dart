import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../../domain/gallery/gallery_models.dart';
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
  invalidate(freeSpaceProvider);
  invalidate(thumbnailCacheSizeProvider);
}
