// AC-0801 to AC-0806 on the operator's screens, offline (no network is
// used anywhere): the gallery at thousands of sessions builds and asks for
// thumbnails only for what is on screen; filters, search and session
// details show every photo, retake, template revision and finished photo;
// export reports exactly what the share sheet said and every file that
// did not go; a finished photo is made again without changing the first;
// deletion is confirmed and journaled; sessions past retention are offered,
// never deleted silently; nothing offers printing; Booth Mode never reaches
// the gallery.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/gallery/gallery_providers.dart';
import 'package:porcelain_photo_booth/core/routing/route_paths.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/repositories/session_repository.dart';
import 'package:porcelain_photo_booth/domain/services/operator_files.dart';
import 'package:porcelain_photo_booth/features/booth/booth_screen.dart';
import 'package:porcelain_photo_booth/features/gallery/gallery_screen.dart';
import 'package:porcelain_photo_booth/features/gallery/session_detail_screen.dart';
import 'package:porcelain_photo_booth/features/gallery/session_tile.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';
import 'package:porcelain_photo_booth/shared/gallery/gallery_copy.dart';
import 'package:porcelain_photo_booth/shared/widgets/porcelain_button.dart';

import '../support/app_harness.dart';
import '../support/fake_export.dart';
import '../support/fake_gallery.dart';
import '../support/gallery_seed.dart';
import '../support/seed.dart';
import '../support/tablet_viewports.dart';

/// The Studio's gallery over [count] sessions of the seeded wedding, the
/// evening before the test clock, with print-ready finished photos.
Future<TestBooth> _gallery(
  WidgetTester tester, {
  int count = 18,
  String location = RoutePaths.gallery,
  TabletViewport viewport = TabletViewport.ipadLandscape,
  BoothEvent Function(BoothEvent event)? event,
  Future<void> Function(BoothDatabase db)? more,
  FakeGalleryExporter? exporter,
}) async {
  useViewport(tester, viewport);
  final exports = FakeExportService();
  final booth = await pumpApp(
    tester,
    location: location,
    exports: exports,
    exporter: exporter,
    seedTemplates: seedTemplateDocuments,
    settle: false,
    seed: (db) async {
      await seedEvents(db, active: event);
      if (count > 0) {
        await seedGallery(
          db,
          count: count,
          firstStart: DateTime.utc(2026, 10, 17, 19),
          outputBytes: printStandIn,
        );
      }
      await more?.call(db);
      for (final output in await db.select(db.sessionOutputs).get()) {
        exports.files[output.relativePath] = printStandIn;
      }
    },
  );
  await settleRendering(tester, rounds: 4);
  await tester.pumpAndSettle();
  return booth;
}

Finder get _pageScroll => find
    .descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(target, 300, scrollable: _pageScroll);
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

