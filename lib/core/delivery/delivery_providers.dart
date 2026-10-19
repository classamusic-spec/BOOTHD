import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/delivery/delivery_intent.dart';
import '../../domain/delivery/delivery_settings.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../di/service_providers.dart';
import 'delivery_runner.dart';
import 'delivery_service.dart';

/// Phone delivery on the booth (M09).
final deliveryServiceProvider = Provider<DeliveryService>((ref) {
  final service = DeliveryService(
    repository: ref.watch(deliveryRepositoryProvider),
    api: ref.watch(deliveryApiProvider),
    secrets: ref.watch(deliverySecretsProvider),
    previews: ref.watch(previewMakerProvider),
    sessions: ref.watch(sessionRepositoryProvider),
    finished: ref.watch(finishedPhotosProvider),
    events: ref.watch(eventRepositoryProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// The queue's driver; started once startup has finished.
final deliveryRunnerProvider = Provider<DeliveryRunner>((ref) {
  final runner = DeliveryRunner(ref.watch(deliveryServiceProvider));
  ref.onDispose(runner.stop);
  return runner;
});

/// This booth's pairing, live; null when not paired.
final deliveryPairingProvider = StreamProvider<DeliveryPairing?>(
  (ref) => ref.watch(deliveryRepositoryProvider).watchPairing(),
);

/// The connection state the booth last saw, updated as it changes.
final class DeliveryLinkNotifier extends Notifier<DeliveryLink> {
  @override
  DeliveryLink build() {
    final service = ref.watch(deliveryServiceProvider);
    void changed() => state = service.link;
    service.addListener(changed);
    ref.onDispose(() => service.removeListener(changed));
    return service.link;
  }
}

final deliveryLinkProvider =
    NotifierProvider<DeliveryLinkNotifier, DeliveryLink>(
      DeliveryLinkNotifier.new,
    );

/// Whether an event's guests are offered texting now (S30).
final deliveryOfferProvider = FutureProvider.autoDispose
    .family<DeliveryOffer, EventDeliverySettings>((ref, settings) async {
      ref
        ..watch(deliveryLinkProvider)
        ..watch(deliveryPairingProvider);
      return ref.watch(deliveryServiceProvider).offerFor(settings);
    });

/// A session's delivery requests, live (S32, S35).
final sessionDeliveriesProvider = StreamProvider.autoDispose
    .family<List<DeliveryIntent>, String>(
      (ref, sessionId) =>
          ref.watch(deliveryRepositoryProvider).watchSession(sessionId),
    );

/// The latest requests across events (S36 delivery list).
final recentDeliveriesProvider = StreamProvider.autoDispose
    .family<List<DeliveryIntent>, String?>(
      (ref, eventId) =>
          ref.watch(deliveryRepositoryProvider).watchRecent(eventId: eventId),
    );

/// Counts by phase for an event (or every event).
final deliveryCountsProvider = FutureProvider.autoDispose
    .family<DeliveryCounts, String?>((ref, eventId) async {
      ref.watch(recentDeliveriesProvider(eventId));
      return ref.watch(deliveryRepositoryProvider).counts(eventId: eventId);
    });
