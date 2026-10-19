// The booth's delivery queue (AC-0902, AC-0904, AC-0906, AC-0908,
// AC-0915, AC-0916, AC-0917) over the real database and a stand-in for
// the service: requests are stored before anything is sent, only the
// finished photo and its preview are uploaded, numbers leave the booth
// once handed over, offline requests wait (or not) as the event says,
// expire after 24 hours, and survive a restart.
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/delivery/delivery_service.dart';
import 'package:porcelain_photo_booth/domain/delivery/consent.dart';
import 'package:porcelain_photo_booth/domain/delivery/delivery_intent.dart';
import 'package:porcelain_photo_booth/domain/delivery/delivery_settings.dart';
import 'package:porcelain_photo_booth/domain/delivery/phone_number.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/repositories/session_repository.dart';
import 'package:porcelain_photo_booth/domain/services/delivery_api.dart';
import 'package:porcelain_photo_booth/domain/services/finished_photos.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_delivery_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_event_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_gallery_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_session_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_template_catalog.dart';

import '../support/fake_delivery.dart';
import '../support/fakes.dart';
import '../support/gallery_seed.dart';
import '../support/seed.dart';
import '../support/test_database.dart';

/// Finished photos as the gallery seed wrote them (in memory).
final class SeededFinishedPhotos implements FinishedPhotos {
  final reads = <String>[];

  /// The files on the tablet were damaged.
  var damaged = false;

  @override
  Future<Uint8List> read({
    required String relativePath,
    required String sha256,
  }) async {
    reads.add(relativePath);
    if (damaged) throw const FinishedPhotoUnreadable('checksum');
    if (crypto.sha256.convert(finishedStandIn).toString() != sha256) {
      throw const FinishedPhotoUnreadable('checksum');
    }
    return finishedStandIn;
  }
}

