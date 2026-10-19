// AC-0804 with the real renderer, originals store and file export: making
// a session's finished photo again from its unmodified originals and
// frozen template revision gives the same file, byte for byte, as a new
// output; the earlier output, the originals and the session's record do
// not change. Sessions still waiting are finished; failed and abandoned
// sessions with a full set can be made; incomplete sets and missing
// originals are refused without recording anything.
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/booth/session_renderer.dart';
import 'package:porcelain_photo_booth/core/gallery/gallery_service.dart';
import 'package:porcelain_photo_booth/domain/gallery/gallery_models.dart';
import 'package:porcelain_photo_booth/domain/repositories/session_repository.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
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
import 'package:porcelain_photo_booth/infrastructure/file_store/managed_storage_cleanup.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/original_store.dart';

import '../support/fakes.dart';
import '../support/gallery_seed.dart';
import '../support/memory_template_store.dart';
import '../support/seed.dart';
import '../support/test_database.dart';

/// A camera-like photo: a diagonal gradient, different per [seed].
Uint8List _photo(int seed) {
  const width = 480;
  const height = 360;
  final rgba = Uint8List(width * height * 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      rgba
        ..[i] = (x * 255 ~/ width + seed * 40) % 256
        ..[i + 1] = (y * 255 ~/ height) % 256
        ..[i + 2] = (seed * 90) % 256
        ..[i + 3] = 255;
    }
  }
  return encodeJpeg(rgba, width: width, height: height);
}

