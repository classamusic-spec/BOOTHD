import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../../domain/delivery/consent.dart';
import '../../domain/delivery/delivery_intent.dart';
import '../../domain/delivery/delivery_policy.dart';
import '../../domain/delivery/delivery_settings.dart';
import '../../domain/delivery/phone_number.dart';
import '../../domain/models/booth_event.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/services/delivery_api.dart';
import '../../domain/services/finished_photos.dart';
import '../../domain/value_objects/clock.dart';
import '../../domain/value_objects/entity_id.dart';

/// Whether texting is offered to the guest of an event right now (S30,
/// UX-PD1).
enum DeliveryOffer {
  /// The event has delivery off.
  off,

  /// The booth is not paired, or its texting is paused.
  unavailable,

  /// The service last said sending is not ready.
  notReady,

  /// Ready and reachable: the text goes now.
  online,

  /// Ready when last checked, but the service cannot be reached now; the
  /// event allows waiting for a connection (up to 24 hours).
  queued,
}

/// The connection state the booth last saw.
@immutable
final class DeliveryLink {
  const DeliveryLink({this.checkedAtUtc, this.failingSinceUtc, this.lastCode});

  /// The last successful contact with the service.
  final DateTime? checkedAtUtc;

  /// Set while calls fail with nothing decided (offline, a portal).
  final DateTime? failingSinceUtc;
  final String? lastCode;

  bool get offline => failingSinceUtc != null;
}

/// A delivery action the operator asked for could not be done.
final class DeliveryActionFailure implements Exception {
  const DeliveryActionFailure(this.code);

  final String code;

  @override
  String toString() => 'DeliveryActionFailure($code)';
}

/// Phone delivery on the booth (M09, PD-05): pairing, the guest's
/// consented requests, the durable queue that hands them to the service,
/// and the operator's actions.
///
/// * A request is stored before anything is sent: the number in platform
///   secure storage, the rest (with the consent's version, digest and
///   time) in the database. The guest's photo is already saved; nothing
///   here can change that.
/// * The queue hands requests over while the app is in front: at once, on
///   resume, and on a timer while work is waiting. Failures that decide
///   nothing (offline, a portal, the service busy) wait and try again with
///   backoff until 24 hours after consent; refusals end the request.
///   There is no background sending when the OS suspends the app.
/// * Once the service has the request, its number is erased from the
///   booth; the service's reports are followed until final. An ambiguous
///   submission is the service's to reconcile; the booth only reports it.
final class DeliveryService extends ChangeNotifier {
  DeliveryService({
    required this._repository,
    required this._api,
    required this._secrets,
    required this._previews,
    required this._sessions,
    required this._finished,
    required this._events,
    required this._clock,
    required this._ids,
    double Function()? random,
  }) : _random = random ?? math.Random().nextDouble;

  final DeliveryRepository _repository;
  final DeliveryApi _api;
  final DeliverySecrets _secrets;
  final PreviewMaker _previews;
  final SessionRepository _sessions;
  final FinishedPhotos _finished;
  final EventRepository _events;
  final Clock _clock;
  final IdGenerator _ids;
  final double Function() _random;

  AccessToken? _token;
  var _link = const DeliveryLink();
  Future<void>? _running;
  var _again = false;
  var _disposed = false;

  DeliveryLink get link => _link;

  DateTime _now() => _clock.now().toUtc();

  // Pairing and the connection.

  /// Pairs this booth with the service at [baseUrl] using an
  /// administrator's single-use [code]; the credential goes to secure
  /// storage. Throws [DeliveryApiException].
  Future<DeliveryPairing> pair({
    required Uri baseUrl,
    required String code,
    required String boothName,
  }) async {
    if (!deliveryAddressAcceptable(baseUrl)) {
      throw const DeliveryApiException(
        DeliveryFailureKind.refused,
        'SERVICE_ADDRESS_INVALID',
      );
    }
    final result = await _api.pair(baseUrl, code: code, boothName: boothName);
    await _secrets.writeCredential(result.credential);
    _token = null;
    var pairing = DeliveryPairing(
      baseUrl: baseUrl,
      boothId: result.boothId,
      boothName: result.boothName,
      brandName: result.brandName,
      pairedAtUtc: _now(),
    );
    await _repository.savePairing(pairing);
    try {
      pairing = await check() ?? pairing;
    } on DeliveryApiException {
      // Paired; readiness is checked again later.
    }
    notifyListeners();
    return pairing;
  }

