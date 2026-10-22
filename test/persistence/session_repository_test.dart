// AC-0703, AC-0707 (persistence half): sessions are frozen to their plan,
// photos and finished photos are only ever added, every change keeps the
// guest flow's rules, and the records survive a restart.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_configuration.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_registry.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/repositories/session_repository.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/domain/services/composition_renderer.dart';
import 'package:porcelain_photo_booth/domain/services/export_service.dart';
import 'package:porcelain_photo_booth/domain/session/session_plan.dart';
import 'package:porcelain_photo_booth/domain/session/session_shots.dart';
import 'package:porcelain_photo_booth/domain/value_objects/orientation.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_event_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_session_repository.dart';

import '../support/fakes.dart';
import '../support/seed.dart';
import '../support/test_database.dart';

const _sessionA = 'c0000000-0000-4000-8000-00000000000a';
const _sessionB = 'c0000000-0000-4000-8000-00000000000b';
const _output = 'd0000000-0000-4000-8000-000000000001';

SessionPlan _plan({RetakePolicy policy = RetakePolicy.perShot}) => SessionPlan(
  eventId: SeedIds.active,
  templateRevisionId: TestIds.revisionA1,
  slotIndexes: const [0, 3],
  capture: CaptureSettings(
    lens: CameraLens.front,
    mirrorPreview: true,
    mirrorOutput: false,
    orientation: GuestOrientationPreference.portrait,
    shotCount: 2,
    retakePolicy: policy,
  ),
  output: const OutputProfile(),
  finishTimeoutSeconds: 30,
);

ShotPhoto _photo(int shot, int attempt, {int round = 0}) => ShotPhoto(
  shot: shot,
  attempt: attempt,
  round: round,
  originalId: 'orig-$shot-$attempt-$round',
  capturedAtUtc: DateTime.utc(2026, 11, 14, 18, shot * 5 + attempt),
);

ExportedFile _exported([String id = _output]) => ExportedFile(
  id: id,
  relativePath: 'outputs/$id.jpg',
  sha256: 'e' * 64,
  byteLength: 812345,
  widthPx: 1200,
  heightPx: 1800,
  format: OutputFormat.jpeg,
  renderVersion: 2,
  warnings: const [],
  stats: const RenderStats(
    decode: Duration.zero,
    paint: Duration.zero,
    rasterize: Duration.zero,
    encode: Duration.zero,
  ),
);