String _sha(File file) =>
    crypto.sha256.convert(file.readAsBytesSync()).toString();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late BoothDatabase db;
  late FakeClock clock;
  late DriftSessionRepository sessions;
  late OriginalStore originals;
  late SessionRenderer renderer;
  late GalleryService service;
  late DriftGalleryRepository gallery;
  var photoSeed = 0;

  setUp(() async {
    root = Directory.systemTemp.createTempSync('porcelain_rerender_');
    final storage = FileManagedStorage(root: () async => root);
    await storage.prepare();
    clock = FakeClock(DateTime.utc(2026, 11, 14, 18));
    db = memoryDatabase(clock: clock);
    await seedEvents(db, clock: clock);
    final templates = MemoryTemplateStore(clock: clock);
    await seedTemplateDocuments(templates);
    sessions = DriftSessionRepository(db, clock: clock);
    originals = OriginalStore(
      database: db,
      root: () async => root,
      writer: storage.writer,
      clock: clock,
    );
    renderer = SessionRenderer(
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
    gallery = DriftGalleryRepository(
      db,
      clock: clock,
      templates: DriftTemplateCatalog(db),
    );
    service = GalleryService(
      gallery: gallery,
      sessions: sessions,
      renderer: renderer,
      cleanup: ManagedStorageCleanup(database: db, root: () async => root),
    );
  });

  tearDown(() async {
    await db.close();
    root.deleteSync(recursive: true);
  });

  /// A session with [photos] committed originals (shot, attempt).
  Future<String> session(
    String id, {
    List<(int, int)> photos = const [(0, 1), (1, 1)],
  }) async {
    await sessions.create(
      id: id,
      plan: galleryPlan(SeedIds.active),
      startedAtUtc: clock.now(),
    );
    for (final (shot, attempt) in photos) {
      clock.advance(const Duration(seconds: 5));
      final still = await originals.commit(
        id: 'orig-${id.substring(id.length - 4)}-$shot-$attempt',
        bytes: _photo(photoSeed++),
        context: CaptureContext(
          lens: CameraLens.front,
          sensorOrientationDegrees: 270,
          mirrorPreviewRequested: true,
          mirrorOutputRequested: false,
          capturedAtUtc: clock.now(),
        ),
      );
      await sessions.addPhoto(
        id,
        ShotPhoto(
          shot: shot,
          attempt: attempt,
          round: 0,
          originalId: still.id,
          capturedAtUtc: clock.now(),
        ),
      );
    }
    return id;
  }

  /// [id] completed the way the booth completes it.
  Future<SessionOutput> complete(String id) async {
    await sessions.markReviewing(id);
    await sessions.beginRender(id);
    final record = (await sessions.find(id))!;
    final (exported, _) = await renderer.render(record.shots);
    return sessions.complete(id, exported);
  }

  Map<String, String> originalChecksums() => {
    for (final file in Directory(
      '${root.path}/originals',
    ).listSync().whereType<File>())
      file.path: _sha(file),
  };

  test('a re-render is the same file again, kept beside the first; '
      'nothing else changes', () async {
    const id = 'c0000000-0000-4000-8000-000000000001';
    await session(id, photos: const [(0, 1), (1, 1), (1, 2)]);
    final first = await complete(id);
    final before = (await sessions.find(id))!;
    final originalsBefore = originalChecksums();
    final firstFile = File('${root.path}/${first.relativePath}');
    final firstSha = _sha(firstFile);
    expect(firstSha, first.sha256);

    clock.advance(const Duration(days: 3));
    final again = await service.render(id);
    final third = await service.render(id);

    expect(again.id, isNot(first.id));
    expect(again.origin, SessionOutputOrigin.rerender);
    expect(again.relativePath, isNot(first.relativePath));
    expect(
      again.sha256,
      first.sha256,
      reason: 'the same originals and revision give the same bytes',
    );
    expect(third.sha256, first.sha256);
    expect((again.widthPx, again.heightPx), (1200, 1800));
    expect(_sha(File('${root.path}/${again.relativePath}')), again.sha256);

    // The first output, the originals and the session are as they were.
    expect(_sha(firstFile), firstSha);
    expect(originalChecksums(), originalsBefore);
    final after = (await sessions.find(id))!;
    expect(after.status, SessionStatus.completed);
    expect(after.outputId, first.id);
    expect(after.updatedAtUtc, before.updatedAtUtc);
    expect(after.renderAttempts, before.renderAttempts);
    final outputs = await sessions.outputs(id);
    expect(outputs.map((o) => o.id), [first.id, again.id, third.id]);
    final listed = (await gallery.sessions(SeedIds.active)).single;
    expect(listed.latestOutput!.id, third.id);
    expect(listed.outputCount, 3);
  });

  test('a session waiting for its finished photo is finished', () async {
    const id = 'c0000000-0000-4000-8000-000000000002';
    await session(id);
    await sessions.markReviewing(id);
    await sessions.beginRender(id);
    final output = await service.render(id);
    final record = (await sessions.find(id))!;
    expect(record.status, SessionStatus.completed);
    expect(record.outputId, output.id);
    expect(record.renderAttempts, 2);
    expect(output.origin, SessionOutputOrigin.session);
  });

  test('failed and abandoned sessions with a full set get a finished photo; '
      'their record still says how they ended', () async {
    const failed = 'c0000000-0000-4000-8000-000000000003';
    await session(failed);
    await sessions.markReviewing(failed);
    await sessions.beginRender(failed);
    await sessions.end(
      failed,
      status: SessionStatus.failed,
      reason: SessionEndReason.renderFailed,
    );
    const left = 'c0000000-0000-4000-8000-000000000004';
    await session(left);
    await sessions.end(
      left,
      status: SessionStatus.abandoned,
      reason: SessionEndReason.operatorExit,
    );

    for (final id in [failed, left]) {
      final output = await service.render(id);
      expect(output.origin, SessionOutputOrigin.rerender);
      final record = (await sessions.find(id))!;
      expect(record.outputId, isNull);
      expect(record.status, isNot(SessionStatus.completed));
    }
    final listed = await gallery.sessions(SeedIds.active);
    expect(listed.map((s) => s.state).toSet(), {GallerySessionState.finished});
    expect(listed.map((s) => s.status).toSet(), {
      SessionStatus.failed,
      SessionStatus.abandoned,
    });
  });

  test('an incomplete set or a missing original is refused and nothing is '
      'recorded', () async {
    const partial = 'c0000000-0000-4000-8000-000000000005';
    await session(partial, photos: const [(0, 1)]);
    await sessions.end(
      partial,
      status: SessionStatus.abandoned,
      reason: SessionEndReason.timedOut,
    );
    await expectLater(
      service.render(partial),
      throwsA(
        isA<GalleryActionFailure>().having(
          (f) => f.code,
          'code',
          'SESSION_SET_INCOMPLETE',
        ),
      ),
    );

    const damaged = 'c0000000-0000-4000-8000-000000000006';
    await session(damaged);
    await complete(damaged);
    final record = (await sessions.find(damaged))!;
    final photo = record.shots.selected(1)!;
    File('${root.path}/originals/${photo.originalId}.jpg').deleteSync();
    await expectLater(
      service.render(damaged),
      throwsA(
        isA<GalleryActionFailure>().having(
          (f) => f.code,
          'code',
          'RENDER_MISSING_PHOTO',
        ),
      ),
    );
    expect(await sessions.outputs(damaged), hasLength(1));
    expect(await sessions.outputs(partial), isEmpty);
    expect(
      Directory('${root.path}/outputs').listSync(),
      hasLength(1),
      reason: 'a refused render leaves no file behind',
    );
  });
}
