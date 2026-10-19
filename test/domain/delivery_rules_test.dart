// Phone delivery rules on the booth (AC-0903, AC-0904, AC-0906): number
// parsing shared with the backend, the consent text and its digest, the
// queue's retry and polling rules, and what operators are shown.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/delivery/consent.dart';
import 'package:porcelain_photo_booth/domain/delivery/delivery_intent.dart';
import 'package:porcelain_photo_booth/domain/delivery/delivery_policy.dart';
import 'package:porcelain_photo_booth/domain/delivery/delivery_settings.dart';
import 'package:porcelain_photo_booth/domain/delivery/phone_number.dart';
import 'package:porcelain_photo_booth/domain/services/delivery_api.dart';

DeliveryIntent intent({
  DeliveryIntentState state = DeliveryIntentState.queued,
  RemoteDeliveryStatus? remote,
  DeliveryPhase? outcome,
  DateTime? created,
}) {
  final at = created ?? DateTime.utc(2026, 11, 14, 18);
  return DeliveryIntent(
    id: '10000000-0000-4000-8000-000000000001',
    sessionId: 'c0000000-0000-4000-8000-000000000001',
    eventId: 'e0000000-0000-4000-8000-000000000002',
    outputId: 'd0000000-0000-4000-8000-000000000001',
    phoneLast4: '0147',
    phoneStored: true,
    consentTextVersion: ConsentText.version,
    consentTextDigest: 'a' * 64,
    consentAcceptedAtUtc: at,
    locale: 'en-US',
    linkDays: 7,
    sendLimit: 200,
    queueAllowed: true,
    idempotencyKey: '10000000-0000-4000-8000-000000000002',
    state: state,
    remoteStatus: remote,
    localOutcome: outcome,
    expiresAtUtc: at.add(DeliveryPolicy.queueWindow),
    createdAtUtc: at,
    updatedAtUtc: at,
  );
}

