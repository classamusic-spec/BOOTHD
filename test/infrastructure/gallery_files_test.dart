// AC-0803 and AC-0805 (files half), offline: export copies every file
// under its export name after checking it, reports each file that cannot
// go with its reason and passes on exactly what the share sheet said;
// deleted records' files are removed from the journal, including after an
// interruption; thumbnails are small, oriented and made once.
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/composition/scene_images.dart';
import 'package:porcelain_photo_booth/domain/gallery/export_plan.dart';
import 'package:porcelain_photo_booth/domain/services/gallery_services.dart';
import 'package:porcelain_photo_booth/domain/services/operator_files.dart';
import 'package:porcelain_photo_booth/infrastructure/codecs/jpeg_encoder.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_gallery_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_template_catalog.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/managed_storage.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/managed_storage_cleanup.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/managed_thumbnail_store.dart';
import 'package:porcelain_photo_booth/infrastructure/files/managed_gallery_exporter.dart';

import '../support/fakes.dart';
import '../support/gallery_seed.dart';
import '../support/seed.dart';
import '../support/simulated_camera.dart';
import '../support/test_database.dart';

const _anchor = (left: 10.0, top: 10.0, width: 40.0, height: 40.0);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late FileManagedStorage storage;
  late BoothDatabase db;
  late FakeClock clock;
  late DriftGalleryRepository gallery;

  setUp(() async {
    root = Directory.systemTemp.createTempSync('porcelain_gallery_');
    storage = FileManagedStorage(root: () async => root);
    await storage.prepare();
    clock = FakeClock(DateTime.utc(2026, 12, 20, 9));
    db = memoryDatabase(clock: clock);
    await seedEvents(db, clock: clock);
    gallery = DriftGalleryRepository(
      db,
      clock: clock,
      templates: DriftTemplateCatalog(db),
    );
  });

  tearDown(() async {
    await db.close();
    root.deleteSync(recursive: true);
  });

  Future<ExportPlan> plan(
    List<String> ids, [
    ExportContent content = ExportContent.finishedPhotos,
  ]) async => ExportPlan.build(
    await gallery.files(ids),
    content,
    toLocal: (utc) => utc,
  );

  group('export', () {
    late List<List<({String path, String mimeType})>> offered;
    ShareReport answer = const ShareReport(
      ShareOutcome.shared,
      destination: 'com.apple.DocumentManagerUICore.SaveToFiles',
    );

    ManagedGalleryExporter exporter({
      FakeDeviceStorage? space,
      Future<void> Function(File, List<int>)? write,
    }) => ManagedGalleryExporter(
      storage: storage,
      space: space ?? FakeDeviceStorage(),
      ids: SequentialIds('e0000000-0000-4000-8000'),
      share: (files, anchor) async {
        offered.add(files);
        return answer;
      },
      writeCopy:
          write ?? (file, bytes) => file.writeAsBytes(bytes, flush: true),
    );

    setUp(() {
      offered = [];
      answer = const ShareReport(
        ShareOutcome.shared,
        destination: 'com.apple.DocumentManagerUICore.SaveToFiles',
      );
    });

    test('verified copies go out under their export names; sources stay '
        'untouched', () async {
      final ids = await seedGallery(db, count: 4, filesRoot: root);
      final before = {
        for (final file in Directory(
          '${root.path}/outputs',
        ).listSync().whereType<File>())
          file.path: crypto.sha256.convert(file.readAsBytesSync()).toString(),
      };
      final export = await plan(ids, ExportContent.finishedAndOriginals);
      final report = await exporter().export(
        export.parts.single,
        anchor: _anchor,
      );

      expect(report.handedOver, isTrue);
      expect(report.share!.destination, contains('SaveToFiles'));
      expect(report.failures, isEmpty);
      final names = [
        for (final file in offered.single) file.path.split('/').last,
      ];
      expect(names, [
        'hannah-theo-s-wedding-0001-20261114-1800.jpg',
        'hannah-theo-s-wedding-0001-photo1.jpg',
        'hannah-theo-s-wedding-0001-photo2.jpg',
        'hannah-theo-s-wedding-0002-20261114-1801.jpg',
        'hannah-theo-s-wedding-0002-photo1.jpg',
        'hannah-theo-s-wedding-0002-photo2.jpg',
        // Session 3's finished photo failed; its photos still go.
        'hannah-theo-s-wedding-0003-photo1.jpg',
        'hannah-theo-s-wedding-0003-photo2.jpg',
        'hannah-theo-s-wedding-0004-20261114-1803.jpg',
        'hannah-theo-s-wedding-0004-photo1.jpg',
        'hannah-theo-s-wedding-0004-photo2.jpg',
        'hannah-theo-s-wedding-0004-photo2-retake1.jpg',
      ]);
      expect(
        export.failures.single.sessionNumber,
        3,
        reason: 'session 3 failed: no finished photo, reported before copying',
      );
      expect(export.failures.single.problem, ExportProblem.noFinishedPhoto);
      for (final file in offered.single) {
        expect(file.mimeType, 'image/jpeg');
        expect(
          File(file.path).readAsBytesSync(),
          finishedStandIn,
          reason: 'a byte-for-byte copy',
        );
      }
      final after = {
        for (final file in Directory(
          '${root.path}/outputs',
        ).listSync().whereType<File>())
          file.path: crypto.sha256.convert(file.readAsBytesSync()).toString(),
      };
      expect(after, before);
    });

    test('missing and damaged files are reported one by one; the rest still '
        'go', () async {
      final ids = await seedGallery(
        db,
        count: 3,
        filesRoot: root,
        outcome: (_) => SeededOutcome.completed,
      );
      File('${root.path}/outputs/${GalleryIds.output(1)}.jpg').deleteSync();
      final damaged = File('${root.path}/outputs/${GalleryIds.output(2)}.jpg');
      final bytes = damaged.readAsBytesSync()..[100] ^= 0xFF;
      damaged.writeAsBytesSync(bytes);

      final report = await exporter().export(
        (await plan(ids)).parts.single,
        anchor: _anchor,
      );
      expect(report.sent.map((item) => item.sessionNumber), [3]);
      expect(
        {for (final f in report.failures) f.sessionNumber: f.problem},
        {1: ExportProblem.missing, 2: ExportProblem.damaged},
      );
      expect(offered.single, hasLength(1));
    });

    test('nothing is copied when the tablet lacks room for the copies, and '
        'the report says how much is needed', () async {
      final ids = await seedGallery(db, count: 2, filesRoot: root);
      final report = await exporter(space: FakeDeviceStorage(free: 1000))
          .export((await plan(ids)).parts.single, anchor: _anchor);
      expect(report.blockedBySpace, isTrue);
      expect(report.freeBytes, 1000);
      expect(report.requiredBytes, greaterThan(64 * 1024 * 1024));
      expect(report.sent, isEmpty);
      expect(report.failures.map((f) => f.problem).toSet(), {
        ExportProblem.noSpace,
      });
      expect(offered, isEmpty);
      expect(Directory('${root.path}/outgoing').listSync(), isEmpty);
    });

    test('a full volume part-way stops the copies and names every file '
        'that did not go', () async {
      final ids = await seedGallery(
        db,
        count: 4,
        filesRoot: root,
        outcome: (_) => SeededOutcome.completed,
      );
      var writes = 0;
      final report = await exporter(
        write: (file, bytes) async {
          if (++writes == 3) {
            throw const FileSystemException(
              'No space left on device',
              '',
              OSError('No space left on device', 28),
            );
          }
          await file.writeAsBytes(bytes, flush: true);
        },
      ).export((await plan(ids)).parts.single, anchor: _anchor);
      expect(report.sent.map((i) => i.sessionNumber), [1, 2]);
      expect(
        {for (final f in report.failures) f.sessionNumber: f.problem},
        {3: ExportProblem.noSpace, 4: ExportProblem.noSpace},
      );
      expect(
        writes,
        3,
        reason: 'nothing more is tried once the volume is full',
      );
    });

    test('what the share sheet said is passed on as it is', () async {
      final ids = await seedGallery(db, count: 1, filesRoot: root);
      final export = await plan(ids);
      answer = const ShareReport(ShareOutcome.dismissed);
      var report = await exporter().export(
        export.parts.single,
        anchor: _anchor,
      );
      expect(report.share!.outcome, ShareOutcome.dismissed);
      expect(report.handedOver, isFalse);

      answer = const ShareReport(ShareOutcome.unknown);
      report = await exporter().export(export.parts.single, anchor: _anchor);
      expect(report.share!.outcome, ShareOutcome.unknown);
      expect(report.share!.destination, isNull);
      expect(
        report.handedOver,
        isTrue,
        reason: 'the platform could not say; the files may have gone',
      );
    });

    test('each export replaces the copies of the last one, and a restart '
        'clears them', () async {
      final ids = await seedGallery(db, count: 2, filesRoot: root);
      final export = await plan(ids);
      await exporter().export(export.parts.single, anchor: _anchor);
      await exporter().export(export.parts.single, anchor: _anchor);
      expect(Directory('${root.path}/outgoing').listSync(), hasLength(1));
      await storage.prepare();
      expect(Directory('${root.path}/outgoing').listSync(), isEmpty);
    });
  });

  group('cleanup', () {
    test('files of deleted sessions are removed; an interruption before '
        'that only delays it', () async {
      final ids = await seedGallery(db, count: 3, filesRoot: root);
      final outputs = Directory('${root.path}/outputs');
      final originals = Directory('${root.path}/originals');
      expect(outputs.listSync(), hasLength(3));
      // A thumbnail of session 1's finished photo exists too.
      final thumbnail = File(
        '${root.path}/${ManagedThumbnailStore.relativePathFor(ThumbnailKind.output, GalleryIds.output(1))}',
      )..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xD9]);

      await gallery.deleteSessions([ids[0], ids[2]]);
      // The app stops here: records gone, files still on disk.
      expect(outputs.listSync(), hasLength(3));

      final cleanup = ManagedStorageCleanup(
        database: db,
        root: () async => root,
      );
      final result = await cleanup.run();
      expect(result.remaining, 0);
      expect(outputs.listSync().map((f) => f.path.split('/').last), [
        '${GalleryIds.output(2)}.jpg',
      ]);
      expect(originals.listSync(), hasLength(2));
      expect(thumbnail.existsSync(), isFalse);
      expect(await db.select(db.pendingFileDeletions).get(), isEmpty);
    });

    test('a file that cannot be removed stays journaled and goes next '
        'time', () async {
      final ids = await seedGallery(
        db,
        count: 1,
        filesRoot: root,
        outcome: (_) => SeededOutcome.completed,
      );
      await gallery.deleteSessions(ids);
      final stuck = ManagedStorageCleanup(
        database: db,
        root: () async => root,
        delete: (file) async {
          if (file.path.contains('/outputs/')) {
            throw const FileSystemException('busy');
          }
          await file.delete();
        },
      );
      final first = await stuck.run();
      expect(first.remaining, 1);
      final left = await db.select(db.pendingFileDeletions).get();
      expect(left.single.relativePath, 'outputs/${GalleryIds.output(1)}.jpg');

      final again = await ManagedStorageCleanup(
        database: db,
        root: () async => root,
      ).run();
      expect(again.remaining, 0);
      expect(Directory('${root.path}/outputs').listSync(), isEmpty);
    });

    test('nothing outside the photo areas is ever removed', () async {
      final manifest = File('${root.path}/templates/keep.json')
        ..createSync(recursive: true)
        ..writeAsStringSync('{}');
      await db
          .into(db.pendingFileDeletions)
          .insert(
            PendingFileDeletionsCompanion.insert(
              relativePath: 'templates/keep.json',
              queuedAt: clock.now(),
            ),
          );
      await ManagedStorageCleanup(database: db, root: () async => root).run();
      expect(manifest.existsSync(), isTrue);
      expect(await db.select(db.pendingFileDeletions).get(), isEmpty);
    });
  });

  group('thumbnails', () {
    Uint8List gradient(int width, int height) {
      final rgba = Uint8List(width * height * 4);
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final i = (y * width + x) * 4;
          rgba
            ..[i] = (255 * x / width).round()
            ..[i + 1] = 120
            ..[i + 2] = (255 * y / height).round()
            ..[i + 3] = 255;
        }
      }
      return encodeJpeg(rgba, width: width, height: height);
    }

    test('a thumbnail is a small JPEG of the photo, made once and kept '
        'until cleared', () async {
      const id = 'd0000000-0000-4000-8000-000000000001';
      File('${root.path}/outputs/$id.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(gradient(1200, 1800));
      final store = ManagedThumbnailStore(storage: storage);
      const source = ThumbnailSource(
        kind: ThumbnailKind.output,
        id: id,
        relativePath: 'outputs/$id.jpg',
      );
      final first = await store.thumbnail(source);
      expect(first.sublist(0, 2), [0xFF, 0xD8]);
      final kept = File(
        '${root.path}/${ManagedThumbnailStore.relativePathFor(ThumbnailKind.output, id)}',
      );
      expect(kept.existsSync(), isTrue);
      expect(kept.lengthSync(), lessThan(60 * 1024));
      final size = await probeImageSize(first);
      expect((size.width, size.height), (320, 480));

      // The source going away does not matter once the thumbnail exists.
      File('${root.path}/outputs/$id.jpg').deleteSync();
      expect(await store.thumbnail(source), first);
      expect(await store.size(), kept.lengthSync());
      expect(await store.clear(), greaterThan(0));
      expect(kept.existsSync(), isFalse);
      await expectLater(
        store.thumbnail(source),
        throwsA(isA<ThumbnailUnavailable>()),
      );
    });

    test('only managed photo paths are read', () async {
      final store = ManagedThumbnailStore(storage: storage);
      await expectLater(
        store.thumbnail(
          const ThumbnailSource(
            kind: ThumbnailKind.original,
            id: 'x',
            relativePath: '../outside.jpg',
          ),
        ),
        throwsA(isA<ThumbnailUnavailable>()),
      );
    });

    test('many requests at once make each thumbnail once', () async {
      final store = ManagedThumbnailStore(storage: storage);
      final sources = [
        for (var n = 0; n < 6; n++)
          ThumbnailSource(
            kind: ThumbnailKind.original,
            id: 'photo-$n',
            relativePath: 'originals/photo-$n.jpg',
          ),
      ];
      for (final source in sources) {
        File('${root.path}/${source.relativePath}')
          ..createSync(recursive: true)
          ..writeAsBytesSync(SimulatedStillStore.photoBytes);
      }
      final results = await Future.wait([
        for (final source in [...sources, ...sources]) store.thumbnail(source),
      ]);
      expect(results, hasLength(12));
      expect(Directory('${root.path}/thumbnails').listSync(), hasLength(6));
      expect(Directory('${root.path}/staging').listSync(), isEmpty);
    });
  });
}
