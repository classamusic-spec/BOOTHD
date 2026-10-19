import 'package:meta/meta.dart';

import '../delivery/delivery_intent.dart';
import '../services/delivery_api.dart';

/// This booth's pairing with the delivery service (the credential itself
/// is in secure storage).
@immutable
final class DeliveryPairing {
  const DeliveryPairing({
    required this.baseUrl,
    required this.boothId,
    required this.boothName,
    required this.brandName,
    required this.pairedAtUtc,
    this.paused = false,
    this.capabilities,
    this.checkedAtUtc,
  });

  final Uri baseUrl;
  final String boothId;
  final String boothName;
  final String brandName;
  final DateTime pairedAtUtc;

  /// The booth's own emergency switch: no new requests, nothing handed
  /// over, until resumed.
  final bool paused;

  /// The service's last answer about this booth, kept so the consent
  /// screen works offline.
  final DeliveryCapabilities? capabilities;

  /// When [capabilities] was received.
  final DateTime? checkedAtUtc;

  DeliveryPairing copyWith({
    bool? paused,
    DeliveryCapabilities? capabilities,
    DateTime? checkedAtUtc,
  }) => DeliveryPairing(
    baseUrl: baseUrl,
    boothId: boothId,
    boothName: boothName,
    brandName: brandName,
    pairedAtUtc: pairedAtUtc,
    paused: paused ?? this.paused,
    capabilities: capabilities ?? this.capabilities,
    checkedAtUtc: checkedAtUtc ?? this.checkedAtUtc,
  );
}

/// A delivery store failure (a code, never data).
final class DeliveryStoreException implements Exception {
  const DeliveryStoreException(this.code);

  final String code;

  @override
  String toString() => 'DeliveryStoreException($code)';
}

/// The booth's durable delivery queue (PD-05, AC-0906): intents survive
/// restarts and go offline with the booth; the service's jobs are mirrored
/// by status only.
abstract interface class DeliveryRepository {
  Future<void> add(DeliveryIntent intent);

  Future<DeliveryIntent?> find(String id);

  /// Replaces the intent's changeable fields.
  Future<void> update(DeliveryIntent intent);

  /// Intents not finished, oldest first.
  Future<List<DeliveryIntent>> open();

  Future<List<DeliveryIntent>> forSession(String sessionId);

  Stream<List<DeliveryIntent>> watchSession(String sessionId);

  /// The most recent intents (every event, or [eventId]'s).
  Stream<List<DeliveryIntent>> watchRecent({String? eventId, int limit = 50});

  Future<DeliveryCounts> counts({String? eventId});

  /// Deliveries this event requested that may still send or did send
  /// (for its send limit).
  Future<int> requestedForEvent(String eventId);

  Future<DeliveryPairing?> pairing();

  Stream<DeliveryPairing?> watchPairing();

  /// Saves (or with null, forgets) the pairing.
  Future<void> savePairing(DeliveryPairing? pairing);

  /// Hosted copies to revoke at the service (sessions deleted on the
  /// booth while offline).
  Future<List<String>> pendingRevocations();

  Future<void> revocationDone(String remoteJobId);
}