void main() {
  test('number parsing agrees with the backend on every shared vector', () {
    final vectors = jsonDecode(
      File('backend/test/fixtures/phone_cases.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final cases = (vectors['cases']! as List).cast<Map<String, Object?>>();
    expect(cases.length, greaterThanOrEqualTo(19));
    for (final vector in cases) {
      final parsed = parseUsPhone(vector['input']! as String);
      final e164 = vector['e164'] as String?;
      if (e164 != null) {
        expect(parsed.ok, isTrue, reason: '${vector['input']}');
        expect(parsed.number!.e164, e164);
        expect(parsed.number!.last4, vector['last4']);
      } else {
        expect(parsed.ok, isFalse, reason: '${vector['input']}');
        expect(
          parsed.problem,
          vector['problem'] == 'PHONE_INVALID'
              ? PhoneProblem.invalid
              : PhoneProblem.regionUnsupported,
          reason: '${vector['input']}',
        );
      }
    }
  });

  test('numbers are shown in full only to the guest who typed them', () {
    final number = parseUsPhone('2125550147').number!;
    expect(number.national, '(212) 555-0147');
    expect(number.masked, '•••-•••-0147');
    expect(number.toString(), isNot(contains('555')));
    expect(formatUsDigits(''), '');
    expect(formatUsDigits('21'), '(21');
    expect(formatUsDigits('2125'), '(212) 5');
    expect(formatUsDigits('2125550'), '(212) 555-0');
    expect(formatUsDigits('212555014799'), '(212) 555-0147');
  });

  test('the consent text names the sender, one text, the link life, STOP and '
      'HELP; its digest is of the exact words', () {
    const consent = ConsentText(brand: 'Porcelain Booth', linkDays: 7);
    expect(ConsentText.version, 'pd-consent-1');
    expect(
      consent.text,
      contains('one photo-delivery text from Porcelain Booth'),
    );
    expect(consent.text, contains('Reply STOP to opt out or HELP for help'));
    expect(consent.text, contains('expires after 7 days'));
    expect(consent.text, contains('Message and data rates may apply'));
    expect(consent.text.toLowerCase(), isNot(contains('marketing')));
    expect(
      consent.digest,
      sha256.convert(utf8.encode(consent.text)).toString(),
    );
    expect(
      const ConsentText(brand: 'Porcelain Booth', linkDays: 1).text,
      contains('expires after 1 day.'),
    );
    expect(
      const ConsentText(brand: 'Porcelain Booth', linkDays: 3).digest,
      isNot(consent.digest),
    );
    final receipt = ConsentReceipt(
      textVersion: ConsentText.version,
      textDigest: consent.digest,
      acceptedAtUtc: DateTime.utc(2026, 11, 14, 18, 11, 30),
    ).toJson();
    expect(receipt, {
      'accepted': true,
      'textVersion': 'pd-consent-1',
      'textDigest': consent.digest,
      'acceptedAt': '2026-11-14T18:11:30.000Z',
      'locale': 'en-US',
      'sourceScreen': 'S31',
    });
  });

  test('delivery is off for events by default (AC-0901)', () {
    const settings = EventDeliverySettings();
    expect(settings.enabled, isFalse);
    expect(settings.linkDays, 7);
    expect(settings.valid, isTrue);
    expect(settings.copyWith(linkDays: 31).valid, isFalse);
    expect(settings.copyWith(sendLimit: 0).valid, isFalse);
  });

  test('retries back off from 30 seconds to 15 minutes, with jitter', () {
    expect(DeliveryPolicy.retryDelay(1, 0), const Duration(seconds: 15));
    expect(DeliveryPolicy.retryDelay(1, 0.999), const Duration(seconds: 30));
    expect(DeliveryPolicy.retryDelay(3, 0.5), const Duration(seconds: 90));
    expect(DeliveryPolicy.retryDelay(20, 0.999), const Duration(seconds: 900));
    expect(DeliveryPolicy.queueWindow, const Duration(hours: 24));
  });

  test('failures that decide nothing wait; refusals end the request', () {
    DeliveryApiException error(DeliveryFailureKind kind, String code) =>
        DeliveryApiException(kind, code);
    expect(
      DeliveryPolicy.decide(error(DeliveryFailureKind.transient, 'OFFLINE')),
      FailureDecision.retryLater,
    );
    expect(
      DeliveryPolicy.decide(
        error(DeliveryFailureKind.unauthorized, 'CREDENTIAL_INVALID'),
      ),
      FailureDecision.retryLater,
    );
    for (final code in [
      'RECIPIENT_OPTED_OUT',
      'PHONE_REGION_UNSUPPORTED',
      'EVENT_LIMIT',
      'BUDGET_REACHED',
      'SENDING_NOT_READY',
      'UPLOAD_CHECKSUM_MISMATCH',
    ]) {
      expect(
        DeliveryPolicy.decide(error(DeliveryFailureKind.refused, code)),
        FailureDecision.fail,
        reason: code,
      );
    }
    expect(
      DeliveryPolicy.decide(
        error(DeliveryFailureKind.refused, 'CONSENT_EXPIRED'),
      ),
      FailureDecision.expire,
    );
  });

  test('status is asked for often while a guest may watch, then rarely, '
      'never once final', () {
    final start = DateTime.utc(2026, 11, 14, 18);
    final handed = intent(
      state: DeliveryIntentState.handedOver,
      remote: RemoteDeliveryStatus.submitted,
      created: start,
    );
    expect(
      DeliveryPolicy.pollInterval(
        handed,
        start.add(const Duration(minutes: 1)),
      ),
      const Duration(seconds: 4),
    );
    expect(
      DeliveryPolicy.pollInterval(
        handed,
        start.add(const Duration(minutes: 30)),
      ),
      const Duration(minutes: 1),
    );
    expect(
      DeliveryPolicy.pollInterval(handed, start.add(const Duration(hours: 5))),
      const Duration(minutes: 15),
    );
    expect(
      DeliveryPolicy.pollInterval(handed, start.add(const Duration(days: 3))),
      isNull,
    );
    expect(
      DeliveryPolicy.pollInterval(
        intent(
          state: DeliveryIntentState.finished,
          remote: RemoteDeliveryStatus.delivered,
        ),
        start,
      ),
      isNull,
    );
  });

  test('operators see accepted, sent and delivered as different things '
      '(AC-0913)', () {
    expect(intent().phase, DeliveryPhase.queuedLocally);
    expect(
      intent(state: DeliveryIntentState.handingOver).phase,
      DeliveryPhase.uploading,
    );
    final phases = {
      RemoteDeliveryStatus.submitting: DeliveryPhase.sending,
      RemoteDeliveryStatus.submitted: DeliveryPhase.submitted,
      RemoteDeliveryStatus.sent: DeliveryPhase.sent,
      RemoteDeliveryStatus.delivered: DeliveryPhase.delivered,
      RemoteDeliveryStatus.failed: DeliveryPhase.failed,
      RemoteDeliveryStatus.unknown: DeliveryPhase.unknown,
      RemoteDeliveryStatus.expired: DeliveryPhase.expired,
    };
    phases.forEach((remote, phase) {
      expect(
        intent(state: DeliveryIntentState.handedOver, remote: remote).phase,
        phase,
      );
    });
    expect(
      intent(
        state: DeliveryIntentState.finished,
        outcome: DeliveryPhase.expired,
      ).phase,
      DeliveryPhase.expired,
    );
    expect(RemoteDeliveryStatus.delivered.isFinal, isTrue);
    expect(RemoteDeliveryStatus.sent.isFinal, isFalse);
  });

  test('a history step that repeats the last phase is not added twice', () {
    final first = intent();
    final at = DateTime.utc(2026, 11, 14, 18, 1);
    final once = first.withStep(DeliveryStep(DeliveryPhase.uploading, at));
    expect(once, hasLength(1));
    final twice = first
        .copyWith(history: once, updatedAtUtc: at)
        .withStep(DeliveryStep(DeliveryPhase.uploading, at));
    expect(twice, hasLength(1));
    expect(DeliveryStep.fromJson(once.single.toJson()), once.single);
    expect(DeliveryStep.fromJson({'phase': 'nonsense'}), isNull);
  });
}
