import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/booth_event.dart';
import '../../domain/models/booth_profile.dart';
import '../../domain/models/template_revision_summary.dart';
import '../../domain/value_objects/appearance.dart';
import '../di/service_providers.dart';

/// Startup (UX-04): prepares managed storage, opens and migrates the
/// database and reads the booth. Errors (storage unavailable, data from a
/// newer app version) surface here, before any screen depends on them.
final startupProvider = FutureProvider<BoothState>((ref) async {
  await ref.watch(managedStorageProvider).prepare();
  return ref.watch(boothSettingsRepositoryProvider).load();
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
