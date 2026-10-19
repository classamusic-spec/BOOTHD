// AC-0803 (flow): a batch export offers each part in turn, stays on a part
// whose share sheet was closed, records only parts whose files left, and
// totals every file that did not go with its reason.
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/gallery/gallery_export_run.dart';
import 'package:porcelain_photo_booth/domain/gallery/export_plan.dart';
import 'package:porcelain_photo_booth/domain/services/operator_files.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_gallery_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_template_catalog.dart';

import '../support/fake_gallery.dart';
import '../support/fakes.dart';
import '../support/gallery_seed.dart';
import '../support/seed.dart';
import '../support/test_database.dart';

const _anchor = (left: 0.0, top: 0.0, width: 10.0, height: 10.0);

void main() {
  late BoothDatabase db;
  late FakeClock clock;
  late DriftGalleryRepository gallery;
  late FakeGalleryExporter exporter;

  setUp(() async {
    clock = FakeClock(DateTime.utc(2026, 12, 20, 9));
    db = memoryDatabase(clock: clock);
    await seedEvents(db, clock: clock);
    gallery = DriftGalleryRepository(
      db,
      clock: clock,
      templates: DriftTemplateCatalog(db),
    );
    exporter = FakeGalleryExporter();
  });

  tearDown(() => db.close());

  GalleryExportRun run(List<String> ids, {ExportContent? content}) =>
      GalleryExportRun(
        gallery: gallery,
        exporter: exporter,
        clock: clock,
        ids: SequentialIds('f0000000-0000-4000-8000'),
        sessionIds: ids,
        content: content ?? ExportContent.finishedPhotos,
        toLocal: (utc) => utc,
      );

  test('parts go one by one; only parts that left are recorded', () async {
    final ids = await seedGallery(
      db,
      count: 450,
      outcome: (_) => SeededOutcome.completed,
    );
    final export = run(ids);
    addTearDown(export.dispose);
    await export.prepare();
    expect(export.stage, ExportRunStage.ready);
    expect(export.partCount, 3);

    await export.exportPart(_anchor);
    expect(export.stage, ExportRunStage.between);
    expect(export.partIndex, 1);

    // The operator closes the sheet for part two: it waits to be offered
    // again, and nothing is recorded for it.
    exporter.share = const ShareReport(ShareOutcome.dismissed);
    await export.exportPart(_anchor);
    expect(export.partIndex, 1);
    expect(export.lastReport!.handedOver, isFalse);

    exporter.share = const ShareReport(
      ShareOutcome.shared,
      destination: 'com.google.android.apps.nbu.files/.SaveActivity',
    );
    await export.exportPart(_anchor);
    await export.exportPart(_anchor);
    expect(export.stage, ExportRunStage.finished);
    expect(export.handedOverCount, 450);
    expect(export.failures, isEmpty);

    final batches = await db.select(db.exportBatches).get();
    expect(batches.map((b) => b.fileCount), [200, 200, 50]);
    expect(
      batches.last.destination,
      'com.google.android.apps.nbu.files/.SaveActivity',
    );
    expect(await db.select(db.exportBatchItems).get(), hasLength(450));
  });

  test('a part can be skipped; failures from the plan and the copies are '
      'all reported', () async {
    final ids = await seedGallery(db, count: 12);
    exporter.missing.add(GalleryIds.output(2));
    final export = run(ids);
    addTearDown(export.dispose);
    await export.prepare();
    await export.exportPart(_anchor);
    expect(export.stage, ExportRunStage.finished);
    expect(
      {for (final f in export.failures) f.sessionNumber: f.problem},
      {
        2: ExportProblem.missing,
        3: ExportProblem.noFinishedPhoto,
        5: ExportProblem.noFinishedPhoto,
        7: ExportProblem.noFinishedPhoto,
        9: ExportProblem.noFinishedPhoto,
      },
    );
    expect(export.handedOverCount, 7);

    final skipped = run(ids);
    addTearDown(skipped.dispose);
    await skipped.prepare();
    skipped.skipPart();
    expect(skipped.stage, ExportRunStage.finished);
    expect(skipped.handedOverCount, 0);
  });

  test('a part refused for space stays to be tried again', () async {
    final ids = await seedGallery(db, count: 2);
    exporter.freeBytes = 1000;
    final export = run(ids);
    addTearDown(export.dispose);
    await export.prepare();
    await export.exportPart(_anchor);
    expect(export.lastReport!.blockedBySpace, isTrue);
    expect(export.partIndex, 0);
    expect(export.stage, ExportRunStage.between);
    exporter.freeBytes = null;
    await export.exportPart(_anchor);
    expect(export.stage, ExportRunStage.finished);
    expect(export.handedOverCount, 2);
  });

  test('sessions with nothing to export finish at once with their '
      'reasons', () async {
    final ids = await seedGallery(
      db,
      count: 2,
      outcome: (_) => SeededOutcome.abandonedIncomplete,
    );
    final export = run(ids);
    addTearDown(export.dispose);
    await export.prepare();
    expect(export.stage, ExportRunStage.finished);
    expect(export.partCount, 0);
    expect(export.failures, hasLength(2));
    expect(exporter.parts, isEmpty);
  });
}
