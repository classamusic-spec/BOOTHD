import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:porcelain_photo_booth/domain/delivery/delivery_intent.dart';
import 'package:porcelain_photo_booth/domain/repositories/delivery_repository.dart';
import 'package:porcelain_photo_booth/domain/services/delivery_api.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_delivery_repository.dart';

/// A stand-in for the delivery service: pairing codes, tokens, readiness,
/// idempotent deliveries, uploads and commits, with switches for each
/// failure the booth must handle. Records what the booth sent (including
/// the numbers, which exist here only because this is the "service").
final class FakeDeliveryApi implements DeliveryApi {
  FakeDeliveryApi({this.ready = true});

  /// The code an administrator "issued".
  static const pairingCode = 'K7QM-4XHT-9ZPA';
  static final baseUrl = Uri.parse('https://photos.example.test');

  bool ready;
  List<String> reasons = const [];

  /// Every call fails as if the booth had no connection.
  bool offline = false;

  /// The next create is refused with this code.
  String? refuseCreateWith;

  /// The status a commit reports.
  RemoteDeliveryStatus afterCommit = RemoteDeliveryStatus.submitted;

  var _next = 0;
  final deliveries = <String, FakeRemoteDelivery>{};
  final requests = <CreateDeliveryRequest>[];
  final uploads = <(String deliveryId, String kind, int bytes)>[];
  final calls = <String>[];
  var paired = false;
  var revoked = false;

  void _call(String name) {
    calls.add(name);
    if (offline) {
      throw const DeliveryApiException(
        DeliveryFailureKind.transient,
        'OFFLINE',
      );
    }
  }

  FakeRemoteDelivery _delivery(String id) {
    final delivery = deliveries[id];
    if (delivery == null) {
      throw const DeliveryApiException(
        DeliveryFailureKind.refused,
        'DELIVERY_NOT_FOUND',
        statusCode: 404,
      );
    }
    return delivery;
  }

  /// The service reports [status] for [id] from now on.
  void advance(String id, RemoteDeliveryStatus status, {String? code}) {
    final delivery = _delivery(id);
    delivery.status = status;
    delivery.failureCode = code;
  }

  @override
  Future<PairingResult> pair(
    Uri baseUrl, {
    required String code,
    required String boothName,
  }) async {
    _call('pair');
    if (code.replaceAll(RegExp(r'[\s-]'), '').toUpperCase() !=
        pairingCode.replaceAll('-', '')) {
      throw const DeliveryApiException(
        DeliveryFailureKind.refused,
        'PAIRING_CODE_INVALID',
        statusCode: 400,
      );
    }
    paired = true;
    return PairingResult(
      boothId: 'b2000000-0000-4000-8000-000000000001',
      boothName: boothName,
      credential: 'credential-${'x' * 33}',
      brandName: 'Porcelain Booth',
    );
  }

  @override
  Future<AccessToken> accessToken(Uri baseUrl, String credential) async {
    _call('token');
    if (revoked) {
      throw const DeliveryApiException(
        DeliveryFailureKind.unauthorized,
        'CREDENTIAL_INVALID',
        statusCode: 401,
      );
    }
    return AccessToken('access-${'y' * 36}', DateTime.utc(2100));
  }

  @override
  Future<String> rotateCredential(Uri baseUrl, String accessToken) async {
    _call('rotate');
    return 'credential-${'z' * 33}';
  }

  @override
  Future<DeliveryCapabilities> capabilities(
    Uri baseUrl,
    String accessToken,
  ) async {
    _call('capabilities');
    return DeliveryCapabilities(
      ready: ready,
      reasons: ready ? const [] : reasons,
      environment: 'staging',
      boothName: 'Front entrance',
      brandName: 'Porcelain Booth',
      privacyUrl: 'https://photos.example.test/privacy',
      termsUrl: 'https://photos.example.test/terms',
      supportContact: 'help@example.test',
      regions: const ['US'],
      linkDaysDefault: 7,
      linkDaysMax: 14,
      queueHours: 24,
      previewMaxBytes: 600000,
      finalMaxBytes: 25 * 1024 * 1024,
      tenantDailyRemaining: 180,
      boothDailyRemaining: 140,
      eventSendLimitMax: 500,
      monthlyBudgetCents: 2000,
      monthEstimatedCents: 64,
      estimatedCostMillicents: 3200,
      statusWebhookAtUtc: DateTime.utc(2026, 11, 14, 17, 58),
      inboundWebhookAtUtc: null,
      dispatchWorkerAtUtc: DateTime.utc(2026, 11, 14, 17, 59),
      retentionWorkerAtUtc: DateTime.utc(2026, 11, 14, 17, 59),
      serverTimeUtc: DateTime.utc(2026, 11, 14, 18),
    );
  }