void main() {
  late BoothDatabase db;
  late FakeClock clock;
  late FakeDeliveryApi api;
  late MemoryDeliverySecrets secrets;
  late FakePreviewMaker previews;
  late DriftDeliveryRepository repository;
  late SeededFinishedPhotos finished;
  late BoothEvent event;
  late SessionOutput output;
  final phone = parseUsPhone('(212) 555-0147').number!;
  const consent = ConsentText(brand: 'Porcelain Booth', linkDays: 7);

  DeliveryService service() => DeliveryService(
    repository: repository,
    api: api,
    secrets: secrets,
    previews: previews,
    sessions: DriftSessionRepository(db, clock: clock),
    finished: finished,
    events: DriftEventRepository(db),
    clock: clock,
    ids: SequentialIds('10000000-0000-4000-8000'),
    random: () => 0.5,
  );

  Future<DeliveryService> paired() async {
    final delivery = service();
    addTearDown(delivery.dispose);
    await delivery.pair(
      baseUrl: FakeDeliveryApi.baseUrl,
      code: 'k7qm 4xht 9zpa',
      boothName: 'Front entrance',
    );
    return delivery;
  }

  Future<DeliveryIntent> submit(
    DeliveryService delivery, {
    EventDeliverySettings? settings,
  }) async {
    final intent = await delivery.submit(
      event: event.copyWith(
        delivery: settings ?? const EventDeliverySettings(enabled: true),
      ),
      output: output,
      phone: phone,
      consent: consent,
      acceptedAtUtc: clock.now(),
    );
    await delivery.processDue();
    return (await repository.find(intent.id))!;
  }

  setUp(() async {
    clock = FakeClock(DateTime.utc(2026, 11, 14, 18, 30));
    db = memoryDatabase(clock: clock);
    addTearDown(db.close);
    await seedEvents(db, clock: clock);
    await seedGallery(
      db,
      count: 2,
      outcome: (_) => SeededOutcome.completed,
      outputBytes: finishedStandIn,
    );
    api = FakeDeliveryApi();
    secrets = MemoryDeliverySecrets();
    previews = FakePreviewMaker();
    repository = DriftDeliveryRepository(db);
    finished = SeededFinishedPhotos();
    event = (await DriftEventRepository(db).findById(SeedIds.active))!;
    output = (await DriftSessionRepository(
      db,
      clock: clock,
    ).outputs(GalleryIds.session(1))).single;
  });

  test('pairing keeps the credential in secure storage and the readiness '
      'snapshot in the database', () async {
    final delivery = await paired();
    expect(secrets.credential, startsWith('credential-'));
    final pairing = (await repository.pairing())!;
    expect(pairing.boothName, 'Front entrance');
    expect(pairing.capabilities!.ready, isTrue);
    expect(
      pairing.capabilities!.privacyUrl,
      'https://photos.example.test/privacy',
    );
    expect(pairing.checkedAtUtc, clock.now());
    final stored = await db.select(db.deliveryPairings).getSingle();
    expect(stored.capabilitiesJson, isNot(contains('credential')));

    await expectLater(
      service().pair(
        baseUrl: FakeDeliveryApi.baseUrl,
        code: 'WRONG-CODE-000',
        boothName: 'x',
      ),
      throwsA(isA<DeliveryApiException>()),
    );
    await delivery.unpair();
    expect(secrets.credential, isNull);
    expect(await repository.pairing(), isNull);
  });

  test('a request is handed over: the finished photo and its preview only, '
      'then the number leaves the booth (AC-0904, AC-0908)', () async {
    final delivery = await paired();
    final intent = await submit(delivery);

    final request = api.requests.single;
    expect(request.phoneE164, '+12125550147');
    expect(request.outputId, output.id);
    expect(request.sessionId, output.sessionId);
    expect(request.eventName, event.title);
    expect(request.linkDays, 7);
    expect(request.consent.textVersion, 'pd-consent-1');
    expect(request.consent.textDigest, consent.digest);
    expect(request.consent.acceptedAtUtc, clock.now());
    expect(request.consent.sourceScreen, 'S31');

    final remote = api.deliveries.values.single;
    final (finalImage, preview) = remote.declared!;
    expect(finalImage.sha256, output.sha256);
    expect(finalImage.bytes, finishedStandIn.length);
    expect(finalImage.width, output.widthPx);
    expect(preview.format, 'jpeg');
    expect(api.uploads.map((u) => u.$2), ['final', 'preview']);
    expect(api.uploads.first.$3, finishedStandIn.length);
    expect(finished.reads, [output.relativePath], reason: 'never an original');

    expect(intent.state, DeliveryIntentState.handedOver);
    expect(intent.phase, DeliveryPhase.submitted);
    expect(intent.remoteJobId, remote.id);
    expect(intent.phoneStored, isFalse);
    expect(secrets.phones, isEmpty, reason: 'the service has it now');
    expect(intent.history.map((step) => step.phase), [
      DeliveryPhase.queuedLocally,
      DeliveryPhase.submitted,
    ]);
    // Nothing readable about the number stays on the booth.
    final row = await db.select(db.deliveryIntents).getSingle();
    expect(row.toString(), isNot(contains('2125550147')));
    expect(row.phoneLast4, '0147');
  });

  test('accepted is not delivered; delivered only when the service says so '
      '(AC-0913)', () async {
    final delivery = await paired();
    final intent = await submit(delivery);
    expect(intent.phase, DeliveryPhase.submitted);
    api.advance(intent.remoteJobId!, RemoteDeliveryStatus.sent);
    await delivery.refreshNow(intent.id);
    expect((await repository.find(intent.id))!.phase, DeliveryPhase.sent);
    api.advance(intent.remoteJobId!, RemoteDeliveryStatus.delivered);
    await delivery.refreshNow(intent.id);
    final done = (await repository.find(intent.id))!;
    expect(done.phase, DeliveryPhase.delivered);
    expect(done.finished, isTrue);
    expect(done.history.map((step) => step.phase), [
      DeliveryPhase.queuedLocally,
      DeliveryPhase.submitted,
      DeliveryPhase.sent,
      DeliveryPhase.delivered,
    ]);
  });

  test('a delivery the service no longer holds keeps its last report and '
      'claims nothing more (AC-0913)', () async {
    final delivery = await paired();
    final intent = await submit(delivery);
    api.advance(intent.remoteJobId!, RemoteDeliveryStatus.sent);
    await delivery.refreshNow(intent.id);
    api.deliveries.clear();
    await delivery.refreshNow(intent.id);
    final gone = (await repository.find(intent.id))!;
    expect(gone.finished, isTrue);
    expect(gone.phase, DeliveryPhase.sent, reason: 'not expired, not failed');
    expect(gone.gone, isTrue);
    expect(gone.history.last.code, DeliveryIntent.goneCode);
    await expectLater(
      delivery.revoke(intent.id),
      throwsA(isA<DeliveryActionFailure>()),
    );
  });

  test('offline with waiting allowed: kept, retried with backoff, sent when '
      'the connection returns (AC-0906)', () async {
    final delivery = await paired();
    api.offline = true;
    final waiting = await submit(delivery);
    expect(waiting.state, DeliveryIntentState.queued);
    expect(waiting.phase, DeliveryPhase.queuedLocally);
    expect(waiting.lastErrorCode, 'OFFLINE');
    expect(waiting.retryAtUtc, clock.now().add(const Duration(seconds: 23)));
    expect(secrets.phones.keys, [waiting.id], reason: 'kept until handed over');
    expect(delivery.link.offline, isTrue);
    expect(
      await delivery.offerFor(const EventDeliverySettings(enabled: true)),
      DeliveryOffer.queued,
    );

    api.offline = false;
    await delivery.processDue();
    expect(api.requests, isEmpty, reason: 'not before its retry time');
    clock.advance(const Duration(seconds: 30));
    await delivery.processDue();
    final sent = (await repository.find(waiting.id))!;
    expect(sent.phase, DeliveryPhase.submitted);
    expect(sent.attemptCount, 2);
    expect(secrets.phones, isEmpty);
    expect(delivery.link.offline, isFalse);
  });

  test('offline without waiting allowed: not kept, number erased', () async {
    final delivery = await paired();
    api.offline = true;
    final dropped = await submit(
      delivery,
      settings: const EventDeliverySettings(enabled: true, offlineQueue: false),
    );
    expect(dropped.finished, isTrue);
    expect(dropped.phase, DeliveryPhase.failed);
    expect(dropped.lastErrorCode, 'OFFLINE');
    expect(secrets.phones, isEmpty);
    expect(
      await delivery.offerFor(
        const EventDeliverySettings(enabled: true, offlineQueue: false),
      ),
      DeliveryOffer.unavailable,
    );
  });

  test('a refusal ends the request and erases the number', () async {
    final delivery = await paired();
    api.refuseCreateWith = 'RECIPIENT_OPTED_OUT';
    final refused = await submit(delivery);
    expect(refused.phase, DeliveryPhase.failed);
    expect(refused.lastErrorCode, 'RECIPIENT_OPTED_OUT');
    expect(secrets.phones, isEmpty);
    expect(api.uploads, isEmpty);
  });

  test('a request never handed over expires 24 hours after consent '
      '(AC-0906)', () async {
    final delivery = await paired();
    api.offline = true;
    final waiting = await submit(delivery);
    clock.advance(const Duration(hours: 23, minutes: 59));
    await delivery.processDue();
    expect((await repository.find(waiting.id))!.finished, isFalse);
    clock.advance(const Duration(minutes: 2));
    await delivery.processDue();
    final expired = (await repository.find(waiting.id))!;
    expect(expired.phase, DeliveryPhase.expired);
    expect(expired.lastErrorCode, 'QUEUE_WINDOW_ENDED');
    expect(secrets.phones, isEmpty);
    api.offline = false;
    clock.advance(const Duration(hours: 1));
    await delivery.processDue();
    expect(api.requests, isEmpty, reason: 'never sent late');
  });

  test(
    'requests survive a restart and are handed over by the next run',
    () async {
      final first = await paired();
      api.offline = true;
      final waiting = await submit(first);
      first.dispose();

      api.offline = false;
      clock.advance(const Duration(minutes: 1));
      final restarted = service();
      addTearDown(restarted.dispose);
      await restarted.processDue();
      final sent = (await repository.find(waiting.id))!;
      expect(sent.phase, DeliveryPhase.submitted);
      expect(api.requests, hasLength(1));
    },
  );

  test('a finished photo that cannot be read or previewed ends the request '
      'plainly: no upload, no text, the number erased (AC-0916)', () async {
    final delivery = await paired();
    finished.damaged = true;
    final unreadable = await submit(delivery);
    expect(unreadable.phase, DeliveryPhase.failed);
    expect(unreadable.lastErrorCode, 'PHOTO_UNREADABLE');
    finished.damaged = false;
    previews.failing = true;
    final noPreview = await submit(delivery);
    expect(noPreview.phase, DeliveryPhase.failed);
    expect(noPreview.lastErrorCode, 'PREVIEW_FAILED');
    expect(api.uploads, isEmpty);
    expect(api.calls, isNot(contains('commit')));
    expect(secrets.phones, isEmpty);
    expect(
      api.deliveries.values.map((remote) => remote.status),
      everyElement(RemoteDeliveryStatus.canceled),
      reason: 'the service is told to drop what it created',
    );
  });

  test('a lost answer never sends twice: the same request is followed '
      '(AC-0915)', () async {
    final delivery = await paired();
    final intent = await submit(delivery);
    final replay = await api.create(
      FakeDeliveryApi.baseUrl,
      'token',
      api.requests.single,
    );
    expect(replay.id, intent.remoteJobId, reason: 'idempotent at the service');
    expect(api.deliveries, hasLength(1));
  });

  test(
    'when the service says the request exists, the booth follows it',
    () async {
      final delivery = await paired();
      api.offline = true;
      final waiting = await submit(delivery);
      api.offline = false;
      // As if a create reached the service but its answer was lost.
      final existing = await api.create(
        FakeDeliveryApi.baseUrl,
        'token',
        CreateDeliveryRequest(
          eventId: event.id,
          eventName: event.title,
          sessionId: output.sessionId,
          outputId: output.id,
          phoneE164: '+12125550147',
          idempotencyKey: 'other-key-0000000000',
          linkDays: 7,
          eventSendLimit: 200,
          consent: ConsentReceipt(
            textVersion: ConsentText.version,
            textDigest: consent.digest,
            acceptedAtUtc: clock.now(),
          ),
        ),
      );
      api.refuseCreateWith = null;
      final duplicate = _DuplicateOnce(api, existing.id);
      final delivery2 = DeliveryService(
        repository: repository,
        api: duplicate,
        secrets: secrets,
        previews: previews,
        sessions: DriftSessionRepository(db, clock: clock),
        finished: finished,
        events: DriftEventRepository(db),
        clock: clock,
        ids: SequentialIds('20000000-0000-4000-8000'),
        random: () => 0.5,
      );
      addTearDown(delivery2.dispose);
      clock.advance(const Duration(minutes: 1));
      await delivery2.processDue();
      final followed = (await repository.find(waiting.id))!;
      expect(followed.remoteJobId, existing.id);
      expect(api.deliveries, hasLength(1));
    },
  );

  test('operators can cancel a waiting request; a sent text cannot be '
      'unsent', () async {
    final delivery = await paired();
    api.offline = true;
    final waiting = await submit(delivery);
    await delivery.cancel(waiting.id);
    final canceled = (await repository.find(waiting.id))!;
    expect(canceled.phase, DeliveryPhase.canceled);
    expect(secrets.phones, isEmpty);

    api.offline = false;
    final sent = await submit(delivery);
    await expectLater(
      delivery.cancel(sent.id),
      throwsA(
        isA<DeliveryActionFailure>().having(
          (f) => f.code,
          'code',
          'DELIVERY_ALREADY_SUBMITTED',
        ),
      ),
    );
    await delivery.revoke(sent.id);
    expect(api.deliveries[sent.remoteJobId]!.linkRevoked, isTrue);
  });

  test('deleting a session revokes its texted copy when online and leaves '
      'no number behind (AC-0917)', () async {
    final delivery = await paired();
    final sent = await submit(delivery);
    api.offline = true;
    final waiting = await submit(delivery);
    expect(secrets.phones.keys, [waiting.id]);

    await DriftGalleryRepository(
      db,
      clock: clock,
      templates: DriftTemplateCatalog(db),
    ).deleteSessions([output.sessionId]);
    expect(await repository.forSession(output.sessionId), isEmpty);
    expect(await repository.pendingRevocations(), [sent.remoteJobId]);

    await delivery.processDue();
    expect(secrets.phones, isEmpty, reason: 'swept even while offline');
    expect(await repository.pendingRevocations(), hasLength(1));

    api.offline = false;
    await delivery.processDue();
    expect(api.deliveries[sent.remoteJobId]!.linkRevoked, isTrue);
    expect(await repository.pendingRevocations(), isEmpty);
  });

  test('what guests are offered follows the event, the pairing and the '
      'service (AC-0901)', () async {
    final delivery = service();
    addTearDown(delivery.dispose);
    const on = EventDeliverySettings(enabled: true);
    expect(
      await delivery.offerFor(const EventDeliverySettings()),
      DeliveryOffer.off,
    );
    expect(await delivery.offerFor(on), DeliveryOffer.unavailable);
    api.ready = false;
    api.reasons = const ['REGISTRATION_NOT_ATTESTED'];
    await delivery.pair(
      baseUrl: FakeDeliveryApi.baseUrl,
      code: FakeDeliveryApi.pairingCode,
      boothName: 'Front entrance',
    );
    expect(await delivery.offerFor(on), DeliveryOffer.notReady);
    api.ready = true;
    await delivery.check();
    expect(await delivery.offerFor(on), DeliveryOffer.online);
    await delivery.setPaused(true);
    expect(await delivery.offerFor(on), DeliveryOffer.unavailable);
    await delivery.setPaused(false);
    clock.advance(const Duration(hours: 25));
    expect(
      await delivery.offerFor(on),
      DeliveryOffer.unavailable,
      reason: 'a day-old readiness answer is not trusted',
    );
  });

  test('a paused booth keeps requests waiting without sending', () async {
    final delivery = await paired();
    await delivery.setPaused(true);
    final waiting = await submit(delivery);
    expect(waiting.state, DeliveryIntentState.queued);
    expect(api.requests, isEmpty);
    await delivery.setPaused(false);
    await delivery.processDue();
    expect((await repository.find(waiting.id))!.phase, DeliveryPhase.submitted);
  });

  test('if secure storage fails, nothing is kept', () async {
    final delivery = await paired();
    secrets.failing = true;
    await expectLater(
      delivery.submit(
        event: event.copyWith(
          delivery: const EventDeliverySettings(enabled: true),
        ),
        output: output,
        phone: phone,
        consent: consent,
        acceptedAtUtc: clock.now(),
      ),
      throwsA(isA<DeliveryActionFailure>()),
    );
    expect(await repository.open(), isEmpty);
  });
}

