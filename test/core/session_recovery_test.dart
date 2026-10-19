// AC-0707 (startup half): sessions the app never finished are settled at
// startup. Sessions cut off while photos were taken or reviewed end as
// abandoned with every photo kept; a finished photo being made keeps its
// checkpoint to be made again, until it has failed three times.
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/booth/session_recovery.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/repositories/session_repository.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/domain/services/composition_renderer.dart';
import 'package:porcelain_photo_booth/domain/services/export_service.dart';
import 'package:porcelain_photo_booth/domain/session/session_plan.dart';
import 'package:porcelain_photo_booth/domain/session/session_shots.dart';
import 'package:porcelain_photo_booth/domain/value_objects/orientation.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_session_repository.dart';

import '../support/fakes.dart';
import '../support/seed.dart';
import '../support/test_database.dart';

String _id(int n) =>
    'c0000000-0000-4000-8000-${n.toRadixString(16).padLeft(12, '0')}';

void main() {
  late BoothDatabase db;
  late FakeClock clock;
  late DriftSessionRepository sessions;

  final plan = SessionPlan(
    eventId: SeedIds.active,
    templateRevisionId: TestIds.revisionA1,
    slotIndexes: const [0, 1],
    capture: const CaptureSettings(
      lens: CameraLens.front,
      mirrorPreview: true,
      mirrorOutput: false,
      orientation: GuestOrientationPreference.portrait,
      shotCount: 2,
    ),
    output: const OutputProfile(),
    finishTimeoutSeconds: 30,
  );

  Future<void> photo(String session, int shot) async {
    final original = '$session-$shot';
    await db
        .into(db.originalPhotos)
        .insert(
          OriginalPhotosCompanion.insert(
            id: original,
            relativePath: 'originals/$original.jpg',
            widthPx: 3024,
            heightPx: 4032,
            byteLength: 3000000,
            sha256: 'a' * 64,
            lens: CameraLens.front,
            sensorOrientation: 270,
            deviceOrientation: CaptureOrientation.portraitUp,
            mirrorPreview: true,
            mirrorOutput: false,
            origin: CaptureOrigin.session,
            capturedAt: clock.now(),
            committedAt: clock.now(),
          ),
        );
    await sessions.addPhoto(
      session,
      ShotPhoto(
        shot: shot,
        attempt: 1,
        round: 0,
        originalId: original,
        capturedAtUtc: clock.now(),
      ),
    );
  }

  Future<void> session(int n, {int photos = 0, int renders = 0}) async {
    await sessions.create(id: _id(n), plan: plan, startedAtUtc: clock.now());
    for (var shot = 0; shot < photos; shot++) {
      await photo(_id(n), shot);
    }
    if (photos == 2) await sessions.markReviewing(_id(n));
    for (var i = 0; i < renders; i++) {
      await sessions.beginRender(_id(n));
    }
  }

  setUp(() async {
    clock = FakeClock(DateTime.utc(2026, 11, 14, 18));
    db = memoryDatabase(clock: clock);
    await seedEvents(db, clock: clock);
    sessions = DriftSessionRepository(db, clock: clock);
  });

  tearDown(() => db.close());

  test('cut-off sessions end, renders wait, repeated failures stop', () async {
    await session(1, photos: 1); // taking photos
    await session(2, photos: 2); // reviewing
    await session(3, photos: 2, renders: 1); // making the finished photo
    await session(4, photos: 2, renders: 3); // failed three times
    await session(5, photos: 2, renders: 1);
    await sessions.complete(
      _id(5),
      ExportedFile(
        id: 'd0000000-0000-4000-8000-000000000005',
        relativePath: 'outputs/d0000000-0000-4000-8000-000000000005.jpg',
        sha256: 'b' * 64,
        byteLength: 1000,
        widthPx: 1200,
        heightPx: 1800,
        format: OutputFormat.jpeg,
        renderVersion: 1,
        warnings: const [],
        stats: const RenderStats(
          decode: Duration.zero,
          paint: Duration.zero,
          rasterize: Duration.zero,
          encode: Duration.zero,
        ),
      ),
    );

    final result = await SessionRecovery(sessions).reconcile();
    expect(result.abandoned, 2);
    expect(result.pendingRenders, 1);
    expect(result.failed, 1);

    Future<SessionRecord> find(int n) async => (await sessions.find(_id(n)))!;
    for (final n in [1, 2]) {
      final record = await find(n);
      expect(record.status, SessionStatus.abandoned);
      expect(record.endReason, SessionEndReason.interrupted);
    }
    expect((await find(1)).photos, hasLength(1), reason: 'photos are kept');
    expect((await find(2)).photos, hasLength(2));
    expect((await find(3)).status, SessionStatus.rendering);
    expect((await find(4)).status, SessionStatus.failed);
    expect((await find(4)).endReason, SessionEndReason.renderFailed);
    expect((await find(5)).status, SessionStatus.completed);
    expect((await sessions.unfinished()).map((s) => s.id), [_id(3)]);

    // A second startup changes nothing more.
    final again = await SessionRecovery(sessions).reconcile();
    expect(again.abandoned + again.failed, 0);
    expect(again.pendingRenders, 1);
  });
}
