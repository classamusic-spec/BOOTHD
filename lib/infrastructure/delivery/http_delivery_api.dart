import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../domain/delivery/delivery_intent.dart';
import '../../domain/services/delivery_api.dart';

/// [DeliveryApi] over HTTPS with `dart:io` (backend/openapi/delivery-v1.yaml).
///
/// Only `https` service addresses are used; plain `http` is accepted for
/// this machine (`127.0.0.1`, `localhost`) so tests can run a local
/// service. Nothing is logged: requests carry the booth's tokens and
/// guests' numbers. Failures become [DeliveryApiException]s with stable
/// codes; a captive portal's page or a dropped connection is `transient`,
/// a decision by the service is `refused`.
final class HttpDeliveryApi implements DeliveryApi {
  HttpDeliveryApi({
    HttpClient? client,
    this.timeout = const Duration(seconds: 20),
  }) : _client =
           client ??
           (HttpClient()..connectionTimeout = const Duration(seconds: 10));

  final HttpClient _client;
  final Duration timeout;

  static const _userAgent = 'PorcelainBooth/1 (delivery)';

  /// Codes the service answers with 429 that are decisions, not overload.
  static const _limits = {
    'RECIPIENT_RATE_LIMITED',
    'BOOTH_DAILY_LIMIT',
    'DAILY_LIMIT',
    'EVENT_LIMIT',
    'BUDGET_REACHED',
  };

  /// Whether [baseUrl] may be used: https, or http on this machine.
  static bool acceptable(Uri baseUrl) => deliveryAddressAcceptable(baseUrl);

  Uri _endpoint(Uri baseUrl, String path) {
    if (!acceptable(baseUrl)) {
      throw const DeliveryApiException(
        DeliveryFailureKind.refused,
        'SERVICE_ADDRESS_INVALID',
      );
    }
    final prefix = baseUrl.path.replaceAll(RegExp(r'/+$'), '');
    return baseUrl.replace(path: '$prefix$path');
  }

  Future<Map<String, Object?>> _send(
    String method,
    Uri url, {
    String? bearer,
    Object? json,
    Uint8List? bytes,
    String? contentType,
    Duration? timeout,
  }) async {
    final HttpClientResponse response;
    final List<int> body;
    try {
      final request = await _client
          .openUrl(method, url)
          .timeout(timeout ?? this.timeout);
      request.followRedirects = false;
      request.headers
        ..set(HttpHeaders.userAgentHeader, _userAgent)
        ..set(HttpHeaders.acceptHeader, 'application/json');
      if (bearer != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearer');
      }
      if (json != null) {
        final encoded = utf8.encode(jsonEncode(json));
        request.headers.contentType = ContentType.json;
        request.contentLength = encoded.length;
        request.add(encoded);
      } else if (bytes != null) {
        request.headers.set(
          HttpHeaders.contentTypeHeader,
          contentType ?? 'application/octet-stream',
        );
        request.contentLength = bytes.length;
        request.add(bytes);
      } else {
        request.contentLength = 0;
      }
      response = await request.close().timeout(timeout ?? this.timeout);
      body = await response
          .fold<BytesBuilder>(
            BytesBuilder(copy: false),
            (b, chunk) => b..add(chunk),
          )
          .then((b) => b.takeBytes())
          .timeout(timeout ?? this.timeout);
    } on TimeoutException {
      throw const DeliveryApiException(
        DeliveryFailureKind.transient,
        'TIMEOUT',
      );
    } on HandshakeException {
      throw const DeliveryApiException(DeliveryFailureKind.transient, 'TLS');
    } on TlsException {
      throw const DeliveryApiException(DeliveryFailureKind.transient, 'TLS');
    } on SocketException {
      throw const DeliveryApiException(
        DeliveryFailureKind.transient,
        'OFFLINE',
      );
    } on HttpException {
      throw const DeliveryApiException(
        DeliveryFailureKind.transient,
        'NETWORK',
      );
    }

    final status = response.statusCode;
    Map<String, Object?> decoded = const {};
    if (body.isNotEmpty) {
      try {
        final value = jsonDecode(utf8.decode(body));
        if (value is Map<String, Object?>) decoded = value;
      } on FormatException {
        // A captive portal's page or a proxy's: handled below.
      }
    }
    if (status >= 200 && status < 300) {
      if (body.isNotEmpty && decoded.isEmpty) {
        throw const DeliveryApiException(
          DeliveryFailureKind.transient,
          'RESPONSE_INVALID',
        );
      }
      return decoded;
    }
    final error = decoded['error'];
    final code = error is Map && error['code'] is String
        ? error['code']! as String
        : 'HTTP_$status';
    final retryAfter = int.tryParse(
      response.headers.value(HttpHeaders.retryAfterHeader) ?? '',
    );
    final reasons = error is Map && error['reasons'] is List
        ? [for (final reason in error['reasons']! as List) '$reason']
        : const <String>[];
    final deliveryId = error is Map && error['deliveryId'] is String
        ? error['deliveryId']! as String
        : null;
    final kind = switch (status) {
      401 || 403
          when code == 'ACCESS_TOKEN_INVALID' || code == 'CREDENTIAL_INVALID' =>
        DeliveryFailureKind.unauthorized,
      429 when !_limits.contains(code) => DeliveryFailureKind.transient,
      >= 500 => DeliveryFailureKind.transient,
      // Not the service answering (a portal or proxy page).
      _ when decoded.isEmpty => DeliveryFailureKind.transient,
      _ => DeliveryFailureKind.refused,
    };
    throw DeliveryApiException(
      kind,
      code,
      statusCode: status,
      retryAfter: retryAfter == null ? null : Duration(seconds: retryAfter),
      deliveryId: deliveryId,
      reasons: reasons,
    );
  }

