// Guest isolation after a crash (M10): the app killed in the middle of a
// guest's session starts again on the welcome screen and shows nothing of
// that guest, not their photos and not a number they were typing or had
// sent. Their session is ended for the operator, with every photo kept; a
// text they asked for stays queued under its last four digits only. The
// restart here is the app built again on the same database, secure
// storage and camera, as after a kill (process deaths on the tablets are
// in the M10 device procedure, BLOCKED).
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/delivery/consent.dart';
import 'package:porcelain_photo_booth/domain/delivery/delivery_settings.dart';
import 'package:porcelain_photo_booth/domain/repositories/session_repository.dart';
import 'package:porcelain_photo_booth/features/booth/booth_copy.dart';
import 'package:porcelain_photo_booth/features/booth/booth_screen.dart';
import 'package:porcelain_photo_booth/features/booth/delivery_copy.dart';
import 'package:porcelain_photo_booth/features/booth/guest_finished.dart';
import 'package:porcelain_photo_booth/features/booth/guest_review.dart';

import '../support/app_harness.dart';
import '../support/fake_delivery.dart';
import '../support/fakes.dart';
import '../support/seed.dart';
import '../support/tablet_viewports.dart';
import 'guest_isolation_test.dart' show actionable;

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

/// Start and two photos: the review.
Future<void> _toReview(WidgetTester tester) async {
  await _tap(tester, 'Start');
  await _countdown(tester);
  await tester.pump(const Duration(seconds: 3));
  await _countdown(tester);
  expect(find.byType(GuestReview), findsOneWidget);
}

Future<void> _type(WidgetTester tester, String digits) async {
  for (final digit in digits.split('')) {
    await tester.tap(find.bySemanticsLabel(digit).last);
    await tester.pump(const Duration(milliseconds: 50));
  }
  await _frames(tester);
}

List<String> _controls(WidgetTester tester) => [
  for (final node in actionable(tester.getSemantics(find.byType(BoothScreen))))
    node.label,
];

Future<TestBooth> _booth(
  WidgetTester tester, {
  bool texting = false,
  bool offline = false,
}) async {
  useViewport(tester, TabletViewport.ipadPortrait);
  final clock = FakeClock();
  final api = FakeDeliveryApi();
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
        active: texting
            ? (event) => event.copyWith(
                delivery: const EventDeliverySettings(enabled: true),
              )
            : null,
      );
      if (texting) await seedPairing(db, secrets, at: clock.now(), api: api);
    },
    seedTemplates: seedTemplateDocuments,
  );
  api.offline = offline;
  await _frames(tester);
  return booth;
}

/// The app built again on the same database, secure storage, camera and
/// delivery service, as after the process was killed.
Future<TestBooth> _killAndStart(WidgetTester tester, TestBooth first) async {
  final second = await pumpApp(
    tester,
    startAs: StartAs.booth,
    boothEventId: SeedIds.active,
    database: first.db,
    pins: first.pins,
    clock: first.clock,
    alreadySetUp: true,
    seedTemplates: seedTemplateDocuments,
    camera: first.camera,
    delivery: first.delivery,
    secrets: first.secrets,
  );
  await _frames(tester);
  return second;
}

Future<SessionRecord> _only(TestBooth booth) async {
  final rows = await booth.db.select(booth.db.captureSessions).get();
  expect(rows, hasLength(1));
  return (await booth.sessions.find(rows.single.id))!;
}

void main() {
  testWidgets('killed at the review, the booth starts again on the welcome; '
      'the session is ended for the operator with its photos kept', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final first = await _booth(tester);
    await _toReview(tester);

    final second = await _killAndStart(tester, first);
    expect(_controls(tester), ['Start'], reason: 'only the welcome');
    expect(find.byType(GuestReview), findsNothing);
    expect(find.byType(GuestFinished), findsNothing);
    final session = await _only(second);
    expect(session.status, SessionStatus.abandoned);
    expect(session.photos, hasLength(2), reason: 'nothing is deleted');

    // The next guest starts afresh.
    await _tap(tester, 'Start');
    expect(find.byType(GuestReview), findsNothing);
    semantics.dispose();
  });

  testWidgets('killed while a guest typed their number, nothing of it '
      'survives: not on screen, not stored', (tester) async {
    final semantics = tester.ensureSemantics();
    final first = await _booth(tester, texting: true);
    await _toReview(tester);
    await _tap(tester, BoothCopy.keepThese);
    expect(find.byType(GuestFinished), findsOneWidget);
    await _tap(tester, DeliveryCopy.textMyPhotos);
    await _type(tester, '2125550147');
    expect(find.text('(212) 555-0147'), findsOneWidget);

    final second = await _killAndStart(tester, first);
    expect(_controls(tester), ['Start']);
    expect(find.textContaining('555'), findsNothing);
    expect(second.secrets.phones, isEmpty, reason: 'never stored');
    expect(await second.db.select(second.db.deliveryIntents).get(), isEmpty);
    expect(
      (await _only(second)).status,
      SessionStatus.completed,
      reason: 'the finished photo was saved before texting began',
    );
    semantics.dispose();
  });

  testWidgets('killed after a guest asked for a text (offline), the next '
      'guest sees nothing of it; it waits under its last four digits', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final first = await _booth(tester, texting: true, offline: true);
    await _toReview(tester);
    await _tap(tester, BoothCopy.keepThese);
    await _tap(tester, DeliveryCopy.textMyPhotos);
    await _type(tester, '2125550147');
    await _tap(
      tester,
      const ConsentText(brand: 'Porcelain Booth', linkDays: 7).text,
    );
    await _tap(tester, DeliveryCopy.sendMyPhotos);
    await _tap(tester, DeliveryCopy.send);
    expect(first.secrets.phones, hasLength(1), reason: 'held to hand over');

    final second = await _killAndStart(tester, first);
    expect(_controls(tester), ['Start']);
    expect(find.textContaining('0147'), findsNothing);
    expect(find.textContaining('555'), findsNothing);
    final intents = await second.deliveries.open();
    expect(intents, hasLength(1), reason: 'the request survives');
    expect(intents.single.phoneLast4, '0147');
    expect(
      second.secrets.phones,
      hasLength(1),
      reason: 'kept only until the service has it',
    );
    semantics.dispose();
  });
}
