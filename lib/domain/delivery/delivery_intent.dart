import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// Where a delivery is on the booth (PD-05: the local phase, separate from
/// the service's own job states).
enum DeliveryIntentState {
  /// Consent recorded; waiting to be handed to the service (offline, or
  /// not tried yet).
  queued,

  /// Being handed over: created, images uploading or the commit sent.
  handingOver,

  /// The service has it; its reports are followed.
  handedOver,

  /// Nothing more will happen; [DeliveryIntent.phase] says how it ended.
  finished,
}

/// The service's report (`status` in the API), as received.
enum RemoteDeliveryStatus {
  queued,
  uploading,
  submitting,
  submitted,
  sent,
  delivered,
  failed,
  unknown,
  expired,
  canceled;

  static RemoteDeliveryStatus? fromName(String? name) =>
      values.firstWhereOrNull((status) => status.name == name);

  bool get isFinal => switch (this) {
    delivered || failed || expired || canceled => true,
    _ => false,
  };
}

/// What operators see for a delivery (UX-PD6). `delivered` only when the
/// provider reported delivery; nothing ever claims the guest read it.
enum DeliveryPhase {
  queuedLocally,
  uploading,
  sending,
  submitted,
  sent,
  delivered,
  failed,
  unknown,
  expired,
  canceled,
}

/// One step of a delivery's history, with its time and code.
@immutable
final class DeliveryStep {
  const DeliveryStep(this.phase, this.atUtc, [this.code]);

  final DeliveryPhase phase;
  final DateTime atUtc;
  final String? code;

  Map<String, Object?> toJson() => {
    'phase': phase.name,
    'at': atUtc.toUtc().toIso8601String(),
    if (code != null) 'code': code,
  };

  static DeliveryStep? fromJson(Object? json) {
    if (json is! Map) return null;
    final phase = DeliveryPhase.values.firstWhereOrNull(
      (phase) => phase.name == json['phase'],
    );
    final at = DateTime.tryParse('${json['at']}');
    if (phase == null || at == null) return null;
    final code = json['code'];
    return DeliveryStep(phase, at.toUtc(), code is String ? code : null);
  }

  @override
  bool operator ==(Object other) =>
      other is DeliveryStep &&
      other.phase == phase &&
      other.atUtc == atUtc &&
      other.code == code;

  @override
  int get hashCode => Object.hash(phase, atUtc, code);
}

/// A guest's consented request to text one finished photo (PD-06 local
/// `DeliveryIntent`). The number itself is never part of this record: it
/// lives in platform secure storage until the service has it, and only
/// its last four digits stay here.
@immutable
final class DeliveryIntent {
  const DeliveryIntent({
    required this.id,
    required this.sessionId,
    required this.eventId,
    required this.outputId,
    required this.phoneLast4,
    required this.phoneStored,
    required this.consentTextVersion,
    required this.consentTextDigest,
    required this.consentAcceptedAtUtc,
    required this.locale,
    required this.linkDays,
    required this.sendLimit,
    required this.queueAllowed,
    required this.idempotencyKey,
    required this.state,
    required this.expiresAtUtc,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    this.remoteJobId,
    this.remoteStatus,
    this.remoteUpdatedAtUtc,
    this.lastErrorCode,
    this.attemptCount = 0,
    this.retryAtUtc,
    this.localOutcome,
    this.history = const [],
  });

  final String id;
  final String sessionId;
  final String eventId;
  final String outputId;
  final String phoneLast4;

  /// Whether the number is still in secure storage (only until the
  /// service has it, the delivery ends or its window closes).
  final bool phoneStored;
  final String consentTextVersion;
  final String consentTextDigest;
  final DateTime consentAcceptedAtUtc;
  final String locale;
  final int linkDays;
  final int sendLimit;

  /// Whether the event allowed waiting for a connection when the guest
  /// asked. Without it, a request that cannot be handed over at once is
  /// dropped (and its number erased) rather than kept.
  final bool queueAllowed;

  /// One per deliberate submission (AC-0915).
  final String idempotencyKey;
  final DeliveryIntentState state;

  /// 24 hours after consent: not handed over by then, never sent.
  final DateTime expiresAtUtc;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  final String? remoteJobId;
  final RemoteDeliveryStatus? remoteStatus;
  final DateTime? remoteUpdatedAtUtc;

  /// The last problem's code (`OFFLINE`, `RECIPIENT_OPTED_OUT`, ...).
  final String? lastErrorCode;
  final int attemptCount;
  final DateTime? retryAtUtc;

  /// How a delivery that never reached the service ended.
  final DeliveryPhase? localOutcome;
  final List<DeliveryStep> history;

