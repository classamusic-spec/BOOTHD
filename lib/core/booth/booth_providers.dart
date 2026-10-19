import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import '../../domain/models/booth_event.dart';
import '../../domain/models/booth_profile.dart';
import '../../domain/models/template_revision_summary.dart';
import '../../domain/services/backup_service.dart';
import '../../domain/session/guest_flow.dart';
import '../../domain/value_objects/appearance.dart';
import '../delivery/delivery_providers.dart';
import '../di/service_providers.dart';
import '../diagnostics/safe_log.dart';
import 'session_recovery.dart';

/// Startup (UX-04): prepares managed storage, opens and migrates the
/// database, reads the booth, finishes or undoes photo saves the app never
/// finished (A-11), ends or queues guest sessions it never finished
/// (A-10), removes files whose records an interrupted deletion already
/// removed (M08) and files a crash left without a record (M10), before
/// anything can take a photo; then starts the phone
/// delivery queue (M09), which never holds startup up. Errors (storage
/// unavailable, data from a newer app version) surface here, before any
/// screen depends on them.
/// Managed storage made ready, once per start: areas created, a staged
/// restore swapped in, unfinished writes discarded (A-11, M10).
final storageReadyProvider = FutureProvider<void>(
  (ref) => ref.watch(managedStorageProvider).prepare(),
);

/// What a restore swapped in at this start brought back, after its
/// clean-up (operator PIN state, texting pairing and waiting texts reset);
/// null when no restore was applied (M10, AC-1006).
final restoreReportProvider = FutureProvider<RestoreReport?>((ref) async {
  await ref.watch(storageReadyProvider.future);
  return ref.watch(backupServiceProvider).finishRestore();
});

final startupProvider = FutureProvider<BoothState>((ref) async {
  await ref.watch(storageReadyProvider.future);
  await ref.watch(restoreReportProvider.future);
  final booth = await ref.watch(boothSettingsRepositoryProvider).load();
  await ref.watch(capturedStillStoreProvider).reconcile();
  await SessionRecovery(ref.watch(sessionRepositoryProvider)).reconcile();
  final cleanup = ref.watch(storageCleanupProvider);
  try {
    await cleanup.run();
  } on Object {
    // Left in the journal; the gallery shows it and tries again.
  }
  try {
    // Files a crash left between their rename and their record (M10,
    // AC-1004); only here, before anything writes.
    final swept = await cleanup.sweepOrphans();
    if (swept.removed + swept.quarantined > 0) {
      SafeLog.event(
        'startup sweep',
        'removed ${swept.removed}, moved aside ${swept.quarantined}',
      );
    }
  } on Object catch (error, stack) {
    SafeLog.error(error, stack, context: 'startup sweep');
  }
  try {
    ref.read(deliveryRunnerProvider).start();
  } on Object {
    // Texting is optional: the booth works without it.
  }
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

/// The last problem a guest met in Booth Mode, and when.
@immutable
final class GuestProblemReport {
  const GuestProblemReport(this.problem, this.atUtc);

  final GuestProblem problem;
  final DateTime atUtc;
}

/// Kept for the operator's screen in Booth Mode (S28, S29 operator
/// recovery): the guest screens never show a code, so this is where the
/// operator learns what went wrong. Cleared when Booth Mode ends.
final class LastGuestProblem extends Notifier<GuestProblemReport?> {
  @override
  GuestProblemReport? build() => null;

  void report(GuestProblem problem, DateTime atUtc) =>
      state = GuestProblemReport(problem, atUtc);

  void clear() => state = null;
}

final lastGuestProblemProvider =
    NotifierProvider<LastGuestProblem, GuestProblemReport?>(
      LastGuestProblem.new,
    );