  @override
  Future<RemoteDelivery> create(
    Uri baseUrl,
    String accessToken,
    CreateDeliveryRequest request,
  ) async {
    _call('create');
    for (final existing in deliveries.values) {
      if (existing.idempotencyKey == request.idempotencyKey) {
        return existing.view;
      }
    }
    final refusal = refuseCreateWith;
    if (refusal != null) {
      refuseCreateWith = null;
      throw DeliveryApiException(
        DeliveryFailureKind.refused,
        refusal,
        statusCode: 403,
      );
    }
    requests.add(request);
    final id =
        '00000000-0000-4000-8000-${(++_next).toString().padLeft(12, '0')}';
    final delivery = FakeRemoteDelivery(
      id,
      request.idempotencyKey,
      request.phoneE164.substring(request.phoneE164.length - 4),
    );
    deliveries[id] = delivery;
    return delivery.view;
  }

  @override
  Future<List<UploadGrant>> uploadInit(
    Uri baseUrl,
    String accessToken,
    String deliveryId, {
    required UploadDeclaration finalImage,
    required UploadDeclaration preview,
  }) async {
    _call('uploadInit');
    final delivery = _delivery(deliveryId);
    delivery
      ..status = RemoteDeliveryStatus.uploading
      ..declared = (finalImage, preview);
    return [
      UploadGrant(
        kind: 'final',
        url: Uri.parse('https://photos.example.test/v1/uploads/f-$deliveryId'),
        contentType: finalImage.format == 'png' ? 'image/png' : 'image/jpeg',
      ),
      UploadGrant(
        kind: 'preview',
        url: Uri.parse('https://photos.example.test/v1/uploads/p-$deliveryId'),
        contentType: 'image/jpeg',
      ),
    ];
  }

  @override
  Future<void> upload(UploadGrant grant, Uint8List bytes) async {
    _call('upload');
    final id = grant.url.pathSegments.last.substring(2);
    uploads.add((id, grant.kind, bytes.length));
    _delivery(id).uploaded.add(grant.kind);
  }

  @override
  Future<RemoteDelivery> commit(
    Uri baseUrl,
    String accessToken,
    String deliveryId,
  ) async {
    _call('commit');
    final delivery = _delivery(deliveryId);
    if (delivery.status == RemoteDeliveryStatus.uploading) {
      if (!delivery.uploaded.containsAll(['final', 'preview'])) {
        throw const DeliveryApiException(
          DeliveryFailureKind.refused,
          'UPLOAD_INCOMPLETE',
          statusCode: 409,
        );
      }
      delivery.status = afterCommit;
    }
    return delivery.view;
  }

  @override
  Future<RemoteDelivery> status(
    Uri baseUrl,
    String accessToken,
    String deliveryId,
  ) async {
    _call('status');
    return _delivery(deliveryId).view;
  }

  @override
  Future<RemoteDelivery> cancel(
    Uri baseUrl,
    String accessToken,
    String deliveryId,
  ) async {
    _call('cancel');
    final delivery = _delivery(deliveryId);
    if (delivery.status == RemoteDeliveryStatus.submitted ||
        delivery.status == RemoteDeliveryStatus.sent ||
        delivery.status == RemoteDeliveryStatus.delivered) {
      throw const DeliveryApiException(
        DeliveryFailureKind.refused,
        'DELIVERY_ALREADY_SUBMITTED',
        statusCode: 409,
      );
    }
    delivery.status = RemoteDeliveryStatus.canceled;
    return delivery.view;
  }

  @override
  Future<RemoteDelivery> revoke(
    Uri baseUrl,
    String accessToken,
    String deliveryId,
  ) async {
    _call('revoke');
    final delivery = _delivery(deliveryId)
      ..linkRevoked = true
      ..hostedFilesDeleted = true;
    return delivery.view;
  }

  @override
  Future<RemoteDelivery> resolve(
    Uri baseUrl,
    String accessToken,
    String deliveryId, {
    required String action,
    bool acknowledgeDuplicateRisk = false,
  }) async {
    _call('resolve');
    final delivery = _delivery(deliveryId);
    delivery.status = action == 'close'
        ? RemoteDeliveryStatus.failed
        : RemoteDeliveryStatus.submitted;
    delivery.failureCode = action == 'close' ? 'CLOSED_BY_OPERATOR' : null;
    return delivery.view;
  }