void main() {
  late Directory root;
  late File file;
  late BoothDatabase db;
  late FakeClock clock;
  late DriftSessionRepository sessions;

  Future<void> original(String id) => db
      .into(db.originalPhotos)
      .insert(
        OriginalPhotosCompanion.insert(
          id: id,
          relativePath: 'originals/$id.jpg',
          widthPx: 4032,
          heightPx: 3024,
          byteLength: 3000000,
          sha256: 'a' * 64,
          lens: CameraLens.front,
          sensorOrientation: 270,
          deviceOrientation: CaptureOrientation.portraitUp,
          mirrorPreview: true,
          mirrorOutput: false,
          origin: CaptureOrigin.session,
          capturedAt: DateTime.utc(2026, 11, 14, 18),
          committedAt: DateTime.utc(2026, 11, 14, 18),
        ),
      );

  Future<void> addPhoto(String session, ShotPhoto photo) async {
    await original(photo.originalId);
    await sessions.addPhoto(session, photo);
  }

  Matcher refused(String code) =>
      throwsA(isA<SessionStoreException>().having((e) => e.code, 'code', code));

  setUp(() async {
    root = Directory.systemTemp.createTempSync('porcelain_sessions_');
    file = File('${root.path}/booth.sqlite');
    clock = FakeClock(DateTime.utc(2026, 11, 14, 18));
    db = fileDatabase(file, clock: clock);
    await seedEvents(db, clock: clock);
    sessions = DriftSessionRepository(db, clock: clock);
  });

  tearDown(() async {
    await db.close();
    root.deleteSync(recursive: true);
  });

  test('a session runs from capturing to completed and survives a '
      'restart', () async {
    final plan = _plan();
    await sessions.create(id: _sessionA, plan: plan, startedAtUtc: clock.now());
    await addPhoto(_sessionA, _photo(0, 1));
    await expectLater(
      sessions.markReviewing(_sessionA),
      refused('SESSION_SET_INCOMPLETE'),
    );
    await addPhoto(_sessionA, _photo(1, 1));
    await sessions.markReviewing(_sessionA);
    await addPhoto(_sessionA, _photo(1, 2));
    clock.advance(const Duration(seconds: 30));
    expect(await sessions.beginRender(_sessionA), 1);
    expect(await sessions.beginRender(_sessionA), 2, reason: 'a retry');
    final completedAt = clock.now();
    final output = await sessions.complete(_sessionA, _exported());
    expect(output.relativePath, 'outputs/$_output.jpg');
    await db.close();

    db = fileDatabase(file, clock: clock);
    sessions = DriftSessionRepository(db, clock: clock);
    final record = (await sessions.find(_sessionA))!;
    expect(record.plan, plan);
    expect(record.status, SessionStatus.completed);
    expect(record.outputId, _output);
    expect(record.renderAttempts, 2);
    expect(record.endedAtUtc, completedAt);
    expect(record.photos, hasLength(3), reason: 'the retaken photo is kept');
    expect(record.shots.slotBindings, {
      0: 'orig-0-1-0',
      3: 'orig-1-2-0',
    }, reason: 'shot 2 fills photo space 3, with its retake');
    final stored = (await sessions.output(_output))!;
    expect(stored.sessionId, _sessionA);
    expect((stored.widthPx, stored.heightPx), (1200, 1800));
    expect(await sessions.unfinished(), isEmpty);
  });

  // EP01: the experience a guest saw stays with the session, whatever
  // happens to the event afterwards.
  test('the frozen experience survives event edits and a restart', () async {
    final events = DriftEventRepository(db);
    final event = (await events.findById(SeedIds.active))!;
    final shown = ExperienceRegistry.bundled.resolve(event.experience);
    final plan = SessionPlan(
      eventId: _plan().eventId,
      templateRevisionId: _plan().templateRevisionId,
      slotIndexes: _plan().slotIndexes,
      capture: _plan().capture,
      output: _plan().output,
      finishTimeoutSeconds: 30,
      experience: shown,
    );
    await sessions.create(id: _sessionA, plan: plan, startedAtUtc: clock.now());
    await events.save(
      event.copyWith(
        experience: const EventExperienceConfiguration(
          packId: 'kid-party-arcade',
          getReadyText: 'Party time!',
        ),
      ),
    );
    await expectLater(
      db.customStatement(
        "UPDATE capture_sessions SET plan_json = '{}' WHERE id = '$_sessionA'",
      ),
      throwsA(anything),
      reason: 'a plan is never rewritten',
    );
    await db.close();
    db = fileDatabase(file, clock: clock);
    sessions = DriftSessionRepository(db, clock: clock);
    final record = (await sessions.find(_sessionA))!;
    expect(record.plan.experience, shown);
    expect(record.plan.experience!.packId, event.experience.packId);
  });

  test('photos must follow the flow rules', () async {
    await sessions.create(
      id: _sessionA,
      plan: _plan(),
      startedAtUtc: clock.now(),
    );
    await addPhoto(_sessionA, _photo(0, 1));
    for (final bad in [_photo(0, 2), _photo(1, 2), _photo(2, 1)]) {
      await original(bad.originalId);
      await expectLater(
        sessions.addPhoto(_sessionA, bad),
        refused('SESSION_PHOTO_REJECTED'),
      );
    }
    await expectLater(
      sessions.addPhoto(_sessionA, _photo(1, 1)),
      refused('SESSION_RULE_REFUSED'),
      reason: 'its original is not stored',
    );
    await expectLater(
      sessions.addPhoto('c0000000-0000-4000-8000-0000000000ff', _photo(1, 1)),
      refused('SESSION_UNKNOWN'),
    );
    await expectLater(
      sessions.beginRender(_sessionA),
      refused('SESSION_WRONG_STATUS'),
    );
  });

  test('a whole-session retake is recorded with its first photo', () async {
    await sessions.create(
      id: _sessionA,
      plan: _plan(policy: RetakePolicy.wholeSession),
      startedAtUtc: clock.now(),
    );
    await addPhoto(_sessionA, _photo(0, 1));
    await addPhoto(_sessionA, _photo(1, 1));
    await sessions.markReviewing(_sessionA);
    // The guest retakes the set: round 1 starts with its first photo.
    await addPhoto(_sessionA, _photo(0, 2, round: 1));
    var record = (await sessions.find(_sessionA))!;
    expect(record.shots.round, 1);
    expect(record.shots.isComplete, isFalse);
    await expectLater(
      sessions.markReviewing(_sessionA),
      refused('SESSION_SET_INCOMPLETE'),
    );
    await addPhoto(_sessionA, _photo(1, 2, round: 1));
    record = (await sessions.find(_sessionA))!;
    expect(record.shots.slotBindings, {0: 'orig-0-2-1', 3: 'orig-1-2-1'});
    // No round left (the limit is one): a third round is refused.
    final third = _photo(0, 3, round: 2);
    await original(third.originalId);
    await expectLater(
      sessions.addPhoto(_sessionA, third),
      refused('SESSION_PHOTO_REJECTED'),
    );
  });

  test('sessions need a real event and template revision', () async {
    for (final plan in [
      SessionPlan.fromJson({
        ..._plan().toJson(),
        'eventId': 'e0000000-0000-4000-8000-0000000000ff',
      }),
      SessionPlan.fromJson({
        ..._plan().toJson(),
        'templateRevisionId': 'a0000000-0000-4000-8000-0000000000ff',
      }),
    ]) {
      await expectLater(
        sessions.create(id: _sessionB, plan: plan, startedAtUtc: clock.now()),
        refused('SESSION_RULE_REFUSED'),
      );
    }
  });

  test('ending a session keeps its photos; finished sessions never '
      'change', () async {
    await sessions.create(
      id: _sessionA,
      plan: _plan(),
      startedAtUtc: clock.now(),
    );
    await addPhoto(_sessionA, _photo(0, 1));
    await sessions.end(
      _sessionA,
      status: SessionStatus.abandoned,
      reason: SessionEndReason.timedOut,
    );
    final ended = (await sessions.find(_sessionA))!;
    expect(ended.status, SessionStatus.abandoned);
    expect(ended.endReason, SessionEndReason.timedOut);
    expect(ended.photos, hasLength(1));
    await expectLater(
      sessions.addPhoto(_sessionA, _photo(1, 1)),
      refused('SESSION_WRONG_STATUS'),
    );
    await expectLater(
      sessions.end(
        _sessionA,
        status: SessionStatus.failed,
        reason: SessionEndReason.problem,
      ),
      refused('SESSION_WRONG_STATUS'),
    );
    expect(
      () => sessions.end(
        _sessionA,
        status: SessionStatus.completed,
        reason: SessionEndReason.problem,
      ),
      throwsArgumentError,
    );
  });

  test('the database refuses changes to plans, photos, outputs and '
      'finished sessions', () async {
    await sessions.create(
      id: _sessionA,
      plan: _plan(),
      startedAtUtc: clock.now(),
    );
    await addPhoto(_sessionA, _photo(0, 1));
    await addPhoto(_sessionA, _photo(1, 1));
    Future<void> rejects(String sql) =>
        expectLater(db.customStatement(sql), throwsA(anything), reason: sql);
    await rejects(
      "UPDATE capture_sessions SET plan_json = '{}' WHERE id = '$_sessionA'",
    );
    await rejects(
      "UPDATE capture_sessions SET event_id = '${SeedIds.draft}' "
      "WHERE id = '$_sessionA'",
    );
    await rejects(
      "UPDATE session_photos SET original_id = 'orig-1-1-0' "
      "WHERE session_id = '$_sessionA' AND shot_index = 0",
    );
    await rejects(
      "UPDATE capture_sessions SET status = 'completed' "
      "WHERE id = '$_sessionA'",
    );
    await sessions.markReviewing(_sessionA);
    await sessions.beginRender(_sessionA);
    await sessions.complete(_sessionA, _exported());
    await rejects(
      "UPDATE session_outputs SET sha256 = '${'f' * 64}' "
      "WHERE id = '$_output'",
    );
    await rejects(
      "UPDATE capture_sessions SET status = 'abandoned', "
      "end_reason = 'timedOut' WHERE id = '$_sessionA'",
    );
    await rejects(
      "INSERT INTO session_outputs VALUES ('${'b' * 36}', '$_sessionA', "
      "'outputs/elsewhere.jpg', '${'c' * 64}', 1, 1, 1, 'jpeg', 1, "
      "'2026-11-14T18:00:00.000Z')",
    );
  });

  test('unfinished sessions are listed oldest first', () async {
    await sessions.create(
      id: _sessionB,
      plan: _plan(),
      startedAtUtc: clock.now(),
    );
    clock.advance(const Duration(minutes: 1));
    await sessions.create(
      id: _sessionA,
      plan: _plan(),
      startedAtUtc: clock.now().subtract(const Duration(minutes: 5)),
    );
    final list = await sessions.unfinished();
    expect(list.map((s) => s.id), [_sessionA, _sessionB]);
    await sessions.end(
      _sessionA,
      status: SessionStatus.abandoned,
      reason: SessionEndReason.interrupted,
    );
    expect((await sessions.unfinished()).map((s) => s.id), [_sessionB]);
    expect(await sessions.find('c0000000-0000-4000-8000-0000000000ff'), isNull);
    expect(await sessions.output(_output), isNull);
    final rows = await db.select(db.captureSessions).get();
    expect(rows, hasLength(2));
    expect(rows.every((r) => r.plannedShots == 2), isTrue);
    expect(await (db.select(db.sessionPhotos)).get(), isEmpty);
    final count = await db
        .customSelect('SELECT count(*) AS n FROM session_outputs')
        .getSingle();
    expect(count.read<int>('n'), 0);
    expect(await db.select(db.sessionOutputs).get(), isEmpty);
  });
}
