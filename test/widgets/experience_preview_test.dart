// EP08 (AC-EP08): the Full Experience Preview runs the event's whole
// guest journey (welcome, camera, countdown, photos, review, texting,
// finished) on the real guest screens with a sample camera, in portrait
// and landscape and in any pack, and leaves nothing behind: no session,
// original, finished photo or text request in the booth's database, no
// file, no camera use and no delivery call.
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/routing/route_paths.dart';
import 'package:porcelain_photo_booth/domain/delivery/consent.dart';
import 'package:porcelain_photo_booth/domain/delivery/delivery_settings.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_configuration.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_pack.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_registry.dart';
import 'package:porcelain_photo_booth/features/booth/delivery_copy.dart';
import 'package:porcelain_photo_booth/features/booth/experience_preview_screen.dart';
import 'package:porcelain_photo_booth/features/booth/guest_finished.dart';
import 'package:porcelain_photo_booth/features/booth/guest_review.dart';

import '../support/app_harness.dart';
import '../support/fake_delivery.dart';
import '../support/fakes.dart';
import '../support/seed.dart';
import '../support/tablet_viewports.dart';

const _ribbon = 'Preview · sample camera · nothing is saved or sent';

Future<(TestBooth, FakeDeliveryApi)> _editor(WidgetTester tester) async {
  useViewport(tester, TabletViewport.ipadLandscape);
  final clock = FakeClock();
  final api = FakeDeliveryApi();
  final secrets = MemoryDeliverySecrets();
  final booth = await pumpApp(
    tester,
    location: RoutePaths.event(SeedIds.active, tab: 'guest'),
    clock: clock,
    delivery: api,
    secrets: secrets,
    seed: (db) async {
      await seedEvents(
        db,
        active: (event) => event.copyWith(
          delivery: const EventDeliverySettings(enabled: true),
          experience: const EventExperienceConfiguration(
            packId: 'kid-party-arcade',
            childrenMayBeGuests: true,
          ),
        ),
      );
      await seedPairing(db, secrets, at: clock.now(), api: api);
    },
    seedTemplates: seedTemplateDocuments,
  );
  api.calls.clear();
  return (booth, api);
}

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _tap(WidgetTester tester, String label) async {
  final target = find.bySemanticsLabel(label).last;
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await _frames(tester);
}

Future<void> _openPreview(WidgetTester tester) async {
  await _tap(tester, 'Preview the whole guest journey');
  await tester.pumpAndSettle();
  expect(find.byType(ExperiencePreviewScreen), findsOneWidget);
  expect(find.text(_ribbon), findsOneWidget);
}

/// Start, two photos, keep: the finished photo, rendered in real time.
Future<void> _journey(WidgetTester tester, GuestCopy words) async {
  await _tap(tester, words[GuestCopyKey.start]);
  for (var photo = 0; photo < 2; photo++) {
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    // The sample photo is drawn by the engine, in real time.
    await settleRendering(tester, rounds: 4);
    await _frames(tester);
    if (photo == 0) await tester.pump(const Duration(seconds: 3));
  }
  await settleRendering(tester, rounds: 4);
  expect(find.byType(GuestReview), findsOneWidget);
  await _tap(tester, words[GuestCopyKey.keepThese]);
  for (var i = 0; i < 3; i++) {
    await settleRendering(tester, rounds: 6);
    await _frames(tester);
  }
  expect(find.byType(GuestFinished), findsOneWidget);
}

Future<void> _expectNothingKept(TestBooth booth, FakeDeliveryApi api) async {
  final db = booth.db;
  expect(await db.select(db.captureSessions).get(), isEmpty);
  expect(await db.select(db.sessionPhotos).get(), isEmpty);
  expect(await db.select(db.sessionOutputs).get(), isEmpty);
  expect(await db.select(db.originalPhotos).get(), isEmpty);
  expect(await db.select(db.deliveryIntents).get(), isEmpty);
  expect(booth.camera.initializations, 0, reason: 'the real camera stays off');
  expect(booth.camera.shutters, 0);
  expect(booth.stills.stills, isEmpty);
  expect(booth.exports.renders, isEmpty);
  expect(api.requests, isEmpty);
  expect(api.uploads, isEmpty);
}

void main() {
  testWidgets('the whole journey, texting included, keeps and sends '
      'nothing', (tester) async {
    final (booth, api) = await _editor(tester);
    await _openPreview(tester);
    final words = ExperienceRegistry.bundled
        .resolve(const EventExperienceConfiguration(packId: 'kid-party-arcade'))
        .copy;
    await _journey(tester, words);

    // Texting, as a guest would: a number, the box, Send, confirm.
    await _tap(tester, words[GuestCopyKey.textMyPhotos]);
    for (final digit in '2125550147'.split('')) {
      await tester.tap(find.bySemanticsLabel(digit).last);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await _frames(tester);
    await _tap(
      tester,
      const ConsentText(brand: 'Porcelain Booth', linkDays: 7).text,
    );
    await _tap(tester, DeliveryCopy.sendMyPhotos);
    await _tap(tester, DeliveryCopy.send);
    expect(find.text(DeliveryCopy.previewTitle), findsOneWidget);
    expect(find.text(_ribbon), findsOneWidget, reason: 'always labelled');
    expect(tester.takeException(), isNull);
    await _expectNothingKept(booth, api);
  });

  testWidgets('landscape and another pack, then Restart', (tester) async {
    final (booth, api) = await _editor(tester);
    await _openPreview(tester);
    await _tap(tester, 'Landscape');
    await _tap(tester, 'Retro Game Quest');
    final words = ExperienceRegistry.bundled
        .resolve(const EventExperienceConfiguration(packId: 'retro-game-quest'))
        .copy;
    await _journey(tester, words);
    await _tap(tester, 'Restart');
    expect(find.bySemanticsLabel(words[GuestCopyKey.start]), findsWidgets);
    expect(find.byType(GuestFinished), findsNothing);
    expect(tester.takeException(), isNull);
    await _expectNothingKept(booth, api);
    // The event keeps its own pack: the preview changed only itself.
    final event = await booth.events.findById(SeedIds.active);
    expect(event!.experience.packId, 'kid-party-arcade');
  });

  testWidgets('Close returns to the editor', (tester) async {
    await _editor(tester);
    await _openPreview(tester);
    await _tap(tester, 'Close preview');
    await tester.pumpAndSettle();
    expect(find.byType(ExperiencePreviewScreen), findsNothing);
  });
}
