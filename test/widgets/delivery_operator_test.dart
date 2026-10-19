// The operator's texting screens (S34 to S36; AC-0901, AC-0907, AC-0913,
// AC-0915, AC-0917) on the in-memory booth and a stand-in for the delivery
// service: pairing needs the administrator's code and keeps only the
// booth's credential; an event can offer texting only when the booth is
// paired and the service ready; a session's texts show the last four
// digits and what the provider reported, and each action is confirmed and
// tells the truth: turning a link off, closing or re-sending an unknown
// text, cancelling one still waiting. No real service is contacted.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/routing/route_paths.dart';
import 'package:porcelain_photo_booth/domain/delivery/delivery_intent.dart';
import 'package:porcelain_photo_booth/shared/widgets/porcelain_switch.dart';

import '../support/app_harness.dart';
import '../support/fake_delivery.dart';
import '../support/fake_export.dart';
import '../support/fake_gallery.dart';
import '../support/fakes.dart';
import '../support/gallery_seed.dart';
import '../support/seed.dart';
import '../support/tablet_viewports.dart';

/// The intent id for gallery session [number].
String _intentId(int number) =>
    'e0000000-0000-4000-8000-${number.toString().padLeft(12, '0')}';

Future<TestBooth> _studio(
  WidgetTester tester, {
  required String location,
  bool paired = true,
  bool offline = false,
  List<(int, String, DeliveryPhase, String?)> texts = const [],
}) async {
  useViewport(tester, TabletViewport.ipadLandscape);
  final clock = FakeClock();
  final api = FakeDeliveryApi();
  final secrets = MemoryDeliverySecrets();
  final exports = FakeExportService();
  final booth = await pumpApp(
    tester,
    location: location,
    clock: clock,
    exports: exports,
    delivery: api,
    secrets: secrets,
    seedTemplates: seedTemplateDocuments,
    settle: false,
    seed: (db) async {
      await seedEvents(db);
      await seedGallery(
        db,
        count: 10,
        firstStart: DateTime.utc(2026, 10, 17, 19),
        outputBytes: printStandIn,
      );
      for (final output in await db.select(db.sessionOutputs).get()) {
        exports.files[output.relativePath] = printStandIn;
      }
      if (paired) await seedPairing(db, secrets, at: clock.now(), api: api);
      await seedTexts(
        db,
        api,
        secrets,
        texts,
        sessionId: GalleryIds.session,
        outputId: GalleryIds.output,
      );
      api.offline = offline;
    },
  );
  await settleRendering(tester, rounds: 4);
  await tester.pumpAndSettle();
  return booth;
}