  static String _string(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is String) return value;
    throw const DeliveryApiException(
      DeliveryFailureKind.transient,
      'RESPONSE_INVALID',
    );
  }

  static int _int(Map<String, Object?> json, String key, [int fallback = 0]) {
    final value = json[key];
    return value is int ? value : fallback;
  }

  static DateTime? _time(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;

  static Map<String, Object?> _map(Object? value) =>
      value is Map<String, Object?> ? value : const {};

  static RemoteDelivery _delivery(Map<String, Object?> json) {
    final status = RemoteDeliveryStatus.fromName(json['status'] as String?);
    if (status == null) {
      throw const DeliveryApiException(
        DeliveryFailureKind.transient,
        'RESPONSE_INVALID',
      );
    }
    final history = <RemoteStep>[
      for (final entry
          in json['history'] is List ? json['history']! as List : const [])
        if (entry is Map<String, Object?> &&
            RemoteDeliveryStatus.fromName(entry['status'] as String?) != null &&
            _time(entry['at']) != null)
          RemoteStep(
            RemoteDeliveryStatus.fromName(entry['status'] as String?)!,
            _time(entry['at'])!,
            entry['code'] as String?,
          ),
    ];
    return RemoteDelivery(
      id: _string(json, 'id'),
      status: status,
      recipientLast4: _string(json, 'recipientLast4'),
      failureCode: json['failureCode'] as String?,
      reviewReason: json['reviewReason'] as String?,
      linkExpiresAtUtc: _time(json['linkExpiresAt']),
      linkRevokedAtUtc: _time(json['linkRevokedAt']),
      hostedFilesDeleted: json['hostedFilesDeleted'] == true,
      history: history,
      updatedAtUtc: _time(json['updatedAt']) ?? DateTime.now().toUtc(),
    );
  }

  @override
  Future<PairingResult> pair(
    Uri baseUrl, {
    required String code,
    required String boothName,
  }) async {
    final json = await _send(
      'POST',
      _endpoint(baseUrl, '/v1/booths/pair'),
      json: {'code': code, 'boothName': boothName},
    );
    return PairingResult(
      boothId: _string(json, 'boothId'),
      boothName: _string(json, 'boothName'),
      credential: _string(json, 'credential'),
      brandName: _string(json, 'brandName'),
    );
  }

  @override
  Future<AccessToken> accessToken(Uri baseUrl, String credential) async {
    final json = await _send(
      'POST',
      _endpoint(baseUrl, '/v1/booths/token'),
      bearer: credential,
    );
    return AccessToken(
      _string(json, 'accessToken'),
      _time(json['expiresAt']) ?? DateTime.now().toUtc(),
    );
  }

  @override
  Future<String> rotateCredential(Uri baseUrl, String accessToken) async {
    final json = await _send(
      'POST',
      _endpoint(baseUrl, '/v1/booths/rotate'),
      bearer: accessToken,
    );
    return _string(json, 'credential');
  }

  @override
  Future<DeliveryCapabilities> capabilities(
    Uri baseUrl,
    String accessToken,
  ) async {
    final json = await _send(
      'GET',
      _endpoint(baseUrl, '/v1/delivery/capabilities'),
      bearer: accessToken,
    );
    final sending = _map(json['sending']);
    final linkDays = _map(json['linkDays']);
    final limits = _map(json['limits']);
    final health = _map(json['health']);
    final booth = _map(json['booth']);
    return DeliveryCapabilities(
      ready: sending['ready'] == true,
      reasons: [
        for (final reason
            in sending['reasons'] is List
                ? sending['reasons']! as List
                : const [])
          '$reason',
      ],
      environment: json['environment'] as String? ?? 'production',
      boothName: booth['name'] as String? ?? '',
      brandName: _string(json, 'brandName'),
      privacyUrl: _string(json, 'privacyUrl'),
      termsUrl: _string(json, 'termsUrl'),
      supportContact: _string(json, 'supportContact'),
      regions: [
        for (final region
            in json['regions'] is List ? json['regions']! as List : const [])
          '$region',
      ],
      linkDaysDefault: _int(linkDays, 'default', 7),
      linkDaysMax: _int(linkDays, 'max', 7),
      queueHours: _int(json, 'queueHours', 24),
      previewMaxBytes: _int(json, 'previewMaxBytes', 400 * 1024),
      finalMaxBytes: _int(json, 'finalMaxBytes', 25 * 1024 * 1024),
      tenantDailyRemaining: _int(limits, 'tenantDailyRemaining'),
      boothDailyRemaining: _int(limits, 'boothDailyRemaining'),
      eventSendLimitMax: _int(limits, 'eventSendLimitMax'),
      monthlyBudgetCents: _int(limits, 'monthlyBudgetCents'),
      monthEstimatedCents: _int(limits, 'monthEstimatedCents'),
      estimatedCostMillicents: _int(limits, 'estimatedCostMillicents'),
      statusWebhookAtUtc: _time(health['statusWebhookAt']),
      inboundWebhookAtUtc: _time(health['inboundWebhookAt']),
      dispatchWorkerAtUtc: _time(health['dispatchWorkerAt']),
      retentionWorkerAtUtc: _time(health['retentionWorkerAt']),
      serverTimeUtc: _time(json['serverTime']) ?? DateTime.now().toUtc(),
    );
  }

  @override
  Future<RemoteDelivery> create(
    Uri baseUrl,
    String accessToken,
    CreateDeliveryRequest request,
  ) async => _delivery(
    await _send(
      'POST',
      _endpoint(baseUrl, '/v1/deliveries'),
      bearer: accessToken,
      json: {
        'eventId': request.eventId,
        'eventName': request.eventName,
        'sessionId': request.sessionId,
        'outputId': request.outputId,
        'phone': request.phoneE164,
        'idempotencyKey': request.idempotencyKey,
        'linkDays': request.linkDays,
        'eventSendLimit': request.eventSendLimit,
        'consent': request.consent.toJson(),
      },
    ),
  );

  @override
  Future<List<UploadGrant>> uploadInit(
    Uri baseUrl,
    String accessToken,
    String deliveryId, {
    required UploadDeclaration finalImage,
    required UploadDeclaration preview,
  }) async {
    Map<String, Object> declare(UploadDeclaration d) => {
      'format': d.format,
      'bytes': d.bytes,
      'sha256': d.sha256,
      'width': d.width,
      'height': d.height,
    };
    final json = await _send(
      'POST',
      _endpoint(baseUrl, '/v1/deliveries/$deliveryId/upload-init'),
      bearer: accessToken,
      json: {'final': declare(finalImage), 'preview': declare(preview)},
    );
    final uploads = json['uploads'];
    if (uploads is! List || uploads.length != 2) {
      throw const DeliveryApiException(
        DeliveryFailureKind.transient,
        'RESPONSE_INVALID',
      );
    }
    return [
      for (final upload in uploads.cast<Map<String, Object?>>())
        UploadGrant(
          kind: _string(upload, 'kind'),
          url: _checkedUploadUrl(baseUrl, _string(upload, 'url')),
          contentType: _string(upload, 'contentType'),
        ),
    ];
  }

  /// Upload grants must point at the same service: an image never goes
  /// anywhere else, whatever the response says.
  Uri _checkedUploadUrl(Uri baseUrl, String url) {
    final parsed = Uri.tryParse(url);
    if (parsed == null ||
        parsed.scheme != baseUrl.scheme ||
        parsed.host != baseUrl.host ||
        parsed.port != baseUrl.port) {
      throw const DeliveryApiException(
        DeliveryFailureKind.refused,
        'UPLOAD_URL_UNTRUSTED',
      );
    }
    return parsed;
  }

  @override
  Future<void> upload(UploadGrant grant, Uint8List bytes) async {
    await _send(
      'PUT',
      grant.url,
      bytes: bytes,
      contentType: grant.contentType,
      timeout: const Duration(seconds: 90),
    );
  }

  @override
  Future<RemoteDelivery> commit(
    Uri baseUrl,
    String accessToken,
    String deliveryId,
  ) async => _delivery(
    await _send(
      'POST',
      _endpoint(baseUrl, '/v1/deliveries/$deliveryId/commit'),
      bearer: accessToken,
      timeout: const Duration(seconds: 40),
    ),
  );

  @override
  Future<RemoteDelivery> status(
    Uri baseUrl,
    String accessToken,
    String deliveryId,
  ) async => _delivery(
    await _send(
      'GET',
      _endpoint(baseUrl, '/v1/deliveries/$deliveryId'),
      bearer: accessToken,
    ),
  );

  @override
  Future<RemoteDelivery> cancel(
    Uri baseUrl,
    String accessToken,
    String deliveryId,
  ) async => _delivery(
    await _send(
      'POST',
      _endpoint(baseUrl, '/v1/deliveries/$deliveryId/cancel'),
      bearer: accessToken,
    ),
  );

  @override
  Future<RemoteDelivery> revoke(
    Uri baseUrl,
    String accessToken,
    String deliveryId,
  ) async => _delivery(
    await _send(
      'POST',
      _endpoint(baseUrl, '/v1/deliveries/$deliveryId/revoke'),
      bearer: accessToken,
    ),
  );

  @override
  Future<RemoteDelivery> resolve(
    Uri baseUrl,
    String accessToken,
    String deliveryId, {
    required String action,
    bool acknowledgeDuplicateRisk = false,
  }) async => _delivery(
    await _send(
      'POST',
      _endpoint(baseUrl, '/v1/deliveries/$deliveryId/resolve'),
      bearer: accessToken,
      json: {
        'action': action,
        if (acknowledgeDuplicateRisk) 'acknowledgeDuplicateRisk': true,
      },
      timeout: const Duration(seconds: 40),
    ),
  );

  @override
  Future<UploadTestResult> uploadTest(
    Uri baseUrl,
    String accessToken,
    Uint8List jpeg,
  ) async {
    final json = await _send(
      'POST',
      _endpoint(baseUrl, '/v1/diagnostics/upload-test'),
      bearer: accessToken,
      bytes: jpeg,
      contentType: 'image/jpeg',
    );
    return UploadTestResult(
      width: _int(json, 'width'),
      height: _int(json, 'height'),
      bytes: _int(json, 'bytes'),
      sha256: _string(json, 'sha256'),
    );
  }
}
