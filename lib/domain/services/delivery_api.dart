import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../delivery/consent.dart';
import '../delivery/delivery_intent.dart';

/// How a call to the delivery service failed, in kinds the queue acts on.
enum DeliveryFailureKind {
  /// No connection, a timeout, a captive portal or trouble at the
  /// service: nothing was decided, so it may be tried again later.
  transient,

  /// The service decided: this delivery will not be accepted (opted out,
  /// a limit, an unsupported number, sending not ready, a bad upload).
  refused,

  /// The booth's identity no longer works (revoked, or pairing lost).
  unauthorized,
}

/// A failed call to the delivery service. [code] is the service's stable
/// code (`RECIPIENT_OPTED_OUT`) or the booth's own (`OFFLINE`, `TIMEOUT`,
/// `TLS`, `SERVER_ERROR`, `RESPONSE_INVALID`). Never carries a number,
/// a token or a URL.
final class DeliveryApiException implements Exception {
  const DeliveryApiException(
    this.kind,
    this.code, {
    this.statusCode,
    this.retryAfter,
    this.deliveryId,
    this.reasons = const [],
  });

  final DeliveryFailureKind kind;
  final String code;
  final int? statusCode;
  final Duration? retryAfter;

  /// For `DUPLICATE_REQUEST`: the delivery that already exists.
  final String? deliveryId;

  /// For `SENDING_NOT_READY`: why.
  final List<String> reasons;

  @override
  String toString() => 'DeliveryApiException(${kind.name}, $code)';
}

/// The booth's identity after pairing (the credential goes to secure
/// storage, never to the database).
@immutable
final class PairingResult {
  const PairingResult({
    required this.boothId,
    required this.boothName,
    required this.credential,
    required this.brandName,
  });

  final String boothId;
  final String boothName;
  final String credential;
  final String brandName;
}

@immutable
final class AccessToken {
  const AccessToken(this.token, this.expiresAtUtc);

  final String token;
  final DateTime expiresAtUtc;
}

/// What the service says this booth may do now (UX-PD5, UX-PD6).
@immutable
final class DeliveryCapabilities {
  const DeliveryCapabilities({
    required this.ready,
    required this.reasons,
    required this.environment,
    required this.boothName,
    required this.brandName,
    required this.privacyUrl,
    required this.termsUrl,
    required this.supportContact,
    required this.regions,
    required this.linkDaysDefault,
    required this.linkDaysMax,
    required this.queueHours,
    required this.previewMaxBytes,
    required this.finalMaxBytes,
    required this.tenantDailyRemaining,
    required this.boothDailyRemaining,
    required this.eventSendLimitMax,
    required this.monthlyBudgetCents,
    required this.monthEstimatedCents,
    required this.estimatedCostMillicents,
    this.statusWebhookAtUtc,
    this.inboundWebhookAtUtc,
    this.dispatchWorkerAtUtc,
    this.retentionWorkerAtUtc,
    required this.serverTimeUtc,
  });

  final bool ready;

  /// `PROVIDER_NOT_CONFIGURED`, `REGISTRATION_NOT_ATTESTED`,
  /// `LEGAL_REVIEW_NOT_ATTESTED`, `SENDING_DISABLED`, `PUBLIC_URL_NOT_HTTPS`.
  final List<String> reasons;
  final String environment;
  final String boothName;
  final String brandName;
  final String privacyUrl;
  final String termsUrl;
  final String supportContact;
  final List<String> regions;
  final int linkDaysDefault;
  final int linkDaysMax;
  final int queueHours;
  final int previewMaxBytes;
  final int finalMaxBytes;
  final int tenantDailyRemaining;
  final int boothDailyRemaining;
  final int eventSendLimitMax;
  final int monthlyBudgetCents;
  final int monthEstimatedCents;
  final int estimatedCostMillicents;
  final DateTime? statusWebhookAtUtc;
  final DateTime? inboundWebhookAtUtc;
  final DateTime? dispatchWorkerAtUtc;
  final DateTime? retentionWorkerAtUtc;
  final DateTime serverTimeUtc;