  /// Forgets the pairing and the credential. Requests still waiting cannot
  /// be handed over any more; they expire (and lose their numbers) on
  /// schedule.
  Future<void> unpair() async {
    await _secrets.deleteCredential();
    await _repository.savePairing(null);
    _token = null;
    _link = const DeliveryLink();
    notifyListeners();
  }

  /// The booth's own emergency switch (UX-PD5).
  Future<void> setPaused(bool paused) async {
    final pairing = await _repository.pairing();
    if (pairing == null) return;
    await _repository.savePairing(pairing.copyWith(paused: paused));
    notifyListeners();
    if (!paused) unawaited(processDue());
  }

  /// Replaces the booth credential (the old one works ten more minutes).
  Future<void> rotateCredential() async {
    final pairing = await _repository.pairing();
    if (pairing == null) throw const DeliveryActionFailure('NOT_PAIRED');
    final credential = await _withToken(
      pairing,
      (token) => _api.rotateCredential(pairing.baseUrl, token),
    );
    await _secrets.writeCredential(credential);
    _token = null;
  }

  Future<String> _accessToken(DeliveryPairing pairing) async {
    final token = _token;
    if (token != null &&
        token.expiresAtUtc.isAfter(_now().add(const Duration(seconds: 60)))) {
      return token.token;
    }
    final credential = await _secrets.readCredential();
    if (credential == null) {
      throw const DeliveryApiException(
        DeliveryFailureKind.unauthorized,
        'NOT_PAIRED',
      );
    }
    final fresh = await _api.accessToken(pairing.baseUrl, credential);
    _token = fresh;
    return fresh.token;
  }

  /// Runs [call] with an access token, once more with a new token if the
  /// first is refused; records whether the service could be reached.
  Future<T> _withToken<T>(
    DeliveryPairing pairing,
    Future<T> Function(String token) call,
  ) async {
    try {
      T value;
      try {
        value = await call(await _accessToken(pairing));
      } on DeliveryApiException catch (error) {
        if (error.kind != DeliveryFailureKind.unauthorized ||
            error.code == 'NOT_PAIRED' ||
            error.code == 'CREDENTIAL_INVALID') {
          rethrow;
        }
        _token = null;
        value = await call(await _accessToken(pairing));
      }
      _markReached();
      return value;
    } on DeliveryApiException catch (error) {
      if (error.kind == DeliveryFailureKind.transient) {
        _link = DeliveryLink(
          checkedAtUtc: _link.checkedAtUtc,
          failingSinceUtc: _link.failingSinceUtc ?? _now(),
          lastCode: error.code,
        );
        notifyListeners();
      } else {
        _markReached();
      }
      rethrow;
    }
  }

  /// The service answered (whatever it said).
  void _markReached() {
    final changed = _link.offline || _link.checkedAtUtc == null;
    _link = DeliveryLink(checkedAtUtc: _now());
    if (changed && !_disposed) notifyListeners();
  }

  /// Asks the service what this booth may do now and keeps the answer
  /// (for offline use). Returns the updated pairing, or null when not
  /// paired. Throws [DeliveryApiException].
  Future<DeliveryPairing?> check() async {
    final pairing = await _repository.pairing();
    if (pairing == null) return null;
    final capabilities = await _withToken(
      pairing,
      (token) => _api.capabilities(pairing.baseUrl, token),
    );
    final updated = pairing.copyWith(
      capabilities: capabilities,
      checkedAtUtc: _now(),
    );
    await _repository.savePairing(updated);
    notifyListeners();
    return updated;
  }

  /// Checks a fixture upload (diagnostics); nothing is stored or sent.
  Future<UploadTestResult> uploadTest(Uint8List jpeg) async {
    final pairing = await _repository.pairing();
    if (pairing == null) throw const DeliveryActionFailure('NOT_PAIRED');
    return _withToken(
      pairing,
      (token) => _api.uploadTest(pairing.baseUrl, token, jpeg),
    );
  }

