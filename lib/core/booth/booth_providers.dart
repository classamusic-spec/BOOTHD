import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/booth_event.dart';
import '../../domain/models/booth_profile.dart';
import '../../domain/models/template_revision_summary.dart';
import '../../domain/value_objects/appearance.dart';
import '../di/service_providers.dart';
import 'session_recovery.dart';

/// Startup (UX-04): prepares managed storage, opens and migrates the
/// database, reads the booth, finishes or undoes photo saves the app never
/// finished (A-11) and ends or queues guest sessions it never finished
/// (A-10), before anything can take a photo. Errors (storage
/// unavailable, data from a newer app version) surface here, before any
/// screen depends on them.
final startupProvider = FutureProvider<BoothState>((ref) async {
  await ref.watch(managedStorageProvider).prepare();
  final booth = await ref.watch(boothSettingsRepositoryProvider).load();
  await ref.watch(capturedStillStoreProvider).reconcile();
  await SessionRecovery(ref.watch(sessionRepositoryProvider)).reconcile();
  return booth;
});

/// The appearance stored with the booth, once startup has read it.
final storedAppearanceProvider = Provider<AppearanceSettings>(
  (ref) =>
      ref.watch(startupProvider).value?.profile.appearance ??
      const AppearanceSettings(),
);

/// The booth profile, live.
final boothProfileProvider = StreamProvider<BoothProfile>(
  (ref) => ref.watch(boothSettingsRepositoryProvider).watchProfile(),
);

/// Every event, most recently updated first, live.
final eventsProvider = StreamProvider<List<BoothEvent>>(
  (ref) => ref.watch(eventRepositoryProvider).watchAll(),
);

/// One event, live; null when it does not exist.
final eventProvider = StreamProvider.family<BoothEvent?, String>(
  (ref, id) => ref.watch(eventRepositoryProvider).watchById(id),
);

/// Templates an operator can add to an event, live.
final selectableTemplatesProvider =
    StreamProvider<List<TemplateRevisionSummary>>(
      (ref) => ref.watch(templateCatalogProvider).watchSelectable(),
    );

/// One template revision's summary (its name and page size), for guest
/// screens; null when the revision does not exist.
final templateSummaryProvider =
    FutureProvider.family<TemplateRevisionSummary?, String>(
      (ref, revisionId) async => (await ref
          .watch(templateCatalogProvider)
          .findRevisions([revisionId]))[revisionId],
    );