  /// A snapshot for the booth's database (no secrets in it).
  Map<String, Object?> toJson() => {
    'ready': ready,
    'reasons': reasons,
    'environment': environment,
    'boothName': boothName,
    'brandName': brandName,
    'privacyUrl': privacyUrl,
    'termsUrl': termsUrl,
    'supportContact': supportContact,
    'regions': regions,
    'linkDaysDefault': linkDaysDefault,
    'linkDaysMax': linkDaysMax,
    'queueHours': queueHours,
    'previewMaxBytes': previewMaxBytes,
    'finalMaxBytes': finalMaxBytes,
    'tenantDailyRemaining': tenantDailyRemaining,
    'boothDailyRemaining': boothDailyRemaining,
    'eventSendLimitMax': eventSendLimitMax,
    'monthlyBudgetCents': monthlyBudgetCents,
    'monthEstimatedCents': monthEstimatedCents,
    'estimatedCostMillicents': estimatedCostMillicents,
    'statusWebhookAt': statusWebhookAtUtc?.toIso8601String(),
    'inboundWebhookAt': inboundWebhookAtUtc?.toIso8601String(),
    'dispatchWorkerAt': dispatchWorkerAtUtc?.toIso8601String(),
    'retentionWorkerAt': retentionWorkerAtUtc?.toIso8601String(),
    'serverTime': serverTimeUtc.toIso8601String(),
  };

  /// A stored snapshot; missing values take conservative defaults, and
  /// anything unreadable reads as not ready.
  static DeliveryCapabilities fromJson(Map<String, Object?> json) {
    int number(String key, int fallback) =>
        json[key] is int ? json[key]! as int : fallback;
    String text(String key) => json[key] is String ? json[key]! as String : '';
    DateTime? time(String key) => json[key] is String
        ? DateTime.tryParse(json[key]! as String)?.toUtc()
        : null;
    List<String> list(String key) => [
      if (json[key] is List)
        for (final item in json[key]! as List) '$item',
    ];
    return DeliveryCapabilities(
      ready: json['ready'] == true,
      reasons: list('reasons'),
      environment: text('environment'),
      boothName: text('boothName'),
      brandName: text('brandName'),
      privacyUrl: text('privacyUrl'),
      termsUrl: text('termsUrl'),
      supportContact: text('supportContact'),
      regions: json['regions'] is List ? list('regions') : const ['US'],
      linkDaysDefault: number('linkDaysDefault', 7),
      linkDaysMax: number('linkDaysMax', 7),
      queueHours: number('queueHours', 24),
      previewMaxBytes: number('previewMaxBytes', 400 * 1024),
      finalMaxBytes: number('finalMaxBytes', 25 * 1024 * 1024),
      tenantDailyRemaining: number('tenantDailyRemaining', 0),
      boothDailyRemaining: number('boothDailyRemaining', 0),
      eventSendLimitMax: number('eventSendLimitMax', 0),
      monthlyBudgetCents: number('monthlyBudgetCents', 0),
      monthEstimatedCents: number('monthEstimatedCents', 0),
      estimatedCostMillicents: number('estimatedCostMillicents', 0),
      statusWebhookAtUtc: time('statusWebhookAt'),
      inboundWebhookAtUtc: time('inboundWebhookAt'),
      dispatchWorkerAtUtc: time('dispatchWorkerAt'),
      retentionWorkerAtUtc: time('retentionWorkerAt'),
      serverTimeUtc: time('serverTime') ?? DateTime.utc(1970),
    );
  }
}

/// The guest's request as the service receives it.
@immutable
final class CreateDeliveryRequest {
  const CreateDeliveryRequest({
    required this.eventId,
    required this.eventName,
    required this.sessionId,
    required this.outputId,
    required this.phoneE164,
    required this.idempotencyKey,
    required this.linkDays,
    required this.eventSendLimit,
    required this.consent,
  });

  final String eventId;
  final String eventName;
  final String sessionId;
  final String outputId;
  final String phoneE164;
  final String idempotencyKey;
  final int linkDays;
  final int eventSendLimit;
  final ConsentReceipt consent;
}

/// One step the service reports.
@immutable
final class RemoteStep {
  const RemoteStep(this.status, this.atUtc, this.code);

  final RemoteDeliveryStatus status;
  final DateTime atUtc;
  final String? code;
}

/// A delivery as the service reports it to its booth (no number, no
/// links).
@immutable
final class RemoteDelivery {
  const RemoteDelivery({
    required this.id,
    required this.status,
    required this.recipientLast4,
    this.failureCode,
    this.reviewReason,
    this.linkExpiresAtUtc,
    this.linkRevokedAtUtc,
    this.hostedFilesDeleted = false,
    this.history = const [],
    required this.updatedAtUtc,
  });

  final String id;
  final RemoteDeliveryStatus status;
  final String recipientLast4;
  final String? failureCode;

  /// Set when an operator must decide (`NOT_FOUND_AT_PROVIDER`).
  final String? reviewReason;
  final DateTime? linkExpiresAtUtc;
  final DateTime? linkRevokedAtUtc;
  final bool hostedFilesDeleted;
  final List<RemoteStep> history;
  final DateTime updatedAtUtc;
}

/// An image the booth is about to upload: exactly what the service will
/// check the bytes against.
@immutable
final class UploadDeclaration {
  const UploadDeclaration({
    required this.format,
    required this.bytes,
    required this.sha256,
    required this.width,
    required this.height,
  });