  /// How long a stored "ready" answer is trusted for offering texting.
  static const readyTrustedFor = Duration(hours: 24);

  /// Whether an event's guests are offered texting now (S30).
  Future<DeliveryOffer> offerFor(EventDeliverySettings settings) async {
    if (!settings.enabled) return DeliveryOffer.off;
    final pairing = await _repository.pairing();
    if (pairing == null || pairing.paused) return DeliveryOffer.unavailable;
    final capabilities = pairing.capabilities;
    final checkedAt = pairing.checkedAtUtc;
    if (capabilities == null ||
        checkedAt == null ||
        _now().difference(checkedAt) > readyTrustedFor ||
        !capabilities.regions.contains('US')) {
      return DeliveryOffer.unavailable;
    }
    if (!capabilities.ready) return DeliveryOffer.notReady;
    if (_link.offline) {
      return settings.offlineQueue
          ? DeliveryOffer.queued
          : DeliveryOffer.unavailable;
    }
    return DeliveryOffer.online;
  }

  // The guest's request.

  /// Stores a consented request for [output] of [event] to [phone] and
  /// starts handing it over (S31 to S32). The number goes to secure
  /// storage first; if anything fails, nothing is kept. Throws
  /// [DeliveryActionFailure].
  Future<DeliveryIntent> submit({
    required BoothEvent event,
    required SessionOutput output,
    required PhoneNumber phone,
    required ConsentText consent,
    required DateTime acceptedAtUtc,
  }) async {
    final now = _now();
    final id = _ids.newId();
    final intent = DeliveryIntent(
      id: id,
      sessionId: output.sessionId,
      eventId: event.id,
      outputId: output.id,
      phoneLast4: phone.last4,
      phoneStored: true,
      consentTextVersion: ConsentText.version,
      consentTextDigest: consent.digest,
      consentAcceptedAtUtc: acceptedAtUtc.toUtc(),
      locale: 'en-US',
      linkDays: event.delivery.linkDays,
      sendLimit: event.delivery.sendLimit,
      queueAllowed: event.delivery.offlineQueue,
      idempotencyKey: _ids.newId(),
      state: DeliveryIntentState.queued,
      expiresAtUtc: acceptedAtUtc.toUtc().add(DeliveryPolicy.queueWindow),
      createdAtUtc: now,
      updatedAtUtc: now,
      history: [DeliveryStep(DeliveryPhase.queuedLocally, now)],
    );
    try {
      await _secrets.storePhone(id, phone.e164);
    } on Object {
      throw const DeliveryActionFailure('SECRETS_UNAVAILABLE');
    }
    try {
      await _repository.add(intent);
    } on Object {
      await _quietly(() => _secrets.erasePhone(id));
      throw const DeliveryActionFailure('QUEUE_UNAVAILABLE');
    }
    notifyListeners();
    unawaited(processDue());
    return intent;
  }

  // The queue.

  /// Hands over waiting requests, follows handed-over ones, expires old
  /// ones, revokes copies of deleted sessions and erases numbers no longer
  /// needed. One pass at a time; a call during a pass runs another after.
  Future<void> processDue() {
    if (_running != null) {
      _again = true;
      return _running!;
    }
    return _running = _loop();
  }

  /// Passes until none was asked for during the last one, so whoever
  /// waits sees the result of their own request.
  Future<void> _loop() async {
    try {
      do {
        _again = false;
        await _process();
      } while (_again && !_disposed);
    } finally {
      _running = null;
    }
  }

  /// Whether a pass would do anything now (for the timer).
  Future<Duration?> nextWork() async {
    final open = await _repository.open();
    if (open.isEmpty) {
      final revocations = await _repository.pendingRevocations();
      return revocations.isEmpty ? null : const Duration(minutes: 1);
    }
    final now = _now();
    Duration? soonest;
    for (final intent in open) {
      final Duration wait;
      if (intent.state == DeliveryIntentState.handedOver) {
        final interval = DeliveryPolicy.pollInterval(intent, now);
        if (interval == null) continue;
        final since = now.difference(
          intent.remoteUpdatedAtUtc ?? intent.updatedAtUtc,
        );
        wait = since >= interval ? Duration.zero : interval - since;
      } else {
        final retry = intent.retryAtUtc;
        wait = retry == null || !retry.isAfter(now)
            ? Duration.zero
            : retry.difference(now);
      }
      if (soonest == null || wait < soonest) soonest = wait;
    }
    return soonest;
  }