  /// What operators are shown.
  DeliveryPhase get phase {
    if (localOutcome != null) return localOutcome!;
    return switch (state) {
      DeliveryIntentState.queued => DeliveryPhase.queuedLocally,
      DeliveryIntentState.handingOver => DeliveryPhase.uploading,
      DeliveryIntentState.handedOver ||
      DeliveryIntentState.finished => switch (remoteStatus) {
        null ||
        RemoteDeliveryStatus.queued ||
        RemoteDeliveryStatus.uploading => DeliveryPhase.uploading,
        RemoteDeliveryStatus.submitting => DeliveryPhase.sending,
        RemoteDeliveryStatus.submitted => DeliveryPhase.submitted,
        RemoteDeliveryStatus.sent => DeliveryPhase.sent,
        RemoteDeliveryStatus.delivered => DeliveryPhase.delivered,
        RemoteDeliveryStatus.failed => DeliveryPhase.failed,
        RemoteDeliveryStatus.unknown => DeliveryPhase.unknown,
        RemoteDeliveryStatus.expired => DeliveryPhase.expired,
        RemoteDeliveryStatus.canceled => DeliveryPhase.canceled,
      },
    };
  }

  bool get finished => state == DeliveryIntentState.finished;

  /// The code recorded when the service no longer holds the delivery (its
  /// retention ended): the last report is all that will ever be known.
  static const goneCode = 'NO_LONGER_AT_SERVICE';

  /// The service no longer holds this delivery; nothing can be done to it.
  bool get gone => lastErrorCode == goneCode;

  /// The code of the history step recorded when an operator turned the
  /// download link off (the hosted copy is deleted with it).
  static const linkRevokedCode = 'LINK_REVOKED';

  /// When an operator turned the download link off, if they did.
  DateTime? get linkRevokedAtUtc =>
      history.lastWhereOrNull((step) => step.code == linkRevokedCode)?.atUtc;

  DeliveryIntent copyWith({
    bool? phoneStored,
    DeliveryIntentState? state,
    String? remoteJobId,
    RemoteDeliveryStatus? remoteStatus,
    DateTime? remoteUpdatedAtUtc,
    String? lastErrorCode,
    bool clearError = false,
    int? attemptCount,
    DateTime? retryAtUtc,
    bool clearRetry = false,
    DeliveryPhase? localOutcome,
    List<DeliveryStep>? history,
    required DateTime updatedAtUtc,
  }) => DeliveryIntent(
    id: id,
    sessionId: sessionId,
    eventId: eventId,
    outputId: outputId,
    phoneLast4: phoneLast4,
    phoneStored: phoneStored ?? this.phoneStored,
    consentTextVersion: consentTextVersion,
    consentTextDigest: consentTextDigest,
    consentAcceptedAtUtc: consentAcceptedAtUtc,
    locale: locale,
    linkDays: linkDays,
    sendLimit: sendLimit,
    queueAllowed: queueAllowed,
    idempotencyKey: idempotencyKey,
    state: state ?? this.state,
    expiresAtUtc: expiresAtUtc,
    createdAtUtc: createdAtUtc,
    updatedAtUtc: updatedAtUtc,
    remoteJobId: remoteJobId ?? this.remoteJobId,
    remoteStatus: remoteStatus ?? this.remoteStatus,
    remoteUpdatedAtUtc: remoteUpdatedAtUtc ?? this.remoteUpdatedAtUtc,
    lastErrorCode: clearError ? null : (lastErrorCode ?? this.lastErrorCode),
    attemptCount: attemptCount ?? this.attemptCount,
    retryAtUtc: clearRetry ? null : (retryAtUtc ?? this.retryAtUtc),
    localOutcome: localOutcome ?? this.localOutcome,
    history: history ?? this.history,
  );

  /// [history] with [step] added unless it repeats the last phase.
  List<DeliveryStep> withStep(DeliveryStep step) =>
      history.isNotEmpty && history.last.phase == step.phase
      ? history
      : List.unmodifiable([...history, step]);
}

/// Counts of an event's (or every) delivery by phase, for operators.
@immutable
final class DeliveryCounts {
  const DeliveryCounts(this.byPhase);

  final Map<DeliveryPhase, int> byPhase;

  int get total => byPhase.values.sum;

  int of(DeliveryPhase phase) => byPhase[phase] ?? 0;

  /// Texts that reached the provider (what costs money).
  int get submitted =>
      of(DeliveryPhase.submitted) +
      of(DeliveryPhase.sent) +
      of(DeliveryPhase.delivered);
}