  /// `jpeg` or `png`.
  final String format;
  final int bytes;
  final String sha256;
  final int width;
  final int height;
}

/// A single-use upload grant for one image.
@immutable
final class UploadGrant {
  const UploadGrant({
    required this.kind,
    required this.url,
    required this.contentType,
  });

  /// `final` or `preview`.
  final String kind;
  final Uri url;
  final String contentType;
}

/// The phone-delivery service (backend/openapi/delivery-v1.yaml). The
/// booth holds no provider or database credentials: only its own booth
/// credential, exchanged for short-lived access tokens. Every failure is a
/// [DeliveryApiException].
abstract interface class DeliveryApi {
  Future<PairingResult> pair(
    Uri baseUrl, {
    required String code,
    required String boothName,
  });

  Future<AccessToken> accessToken(Uri baseUrl, String credential);

  Future<String> rotateCredential(Uri baseUrl, String accessToken);

  Future<DeliveryCapabilities> capabilities(Uri baseUrl, String accessToken);

  Future<RemoteDelivery> create(
    Uri baseUrl,
    String accessToken,
    CreateDeliveryRequest request,
  );

  Future<List<UploadGrant>> uploadInit(
    Uri baseUrl,
    String accessToken,
    String deliveryId, {
    required UploadDeclaration finalImage,
    required UploadDeclaration preview,
  });

  Future<void> upload(UploadGrant grant, Uint8List bytes);

  Future<RemoteDelivery> commit(
    Uri baseUrl,
    String accessToken,
    String deliveryId,
  );

  Future<RemoteDelivery> status(
    Uri baseUrl,
    String accessToken,
    String deliveryId,
  );

  Future<RemoteDelivery> cancel(
    Uri baseUrl,
    String accessToken,
    String deliveryId,
  );

  Future<RemoteDelivery> revoke(
    Uri baseUrl,
    String accessToken,
    String deliveryId,
  );

  /// [action] `close` or `resend` (resend only with
  /// [acknowledgeDuplicateRisk]).
  Future<RemoteDelivery> resolve(
    Uri baseUrl,
    String accessToken,
    String deliveryId, {
    required String action,
    bool acknowledgeDuplicateRisk = false,
  });

  /// Checks [jpeg] like an upload; nothing is stored or sent.
  Future<UploadTestResult> uploadTest(
    Uri baseUrl,
    String accessToken,
    Uint8List jpeg,
  );
}

@immutable
final class UploadTestResult {
  const UploadTestResult({
    required this.width,
    required this.height,
    required this.bytes,
    required this.sha256,
  });

  final int width;
  final int height;
  final int bytes;
  final String sha256;
}

/// Platform secure storage for delivery secrets (PD-05): the booth
/// credential and each pending delivery's phone number. Neither is ever
/// written to the database or a log.
abstract interface class DeliverySecrets {
  Future<String?> readCredential();
  Future<void> writeCredential(String credential);
  Future<void> deleteCredential();

  Future<void> storePhone(String intentId, String e164);
  Future<String?> readPhone(String intentId);
  Future<void> erasePhone(String intentId);

  /// Intents that still have a stored number (for cleanup).
  Future<Set<String>> storedPhoneIds();
}

/// A storage failure of [DeliverySecrets] (the platform's code only).
final class DeliverySecretsException implements Exception {
  const DeliverySecretsException(this.code);

  final String code;

  @override
  String toString() => 'DeliverySecretsException($code)';
}

/// The small JPEG sent as the MMS picture (PD-04): from the finished
/// photo, within the service's byte limit.
@immutable
final class PreviewImage {
  const PreviewImage(this.bytes, this.width, this.height, this.sha256);

  final Uint8List bytes;
  final int width;
  final int height;

  /// SHA-256 of [bytes], lowercase hex (the service checks the upload
  /// against it).
  final String sha256;
}

abstract interface class PreviewMaker {
  /// A JPEG of [finished] at most [maxBytes] long and [maxSide] pixels on
  /// its longer side (smaller when needed to fit).
  Future<PreviewImage> make(
    Uint8List finished, {
    required int maxBytes,
    int maxSide = 1024,
  });
}

/// Whether [baseUrl] may be a delivery service's address: https only (plain
/// http only on this machine, for tests), with no user name, query or
/// fragment. Checked before pairing and before every request.
bool deliveryAddressAcceptable(Uri baseUrl) =>
    baseUrl.hasAuthority &&
    baseUrl.userInfo.isEmpty &&
    !baseUrl.hasQuery &&
    !baseUrl.hasFragment &&
    (baseUrl.scheme == 'https' ||
        (baseUrl.scheme == 'http' &&
            (baseUrl.host == '127.0.0.1' || baseUrl.host == 'localhost')));
