// AC-0801, AC-0802, AC-0805 (records half): the gallery's index, filters
// and details at large counts, the export history, and deletions that
// remove records in one transaction and journal every file they owned.
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/gallery/export_plan.dart';
import 'package:porcelain_photo_booth/domain/gallery/gallery_models.dart';
import 'package:porcelain_photo_booth/domain/gallery/gallery_search.dart';
import 'package:porcelain_photo_booth/domain/repositories/gallery_repository.dart';
import 'package:porcelain_photo_booth/domain/repositories/session_repository.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/domain/services/operator_files.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_gallery_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_session_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_template_catalog.dart';

import '../support/fakes.dart';
import '../support/gallery_seed.dart';
import '../support/seed.dart';
import '../support/test_database.dart';

void main() {
  late BoothDatabase db;
  late FakeClock clock;
  late DriftGalleryRepository gallery;

  setUp(() async {
    clock = FakeClock(DateTime.utc(2026, 12, 20, 9));
    db = memoryDatabase(clock: clock);
    await seedEvents(db, clock: clock);
    gallery = DriftGalleryRepository(
      db,
      clock: clock,
      templates: DriftTemplateCatalog(db),
    );
  });

  tearDown(() => db.close());

  Future<List<String>> journal() async => [
    for (final row in await (db.select(
      db.pendingFileDeletions,
    )..orderBy([(p) => OrderingTerm.asc(p.relativePath)])).get())
      row.relativePath,
  ];

  test('events list their session counts and dates, busiest first', () async {
    await seedGallery(db, count: 12);
    await seedGallery(
      db,
      eventId: SeedIds.archived,
      eventIndex: 1,
      count: 3,
      firstStart: DateTime.utc(2025, 12, 19, 20),
    );
    final events = await gallery.events();
    expect(events.map((e) => e.eventId), [
      SeedIds.active,
      SeedIds.archived,
      SeedIds.draft,
    ]);
    final wedding = events.first;
    expect(wedding.title, 'Hannah & Theo’s wedding');
    expect(wedding.sessionCount, 12);
    // Sessions 5 (left early), 7 (waiting) and 9 (left in review) have no
    // finished photo; 3 failed.
    expect(wedding.finishedCount, 8);
    expect(wedding.firstSessionAtUtc, DateTime.utc(2026, 11, 14, 18));
    expect(wedding.lastSessionAtUtc, DateTime.utc(2026, 11, 14, 18, 11));
    expect(events.last.sessionCount, 0);
    expect(events.last.firstSessionAtUtc, isNull);
  });

  test('the index lists sessions newest first with what each one '
      'amounts to', () async {
    await seedGallery(db, count: 12);
    final sessions = await gallery.sessions(SeedIds.active);
    expect(sessions.map((s) => s.number), [for (var n = 12; n >= 1; n--) n]);
    GallerySession number(int n) => sessions.firstWhere((s) => s.number == n);

    expect(number(1).state, GallerySessionState.finished);
    expect(
      number(1).latestOutput!.id,
      GalleryIds.output(1, version: 2),
      reason: 'the newest finished photo is the one shown',
    );
    expect(number(1).outputCount, 2);
    expect(number(3).state, GallerySessionState.renderFailed);
    expect(number(3).setComplete, isTrue);
    expect(number(5).state, GallerySessionState.notFinished);
    expect(number(5).setComplete, isFalse);
    expect(number(5).photoCount, 1);
    expect(number(7).state, GallerySessionState.waitingToFinish);
    expect(number(9).state, GallerySessionState.notFinished);
    expect(number(9).setComplete, isTrue);
    expect(number(8).photoCount, 3, reason: 'a retake of the second photo');
    expect(number(8).coverOriginalId, GalleryIds.original(8, 0, 1));
    expect(number(2).latestOutput!.widthPx, 1200);
    expect(number(2).lastExportedAtUtc, isNull);

    expect(sessions.where(GalleryFilter.finished.shows).length, 8);
    expect(
      sessions.where(GalleryFilter.needsAttention.shows).map((s) => s.number),
      [7, 3],
    );
    expect(
      sessions.where(GalleryFilter.notFinished.shows).map((s) => s.number),
      [9, 5],
    );
  });

  test('thousands of sessions list, filter and search quickly', () async {
    const count = 5000;
    await seedGallery(db, count: count);
    final watch = Stopwatch()..start();
    final sessions = await gallery.sessions(SeedIds.active);
    final elapsed = watch.elapsed;
    // ignore: avoid_print
    print('gallery index of $count sessions: ${elapsed.inMilliseconds} ms');
    expect(sessions, hasLength(count));
    expect(elapsed, lessThan(const Duration(seconds: 10)));

    final byFilter = {
      for (final filter in GalleryFilter.values)
        filter: sessions.where(filter.shows).length,
    };
    var expected = <GalleryFilter, int>{
      for (final filter in GalleryFilter.values) filter: 0,
    };
    for (var n = 1; n <= count; n++) {
      final filter = switch (mixedOutcome(n)) {
        SeededOutcome.completed ||
        SeededOutcome.rerendered => GalleryFilter.finished,
        SeededOutcome.rendering ||
        SeededOutcome.failed => GalleryFilter.needsAttention,
        _ => GalleryFilter.notFinished,
      };
      expected = {...expected, filter: expected[filter]! + 1};
    }
    expected = {...expected, GalleryFilter.all: count};
    expect(byFilter, expected);

    final search = GallerySearch.parse('#4321')!;
    expect(sessions.where(search.matches).single.number, 4321);
    final atTime = GallerySearch.parse('18:30')!;
    // A time of day matches on every day of the event, newest first.
    expect(
      sessions
          .where((s) => atTime.matches(s, toLocal: (utc) => utc))
          .map((s) => s.number),
      [4351, 2911, 1471, 31],
    );
  });

  test('a session shows its photos, retakes, template revision, finished '
      'photos and exports (AC-0802)', () async {
    await seedGallery(db, count: 8);
    final id = GalleryIds.session(8);
    await gallery.recordExport(
      ExportRecord(
        id: 'f0000000-0000-4000-8000-000000000001',
        createdAtUtc: DateTime.utc(2026, 11, 20, 10),
        outcome: ShareOutcome.shared,
        destination: 'com.apple.UIKit.activity.AirDrop',
        files: [
          ExportItem(
            sessionId: id,
            sessionNumber: 8,
            kind: ExportFileKind.finished,
            sourceId: GalleryIds.output(8),
            relativePath: 'outputs/${GalleryIds.output(8)}.jpg',
            sha256: 'e' * 64,
            byteLength: 812345,
            fileName: 'wedding-0008-20261114-1807.jpg',
          ),
        ],
        failureCount: 1,
      ),
    );
    final detail = (await gallery.detail(id))!;
    expect(detail.number, 8);
    expect(detail.eventTitle, 'Hannah & Theo’s wedding');
    expect(detail.session.status, SessionStatus.completed);
    expect(detail.session.photos, hasLength(3));
    expect(detail.session.shots.slotBindings, {
      0: GalleryIds.original(8, 0, 1),
      1: GalleryIds.original(8, 1, 2),
    }, reason: 'the retake fills the second space; the first is kept');
    expect(detail.originals.keys, hasLength(3));
    final retake = detail.originals[GalleryIds.original(8, 1, 2)]!;
    expect((retake.widthPx, retake.heightPx), (4032, 3024));
    expect(retake.lens, CameraLens.front);
    expect(detail.template!.templateName, 'Two-up classic');
    expect(detail.template!.revisionNumber, 1);
    expect(detail.outputs.single.id, GalleryIds.output(8));
    expect(detail.outputs.single.origin, SessionOutputOrigin.session);
    final export = detail.exports.single;
    expect(export.destination, 'com.apple.UIKit.activity.AirDrop');
    expect(export.fileNames, ['wedding-0008-20261114-1807.jpg']);
    expect(await gallery.detail(GalleryIds.session(99)), isNull);

    final index = await gallery.sessions(SeedIds.active);
    expect(
      index.firstWhere((s) => s.number == 8).lastExportedAtUtc,
      DateTime.utc(2026, 11, 20, 10),
    );
  });

  test('files for export keep the order asked for, with every take', () async {
    await seedGallery(db, count: 8);
    final files = await gallery.files([
      GalleryIds.session(8),
      GalleryIds.session(99),
      GalleryIds.session(5),
    ]);
    expect(files.map((f) => f.number), [8, 5]);
    expect(files.first.photos.map((p) => (p.shot, p.attempt)), [
      (0, 1),
      (1, 1),
      (1, 2),
    ]);
    expect(files.first.outputs.single.id, GalleryIds.output(8));
    expect(files.last.outputs, isEmpty);
    expect(files.first.eventTitle, 'Hannah & Theo’s wedding');
  });

  test('storage use is counted per event and for the whole booth', () async {
    await seedGallery(db, count: 4);
    await db
        .into(db.originalPhotos)
        .insert(
          OriginalPhotosCompanion.insert(
            id: 'camera-test-1',
            relativePath: 'originals/camera-test-1.jpg',
            widthPx: 4032,
            heightPx: 3024,
            byteLength: 2500000,
            sha256: 'b' * 64,
            lens: CameraLens.back,
            sensorOrientation: 90,
            deviceOrientation: CaptureOrientation.landscapeLeft,
            mirrorPreview: false,
            mirrorOutput: false,
            origin: CaptureOrigin.diagnostics,
            capturedAt: DateTime.utc(2026, 11, 14, 17),
            committedAt: DateTime.utc(2026, 11, 14, 17),
          ),
        );
    final event = await gallery.usage(eventId: SeedIds.active);
    // Four sessions: 1 has two finished photos, 2 and 4 one, 3 failed;
    // eight photos plus session 4's retake.
    expect(event.sessionCount, 4);
    expect(event.finishedCount, 4);
    expect(event.finishedBytes, 4 * 812345);
    expect(event.originalCount, 9);
    expect(event.originalBytes, 9 * 3000000);
    expect(event.unassignedCount, 0);
    final all = await gallery.usage();
    expect(all.unassignedCount, 1);
    expect(all.unassignedBytes, 2500000);
    expect(all.totalBytes, 4 * 812345 + 9 * 3000000 + 2500000);
  });

  test('sessions past a cutoff are found oldest first, never one a guest '
      'is in', () async {
    await seedGallery(db, count: 6);
    final cutoff = DateTime.utc(2026, 11, 14, 18, 3);
    expect(await gallery.sessionsStartedBefore(SeedIds.active, cutoff), [
      GalleryIds.session(1),
      GalleryIds.session(2),
      GalleryIds.session(3),
    ]);
    await DriftSessionRepository(db, clock: clock).create(
      id: 'c9999999-0000-4000-8000-000000000001',
      plan: galleryPlan(SeedIds.active),
      startedAtUtc: DateTime.utc(2026, 11, 14, 17),
    );
    expect(
      await gallery.sessionsStartedBefore(SeedIds.active, cutoff),
      hasLength(3),
      reason: 'a session still capturing is left alone',
    );
  });

  test('deleting sessions removes every record at once and journals each '
      'file, thumbnails included (AC-0805)', () async {
    await seedGallery(db, count: 4);
    await gallery.recordExport(
      ExportRecord(
        id: 'f0000000-0000-4000-8000-000000000001',
        createdAtUtc: clock.now(),
        outcome: ShareOutcome.unknown,
        files: [
          ExportItem(
            sessionId: GalleryIds.session(1),
            sessionNumber: 1,
            kind: ExportFileKind.finished,
            sourceId: GalleryIds.output(1),
            relativePath: 'outputs/${GalleryIds.output(1)}.jpg',
            sha256: 'e' * 64,
            byteLength: 812345,
            fileName: 'wedding-0001-20261114-1800.jpg',
          ),
        ],
        failureCount: 0,
      ),
    );
    final receipt = await gallery.deleteSessions([
      GalleryIds.session(1),
      GalleryIds.session(4),
    ]);
    expect(receipt.sessions, 2);
    expect(receipt.outputs, 3);
    expect(receipt.originals, 5);
    expect(receipt.files, 8);
    final paths = await journal();
    expect(paths, hasLength(16), reason: 'eight files and their thumbnails');
    expect(
      paths,
      containsAll([
        'outputs/${GalleryIds.output(1)}.jpg',
        'outputs/${GalleryIds.output(1, version: 2)}.jpg',
        'thumbnails/output-${GalleryIds.output(4)}.jpg',
        'originals/${GalleryIds.original(4, 1, 2)}.jpg',
        'thumbnails/original-${GalleryIds.original(1, 0, 1)}.jpg',
      ]),
    );
    final left = await gallery.sessions(SeedIds.active);
    expect(left.map((s) => s.number), [3, 2]);
    expect(await db.select(db.exportBatchItems).get(), isEmpty);
    expect(
      (await db.select(db.exportBatches).get()).single.fileCount,
      1,
      reason: 'the export keeps its counts',
    );
    expect(await db.select(db.originalPhotos).get(), hasLength(4));
    expect(await gallery.sessions(SeedIds.active), hasLength(2));
  });

  test('a deletion is all or nothing', () async {
    await seedGallery(db, count: 3);
    await db.customStatement(
      'CREATE TEMP TRIGGER refuse_two BEFORE DELETE ON capture_sessions '
      "WHEN OLD.id = '${GalleryIds.session(2)}' "
      "BEGIN SELECT RAISE(ABORT, 'refused'); END",
    );
    await expectLater(
      gallery.deleteSessions([GalleryIds.session(1), GalleryIds.session(2)]),
      throwsA(isA<GalleryException>()),
    );
    expect(await gallery.sessions(SeedIds.active), hasLength(3));
    expect(await journal(), isEmpty);
    expect(await db.select(db.originalPhotos).get(), hasLength(6));
  });

  test('a session a guest is in is never deleted', () async {
    await seedGallery(db, count: 2);
    const busy = 'c9999999-0000-4000-8000-000000000001';
    await DriftSessionRepository(db, clock: clock).create(
      id: busy,
      plan: galleryPlan(SeedIds.active),
      startedAtUtc: clock.now(),
    );
    await expectLater(
      gallery.deleteSessions([GalleryIds.session(1), busy]),
      throwsA(
        isA<GalleryException>().having(
          (e) => e.code,
          'code',
          'GALLERY_SESSION_IN_PROGRESS',
        ),
      ),
    );
    expect(await gallery.sessions(SeedIds.active), hasLength(3));
  });

  test('only an archived event can be deleted, with all of its '
      'sessions', () async {
    await seedGallery(db, count: 2);
    await seedGallery(db, eventId: SeedIds.archived, eventIndex: 1, count: 3);
    await expectLater(
      gallery.deleteEvent(SeedIds.active),
      throwsA(
        isA<GalleryException>().having(
          (e) => e.code,
          'code',
          'GALLERY_EVENT_NOT_ARCHIVED',
        ),
      ),
    );
    final receipt = await gallery.deleteEvent(SeedIds.archived);
    expect(receipt.sessions, 3);
    expect(await gallery.sessions(SeedIds.archived), isEmpty);
    expect(
      (await gallery.events()).map((e) => e.eventId),
      isNot(contains(SeedIds.archived)),
    );
    expect(await gallery.sessions(SeedIds.active), hasLength(2));
    expect(await journal(), hasLength(receipt.files * 2));
  });

  test('camera photos in no session can be cleared; session photos '
      'stay', () async {
    await seedGallery(db, count: 2);
    await db
        .into(db.originalPhotos)
        .insert(
          OriginalPhotosCompanion.insert(
            id: 'late-photo',
            relativePath: 'originals/late-photo.jpg',
            widthPx: 4032,
            heightPx: 3024,
            byteLength: 2500000,
            sha256: 'b' * 64,
            lens: CameraLens.front,
            sensorOrientation: 270,
            deviceOrientation: CaptureOrientation.portraitUp,
            mirrorPreview: true,
            mirrorOutput: false,
            origin: CaptureOrigin.session,
            capturedAt: DateTime.utc(2026, 11, 14, 18, 30),
            committedAt: DateTime.utc(2026, 11, 14, 18, 30),
          ),
        );
    final receipt = await gallery.deleteUnassignedOriginals();
    expect(receipt.originals, 1);
    expect(await journal(), [
      'originals/late-photo.jpg',
      'thumbnails/original-late-photo.jpg',
    ]);
    expect(await db.select(db.originalPhotos).get(), hasLength(4));
  });

  test('a file no record refers to can be discarded; a recorded one '
      'cannot', () async {
    await seedGallery(db, count: 1);
    await gallery.discardFiles([
      'outputs/d9999999-0000-4000-8000-000000000001.jpg',
      'outputs/${GalleryIds.output(1)}.jpg',
    ]);
    expect(await journal(), [
      'outputs/d9999999-0000-4000-8000-000000000001.jpg',
    ]);
  });
}