  Future<void> _process() async {
    try {
      final pairing = await _repository.pairing();
      final now = _now();
      for (final intent in await _repository.open()) {
        if (_disposed) return;
        final current = await _repository.find(intent.id);
        if (current == null || current.finished) continue;
        if (current.remoteJobId == null && !current.expiresAtUtc.isAfter(now)) {
          await _finishLocally(
            current,
            DeliveryPhase.expired,
            'QUEUE_WINDOW_ENDED',
          );
          continue;
        }
        if (pairing == null || pairing.paused) continue;
        switch (current.state) {
          case DeliveryIntentState.queued || DeliveryIntentState.handingOver:
            final retry = current.retryAtUtc;
            if (retry == null || !retry.isAfter(now)) {
              await _handOver(pairing, current);
            }
          case DeliveryIntentState.handedOver:
            final interval = DeliveryPolicy.pollInterval(current, now);
            final since = now.difference(
              current.remoteUpdatedAtUtc ?? current.updatedAtUtc,
            );
            if (interval != null && since >= interval) {
              await _refresh(pairing, current);
            }
          case DeliveryIntentState.finished:
            break;
        }
      }
      if (pairing != null) await _revokeDeleted(pairing);
      await sweepSecrets();
    } on Object {
      // A pass that fails is tried again by the next one; requests keep
      // their state. Nothing here is shown to guests.
    }
  }

  Future<void> _handOver(DeliveryPairing pairing, DeliveryIntent start) async {
    var intent = await _save(
      start.copyWith(
        state: DeliveryIntentState.handingOver,
        attemptCount: start.attemptCount + 1,
        clearRetry: true,
        updatedAtUtc: _now(),
      ),
    );
    try {
      final event = await _events.findById(intent.eventId);
      RemoteDelivery remote;
      if (intent.remoteJobId == null) {
        final phone = await _secrets.readPhone(intent.id);
        if (phone == null) {
          await _finishLocally(intent, DeliveryPhase.failed, 'PHONE_MISSING');
          return;
        }
        try {
          remote = await _withToken(
            pairing,
            (token) => _api.create(
              pairing.baseUrl,
              token,
              CreateDeliveryRequest(
                eventId: intent.eventId,
                eventName: event?.title ?? 'your event',
                sessionId: intent.sessionId,
                outputId: intent.outputId,
                phoneE164: phone,
                idempotencyKey: intent.idempotencyKey,
                linkDays: intent.linkDays,
                eventSendLimit: intent.sendLimit,
                consent: ConsentReceipt(
                  textVersion: intent.consentTextVersion,
                  textDigest: intent.consentTextDigest,
                  acceptedAtUtc: intent.consentAcceptedAtUtc,
                  locale: intent.locale,
                ),
              ),
            ),
          );
        } on DeliveryApiException catch (error) {
          // Already requested (a retry after a lost answer): follow it.
          if (error.code != 'DUPLICATE_REQUEST' || error.deliveryId == null) {
            rethrow;
          }
          remote = await _withToken(
            pairing,
            (token) => _api.status(pairing.baseUrl, token, error.deliveryId!),
          );
        }
        intent = await _save(
          intent.copyWith(remoteJobId: remote.id, updatedAtUtc: _now()),
        );
      } else {
        remote = await _withToken(
          pairing,
          (token) => _api.status(pairing.baseUrl, token, intent.remoteJobId!),
        );
      }

      if (remote.status == RemoteDeliveryStatus.queued ||
          remote.status == RemoteDeliveryStatus.uploading) {
        await _upload(pairing, intent, remote.id);
        remote = await _withToken(
          pairing,
          (token) => _api.commit(pairing.baseUrl, token, remote.id),
        );
      }
      // The service has it: the booth no longer needs the number.
      await _quietly(() => _secrets.erasePhone(intent.id));
      await _applyRemote(
        intent.copyWith(phoneStored: false, updatedAtUtc: _now()),
        remote,
      );
    } on DeliveryApiException catch (error) {
      await _failed(intent, error);
    } on DeliveryUploadProblem catch (problem) {
      await _finishLocally(intent, DeliveryPhase.failed, problem.code);
      await _cancelRemote(pairing, intent);
    } on Object {
      // Secure storage or the database: try again later within the window.
      await _save(
        intent.copyWith(
          state: DeliveryIntentState.queued,
          lastErrorCode: 'BOOTH_STORAGE',
          retryAtUtc: _now().add(
            DeliveryPolicy.retryDelay(intent.attemptCount, _random()),
          ),
          updatedAtUtc: _now(),
        ),
      );
    }
  }