  @override
  Future<UploadTestResult> uploadTest(
    Uri baseUrl,
    String accessToken,
    Uint8List jpeg,
  ) async {
    _call('uploadTest');
    return UploadTestResult(
      width: 16,
      height: 16,
      bytes: jpeg.length,
      sha256: crypto.sha256.convert(jpeg).toString(),
    );
  }
}

final class FakeRemoteDelivery {
  FakeRemoteDelivery(this.id, this.idempotencyKey, this.last4);

  final String id;
  final String idempotencyKey;
  final String last4;
  var status = RemoteDeliveryStatus.queued;
  String? failureCode;
  var linkRevoked = false;
  var hostedFilesDeleted = false;
  (UploadDeclaration, UploadDeclaration)? declared;
  final uploaded = <String>{};

  RemoteDelivery get view => RemoteDelivery(
    id: id,
    status: status,
    recipientLast4: last4,
    failureCode: failureCode,
    linkRevokedAtUtc: linkRevoked ? DateTime.utc(2026, 11, 14, 19) : null,
    hostedFilesDeleted: hostedFilesDeleted,
    updatedAtUtc: DateTime.utc(2026, 11, 14, 18),
  );
}

/// Secure storage in memory.
final class MemoryDeliverySecrets implements DeliverySecrets {
  String? credential;
  final phones = <String, String>{};
  var failing = false;

  void _check() {
    if (failing) throw const DeliverySecretsException('unavailable');
  }

  @override
  Future<String?> readCredential() async {
    _check();
    return credential;
  }

  @override
  Future<void> writeCredential(String value) async {
    _check();
    credential = value;
  }

  @override
  Future<void> deleteCredential() async {
    _check();
    credential = null;
  }

  @override
  Future<void> storePhone(String intentId, String e164) async {
    _check();
    phones[intentId] = e164;
  }

  @override
  Future<String?> readPhone(String intentId) async {
    _check();
    return phones[intentId];
  }

  @override
  Future<void> erasePhone(String intentId) async {
    _check();
    phones.remove(intentId);
  }

  @override
  Future<Set<String>> storedPhoneIds() async {
    _check();
    return phones.keys.toSet();
  }
}

/// A preview of fixed bytes (the real maker is tested on its own).
final class FakePreviewMaker implements PreviewMaker {
  final made = <int>[];

  /// The next previews cannot be made.
  var failing = false;

  @override
  Future<PreviewImage> make(
    Uint8List finished, {
    required int maxBytes,
    int maxSide = 1024,
  }) async {
    made.add(maxBytes);
    if (failing) throw StateError('preview does not fit the byte limit');
    final bytes = Uint8List.fromList([
      0xFF,
      0xD8,
      0xFF,
      0xE0,
      1,
      2,
      3,
      0xFF,
      0xD9,
    ]);
    return PreviewImage(
      bytes,
      400,
      600,
      crypto.sha256.convert(bytes).toString(),
    );
  }
}

/// Pairs [db]'s booth with [api] as of [at], with the service's readiness
/// already checked (what pairing and the first check leave behind).
Future<void> seedPairing(
  BoothDatabase db,
  MemoryDeliverySecrets secrets, {
  required DateTime at,
  FakeDeliveryApi? api,
  bool paused = false,
}) async {
  final service = api ?? FakeDeliveryApi();
  final result = await service.pair(
    FakeDeliveryApi.baseUrl,
    code: FakeDeliveryApi.pairingCode,
    boothName: 'Front entrance',
  );
  secrets.credential = result.credential;
  await DriftDeliveryRepository(db).savePairing(
    DeliveryPairing(
      baseUrl: FakeDeliveryApi.baseUrl,
      boothId: result.boothId,
      boothName: result.boothName,
      brandName: result.brandName,
      pairedAtUtc: at.toUtc(),
      paused: paused,
      capabilities: await service.capabilities(FakeDeliveryApi.baseUrl, ''),
      checkedAtUtc: at.toUtc(),
    ),
  );
  service.calls.clear();
}

