// The booth's delivery client against the real backend (AC-0904, AC-0908,
// AC-0909, AC-0913): pairing, readiness, a consented request handed over
// with a real finished photo and preview, the service's checks of both
// images, the message the provider receives (and its fetch of the
// preview), and status reports, end to end on this machine.
//
// Runs only under tool/delivery_contract.sh, which starts the backend
// (backend/tool/serve_local.ts: a real Postgres, the stand-in for Twilio,
// memory storage) and passes its address in DELIVERY_CONTRACT. Nothing
// leaves this machine and no real text is sent.
@Tags(['contract'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/delivery/delivery_service.dart';
import 'package:porcelain_photo_booth/domain/delivery/consent.dart';
import 'package:porcelain_photo_booth/domain/delivery/delivery_intent.dart';
import 'package:porcelain_photo_booth/domain/delivery/delivery_settings.dart';
import 'package:porcelain_photo_booth/domain/delivery/phone_number.dart';
import 'package:porcelain_photo_booth/domain/repositories/session_repository.dart';
import 'package:porcelain_photo_booth/domain/services/finished_photos.dart';
import 'package:porcelain_photo_booth/infrastructure/codecs/jpeg_encoder.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_delivery_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_event_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_session_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/delivery/http_delivery_api.dart';
import 'package:porcelain_photo_booth/infrastructure/delivery/jpeg_preview_maker.dart';

import '../support/fake_delivery.dart';
import '../support/fakes.dart';
import '../support/gallery_seed.dart';
import '../support/seed.dart';
import '../support/test_database.dart';

final class _RealHttp extends HttpOverrides {}

/// The finished photo, as the session recorded it.
final class _Finished implements FinishedPhotos {
  _Finished(this.bytes);

  final Uint8List bytes;

  @override
  Future<Uint8List> read({
    required String relativePath,
    required String sha256,
  }) async => bytes;
}

void main() {
  final config = Platform.environment['DELIVERY_CONTRACT'];
  final skip = config == null
      ? 'Runs under tool/delivery_contract.sh with the backend started'
      : null;

  test(
    'a consented request reaches the real service and its provider '
    'stand-in, verified at every step',
    () async {
      HttpOverrides.global = _RealHttp();
      final settings = jsonDecode(config!) as Map<String, Object?>;
      final baseUrl = Uri.parse(settings['baseUrl']! as String);
      final control = Uri.parse(settings['controlUrl']! as String);
      final http = HttpClient();
      addTearDown(http.close);
      Future<Object?> controlCall(
        String method,
        String path, [
        Object? body,
      ]) async {
        final request = await http.openUrl(method, control.resolve(path));
        if (body != null) {
          request.headers.contentType = ContentType.json;
          request.write(jsonEncode(body));
        }
        final response = await request.close();
        final text = await response.transform(utf8.decoder).join();
        return text.isEmpty ? null : jsonDecode(text);
      }

      // A real 1200 x 1800 finished photo for a seeded session.
      final pixels = Uint8List(1200 * 1800 * 4);
      for (var i = 0; i < pixels.length; i += 4) {
        final y = i ~/ (1200 * 4);
        pixels
          ..[i] = 240
          ..[i + 1] = 230 - y ~/ 20
          ..[i + 2] = 210
          ..[i + 3] = 255;
      }
      final finished = encodeJpeg(
        pixels,
        width: 1200,
        height: 1800,
        quality: 88,
        dpi: 300,
      );
      final clock = FakeClock(DateTime.now().toUtc());
      final db = memoryDatabase(clock: clock);
      addTearDown(db.close);
      await seedEvents(db, clock: clock);
      await seedGallery(
        db,
        count: 1,
        outcome: (_) => SeededOutcome.completed,
        outputBytes: finished,
        firstStart: clock.now().subtract(const Duration(minutes: 2)),
      );
      final sessions = DriftSessionRepository(db, clock: clock);
      final SessionOutput output = (await sessions.outputs(
        GalleryIds.session(1),
      )).single;
      expect(output.sha256, crypto.sha256.convert(finished).toString());
      // The seed records 1200 x 1800, as the template's page.
      expect((output.widthPx, output.heightPx), (1200, 1800));

      final repository = DriftDeliveryRepository(db);
      final secrets = MemoryDeliverySecrets();
      final delivery = DeliveryService(
        repository: repository,
        api: HttpDeliveryApi(),
        secrets: secrets,
        previews: const JpegPreviewMaker(),
        sessions: sessions,
        finished: _Finished(finished),
        events: DriftEventRepository(db),
        clock: clock,
        ids: SequentialIds('30000000-0000-4000-8000'),
      );
      addTearDown(delivery.dispose);

      // Pairing with the administrator's code; the service reports ready.
      final pairing = await delivery.pair(
        baseUrl: baseUrl,
        code: settings['pairingCode']! as String,
        boothName: 'Contract test booth',
      );
      expect(secrets.credential, isNotNull);
      expect(pairing.capabilities!.ready, isTrue);
      expect(pairing.capabilities!.regions, ['US']);
      expect(pairing.capabilities!.brandName, 'Porcelain Booth');

      final event = (await DriftEventRepository(db).findById(SeedIds.active))!
          .copyWith(delivery: const EventDeliverySettings(enabled: true));
      expect(await delivery.offerFor(event.delivery), DeliveryOffer.online);
      final consent = ConsentText(
        brand: pairing.capabilities!.brandName,
        linkDays: 7,
      );
      final submitted = await delivery.submit(
        event: event,
        output: output,
        phone: parseUsPhone('(212) 555-0147').number!,
        consent: consent,
        acceptedAtUtc: clock.now(),
      );
      await delivery.processDue();
      var intent = (await repository.find(submitted.id))!;
      expect(intent.lastErrorCode, isNull);
      expect(
        intent.phase,
        DeliveryPhase.submitted,
        reason: 'accepted, not delivered',
      );
      expect(intent.remoteJobId, isNotNull);
      expect(secrets.phones, isEmpty, reason: 'the number left the booth');

      // What the provider stand-in received.
      final messages =
          (await controlCall('GET', '/messages'))! as List<Object?>;
      final message = messages.single! as Map<String, Object?>;
      expect(message['to'], '+12125550147');
      final body = message['body']! as String;
      expect(body, startsWith('Porcelain Booth: Your photos from '));
      expect(body, contains('${baseUrl.toString()}/p/'));
      expect(body, endsWith('Reply STOP to opt out, HELP for help.'));
      final media = message['media']! as Map<String, Object?>;
      expect(media['head'], 200);
      expect(media['get'], 200);
      expect(media['contentType'], 'image/jpeg');
      expect(media['bytes'] as int, lessThanOrEqualTo(400 * 1024));
      expect(message['mediaUrl'], isNot(contains('/p/')));

      // The guest's link serves the exact finished photo.
      final link = RegExp(r'https?://\S+/p/[A-Za-z0-9_-]{43}')
          .firstMatch(body)![0]!;
      final download = await (await http.getUrl(Uri.parse('$link/download')))
          .close();
      final bytes = await download.fold<List<int>>([], (a, b) => a..addAll(b));
      expect(download.statusCode, 200);
      expect(crypto.sha256.convert(bytes).toString(), output.sha256);

      // Status reports: sent, then delivered.
      await controlCall('POST', '/report', {
        'sid': message['sid'],
        'status': 'sent',
      });
      await delivery.refreshNow(intent.id);
      intent = (await repository.find(intent.id))!;
      expect(intent.phase, DeliveryPhase.sent);
      await controlCall('POST', '/report', {
        'sid': message['sid'],
        'status': 'delivered',
      });
      await delivery.refreshNow(intent.id);
      intent = (await repository.find(intent.id))!;
      expect(intent.phase, DeliveryPhase.delivered);
      expect(intent.finished, isTrue);

      // Operator revoke: the link stops working.
      await delivery.revoke(intent.id);
      final gone = await (await http.getUrl(Uri.parse(link))).close();
      await gone.drain<void>();
      expect(gone.statusCode, 410);
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