  Future<void> _upload(
    DeliveryPairing pairing,
    DeliveryIntent intent,
    String deliveryId,
  ) async {
    final output = (await _sessions.outputs(intent.sessionId))
        .firstWhereOrNull((output) => output.id == intent.outputId);
    if (output == null) throw const DeliveryUploadProblem('PHOTO_MISSING');
    final Uint8List finished;
    try {
      finished = await _finished.read(
        relativePath: output.relativePath,
        sha256: output.sha256,
      );
    } on FinishedPhotoUnreadable {
      throw const DeliveryUploadProblem('PHOTO_UNREADABLE');
    }
    final limit = math.min(
      pairing.capabilities?.previewMaxBytes ??
          DeliveryPolicy.previewTargetBytes,
      DeliveryPolicy.previewTargetBytes,
    );
    final PreviewImage preview;
    try {
      preview = await _previews.make(finished, maxBytes: limit);
    } on Object {
      throw const DeliveryUploadProblem('PREVIEW_FAILED');
    }
    final grants = await _withToken(
      pairing,
      (token) => _api.uploadInit(
        pairing.baseUrl,
        token,
        deliveryId,
        finalImage: UploadDeclaration(
          format: output.format.name,
          bytes: finished.length,
          sha256: output.sha256,
          width: output.widthPx,
          height: output.heightPx,
        ),
        preview: UploadDeclaration(
          format: 'jpeg',
          bytes: preview.bytes.length,
          sha256: preview.sha256,
          width: preview.width,
          height: preview.height,
        ),
      ),
    );
    for (final grant in grants) {
      final bytes = switch (grant.kind) {
        'final' => finished,
        'preview' => preview.bytes,
        _ => throw const DeliveryUploadProblem('UPLOAD_KIND_UNKNOWN'),
      };
      try {
        await _api.upload(grant, bytes);
        _markReached();
      } on DeliveryApiException catch (error) {
        if (error.kind == DeliveryFailureKind.transient) {
          _link = DeliveryLink(
            checkedAtUtc: _link.checkedAtUtc,
            failingSinceUtc: _link.failingSinceUtc ?? _now(),
            lastCode: error.code,
          );
        }
        rethrow;
      }
    }
  }

  Future<void> _failed(
    DeliveryIntent intent,
    DeliveryApiException error,
  ) async {
    switch (DeliveryPolicy.decide(error)) {
      case FailureDecision.retryLater:
        // Without the event's permission to wait, a request the service
        // never received is not kept.
        if (!intent.queueAllowed &&
            intent.remoteJobId == null &&
            error.kind == DeliveryFailureKind.transient) {
          await _finishLocally(intent, DeliveryPhase.failed, error.code);
          return;
        }
        final delay =
            error.retryAfter ??
            DeliveryPolicy.retryDelay(intent.attemptCount, _random());
        await _save(
          intent.copyWith(
            state: DeliveryIntentState.queued,
            lastErrorCode: error.code,
            retryAtUtc: _now().add(delay),
            updatedAtUtc: _now(),
          ),
        );
      case FailureDecision.fail:
        await _finishLocally(intent, DeliveryPhase.failed, error.code);
      case FailureDecision.expire:
        await _finishLocally(intent, DeliveryPhase.expired, error.code);
    }
  }