/// A guest's request as the booth stores it, in [phase], for screens and
/// lists: asked at [at], with the history a real request would have.
DeliveryIntent seededIntent({
  required String id,
  required String sessionId,
  required String eventId,
  required String outputId,
  required String last4,
  required DateTime at,
  required DeliveryPhase phase,
  String? code,
}) {
  final asked = at.toUtc();
  final steps = <DeliveryPhase>[
    DeliveryPhase.queuedLocally,
    if (phase != DeliveryPhase.queuedLocally) DeliveryPhase.uploading,
    ...switch (phase) {
      DeliveryPhase.submitted => [DeliveryPhase.submitted],
      DeliveryPhase.sent => [DeliveryPhase.submitted, DeliveryPhase.sent],
      DeliveryPhase.delivered => [
        DeliveryPhase.submitted,
        DeliveryPhase.sent,
        DeliveryPhase.delivered,
      ],
      DeliveryPhase.unknown => [DeliveryPhase.sending, DeliveryPhase.unknown],
      DeliveryPhase.failed => [DeliveryPhase.failed],
      _ => const <DeliveryPhase>[],
    },
  ];
  final remote = switch (phase) {
    DeliveryPhase.queuedLocally => null,
    DeliveryPhase.submitted => RemoteDeliveryStatus.submitted,
    DeliveryPhase.sent => RemoteDeliveryStatus.sent,
    DeliveryPhase.delivered => RemoteDeliveryStatus.delivered,
    DeliveryPhase.unknown => RemoteDeliveryStatus.unknown,
    DeliveryPhase.failed => RemoteDeliveryStatus.failed,
    DeliveryPhase.expired => RemoteDeliveryStatus.expired,
    DeliveryPhase.canceled => RemoteDeliveryStatus.canceled,
    DeliveryPhase.uploading => RemoteDeliveryStatus.uploading,
    DeliveryPhase.sending => RemoteDeliveryStatus.submitting,
  };
  return DeliveryIntent(
    id: id,
    sessionId: sessionId,
    eventId: eventId,
    outputId: outputId,
    phoneLast4: last4,
    phoneStored: phase == DeliveryPhase.queuedLocally,
    consentTextVersion: 'pd-consent-1',
    consentTextDigest: 'f' * 64,
    consentAcceptedAtUtc: asked,
    locale: 'en-US',
    linkDays: 7,
    sendLimit: 200,
    queueAllowed: true,
    idempotencyKey: 'key-$id',
    state: switch (phase) {
      DeliveryPhase.queuedLocally => DeliveryIntentState.queued,
      _ when remote?.isFinal ?? false => DeliveryIntentState.finished,
      _ => DeliveryIntentState.handedOver,
    },
    expiresAtUtc: asked.add(const Duration(hours: 24)),
    createdAtUtc: asked,
    updatedAtUtc: asked.add(Duration(seconds: 8 * steps.length)),
    remoteJobId: remote == null
        ? null
        : '00000000-0000-4000-8000-${id.substring(id.length - 12)}',
    remoteStatus: remote,
    remoteUpdatedAtUtc: remote == null
        ? null
        : asked.add(Duration(seconds: 8 * steps.length)),
    lastErrorCode: code,
    attemptCount: phase == DeliveryPhase.queuedLocally ? 2 : 1,
    retryAtUtc: phase == DeliveryPhase.queuedLocally
        ? asked.add(const Duration(minutes: 4))
        : null,
    history: [
      for (final (index, step) in steps.indexed)
        DeliveryStep(
          step,
          asked.add(Duration(seconds: 8 * index)),
          index == steps.length - 1 ? code : null,
        ),
    ],
  );
}

/// Stores [texts] (session number, last four digits, phase, code) for the
/// gallery's sessions as the booth would have them, with the service's
/// side in [api] and pending numbers in [secrets].
Future<void> seedTexts(
  BoothDatabase db,
  FakeDeliveryApi api,
  MemoryDeliverySecrets secrets,
  List<(int, String, DeliveryPhase, String?)> texts, {
  required String Function(int number) sessionId,
  required String Function(int number) outputId,
}) async {
  final repository = DriftDeliveryRepository(db);
  for (final (number, last4, phase, code) in texts) {
    final session = await (db.select(
      db.captureSessions,
    )..where((t) => t.id.equals(sessionId(number)))).getSingle();
    final intent = seededIntent(
      id: 'e0000000-0000-4000-8000-${number.toString().padLeft(12, '0')}',
      sessionId: session.id,
      eventId: session.eventId,
      outputId: outputId(number),
      last4: last4,
      at: session.startedAt.add(const Duration(minutes: 2)),
      phase: phase,
      code: code,
    );
    await repository.add(intent);
    if (intent.phoneStored) secrets.phones[intent.id] = '+1212555$last4';
    if (intent.remoteJobId case final remote?) {
      api.deliveries[remote] =
          FakeRemoteDelivery(remote, intent.idempotencyKey, last4)
            ..status = intent.remoteStatus!
            ..failureCode = code;
    }
  }
}
