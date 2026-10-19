// AC-0807 on the host: finished photos rendered with the event's output
// profile (JPEG at its quality, or PNG), then exported through the
// gallery's exporter under their export names, open in two independent
// decoders, ImageMagick and Python's Pillow: the right format, the
// template's pixel size, 300 dpi (4 x 6 inches) and a full decode. The
// device half (Files, Photos and Gallery apps on the tablets, and a
// computer) is BLOCKED until hardware is available (M08 device procedure).
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/booth/session_renderer.dart';
import 'package:porcelain_photo_booth/domain/gallery/export_plan.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/domain/services/operator_files.dart';
import 'package:porcelain_photo_booth/domain/session/session_plan.dart';
import 'package:porcelain_photo_booth/domain/session/session_shots.dart';
import 'package:porcelain_photo_booth/infrastructure/codecs/jpeg_encoder.dart';
import 'package:porcelain_photo_booth/infrastructure/composition/dart_ui_composition_renderer.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_gallery_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_session_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_template_catalog.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/file_export_service.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/managed_finished_photos.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/managed_storage.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/original_store.dart';
import 'package:porcelain_photo_booth/infrastructure/files/managed_gallery_exporter.dart';

import '../support/fakes.dart';
import '../support/gallery_seed.dart';
import '../support/memory_template_store.dart';
import '../support/seed.dart';
import '../support/simulated_camera.dart';
import '../support/test_database.dart';

bool _has(String tool, List<String> probe) {
  try {
    return Process.runSync(tool, probe).exitCode == 0;
  } on ProcessException {
    return false;
  }
}