  Future<void> _cancelRemote(
    DeliveryPairing pairing,
    DeliveryIntent intent,
  ) async {
    final id = intent.remoteJobId;
    if (id == null) return;
    await _quietly(
      () => _withToken(
        pairing,
        (token) => _api.cancel(pairing.baseUrl, token, id),
      ),
    );
  }

  Future<void> _refresh(DeliveryPairing pairing, DeliveryIntent intent) async {
    try {
      final remote = await _withToken(
        pairing,
        (token) => _api.status(pairing.baseUrl, token, intent.remoteJobId!),
      );
      await _applyRemote(intent, remote);
    } on DeliveryApiException catch (error) {
      if (error.kind == DeliveryFailureKind.refused &&
          error.code == 'DELIVERY_NOT_FOUND') {
        // Deleted at the service (its retention ran): nothing more will be
        // known. The last report stands; nothing is claimed beyond it.
        final now = _now();
        await _save(
          intent.copyWith(
            state: DeliveryIntentState.finished,
            lastErrorCode: DeliveryIntent.goneCode,
            history: List.unmodifiable([
              ...intent.history,
              DeliveryStep(intent.phase, now, DeliveryIntent.goneCode),
            ]),
            updatedAtUtc: now,
          ),
        );
        return;
      }
      await _save(
        intent.copyWith(remoteUpdatedAtUtc: _now(), updatedAtUtc: _now()),
      );
    }
  }

  /// Mirrors the service's report into [intent].
  Future<DeliveryIntent> _applyRemote(
    DeliveryIntent intent,
    RemoteDelivery remote,
  ) async {
    final now = _now();
    var history = intent.history;
    final phase = intent
        .copyWith(
          state: DeliveryIntentState.handedOver,
          remoteStatus: remote.status,
          updatedAtUtc: now,
        )
        .phase;
    history = intent.withStep(DeliveryStep(phase, now, remote.failureCode));
    return _save(
      intent.copyWith(
        state: remote.status.isFinal
            ? DeliveryIntentState.finished
            : DeliveryIntentState.handedOver,
        remoteJobId: remote.id,
        remoteStatus: remote.status,
        remoteUpdatedAtUtc: now,
        lastErrorCode: remote.failureCode ?? remote.reviewReason,
        clearError: remote.failureCode == null && remote.reviewReason == null,
        clearRetry: true,
        history: history,
        updatedAtUtc: now,
      ),
    );
  }

  Future<void> _finishLocally(
    DeliveryIntent intent,
    DeliveryPhase outcome,
    String code,
  ) async {
    await _quietly(() => _secrets.erasePhone(intent.id));
    final now = _now();
    await _save(
      intent.copyWith(
        state: DeliveryIntentState.finished,
        localOutcome: outcome,
        phoneStored: false,
        lastErrorCode: code,
        clearRetry: true,
        history: intent.withStep(DeliveryStep(outcome, now, code)),
        updatedAtUtc: now,
      ),
    );
  }

  Future<DeliveryIntent> _save(DeliveryIntent intent) async {
    await _repository.update(intent);
    if (!_disposed) notifyListeners();
    return intent;
  }

  Future<void> _revokeDeleted(DeliveryPairing pairing) async {
    for (final id in await _repository.pendingRevocations()) {
      try {
        await _withToken(
          pairing,
          (token) => _api.revoke(pairing.baseUrl, token, id),
        );
        await _repository.revocationDone(id);
      } on DeliveryApiException catch (error) {
        if (error.kind == DeliveryFailureKind.refused) {
          // Gone already, or not this booth's: nothing left to revoke.
          await _repository.revocationDone(id);
        } else {
          return;
        }
      }
    }
  }

  /// Erases stored numbers that no waiting request needs (finished,
  /// handed over or deleted with their session).
  Future<void> sweepSecrets() async {
    final stored = await _secrets.storedPhoneIds();
    if (stored.isEmpty) return;
    final needed = {
      for (final intent in await _repository.open())
        if (intent.phoneStored && intent.remoteJobId == null) intent.id,
    };
    for (final id in stored.difference(needed)) {
      await _quietly(() => _secrets.erasePhone(id));
    }
  }

