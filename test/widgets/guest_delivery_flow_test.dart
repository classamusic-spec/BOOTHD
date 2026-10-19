// AC-0901 to AC-0906, AC-0914, AC-0916 and AC-0922 at the booth,
// end to end on the simulated camera and a stand-in for the delivery
// service: texting is offered only when the event, the pairing and the
// service allow it; nothing is stored without a valid number and the
// checked box; "No thanks" and the booth's own reset leave nothing behind;
// offline requests are told the truth; the number is never shown in full
// after it is sent; and guests can still never leave Booth Mode. In
// portrait and landscape at every tablet size. Real texts to real phones
// are BLOCKED (M09 device procedure); nothing here stands in for them.
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/routing/route_paths.dart';
import 'package:porcelain_photo_booth/domain/delivery/consent.dart';
import 'package:porcelain_photo_booth/domain/delivery/delivery_intent.dart';
import 'package:porcelain_photo_booth/domain/delivery/delivery_settings.dart';
import 'package:porcelain_photo_booth/features/booth/booth_copy.dart';
import 'package:porcelain_photo_booth/features/booth/booth_screen.dart';
import 'package:porcelain_photo_booth/features/booth/delivery_copy.dart';
import 'package:porcelain_photo_booth/features/booth/guest_finished.dart';
import 'package:porcelain_photo_booth/features/booth/guest_review.dart';
import 'package:porcelain_photo_booth/features/studio_shell/studio_shell.dart';

import '../support/app_harness.dart';
import '../support/fake_delivery.dart';
import '../support/fakes.dart';
import '../support/seed.dart';
import '../support/tablet_viewports.dart';
import 'guest_isolation_test.dart' show actionable, forbiddenWords;

/// 212-555-0147, typed on the booth keypad.
const _digits = '2125550147';

Future<TestBooth> _booth(
  WidgetTester tester, {
  TabletViewport viewport = TabletViewport.ipadPortrait,
  EventDeliverySettings delivery = const EventDeliverySettings(enabled: true),
  bool paired = true,
  bool ready = true,
  bool offline = false,
}) async {
  useViewport(tester, viewport);
  final clock = FakeClock();
  final api = FakeDeliveryApi(ready: ready)
    ..reasons = ready ? const [] : const ['REGISTRATION_NOT_ATTESTED'];
  final secrets = MemoryDeliverySecrets();
  final booth = await pumpApp(
    tester,
    startAs: StartAs.booth,
    boothEventId: SeedIds.active,
    clock: clock,
    delivery: api,
    secrets: secrets,
    seed: (db) async {
      await seedEvents(
        db,
        active: (event) => event.copyWith(delivery: delivery),
      );
      if (paired) await seedPairing(db, secrets, at: clock.now(), api: api);
      api.offline = offline;
    },
    seedTemplates: seedTemplateDocuments,
  );
  await _frames(tester);
  return booth;
}

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.tap(find.bySemanticsLabel(label).last);
  await _frames(tester);
}

Future<void> _countdown(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
  await _frames(tester);
}

/// Start, two photos, keep them: the finished screen (S27 or S30).
Future<void> _toFinished(WidgetTester tester) async {
  await _tap(tester, 'Start');
  await _countdown(tester);
  await tester.pump(const Duration(seconds: 3));
  await _countdown(tester);
  expect(find.byType(GuestReview), findsOneWidget);
  await _tap(tester, BoothCopy.keepThese);
  expect(find.byType(GuestFinished), findsOneWidget);
  await _frames(tester);
}

Future<void> _type(WidgetTester tester, String digits) async {
  for (final digit in digits.split('')) {
    await tester.tap(find.bySemanticsLabel(digit).last);
    await tester.pump(const Duration(milliseconds: 50));
  }
  await _frames(tester);
}

/// Labels of the controls a guest can use now.
List<String> _controls(WidgetTester tester) => [
  for (final node in actionable(tester.getSemantics(find.byType(BoothScreen))))
    node.label,
];

String _consentText() =>
    const ConsentText(brand: 'Porcelain Booth', linkDays: 7).text;

bool _enabled(WidgetTester tester, String label) => tester
    .getSemantics(find.bySemanticsLabel(label).last)
    .getSemanticsData()
    .flagsCollection
    .isEnabled
    .toBoolOrNull()!;