Future<void> _tap(WidgetTester tester, String label) async {
  final target = find.bySemanticsLabel(label).last;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<DeliveryIntent> _intent(TestBooth booth, int number) async =>
    (await booth.deliveries.find(_intentId(number)))!;

void main() {
  testWidgets('a delivered text shows four digits, its history, and its '
      'link can be turned off after a confirmation (AC-0913, AC-0917)', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final booth = await _studio(
      tester,
      location: RoutePaths.gallerySession(GalleryIds.session(8)),
      texts: [(8, '0147', DeliveryPhase.delivered, null)],
    );
    expect(find.text('Texts'), findsOneWidget);
    expect(find.text('•••-•••-0147'), findsOneWidget);
    expect(find.text('Delivered'), findsWidgets);
    expect(
      find.text(DeliveryPhase.delivered.name),
      findsNothing,
      reason: 'labels, not codes',
    );
    expect(find.textContaining('never mean the guest opened it'), findsOne);

    await _tap(tester, 'Turn link off');
    expect(find.text('Turn the link off?'), findsOneWidget);
    await _tap(tester, 'Keep the link');
    expect(booth.delivery.calls, isNot(contains('revoke')));

    await _tap(tester, 'Turn link off');
    await tester.tap(find.bySemanticsLabel('Turn link off').last);
    await tester.pumpAndSettle();
    expect(booth.delivery.calls, contains('revoke'));
    final intent = await _intent(booth, 8);
    expect(intent.linkRevokedAtUtc, isNotNull);
    expect(find.textContaining('Link turned off'), findsWidgets);
    expect(find.bySemanticsLabel('Turn link off'), findsNothing);
    semantics.dispose();
  });

  testWidgets('an unknown text is closed, or sent again only after the '
      'duplicate risk is acknowledged (AC-0915)', (tester) async {
    final semantics = tester.ensureSemantics();
    final booth = await _studio(
      tester,
      location: RoutePaths.gallerySession(GalleryIds.session(6)),
      texts: [(6, '8830', DeliveryPhase.unknown, 'PROVIDER_TIMEOUT')],
    );
    expect(find.text('Unknown'), findsWidgets);
    expect(find.textContaining('Check it before sending again'), findsOne);

    await _tap(tester, 'Send again');
    expect(find.textContaining('the guest gets two texts'), findsOneWidget);
    await _tap(tester, 'Not now');
    expect(booth.delivery.calls, isNot(contains('resolve')));

    await _tap(tester, 'Send again');
    await tester.tap(find.bySemanticsLabel('Send again').last);
    await tester.pumpAndSettle();
    expect(booth.delivery.calls, contains('resolve'));
    expect((await _intent(booth, 6)).phase, DeliveryPhase.submitted);
    semantics.dispose();
  });

  testWidgets('closing an unknown text ends it without a second send', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final booth = await _studio(
      tester,
      location: RoutePaths.gallerySession(GalleryIds.session(6)),
      texts: [(6, '8830', DeliveryPhase.unknown, 'PROVIDER_TIMEOUT')],
    );
    await _tap(tester, 'Close it');
    await tester.tap(find.bySemanticsLabel('Close it').last);
    await tester.pumpAndSettle();
    final intent = await _intent(booth, 6);
    expect(intent.phase, DeliveryPhase.failed);
    expect(intent.lastErrorCode, 'CLOSED_BY_OPERATOR');
    expect(booth.delivery.requests, isEmpty);
    semantics.dispose();
  });

  testWidgets('a text still waiting on the booth can be tried now or '
      'canceled, which erases its number (AC-0906)', (tester) async {
    final semantics = tester.ensureSemantics();
    final booth = await _studio(
      tester,
      location: RoutePaths.gallerySession(GalleryIds.session(4)),
      offline: true,
      texts: [(4, '4410', DeliveryPhase.queuedLocally, 'OFFLINE')],
    );
    expect(find.text('Queued locally'), findsWidgets);
    expect(booth.secrets.phones, contains(_intentId(4)));
    await _tap(tester, 'Try now');
    expect(find.textContaining('Still waiting'), findsOneWidget);
    expect((await _intent(booth, 4)).phase, DeliveryPhase.queuedLocally);

    await _tap(tester, 'Cancel text');
    expect(find.text('Cancel this text?'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Cancel text').last);
    await tester.pumpAndSettle();
    final intent = await _intent(booth, 4);
    expect(intent.phase, DeliveryPhase.canceled);
    expect(booth.secrets.phones, isEmpty);
    expect(booth.delivery.requests, isEmpty);
    semantics.dispose();
  });

  testWidgets('pairing needs the administrator code and keeps only the '
      "booth's credential; unpairing is confirmed (AC-0907)", (tester) async {
    final semantics = tester.ensureSemantics();
    final booth = await _studio(
      tester,
      location: '/studio/settings?section=delivery',
      paired: false,
    );
    expect(find.text('Pair this booth'), findsOneWidget);
    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), FakeDeliveryApi.baseUrl.toString());
    await tester.enterText(fields.at(1), 'AAAA-BBBB-CCCC');
    await tester.pumpAndSettle();
    await _tap(tester, 'Pair');
    expect(find.textContaining("isn't valid or has expired"), findsOneWidget);
    expect(booth.secrets.credential, isNull);

    await tester.enterText(fields.at(1), 'k7qm 4xht 9zpa');
    await _tap(tester, 'Pair');
    expect(booth.secrets.credential, startsWith('credential-'));
    expect(find.text('Delivery service'), findsOneWidget);
    expect(find.text('photos.example.test'), findsOneWidget);
    expect(find.text('Ready'), findsWidgets);
    expect(
      find.textContaining('staging service (test numbers only)'),
      findsOneWidget,
    );

    await _tap(tester, 'Unpair');
    expect(find.text('Unpair this booth?'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Unpair').last);
    await tester.pumpAndSettle();
    expect(booth.secrets.credential, isNull);
    expect(await booth.deliveries.pairing(), isNull);
    expect(find.text('Pair this booth'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('an address that is not https is refused before any call', (
    tester,
  ) async {
    final booth = await _studio(
      tester,
      location: '/studio/settings?section=delivery',
      paired: false,
    );
    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), 'http://photos.example.test');
    await tester.enterText(fields.at(1), FakeDeliveryApi.pairingCode);
    await tester.pumpAndSettle();
    await _tap(tester, 'Pair');
    expect(booth.delivery.calls, isEmpty);
    expect(booth.secrets.credential, isNull);
    expect(find.textContaining('Use the https address'), findsOneWidget);
  });

  testWidgets('an event cannot offer texting until the booth is paired and '
      'the service is ready (AC-0901)', (tester) async {
    final semantics = tester.ensureSemantics();
    await _studio(
      tester,
      location: RoutePaths.event(SeedIds.active, tab: 'delivery'),
      paired: false,
    );
    final toggle = tester.widget<PorcelainSwitchRow>(
      find.byType(PorcelainSwitchRow).first,
    );
    expect(toggle.value, isFalse);
    expect(toggle.onChanged, isNull);
    expect(toggle.disabledReason, contains('Pair this booth first'));
    semantics.dispose();
  });

  testWidgets('paired and ready, the event can turn texting on', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _studio(
      tester,
      location: RoutePaths.event(SeedIds.active, tab: 'delivery'),
    );
    final toggle = tester.widget<PorcelainSwitchRow>(
      find.byType(PorcelainSwitchRow).first,
    );
    expect(toggle.value, isFalse, reason: 'off by default');
    expect(toggle.onChanged, isNotNull);
    expect(find.text('Service ready'), findsOneWidget);
    expect(find.textContaining('Version pd-consent-1'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a sent text never reads as delivered (AC-0913)', (tester) async {
    final booth = await _studio(
      tester,
      location: RoutePaths.gallerySession(GalleryIds.session(7)),
      texts: [(7, '2291', DeliveryPhase.sent, null)],
    );
    expect(find.text('Sent'), findsWidgets);
    expect(find.text('Delivered'), findsNothing);
    expect(find.textContaining('Not confirmed delivered'), findsOneWidget);
    expect(booth.delivery.calls, isNot(contains('resolve')));
  });
}