Future<void> _tapSession(WidgetTester tester, int number) async {
  final tile = find.byKey(ValueKey(GalleryIds.session(number)));
  await _scrollTo(tester, tile);
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('thousands of sessions: counts, filters and search, with only '
      'shown tiles built and thumbnailed (AC-0801)', (tester) async {
    const count = 2000;
    final booth = await _gallery(tester, count: count);
    expect(find.text('All · $count'), findsOneWidget);
    expect(find.textContaining('2000 sessions'), findsOneWidget);
    final built = find
        .byType(SessionTile, skipOffstage: false)
        .evaluate()
        .length;
    expect(built, inInclusiveRange(1, 60), reason: 'a lazy grid');
    expect(
      booth.thumbnails.requests.toSet().length,
      lessThanOrEqualTo(built),
      reason: 'thumbnails only for built tiles',
    );

    // Far down the grid, still only what is near the screen.
    await tester.drag(_pageScroll, const Offset(0, -20000));
    await tester.pumpAndSettle();
    expect(
      find.byType(SessionTile, skipOffstage: false).evaluate().length,
      lessThan(80),
    );
    expect(booth.thumbnails.requests.toSet().length, lessThan(200));

    await tester.drag(_pageScroll, const Offset(0, 40000));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, '#1234');
    await tester.pumpAndSettle();
    expect(find.byType(SessionTile), findsOneWidget);
    expect(find.text('No. 1234'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).first, 'wedding');
    await tester.pumpAndSettle();
    expect(find.text(GalleryCopy.searchNotUnderstood), findsWidgets);

    await tester.enterText(find.byType(EditableText).first, '');
    await tester.pumpAndSettle();
    var attention = 0;
    for (var n = 1; n <= count; n++) {
      if (mixedOutcome(n) == SeededOutcome.rendering ||
          mixedOutcome(n) == SeededOutcome.failed) {
        attention++;
      }
    }
    await _tapText(tester, 'To finish · $attention');
    expect(
      find.byType(SessionTile).evaluate().length,
      lessThanOrEqualTo(attention),
    );
    expect(find.text('Waiting to finish').evaluate(), isNotEmpty);
  });

  testWidgets('a session shows its photos, retakes, bindings, template '
      'revision and a checked finished photo (AC-0802)', (tester) async {
    await _gallery(tester);
    await _tapSession(tester, 8);
    await settleRendering(tester, rounds: 4);
    await tester.pumpAndSettle();
    expect(find.byType(SessionDetailScreen), findsOneWidget);
    expect(find.text('Session 8'), findsOneWidget);
    expect(find.text('1200 × 1800 px'), findsOneWidget);
    expect(find.text('4 × 6 in at 300 dpi'), findsOneWidget);
    expect(find.text('Print-ready'), findsOneWidget);
    expect(find.text('Two-up classic, revision 1'), findsOneWidget);
    expect(find.text('Photo 2, retake 1'), findsWidgets);
    expect(find.text('In the finished photo'), findsNWidgets(2));
    expect(
      find.bySemanticsLabel('Photo 2, not used'),
      findsOneWidget,
      reason: 'the first attempt is kept and labelled',
    );
    expect(find.text('Not exported yet.'), findsOneWidget);
  });

  testWidgets('a damaged finished photo is labelled, not shown as ready', (
    tester,
  ) async {
    final booth = await _gallery(
      tester,
      location: RoutePaths.gallerySession(GalleryIds.session(2)),
    );
    // Its file no longer matches its record.
    booth.exports.files['outputs/${GalleryIds.output(2)}.jpg'] =
        finishedStandIn;
    booth.container.invalidate(outputCheckProvider);
    await settleRendering(tester, rounds: 4);
    await tester.pumpAndSettle();
    expect(find.text('Needs attention'), findsOneWidget);
    expect(find.text('The file no longer matches its record'), findsOneWidget);
  });

  testWidgets('export hands over what it can and names every file that did '
      'not go (AC-0803)', (tester) async {
    final booth = await _gallery(tester);
    await _tapText(tester, GalleryCopy.select);
    await _tapSession(tester, 18);
    await _tapSession(tester, 15);
    expect(find.text('2 selected'), findsOneWidget);
    await _tapText(tester, GalleryCopy.export);
    await _tapText(tester, GalleryCopy.chooseDestination);

    expect(find.text('1 file handed to Save to Files.'), findsOneWidget);
    expect(
      find.text(
        'Session 15, finished photo: no finished photo yet '
        '(EXPORT_NO_FINISHED_PHOTO)',
      ),
      findsOneWidget,
    );
    expect(booth.exporter.parts.single.single.sessionNumber, 18);
    final batch = (await booth.db.select(booth.db.exportBatches).get()).single;
    expect(batch.destination, 'com.apple.DocumentManagerUICore.SaveToFiles');
    expect(batch.failureCount, 0);
    await _tapText(tester, GalleryCopy.done);
  });

  testWidgets('a closed share sheet sends nothing and can be offered again', (
    tester,
  ) async {
    final exporter = FakeGalleryExporter()
      ..share = const ShareReport(ShareOutcome.dismissed);
    final booth = await _gallery(tester, exporter: exporter);
    await _tapText(tester, GalleryCopy.select);
    await _tapSession(tester, 18);
    await _tapText(tester, GalleryCopy.export);
    await _tapText(tester, GalleryCopy.chooseDestination);
    expect(find.text(GalleryCopy.sheetClosed), findsOneWidget);
    expect(await booth.db.select(booth.db.exportBatches).get(), isEmpty);

    exporter.share = const ShareReport(ShareOutcome.unknown);
    await _tapText(tester, GalleryCopy.shareAgain);
    expect(find.text(GalleryCopy.handedOverUnknown(1)), findsOneWidget);
    expect(await booth.db.select(booth.db.exportBatches).get(), hasLength(1));
  });

  testWidgets('a finished photo is made again beside the first, and a '
      'failed session gets one (AC-0804)', (tester) async {
    final booth = await _gallery(
      tester,
      location: RoutePaths.gallerySession(GalleryIds.session(8)),
    );
    await _tapText(tester, GalleryCopy.makeAgain);
    await settleRendering(tester, rounds: 4);
    await tester.pumpAndSettle();
    final outputs = await booth.sessions.outputs(GalleryIds.session(8));
    expect(outputs.map((o) => o.origin), [
      SessionOutputOrigin.session,
      SessionOutputOrigin.rerender,
    ]);
    expect(find.textContaining('Version 2'), findsOneWidget);
    expect(booth.exports.files, contains(outputs.first.relativePath));

    booth.router.go(RoutePaths.gallerySession(GalleryIds.session(3)));
    await settleRendering(tester, rounds: 4);
    await tester.pumpAndSettle();
    await _tapText(tester, GalleryCopy.makePrint);
    await settleRendering(tester, rounds: 4);
    await tester.pumpAndSettle();
    final record = (await booth.sessions.find(GalleryIds.session(3)))!;
    expect(record.status, SessionStatus.failed, reason: 'history kept');
    expect(await booth.sessions.outputs(GalleryIds.session(3)), hasLength(1));
    expect(find.textContaining('made later in the gallery'), findsWidgets);

    booth.router.go(RoutePaths.gallerySession(GalleryIds.session(5)));
    await settleRendering(tester, rounds: 4);
    await tester.pumpAndSettle();
    final make = tester.widget<PorcelainButton>(
      find.byWidgetPredicate(
        (w) => w is PorcelainButton && w.label == GalleryCopy.makePrint,
      ),
    );
    expect(make.onPressed, isNull);
    expect(make.disabledReason, GalleryCopy.cannotRenderIncomplete);
    expect(
      find.textContaining('ended before every photo was taken'),
      findsOneWidget,
    );
  });

  testWidgets('deleting asks first, then removes the records and their '
      'files (AC-0805)', (tester) async {
    final booth = await _gallery(tester);
    await _tapText(tester, GalleryCopy.select);
    await _tapSession(tester, 18);
    await _tapText(tester, GalleryCopy.deleteConfirm);
    expect(find.text(GalleryCopy.deleteSessionsTitle(1)), findsOneWidget);
    await _tapText(tester, GalleryCopy.keep);
    expect(await booth.sessions.find(GalleryIds.session(18)), isNotNull);

    await _tapText(tester, GalleryCopy.deleteConfirm);
    await _tapText(tester, GalleryCopy.deleteConfirm);
    await tester.pumpAndSettle();
    expect(await booth.sessions.find(GalleryIds.session(18)), isNull);
    expect(
      booth.cleanup.removed,
      containsAll([
        'outputs/${GalleryIds.output(18)}.jpg',
        'originals/${GalleryIds.original(18, 0, 1)}.jpg',
        'thumbnails/output-${GalleryIds.output(18)}.jpg',
      ]),
    );
    expect(find.byKey(ValueKey(GalleryIds.session(18))), findsNothing);
    expect(find.text('All · 17'), findsOneWidget);
  });

  testWidgets('sessions past retention are offered for deletion and go '
      'only once confirmed', (tester) async {
    final booth = await _gallery(
      tester,
      count: 0,
      event: (event) =>
          event.copyWith(retention: const RetentionPolicy.deleteAfterDays(30)),
      more: (db) async {
        await seedGallery(
          db,
          count: 3,
          firstStart: DateTime.utc(2026, 8, 22, 19),
          outputBytes: printStandIn,
        );
        await seedGallery(
          db,
          count: 2,
          firstNumber: 4,
          firstStart: DateTime.utc(2026, 10, 17, 19),
          outputBytes: printStandIn,
        );
      },
    );
    expect(find.text(GalleryCopy.pastRetention(3, 30)), findsOneWidget);
    await _tapText(tester, GalleryCopy.reviewRetention);
    expect(find.text(GalleryCopy.retentionTitle(3)), findsOneWidget);

    // Delete waits for the explicit acknowledgement.
    await tester.tap(find.text(GalleryCopy.deleteConfirm).last);
    await tester.pumpAndSettle();
    expect(await booth.gallery.sessions(SeedIds.active), hasLength(5));
    await _tapText(tester, 'Delete them permanently');
    await _tapText(tester, GalleryCopy.deleteConfirm);
    await tester.pumpAndSettle();
    final left = await booth.gallery.sessions(SeedIds.active);
    expect(left.map((s) => s.number), [5, 4]);
    expect(find.text(GalleryCopy.pastRetention(3, 30)), findsNothing);
  });

  testWidgets('an archived event can be deleted with all its photos, after '
      'confirmation', (tester) async {
    final booth = await _gallery(
      tester,
      count: 0,
      location: RoutePaths.events,
      more: (db) => seedGallery(
        db,
        eventId: SeedIds.archived,
        eventIndex: 1,
        count: 2,
        outputBytes: printStandIn,
      ),
    );
    await _tapText(tester, 'Archived · 1');
    await _tapText(tester, 'Delete');
    expect(find.textContaining('2 sessions'), findsWidgets);
    await _tapText(tester, 'Delete them permanently');
    await _tapText(tester, GalleryCopy.deleteConfirm);
    await tester.pumpAndSettle();
    expect(await booth.events.findById(SeedIds.archived), isNull);
    expect(await booth.gallery.sessions(SeedIds.archived), isEmpty);
    expect(find.text('Archived · 0'), findsOneWidget);
  });

  testWidgets('nothing in the Studio offers printing; the printer reads '
      '"Not configured" (AC-0806)', (tester) async {
    final booth = await _gallery(
      tester,
      location: RoutePaths.gallerySession(GalleryIds.session(8)),
    );
    for (final location in [
      RoutePaths.gallerySession(GalleryIds.session(8)),
      RoutePaths.gallery,
      RoutePaths.settingsSection('output'),
    ]) {
      booth.router.go(location);
      await settleRendering(tester, rounds: 3);
      await tester.pumpAndSettle();
      for (final label in ['Print', 'Print photo', 'Send to printer']) {
        expect(find.text(label), findsNothing, reason: '$label at $location');
      }
    }
    expect(find.text('Not configured'), findsOneWidget);
  });

  testWidgets('Booth Mode never reaches the gallery or a session', (
    tester,
  ) async {
    useViewport(tester, TabletViewport.ipadPortrait);
    final booth = await pumpApp(
      tester,
      startAs: StartAs.booth,
      boothEventId: SeedIds.active,
      seed: (db) async {
        await seedEvents(db);
        await seedGallery(db, count: 2);
      },
      seedTemplates: seedTemplateDocuments,
      settle: false,
    );
    await settleRendering(tester, rounds: 3);
    for (final location in [
      RoutePaths.gallery,
      RoutePaths.gallerySession(GalleryIds.session(1)),
      RoutePaths.galleryEvent(SeedIds.active),
      RoutePaths.settingsSection('storage'),
    ]) {
      booth.router.go(location);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(GalleryScreen), findsNothing);
      expect(find.byType(SessionDetailScreen), findsNothing);
      expect(find.byType(BoothScreen), findsOneWidget);
    }
  });
}
