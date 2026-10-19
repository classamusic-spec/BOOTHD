// AC-0704 and AC-0705 with the real renderer and file export: a guest
// session on the simulated camera makes its finished photo at print size
// (1200 x 1800 for 4x6 at 300 DPI) from the unmodified originals, each
// photo in its own photo space and the right way round, saved atomically
// under managed storage and read back against its checksum before the
// session is recorded as completed.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/booth/booth_session_controller.dart';
import 'package:porcelain_photo_booth/domain/repositories/session_repository.dart';
import 'package:porcelain_photo_booth/domain/session/guest_flow.dart';
import 'package:porcelain_photo_booth/infrastructure/composition/dart_ui_composition_renderer.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_event_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_session_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/file_export_service.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/managed_finished_photos.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/managed_storage.dart';

import '../support/fakes.dart';
import '../support/memory_template_store.dart';
import '../support/seed.dart';
import '../support/simulated_camera.dart';
import '../support/test_database.dart';
import 'support/pixels.dart';

/// Waits, in real time, until [done] holds.
Future<void> _until(bool Function() done, String what) async {
  final watch = Stopwatch()..start();
  while (!done()) {
    if (watch.elapsed > const Duration(seconds: 30)) {
      fail('timed out waiting for $what');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a session renders each photo into its own space at print size and '
      'is completed only once the file reads back intact', () async {
    final root = await Directory.systemTemp.createTemp('booth_render_');
    addTearDown(() => root.delete(recursive: true));
    final storage = FileManagedStorage(root: () async => root);
    await storage.prepare();

    final clock = FakeClock(DateTime.utc(2026, 11, 14, 18));
    final db = memoryDatabase(clock: clock);
    addTearDown(db.close);
    // The shortest countdown and pause the event allows: this runs in real
    // time.
    await seedEvents(
      db,
      clock: clock,
      active: (event) => event.copyWith(
        capture: event.capture.copyWith(
          countdownSeconds: 2,
          shotIntervalSeconds: 1,
        ),
      ),
    );
    final templates = MemoryTemplateStore(clock: clock);
    await seedTemplateDocuments(templates);
    final camera = SimulatedCameraService()..store.database = db;
    final sessions = DriftSessionRepository(db, clock: clock);
    final booth = BoothSessionController(
      event: (await DriftEventRepository(db).findById(SeedIds.active))!,
      camera: camera,
      originals: camera.store,
      sessions: sessions,
      export: FileExportService(
        renderer: DartUiCompositionRenderer(),
        storage: storage,
        ids: SequentialIds('d0000000-0000-4000-8000'),
      ),
      finished: ManagedFinishedPhotos(root: () async => root),
      templates: templates.templates,
      assets: templates.assets,
      space: FakeDeviceStorage(),
      clock: clock,
      ids: SequentialIds('c0000000-0000-4000-8000'),
    );
    addTearDown(booth.dispose);

    await booth.start();
    await _until(() => booth.flow.stage == GuestStage.review, 'the review');
    booth.keep();
    await _until(
      () => booth.flow.stage == GuestStage.completed,
      'the finished photo',
    );

    final output = booth.output!;
    final file = File('${root.path}/${output.relativePath}');
    expect(file.existsSync(), isTrue);
    expect(booth.finishedPhoto, file.readAsBytesSync());
    expect(
      Directory('${root.path}/staging').listSync(),
      isEmpty,
      reason: 'committed atomically',
    );
    final record = (await sessions.find(output.sessionId))!;
    expect(record.status, SessionStatus.completed);
    expect(record.outputId, output.id);

    final image = await decodeRgba(booth.finishedPhoto!);
    expect((image.width, image.height), (1200, 1800));
    (int, int, int) pixel(double x, double y) {
      final i =
          ((y * image.height).floor() * image.width +
              (x * image.width).floor()) *
          4;
      return (image.rgba[i], image.rgba[i + 1], image.rgba[i + 2]);
    }

    // The stand-in photo is a gradient from (200, 170, 140) at its top
    // left to (231, 217, 140); the paper is ivory (251, 248, 243). Both
    // photo spaces hold a photo; the paper shows between them.
    for (final y in [0.265, 0.735]) {
      final (r, g, b) = pixel(0.5, y);
      expect(b, lessThan(170), reason: 'a photo at y=$y, not paper');
      expect(r, inInclusiveRange(200, 235));
      expect(g, inInclusiveRange(165, 222));
    }
    final (pr, pg, pb) = pixel(0.5, 0.5);
    expect(pr, greaterThan(240), reason: 'paper between the photos');
    expect(pg, greaterThan(235));
    expect(pb, greaterThan(225));
    // Not mirrored (the event mirrors only the preview): red rises from
    // left to right as in the original.
    final (left, _, _) = pixel(0.15, 0.265);
    final (right, _, _) = pixel(0.85, 0.265);
    expect(left, lessThan(right));
  });
}