  // Operator actions (S35).

  /// Cancels a request not yet sent. Throws [DeliveryActionFailure].
  Future<void> cancel(String intentId) async {
    final intent = await _repository.find(intentId);
    if (intent == null || intent.finished) {
      throw const DeliveryActionFailure('DELIVERY_NOT_OPEN');
    }
    if (intent.remoteJobId == null) {
      await _finishLocally(
        intent,
        DeliveryPhase.canceled,
        'CANCELED_BY_OPERATOR',
      );
      return;
    }
    final pairing = await _pairingOrThrow();
    try {
      final remote = await _withToken(
        pairing,
        (token) => _api.cancel(pairing.baseUrl, token, intent.remoteJobId!),
      );
      await _quietly(() => _secrets.erasePhone(intent.id));
      await _applyRemote(
        intent.copyWith(phoneStored: false, updatedAtUtc: _now()),
        remote,
      );
    } on DeliveryApiException catch (error) {
      throw DeliveryActionFailure(error.code);
    }
  }

  /// Turns the download link off and deletes the hosted copy.
  Future<void> revoke(String intentId) async {
    final intent = await _repository.find(intentId);
    if (intent?.remoteJobId == null) {
      throw const DeliveryActionFailure('DELIVERY_NOT_SENT');
    }
    final pairing = await _pairingOrThrow();
    try {
      final remote = await _withToken(
        pairing,
        (token) => _api.revoke(pairing.baseUrl, token, intent!.remoteJobId!),
      );
      final saved = await _applyRemote(intent!, remote);
      if (saved.linkRevokedAtUtc == null) {
        await _save(
          saved.copyWith(
            history: List.unmodifiable([
              ...saved.history,
              DeliveryStep(
                saved.phase,
                (remote.linkRevokedAtUtc ?? _now()).toUtc(),
                DeliveryIntent.linkRevokedCode,
              ),
            ]),
            updatedAtUtc: _now(),
          ),
        );
      }
    } on DeliveryApiException catch (error) {
      throw DeliveryActionFailure(error.code);
    }
  }

  /// Decides a delivery whose submission stayed unknown: `close` or
  /// `resend` (a resend may give the guest two texts).
  Future<void> resolve(String intentId, {required bool resend}) async {
    final intent = await _repository.find(intentId);
    if (intent?.remoteJobId == null) {
      throw const DeliveryActionFailure('DELIVERY_NOT_SENT');
    }
    final pairing = await _pairingOrThrow();
    try {
      final remote = await _withToken(
        pairing,
        (token) => _api.resolve(
          pairing.baseUrl,
          token,
          intent!.remoteJobId!,
          action: resend ? 'resend' : 'close',
          acknowledgeDuplicateRisk: resend,
        ),
      );
      await _applyRemote(intent!, remote);
    } on DeliveryApiException catch (error) {
      throw DeliveryActionFailure(error.code);
    }
  }

  /// Tries a waiting request now instead of at its next retry.
  Future<void> tryNow(String intentId) async {
    final intent = await _repository.find(intentId);
    if (intent == null || intent.finished) return;
    await _save(intent.copyWith(clearRetry: true, updatedAtUtc: _now()));
    await processDue();
  }

  /// Asks the service for the latest status of [intentId] now.
  Future<void> refreshNow(String intentId) async {
    final intent = await _repository.find(intentId);
    final pairing = await _repository.pairing();
    if (intent?.remoteJobId == null || pairing == null) return;
    await _refresh(pairing, intent!);
  }

  Future<DeliveryPairing> _pairingOrThrow() async {
    final pairing = await _repository.pairing();
    if (pairing == null) throw const DeliveryActionFailure('NOT_PAIRED');
    return pairing;
  }

  static Future<void> _quietly(Future<Object?> Function() action) async {
    try {
      await action();
    } on Object {
      // Best effort; the sweep tries again.
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    super.dispose();
  }
}

/// The finished photo or its preview could not be prepared for upload.
final class DeliveryUploadProblem implements Exception {
  const DeliveryUploadProblem(this.code);

  final String code;
}