/// The service answering a create with DUPLICATE_REQUEST once.
final class _DuplicateOnce implements DeliveryApi {
  _DuplicateOnce(this._api, this._existing);

  final FakeDeliveryApi _api;
  final String _existing;
  var _done = false;

  @override
  Future<RemoteDelivery> create(Uri b, String t, CreateDeliveryRequest r) {
    if (!_done) {
      _done = true;
      throw DeliveryApiException(
        DeliveryFailureKind.refused,
        'DUPLICATE_REQUEST',
        deliveryId: _existing,
      );
    }
    return _api.create(b, t, r);
  }

  @override
  Future<PairingResult> pair(
    Uri b, {
    required String code,
    required String boothName,
  }) => _api.pair(b, code: code, boothName: boothName);

  @override
  Future<AccessToken> accessToken(Uri b, String c) => _api.accessToken(b, c);

  @override
  Future<String> rotateCredential(Uri b, String t) =>
      _api.rotateCredential(b, t);

  @override
  Future<DeliveryCapabilities> capabilities(Uri b, String t) =>
      _api.capabilities(b, t);

  @override
  Future<List<UploadGrant>> uploadInit(
    Uri b,
    String t,
    String id, {
    required UploadDeclaration finalImage,
    required UploadDeclaration preview,
  }) => _api.uploadInit(b, t, id, finalImage: finalImage, preview: preview);

  @override
  Future<void> upload(UploadGrant grant, Uint8List bytes) =>
      _api.upload(grant, bytes);

  @override
  Future<RemoteDelivery> commit(Uri b, String t, String id) =>
      _api.commit(b, t, id);

  @override
  Future<RemoteDelivery> status(Uri b, String t, String id) =>
      _api.status(b, t, id);

  @override
  Future<RemoteDelivery> cancel(Uri b, String t, String id) =>
      _api.cancel(b, t, id);

  @override
  Future<RemoteDelivery> revoke(Uri b, String t, String id) =>
      _api.revoke(b, t, id);

  @override
  Future<RemoteDelivery> resolve(
    Uri b,
    String t,
    String id, {
    required String action,
    bool acknowledgeDuplicateRisk = false,
  }) => _api.resolve(
    b,
    t,
    id,
    action: action,
    acknowledgeDuplicateRisk: acknowledgeDuplicateRisk,
  );

  @override
  Future<UploadTestResult> uploadTest(Uri b, String t, Uint8List jpeg) =>
      _api.uploadTest(b, t, jpeg);
}
