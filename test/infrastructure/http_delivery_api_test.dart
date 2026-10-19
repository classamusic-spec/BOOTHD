// The booth's client for the delivery service (AC-0907, AC-0916) against
// a local HTTP server: the requests it sends, and how every kind of answer
// becomes a decision (refused), a wait (transient) or re-authentication.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/delivery/consent.dart';
import 'package:porcelain_photo_booth/domain/delivery/delivery_intent.dart';
import 'package:porcelain_photo_booth/domain/services/delivery_api.dart';
import 'package:porcelain_photo_booth/infrastructure/delivery/http_delivery_api.dart';

final class Seen {
  Seen(this.method, this.path, this.headers, this.body);

  final String method;
  final String path;
  final HttpHeaders headers;
  final List<int> body;

  Map<String, Object?> get json =>
      jsonDecode(utf8.decode(body)) as Map<String, Object?>;
}

/// The real network: the test binding answers every request with 400.
final class _RealHttp extends HttpOverrides {}

void main() {
  HttpOverrides? previous;
  setUpAll(() {
    previous = HttpOverrides.current;
    HttpOverrides.global = _RealHttp();
  });
  tearDownAll(() => HttpOverrides.global = previous);

  late HttpServer server;
  late Uri base;
  final seen = <Seen>[];
  late Future<void> Function(HttpRequest request) respond;

  setUp(() async {
    seen.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = Uri.parse('http://127.0.0.1:${server.port}/functions/v1/delivery');
    server.listen((request) async {
      final body = await request.fold<List<int>>([], (a, b) => a..addAll(b));
      seen.add(Seen(request.method, request.uri.path, request.headers, body));
      await respond(request);
    });
  });

  tearDown(() => server.close(force: true));

  Future<void> json(HttpRequest request, int status, Object body) async {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
    await request.response.close();
  }

  final delivery = {
    'id': '33333333-3333-4333-8333-333333333333',
    'state': 'provider_accepted',
    'status': 'submitted',
    'recipientLast4': '0147',
    'failureCode': null,
    'reviewReason': null,
    'updatedAt': '2026-11-14T18:12:00.000Z',
    'linkExpiresAt': '2026-11-21T18:12:00.000Z',
    'linkRevokedAt': null,
    'hostedFilesDeleted': false,
    'history': [
      {
        'state': 'created',
        'status': 'queued',
        'code': null,
        'at': '2026-11-14T18:11:30.000Z',
      },
      {
        'state': 'provider_accepted',
        'status': 'submitted',
        'code': null,
        'at': '2026-11-14T18:12:00.000Z',
      },
    ],
  };

  test('only https, or http on this machine, is used', () async {
    final api = HttpDeliveryApi();
    expect(
      HttpDeliveryApi.acceptable(Uri.parse('https://photos.example.test')),
      isTrue,
    );
    expect(
      HttpDeliveryApi.acceptable(Uri.parse('http://photos.example.test')),
      isFalse,
    );
    expect(
      HttpDeliveryApi.acceptable(Uri.parse('http://127.0.0.1:8080')),
      isTrue,
    );
    expect(
      HttpDeliveryApi.acceptable(
        Uri.parse('https://user:pw@photos.example.test'),
      ),
      isFalse,
    );
    expect(
      HttpDeliveryApi.acceptable(Uri.parse('https://photos.example.test?x=1')),
      isFalse,
    );
    await expectLater(
      api.pair(
        Uri.parse('http://photos.example.test'),
        code: 'x',
        boothName: 'y',
      ),
      throwsA(
        isA<DeliveryApiException>().having(
          (e) => e.code,
          'code',
          'SERVICE_ADDRESS_INVALID',
        ),
      ),
    );
  });

  test('requests carry the documented shapes under the service path', () async {
    respond = (request) async {
      switch (request.uri.path) {
        case '/functions/v1/delivery/v1/booths/pair':
          await json(request, 201, {
            'boothId': 'b2000000-0000-4000-8000-000000000001',
            'boothName': 'Front entrance',
            'credential': 'c' * 43,
            'brandName': 'Porcelain Booth',
          });
        case '/functions/v1/delivery/v1/booths/token':
          await json(request, 200, {
            'accessToken': 'a' * 43,
            'expiresAt': '2026-11-14T18:15:00.000Z',
            'boothId': 'b2000000-0000-4000-8000-000000000001',
          });
        case '/functions/v1/delivery/v1/deliveries':
          await json(request, 201, delivery);
        default:
          await json(request, 404, {
            'error': {'code': 'NOT_FOUND'},
          });
      }
    };
    final api = HttpDeliveryApi();
    final paired = await api.pair(
      base,
      code: 'K7QM-4XHT-9ZPA',
      boothName: 'Front entrance',
    );
    expect(paired.credential, 'c' * 43);
    expect(seen.last.json, {
      'code': 'K7QM-4XHT-9ZPA',
      'boothName': 'Front entrance',
    });
    expect(seen.last.headers.value(HttpHeaders.authorizationHeader), isNull);

    final token = await api.accessToken(base, paired.credential);
    expect(
      seen.last.headers.value(HttpHeaders.authorizationHeader),
      'Bearer ${'c' * 43}',
    );
    expect(token.expiresAtUtc, DateTime.utc(2026, 11, 14, 18, 15));

    const consent = ConsentText(brand: 'Porcelain Booth', linkDays: 7);
    final created = await api.create(
      base,
      token.token,
      CreateDeliveryRequest(
        eventId: '11111111-1111-4111-8111-111111111111',
        eventName: 'Garden Wedding',
        sessionId: '22222222-2222-4222-8222-222222222222',
        outputId: '33333333-3333-4333-8333-333333333333',
        phoneE164: '+12125550147',
        idempotencyKey: '44444444-4444-4444-8444-444444444444',
        linkDays: 7,
        eventSendLimit: 200,
        consent: ConsentReceipt(
          textVersion: ConsentText.version,
          textDigest: consent.digest,
          acceptedAtUtc: DateTime.utc(2026, 11, 14, 18, 11, 30),
        ),
      ),
    );
    final body = seen.last.json;
    expect(seen.last.method, 'POST');
    expect(
      seen.last.headers.value(HttpHeaders.authorizationHeader),
      'Bearer ${'a' * 43}',
    );
    expect(body['phone'], '+12125550147');
    expect(body['idempotencyKey'], '44444444-4444-4444-8444-444444444444');
    expect(body['consent'], {
      'accepted': true,
      'textVersion': 'pd-consent-1',
      'textDigest': consent.digest,
      'acceptedAt': '2026-11-14T18:11:30.000Z',
      'locale': 'en-US',
      'sourceScreen': 'S31',
    });
    expect(created.status, RemoteDeliveryStatus.submitted);
    expect(created.recipientLast4, '0147');
    expect(created.linkExpiresAtUtc, DateTime.utc(2026, 11, 21, 18, 12));
    expect(created.history.map((step) => step.status), [
      RemoteDeliveryStatus.queued,
      RemoteDeliveryStatus.submitted,
    ]);
  });

  test(
    "the service's decisions are refusals; its trouble is transient",
    () async {
      final api = HttpDeliveryApi();
      Future<DeliveryApiException> failure(
        int status,
        Object body, {
        Map<String, String> headers = const {},
      }) async {
        respond = (request) async {
          headers.forEach(request.response.headers.set);
          await json(request, status, body);
        };
        try {
          await api.status(
            base,
            't' * 43,
            '33333333-3333-4333-8333-333333333333',
          );
        } on DeliveryApiException catch (error) {
          return error;
        }
        fail('expected a failure');
      }

      var error = await failure(403, {
        'error': {'code': 'RECIPIENT_OPTED_OUT'},
      });
      expect(
        (error.kind, error.code),
        (DeliveryFailureKind.refused, 'RECIPIENT_OPTED_OUT'),
      );
      error = await failure(409, {
        'error': {
          'code': 'SENDING_NOT_READY',
          'reasons': ['SENDING_DISABLED'],
        },
      });
      expect(error.reasons, ['SENDING_DISABLED']);
      error = await failure(409, {
        'error': {'code': 'DUPLICATE_REQUEST', 'deliveryId': '5' * 36},
      });
      expect(error.deliveryId, '5' * 36);
      error = await failure(429, {
        'error': {'code': 'EVENT_LIMIT'},
      });
      expect(error.kind, DeliveryFailureKind.refused);
      error = await failure(
        429,
        {
          'error': {'code': 'TOKEN_RATE_LIMITED'},
        },
        headers: {'retry-after': '30'},
      );
      expect(
        (error.kind, error.retryAfter),
        (DeliveryFailureKind.transient, const Duration(seconds: 30)),
      );
      error = await failure(401, {
        'error': {'code': 'ACCESS_TOKEN_INVALID'},
      });
      expect(error.kind, DeliveryFailureKind.unauthorized);
      error = await failure(500, {
        'error': {'code': 'INTERNAL'},
      });
      expect(
        (error.kind, error.code),
        (DeliveryFailureKind.transient, 'INTERNAL'),
      );
    },
  );

  test(
    'a captive portal or proxy page is never mistaken for an answer',
    () async {
      final api = HttpDeliveryApi();
      for (final status in [200, 302, 403, 511]) {
        respond = (request) async {
          request.response
            ..statusCode = status
            ..headers.contentType = ContentType.html
            ..write('<html><body>Sign in to Venue Wi-Fi</body></html>');
          await request.response.close();
        };
        await expectLater(
          api.capabilities(base, 't' * 43),
          throwsA(
            isA<DeliveryApiException>().having(
              (e) => e.kind,
              'kind',
              DeliveryFailureKind.transient,
            ),
          ),
          reason: 'status $status',
        );
      }
    },
  );

  test('no connection and no answer are transient', () async {
    final closed = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = closed.port;
    await closed.close();
    await expectLater(
      HttpDeliveryApi().capabilities(
        Uri.parse('http://127.0.0.1:$port'),
        't' * 43,
      ),
      throwsA(
        isA<DeliveryApiException>().having((e) => e.code, 'code', 'OFFLINE'),
      ),
    );
    respond = (request) async {
      await Future<void>.delayed(const Duration(seconds: 2));
      await json(request, 200, {});
    };
    await expectLater(
      HttpDeliveryApi(timeout: const Duration(milliseconds: 200))
          .capabilities(base, 't' * 43),
      throwsA(
        isA<DeliveryApiException>().having((e) => e.code, 'code', 'TIMEOUT'),
      ),
    );
  });

  test('images are uploaded only to the same service', () async {
    respond = (request) async {
      if (request.uri.path.endsWith('/upload-init')) {
        await json(request, 200, {
          'uploads': [
            {
              'kind': 'final',
              'method': 'PUT',
              'url':
                  'http://127.0.0.1:${server.port}/functions/v1/delivery/v1/uploads/${'f' * 43}',
              'contentType': 'image/jpeg',
              'bytes': 3,
              'expiresAt': '2026-11-14T18:30:00Z',
            },
            {
              'kind': 'preview',
              'method': 'PUT',
              'url': 'https://elsewhere.example.test/v1/uploads/${'p' * 43}',
              'contentType': 'image/jpeg',
              'bytes': 3,
              'expiresAt': '2026-11-14T18:30:00Z',
            },
          ],
        });
      } else {
        await json(request, 201, {'kind': 'final'});
      }
    };
    const declaration = UploadDeclaration(
      format: 'jpeg',
      bytes: 3,
      sha256: 'x',
      width: 1,
      height: 1,
    );
    final api = HttpDeliveryApi();
    await expectLater(
      api.uploadInit(
        base,
        't' * 43,
        '3' * 36,
        finalImage: declaration,
        preview: declaration,
      ),
      throwsA(
        isA<DeliveryApiException>().having(
          (e) => e.code,
          'code',
          'UPLOAD_URL_UNTRUSTED',
        ),
      ),
    );
    await api.upload(
      UploadGrant(
        kind: 'final',
        url: Uri.parse(
          'http://127.0.0.1:${server.port}/functions/v1/delivery/v1/uploads/${'f' * 43}',
        ),
        contentType: 'image/jpeg',
      ),
      Uint8List.fromList([1, 2, 3]),
    );
    expect(seen.last.method, 'PUT');
    expect(seen.last.body, [1, 2, 3]);
    expect(seen.last.headers.contentType?.mimeType, 'image/jpeg');
  });
}
