import 'dart:math' as math;

import '../services/delivery_api.dart';
import 'delivery_intent.dart';

/// The booth's delivery rules (PD-01, PD-05), as pure functions.
abstract final class DeliveryPolicy {
  /// A request not handed over within this window after consent is never
  /// sent, and its number is erased.
  static const queueWindow = Duration(hours: 24);

  /// The service's preview limit stays below the provider's 5 MB ceiling;
  /// the booth aims well under it.
  static const previewTargetBytes = 400 * 1024;

  /// Waits before handing over again after a failure that decided
  /// nothing: 30 s doubling to 15 min, with jitter ([random] in [0, 1)).
  static Duration retryDelay(int attempts, double random) {
    final base = math.min(900, 30 * math.pow(2, math.max(0, attempts - 1)));
    return Duration(seconds: (base * (0.5 + random / 2)).round());
  }

  /// How often a handed-over delivery's status is asked for: quickly
  /// while the guest may be watching, then rarely, and not at all once
  /// final.
  static Duration? pollInterval(DeliveryIntent intent, DateTime nowUtc) {
    if (intent.finished || intent.remoteStatus?.isFinal == true) return null;
    final age = nowUtc.difference(intent.createdAtUtc);
    if (age < const Duration(minutes: 3)) return const Duration(seconds: 4);
    if (age < const Duration(hours: 1)) return const Duration(minutes: 1);
    if (age < const Duration(days: 2)) return const Duration(minutes: 15);
    return null;
  }

  /// What a failed hand-over means for the intent.
  static FailureDecision decide(DeliveryApiException error) =>
      switch (error.kind) {
        DeliveryFailureKind.transient => FailureDecision.retryLater,
        DeliveryFailureKind.unauthorized => FailureDecision.retryLater,
        DeliveryFailureKind.refused => switch (error.code) {
          'CONSENT_EXPIRED' => FailureDecision.expire,
          'UPLOAD_GRANT_EXPIRED' ||
          'UPLOAD_SUPERSEDED' => FailureDecision.retryLater,
          _ => FailureDecision.fail,
        },
      };
}

enum FailureDecision { retryLater, fail, expire }