/// Every request the booth stored, open or finished.
Future<List<DeliveryIntent>> _intents(TestBooth booth) async => [
  for (final row in await booth.db.select(booth.db.deliveryIntents).get())
    (await booth.deliveries.find(row.id))!,
];

void main() {
  for (final viewport in TabletViewport.values) {
    testWidgets('a guest texts their photo with a checked box and a '
        'confirmed number at ${viewport.name} (AC-0902 to AC-0905)', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final booth = await _booth(tester, viewport: viewport);
      await _toFinished(tester);
      expect(_controls(tester), [
        DeliveryCopy.textMyPhotos,
        DeliveryCopy.noThanksFinish,
      ]);
      expect(find.text(BoothCopy.savedToGallery), findsOneWidget);

      await _tap(tester, DeliveryCopy.textMyPhotos);
      expect(find.text('+1'), findsOneWidget);
      expect(find.text(DeliveryCopy.countryHint), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(RegExp.escape(DeliveryCopy.country))),
        findsOneWidget,
      );
      expect(find.text(_consentText()), findsOneWidget);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel(_consentText()))
            .getSemanticsData()
            .flagsCollection
            .isToggled
            .toBoolOrNull(),
        isFalse,
        reason: 'the box starts unchecked',
      );
      expect(_enabled(tester, DeliveryCopy.sendMyPhotos), isFalse);

      await _type(tester, _digits);
      expect(find.text('(212) 555-0147'), findsOneWidget);
      expect(
        _enabled(tester, DeliveryCopy.sendMyPhotos),
        isFalse,
        reason: 'a number alone is not consent',
      );
      await _tap(tester, _consentText());
      expect(_enabled(tester, DeliveryCopy.sendMyPhotos), isTrue);

      await _tap(tester, DeliveryCopy.sendMyPhotos);
      expect(find.text(DeliveryCopy.confirmTitle), findsOneWidget);
      expect(await booth.deliveries.open(), isEmpty, reason: 'not yet');
      await _tap(tester, DeliveryCopy.send);
      await _frames(tester);

      final intents = await _intents(booth);
      expect(intents, hasLength(1));
      final intent = intents.single;
      expect(intent.phoneLast4, '0147');
      expect(intent.consentTextVersion, ConsentText.version);
      expect(
        intent.consentTextDigest,
        const ConsentText(brand: 'Porcelain Booth', linkDays: 7).digest,
      );
      expect(booth.delivery.requests.single.phoneE164, '+12125550147');
      expect(
        booth.delivery.uploads.map((upload) => upload.$2),
        unorderedEquals(['final', 'preview']),
      );
      expect(intent.phase, DeliveryPhase.submitted);
      expect(
        booth.secrets.phones,
        isEmpty,
        reason: 'the number leaves the booth once the service has it',
      );

      expect(find.text('Text request sent'), findsOneWidget);
      expect(find.textContaining('•••-•••-0147'), findsOneWidget);
      expect(find.textContaining('555-0147'), findsNothing);
      expect(find.textContaining(DeliveryCopy.photoSaved), findsOneWidget);
      expect(_controls(tester), [DeliveryCopy.done]);

      await _tap(tester, DeliveryCopy.done);
      expect(_controls(tester), ['Start']);
      expect(find.textContaining('0147'), findsNothing);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('without the checked box nothing is stored, and No thanks '
      'leaves nothing behind (AC-0902, AC-0904)', (tester) async {
    final semantics = tester.ensureSemantics();
    final booth = await _booth(tester);
    await _toFinished(tester);
    await _tap(tester, DeliveryCopy.textMyPhotos);
    await _type(tester, _digits);

    await _tap(tester, DeliveryCopy.sendMyPhotos);
    expect(find.text(DeliveryCopy.confirmTitle), findsNothing);
    expect(find.text(DeliveryCopy.needConsent), findsWidgets);

    // Checking and unchecking is not consent either.
    await _tap(tester, _consentText());
    await _tap(tester, _consentText());
    expect(_enabled(tester, DeliveryCopy.sendMyPhotos), isFalse);

    await _tap(tester, DeliveryCopy.noThanks);
    expect(_controls(tester), ['Start']);
    expect(await _intents(booth), isEmpty);
    expect(booth.secrets.phones, isEmpty);
    expect(booth.delivery.requests, isEmpty);
    expect(find.textContaining('0147'), findsNothing);
    semantics.dispose();
  });

  testWidgets('No thanks, finish goes to the next guest with nothing '
      'stored (AC-0902)', (tester) async {
    final semantics = tester.ensureSemantics();
    final booth = await _booth(tester);
    await _toFinished(tester);
    await _tap(tester, DeliveryCopy.noThanksFinish);
    expect(_controls(tester), ['Start']);
    expect(await _intents(booth), isEmpty);
    expect(booth.delivery.calls.where((call) => call == 'create'), isEmpty);
    semantics.dispose();
  });

  testWidgets('a number left on screen is wiped when the booth resets on '
      'its own, and the next guest starts empty (AC-0903, AC-0922)', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final booth = await _booth(tester);
    await _toFinished(tester);
    await _tap(tester, DeliveryCopy.textMyPhotos);
    await _type(tester, '21255');
    await _tap(tester, _consentText());
    expect(find.text('(212) 55'), findsOneWidget);

    // Typing keeps the booth waiting; walking away resets it.
    await tester.pump(const Duration(seconds: 20));
    await _type(tester, '5');
    await tester.pump(const Duration(seconds: 20));
    expect(find.text('(212) 555'), findsOneWidget, reason: 'not cut off');
    await tester.pump(const Duration(seconds: 15));
    await _frames(tester);
    expect(_controls(tester), ['Start']);
    expect(await _intents(booth), isEmpty);

    await _toFinished(tester);
    await _tap(tester, DeliveryCopy.textMyPhotos);
    expect(find.textContaining('212'), findsNothing);
    expect(_enabled(tester, DeliveryCopy.sendMyPhotos), isFalse);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel(_consentText()))
          .getSemanticsData()
          .flagsCollection
          .isToggled
          .toBoolOrNull(),
      isFalse,
    );
    semantics.dispose();
  });

  testWidgets('turning the tablet keeps the number and the box within the '
      'session (UX-PD7, AC-0905)', (tester) async {
    final semantics = tester.ensureSemantics();
    final booth = await _booth(tester);
    await _toFinished(tester);
    await _tap(tester, DeliveryCopy.textMyPhotos);
    await _type(tester, '212555');
    await _tap(tester, _consentText());

    useViewport(tester, TabletViewport.ipadLandscape);
    await _frames(tester);
    expect(find.text('(212) 555'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel(_consentText()))
          .getSemanticsData()
          .flagsCollection
          .isToggled
          .toBoolOrNull(),
      isTrue,
    );
    await _type(tester, '0147');
    expect(_enabled(tester, DeliveryCopy.sendMyPhotos), isTrue);

    useViewport(tester, TabletViewport.androidPortrait);
    await _frames(tester);
    expect(find.text('(212) 555-0147'), findsOneWidget);
    await _tap(tester, DeliveryCopy.sendMyPhotos);
    await _tap(tester, DeliveryCopy.send);
    await _frames(tester);
    expect((await _intents(booth)).single.phoneLast4, '0147');
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('offline, the guest is told the text may come later or not '
      'at all, and the request waits (AC-0905, AC-0906)', (tester) async {
    final semantics = tester.ensureSemantics();
    final booth = await _booth(tester, offline: true);
    await _toFinished(tester);
    expect(find.text(DeliveryCopy.offlineNote), findsOneWidget);

    await _tap(tester, DeliveryCopy.textMyPhotos);
    await _type(tester, _digits);
    await _tap(tester, _consentText());
    await _tap(tester, DeliveryCopy.sendMyPhotos);
    await _tap(tester, DeliveryCopy.send);
    await _frames(tester);

    expect(find.text('Waiting for a connection'), findsOneWidget);
    expect(find.textContaining('may arrive later'), findsOneWidget);
    final intent = (await _intents(booth)).single;
    expect(intent.phase, DeliveryPhase.queuedLocally);
    expect(booth.secrets.phones.values, ['+12125550147']);
    expect(booth.delivery.requests, isEmpty);
    semantics.dispose();
  });

  testWidgets('offline without waiting allowed, texting is not offered '
      '(AC-0906)', (tester) async {
    final semantics = tester.ensureSemantics();
    await _booth(
      tester,
      offline: true,
      delivery: const EventDeliverySettings(enabled: true, offlineQueue: false),
    );
    await _toFinished(tester);
    expect(_controls(tester), [BoothCopy.nextGuest]);
    semantics.dispose();
  });

  for (final (name, paired, ready, enabled) in [
    ('the event has texting off', true, true, false),
    ('the booth is not paired', false, true, true),
    ('the service is not ready', true, false, true),
  ]) {
    testWidgets('texting is not offered when $name (AC-0901)', (tester) async {
      final semantics = tester.ensureSemantics();
      await _booth(
        tester,
        paired: paired,
        ready: ready,
        delivery: EventDeliverySettings(enabled: enabled),
      );
      await _toFinished(tester);
      expect(_controls(tester), [BoothCopy.nextGuest]);
      expect(find.bySemanticsLabel(DeliveryCopy.textMyPhotos), findsNothing);
      semantics.dispose();
    });
  }

  testWidgets('texting screens offer no way out of Booth Mode, no browser '
      'and no share sheet (AC-0922)', (tester) async {
    final semantics = tester.ensureSemantics();
    final booth = await _booth(tester);
    await _toFinished(tester);
    await _tap(tester, DeliveryCopy.textMyPhotos);

    Future<void> checkScreen() async {
      for (final label in _controls(tester)) {
        // The consent box reads out what the guest agrees to, which names
        // the text's download link; the box itself only checks.
        if (label == _consentText()) continue;
        expect(forbiddenWords.hasMatch(label), isFalse, reason: label);
      }
      for (final location in [
        RoutePaths.dashboard,
        RoutePaths.gallery,
        RoutePaths.settings,
      ]) {
        booth.router.go(location);
        await _frames(tester);
        expect(find.byType(BoothScreen), findsOneWidget, reason: location);
        expect(find.byType(StudioShell), findsNothing, reason: location);
      }
    }

    await checkScreen();
    await _tap(tester, DeliveryCopy.privacy);
    expect(find.text(DeliveryCopy.privacyTitle), findsOneWidget);
    expect(
      find.textContaining('photos.example.test/privacy'),
      findsOneWidget,
      reason: 'the address to read on their own phone, not a browser',
    );
    await checkScreen();
    await _tap(tester, DeliveryCopy.close);
    await _type(tester, _digits);
    await _tap(tester, _consentText());
    await _tap(tester, DeliveryCopy.sendMyPhotos);
    await checkScreen();
    await _tap(tester, DeliveryCopy.send);
    await checkScreen();
    expect(booth.files.shared, isEmpty);
    expect(booth.files.picks, isEmpty);
    semantics.dispose();
  });

  testWidgets('a refused request tells the guest plainly, and their photo '
      'is still saved (AC-0914, AC-0916)', (tester) async {
    final semantics = tester.ensureSemantics();
    final booth = await _booth(tester);
    booth.delivery.refuseCreateWith = 'RECIPIENT_OPTED_OUT';
    await _toFinished(tester);
    await _tap(tester, DeliveryCopy.textMyPhotos);
    await _type(tester, _digits);
    await _tap(tester, _consentText());
    await _tap(tester, DeliveryCopy.sendMyPhotos);
    await _tap(tester, DeliveryCopy.send);
    await _frames(tester);
    expect(find.text('This number opted out of our texts'), findsOneWidget);
    expect(find.textContaining(DeliveryCopy.photoSaved), findsOneWidget);
    final intent = (await _intents(booth)).single;
    expect(intent.phase, DeliveryPhase.failed);
    expect(booth.secrets.phones, isEmpty);
    semantics.dispose();
  });

  testWidgets('the booth database keeps only the last four digits '
      '(AC-0903)', (tester) async {
    final booth = await _booth(tester);
    await _toFinished(tester);
    await _tap(tester, DeliveryCopy.textMyPhotos);
    await _type(tester, _digits);
    await _tap(tester, _consentText());
    await _tap(tester, DeliveryCopy.sendMyPhotos);
    await _tap(tester, DeliveryCopy.send);
    await _frames(tester);
    final intent = (await _intents(booth)).single;
    final row = await (booth.db.select(
      booth.db.deliveryIntents,
    )..where((t) => t.id.equals(intent.id))).getSingle();
    expect(row.toString(), isNot(contains('2125550147')));
    expect(row.toString(), isNot(contains('555-0147')));
  });
}