Uint8List _cameraPhoto(int seed) {
  const width = 640;
  const height = 480;
  final rgba = Uint8List(width * height * 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      rgba
        ..[i] = (x * 255 ~/ width + seed * 50) % 256
        ..[i + 1] = y * 255 ~/ height
        ..[i + 2] = 140
        ..[i + 3] = 255;
    }
  }
  return encodeJpeg(rgba, width: width, height: height);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final magick = _has('identify', ['-version']);
  final pillow = _has('python3', ['-I', '-c', 'import PIL']);

  for (final output in const [
    OutputProfile(jpegQuality: 92),
    OutputProfile(format: OutputFormat.png),
  ]) {
    final kind = output.format.name;
    test('an exported $kind finished photo opens in independent decoders at '
        '1200 x 1800 and 300 dpi', () async {
      final root = Directory.systemTemp.createTempSync('porcelain_viewer_');
      addTearDown(() => root.deleteSync(recursive: true));
      final storage = FileManagedStorage(root: () async => root);
      await storage.prepare();
      final clock = FakeClock(DateTime.utc(2026, 11, 14, 18));
      final BoothDatabase db = memoryDatabase(clock: clock);
      addTearDown(db.close);
      await seedEvents(db, clock: clock);
      final templates = MemoryTemplateStore(clock: clock);
      await seedTemplateDocuments(templates);
      final originals = OriginalStore(
        database: db,
        root: () async => root,
        writer: storage.writer,
        clock: clock,
      );
      final sessions = DriftSessionRepository(db, clock: clock);
      const id = 'c0000000-0000-4000-8000-000000000001';
      final plan = SessionPlan(
        eventId: SeedIds.active,
        templateRevisionId: TestIds.revisionA1,
        slotIndexes: const [0, 1],
        capture: galleryPlan(SeedIds.active).capture,
        output: output,
        finishTimeoutSeconds: 30,
      );
      await sessions.create(id: id, plan: plan, startedAtUtc: clock.now());
      for (final shot in [0, 1]) {
        final still = await originals.commit(
          id: 'viewer-$shot',
          bytes: _cameraPhoto(shot),
          context: CaptureContext(
            lens: CameraLens.back,
            sensorOrientationDegrees: 90,
            mirrorPreviewRequested: false,
            mirrorOutputRequested: false,
            capturedAtUtc: clock.now(),
          ),
        );
        await sessions.addPhoto(
          id,
          ShotPhoto(
            shot: shot,
            attempt: 1,
            round: 0,
            originalId: still.id,
            capturedAtUtc: clock.now(),
          ),
        );
      }
      await sessions.markReviewing(id);
      await sessions.beginRender(id);
      final renderer = SessionRenderer(
        export: FileExportService(
          renderer: DartUiCompositionRenderer(),
          storage: storage,
          ids: SequentialIds('d0000000-0000-4000-8000'),
        ),
        finished: ManagedFinishedPhotos(root: () async => root),
        templates: templates.templates,
        assets: templates.assets,
        originals: originals,
      );
      final (exported, _) = await renderer.render(
        (await sessions.find(id))!.shots,
      );
      await sessions.complete(id, exported);

      // Out through the gallery exporter, as the operator would.
      final gallery = DriftGalleryRepository(
        db,
        clock: clock,
        templates: DriftTemplateCatalog(db),
      );
      final exportPlan = ExportPlan.build(
        await gallery.files([id]),
        ExportContent.finishedAndOriginals,
        toLocal: (utc) => utc,
      );
      late List<({String path, String mimeType})> offered;
      final report =
          await ManagedGalleryExporter(
            storage: storage,
            space: FakeDeviceStorage(),
            ids: SequentialIds('e0000000-0000-4000-8000'),
            share: (files, anchor) async {
              offered = files;
              return const ShareReport(ShareOutcome.shared);
            },
          ).export(
            exportPlan.parts.single,
            anchor: (left: 0, top: 0, width: 1, height: 1),
          );
      expect(report.failures, isEmpty);
      final finished = offered.first.path;
      expect(
        finished.split('/').last,
        matches(
          RegExp(
            r'^hannah-theo-s-wedding-0001-20261114-\d{4}\.'
            '${output.format == OutputFormat.png ? 'png' : 'jpg'}\$',
          ),
        ),
      );

      if (magick) {
        final identify = Process.runSync('identify', [
          '-format',
          '%m %w %h %x %y %U',
          finished,
        ]);
        expect(identify.exitCode, 0, reason: '${identify.stderr}');
        final fields = (identify.stdout as String).trim().split(' ');
        expect(fields[0], output.format == OutputFormat.png ? 'PNG' : 'JPEG');
        expect(fields.sublist(1, 3), ['1200', '1800']);
        // PNG stores its resolution per metre, which ImageMagick reports
        // per centimetre; JPEG's JFIF header stores it per inch.
        final perInch = switch (fields[5]) {
          'PixelsPerInch' => 1.0,
          'PixelsPerCentimeter' => 2.54,
          final units => fail('no print resolution units: $units'),
        };
        expect((double.parse(fields[3]) * perInch).round(), 300);
        expect((double.parse(fields[4]) * perInch).round(), 300);
        // A full decode, warnings treated as errors.
        final decode = Process.runSync('convert', [
          '-regard-warnings',
          finished,
          'null:',
        ]);
        expect(decode.exitCode, 0, reason: '${decode.stderr}');
        // The camera photos exported beside it open too.
        for (final photo in offered.skip(1)) {
          final check = Process.runSync('identify', [photo.path]);
          expect(check.exitCode, 0, reason: '${check.stderr}');
        }
      }
      if (pillow) {
        final result = Process.runSync('python3', [
          '-I',
          '-c',
          'import sys\n'
              'from PIL import Image\n'
              'im = Image.open(sys.argv[1])\n'
              'im.load()\n'
              'dpi = im.info.get("dpi") or (0, 0)\n'
              'print(im.format, im.size[0], im.size[1], round(dpi[0]), '
              'round(dpi[1]))\n',
          finished,
        ]);
        expect(result.exitCode, 0, reason: '${result.stderr}');
        expect(
          (result.stdout as String).trim(),
          '${output.format == OutputFormat.png ? 'PNG' : 'JPEG'} 1200 1800 300 300',
        );
      }
      if (!magick && !pillow) {
        markTestSkipped('Neither ImageMagick nor Pillow is installed.');
      }
    });
  }
}
