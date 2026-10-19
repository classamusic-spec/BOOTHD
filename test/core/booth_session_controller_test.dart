// AC-0701 to AC-0705, AC-0707, AC-0709 (controller half): a guest session
// on the simulated camera, from Start to the next guest: the countdown
// runs on timers and never fires once the booth leaves the foreground;
// photos are recorded only once saved, retakes keep every original, the
// finished photo is called saved only once it reads back intact and is
// recorded; problems are recoverable, timeouts bring guests back to the
// welcome, and nothing of the last guest is kept in memory.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/booth/booth_session_controller.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/repositories/session_repository.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/domain/services/export_service.dart';
import 'package:porcelain_photo_booth/domain/session/guest_flow.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_event_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_session_repository.dart';

import '../support/fake_export.dart';
import '../support/fakes.dart';
import '../support/memory_template_store.dart';
import '../support/seed.dart';
import '../support/simulated_camera.dart';
import '../support/test_database.dart';

/// A booth for the seeded event (two photos, a three-second countdown,
/// three seconds between photos, one retake per photo) and its fakes.
final class _Booth {
  _Booth._(
    this.db,
    this.clock,
    this.camera,
    this.templates,
    this.exports,
    this.space,
  );

  final BoothDatabase db;
  final FakeClock clock;
  final SimulatedCameraService camera;
  final MemoryTemplateStore templates;
  final FakeExportService exports;
  final FakeDeviceStorage space;
  late final BoothSessionController session;

  DriftSessionRepository get sessions =>
      DriftSessionRepository(db, clock: clock);

  GuestFlow get flow => session.flow;
  GuestStage get stage => session.flow.stage;

  static Future<_Booth> open(
    WidgetTester tester, {
    BoothEvent Function(BoothEvent event)? event,
  }) async {
    final clock = FakeClock(DateTime.utc(2026, 11, 14, 18));
    final db = memoryDatabase(clock: clock);
    await seedEvents(db, clock: clock, active: event);
    final templates = MemoryTemplateStore(clock: clock);
    await seedTemplateDocuments(templates);
    final camera = SimulatedCameraService()..store.database = db;
    final booth = _Booth._(
      db,
      clock,
      camera,
      templates,
      FakeExportService(),
      FakeDeviceStorage(),
    );
    final seeded = (await DriftEventRepository(db).findById(SeedIds.active))!;
    booth.session = BoothSessionController(
      event: seeded,
      camera: camera,
      originals: camera.store,
      sessions: booth.sessions,
      export: booth.exports,
      finished: booth.exports.finished,
      templates: templates.templates,
      assets: templates.assets,
      space: booth.space,
      clock: clock,
      ids: SequentialIds('c0000000-0000-4000-8000'),
    );
    addTearDown(() async {
      if (!booth._closed) booth.session.dispose();
      await db.close();
    });
    return booth;
  }

  var _closed = false;

  /// Ends the test's booth: the controller stops its timers and releases
  /// the camera, as when Booth Mode is left.
  Future<void> close(WidgetTester tester) async {
    _closed = true;
    session.dispose();
    await settle(tester);
  }

  /// The booth leaves the foreground (another app, the home screen).
  Future<void> away(WidgetTester tester) async {
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await settle(tester);
  }

  /// A moment's interruption (a system prompt, Control Center), or the way
  /// back from [away]'s first step.
  Future<void> inactive(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await settle(tester);
  }

  /// In front again.
  Future<void> back(WidgetTester tester) async {
    final state = tester.binding.lifecycleState;
    if (state == AppLifecycleState.hidden) {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    }
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settle(tester);
  }

  /// Lets queued work (database, camera, export) finish: microtasks and
  /// timers that are due, without moving the clock.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(Duration.zero);
    }
  }

  /// Start, through the camera opening, to the first countdown.
  Future<void> start(WidgetTester tester) async {
    await session.start();
    await settle(tester);
  }

  /// One second of countdown.
  Future<void> second(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 1));
    await settle(tester);
  }

  /// A whole countdown, to the photo saved.
  Future<void> countdown(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await second(tester);
    }
  }

  /// Both photos, to the review.
  Future<void> toReview(WidgetTester tester) async {
    await start(tester);
    await countdown(tester);
    expect(stage, GuestStage.shotSaved);
    await tester.pump(const Duration(seconds: 3));
    await settle(tester);
    await countdown(tester);
    expect(stage, GuestStage.review);
  }

  Future<SessionRecord> record() async => (await sessions.find(sessionId))!;

  /// The one session of these tests.
  static const sessionId = 'c0000000-0000-4000-8000-000000000001';
}

void main() {
  testWidgets('a session runs from Start to saved, and the next guest '
      'starts clean (AC-0701, AC-0704, AC-0705, AC-0709)', (tester) async {
    final booth = await _Booth.open(tester);
    expect(booth.stage, GuestStage.idle);
    expect(booth.camera.initializations, 0, reason: 'no camera while idle');

    await booth.start(tester);
    expect(booth.stage, GuestStage.countdown);
    expect(booth.flow.secondsLeft, 3);
    final record = await booth.record();
    expect(record.status, SessionStatus.capturing);
    expect(record.plan.eventId, SeedIds.active);
    expect(
      record.plan.templateRevisionId,
      TestIds.revisionA1,
      reason: 'the event and its template revision are frozen',
    );

    // A monotonic countdown: one step a second, then the photo.
    final seen = <int>[];
    for (var i = 0; i < 2; i++) {
      seen.add(booth.flow.secondsLeft);
      await booth.second(tester);
    }
    seen.add(booth.flow.secondsLeft);
    expect(seen, [3, 2, 1]);
    expect(booth.camera.shutters, 0);
    await booth.second(tester);
    expect(booth.camera.shutters, 1);
    expect(booth.stage, GuestStage.shotSaved);
    expect((await booth.record()).photos, hasLength(1));

    await tester.pump(const Duration(seconds: 3));
    await booth.settle(tester);
    expect(booth.stage, GuestStage.countdown);
    expect(booth.flow.shot, 1);
    await booth.countdown(tester);
    expect(booth.stage, GuestStage.review);
    expect((await booth.record()).status, SessionStatus.reviewing);

    final stills = booth.camera.store.stills;
    booth.session.keep();
    await booth.settle(tester);
    expect(booth.stage, GuestStage.completed);

    // Each photo fills the photo space of its shot, as the plan says.
    final render = booth.exports.renders.single;
    expect(render.photos.map((slot, photo) => MapEntry(slot, photo.photoId)), {
      0: stills[0].id,
      1: stills[1].id,
    });
    expect(
      render.photos.values.every((photo) => !photo.mirrored),
      isTrue,
      reason: 'the event does not mirror its output',
    );

    // Saved: verified, read back and recorded.
    final done = await booth.record();
    expect(done.status, SessionStatus.completed);
    expect(done.renderAttempts, 1);
    final output = (await booth.sessions.output(done.outputId!))!;
    expect(booth.session.output?.id, output.id);
    expect(
      booth.session.finishedPhoto,
      booth.exports.files[output.relativePath],
    );

    // Next guest: nothing of this one is kept.
    final suspensions = booth.camera.suspensions;
    await booth.session.nextGuest();
    await booth.settle(tester);
    expect(booth.stage, GuestStage.idle);
    expect(booth.session.finishedPhoto, isNull);
    expect(booth.session.output, isNull);
    expect(booth.session.photoAspect(stills[0].id), isNull);
    expect(booth.camera.suspensions, greaterThan(suspensions));
    expect(booth.camera.status.lifecycle, CameraLifecycle.suspended);
    expect(PaintingBinding.instance.imageCache.currentSize, 0);
    expect(PaintingBinding.instance.imageCache.liveImageCount, 0);
    expect((await booth.record()).status, SessionStatus.completed);
    await booth.close(tester);
  });

  testWidgets('the countdown stops when the booth leaves the foreground '
      'and never fires late (AC-0702)', (tester) async {
    final booth = await _Booth.open(tester);
    await booth.start(tester);
    await booth.second(tester);
    expect(booth.flow.secondsLeft, 2);

    await booth.inactive(tester);
    expect(booth.stage, GuestStage.interrupted);
    await tester.pump(const Duration(seconds: 10));
    await booth.settle(tester);
    expect(booth.camera.shutters, 0, reason: 'no photo while away');

    // Hidden: the camera is released; back in front it opens again, but
    // nothing happens until the guest taps Continue.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await booth.settle(tester);
    expect(booth.camera.status.lifecycle, CameraLifecycle.suspended);
    await booth.back(tester);
    expect(booth.stage, GuestStage.interrupted);
    await tester.pump(const Duration(seconds: 5));
    expect(booth.camera.shutters, 0);

    booth.session.resume();
    await booth.settle(tester);
    expect(booth.stage, GuestStage.countdown);
    expect(booth.flow.secondsLeft, 3, reason: 'a fresh countdown');
    expect(booth.flow.shot, 0);
    await booth.countdown(tester);
    expect(booth.camera.shutters, 1);
    expect(booth.stage, GuestStage.shotSaved);

    // Between photos too: the next shot waits for the guest.
    await booth.inactive(tester);
    expect(booth.stage, GuestStage.interrupted);
    expect(booth.flow.shot, 1);
    await booth.back(tester);
    await tester.pump(const Duration(seconds: 10));
    expect(booth.camera.shutters, 1);
    expect((await booth.record()).photos, hasLength(1));
    await booth.close(tester);
  });

  testWidgets('a photo being taken finishes first, then the session '
      'pauses (AC-0702)', (tester) async {
    final booth = await _Booth.open(tester);
    booth.camera.captureGate = Completer<void>();
    await booth.start(tester);
    await booth.countdown(tester);
    expect(booth.stage, GuestStage.capturing);

    await booth.inactive(tester);
    expect(booth.stage, GuestStage.capturing);

    booth.camera.captureGate!.complete();
    await booth.settle(tester);
    expect((await booth.record()).photos, hasLength(1));
    expect(booth.stage, GuestStage.interrupted);
    expect(booth.flow.shot, 1, reason: 'the next photo, once back');
    await booth.back(tester);
    await booth.close(tester);
  });

  testWidgets('a retake is a new photo; the earlier one is kept and only '
      'the binding changes (AC-0703)', (tester) async {
    final booth = await _Booth.open(tester);
    await booth.toReview(tester);
    final first = booth.camera.store.stills;
    expect(booth.flow.shots!.retakesLeft(0), 1);

    booth.session.retakeShot(0);
    await booth.settle(tester);
    expect(booth.stage, GuestStage.countdown);
    expect(booth.flow.shot, 0);
    await booth.countdown(tester);
    expect(booth.stage, GuestStage.review);

    final stills = booth.camera.store.stills;
    expect(stills, hasLength(3));
    final record = await booth.record();
    expect(record.photos, hasLength(3));
    expect(record.shots.slotBindings, {0: stills[2].id, 1: first[1].id});
    // The retaken original is still stored and readable.
    expect(await booth.camera.store.read(first[0]), isNotEmpty);

    // No retakes left for that photo: the request is ignored.
    expect(booth.flow.shots!.canRetake(0), isFalse);
    booth.session.retakeShot(0);
    expect(booth.stage, GuestStage.review);

    booth.session.keep();
    await booth.settle(tester);
    expect(
      booth.exports.renders.single.photos.map((s, p) => MapEntry(s, p.photoId)),
      {0: stills[2].id, 1: first[1].id},
    );
    await booth.close(tester);
  });

  testWidgets('retaking the whole set starts a new round and keeps every '
      'original (AC-0703)', (tester) async {
    final booth = await _Booth.open(
      tester,
      event: (event) => event.copyWith(
        capture: event.capture.copyWith(
          retakePolicy: RetakePolicy.wholeSession,
        ),
      ),
    );
    await booth.toReview(tester);
    expect(booth.flow.shots!.canRetakeAll, isTrue);
    booth.session.retakeAll();
    await booth.settle(tester);
    expect(booth.stage, GuestStage.countdown);
    expect(booth.flow.shot, 0);
    await booth.countdown(tester);
    await tester.pump(const Duration(seconds: 3));
    await booth.settle(tester);
    await booth.countdown(tester);
    expect(booth.stage, GuestStage.review);

    final stills = booth.camera.store.stills;
    final record = await booth.record();
    expect(record.photos, hasLength(4));
    expect(record.shots.round, 1);
    expect(record.shots.slotBindings, {0: stills[2].id, 1: stills[3].id});
    expect(booth.flow.shots!.canRetakeAll, isFalse);
    await booth.close(tester);
  });

  testWidgets('a photo that fails is retried without losing the others', (
    tester,
  ) async {
    final booth = await _Booth.open(tester);
    await booth.start(tester);
    await booth.countdown(tester);
    booth.camera.captureFailure = const CameraFailure(
      CameraFailureCode.captureFailed,
    );
    await tester.pump(const Duration(seconds: 3));
    await booth.settle(tester);
    await booth.countdown(tester);
    expect(booth.stage, GuestStage.failed);
    expect(booth.flow.problem!.kind, GuestProblemKind.capture);
    expect(booth.flow.problem!.recoverable, isTrue);
    expect((await booth.record()).photos, hasLength(1));

    booth.session.retry();
    await booth.settle(tester);
    expect(booth.stage, GuestStage.countdown);
    expect(booth.flow.shot, 1);
    await booth.countdown(tester);
    expect(booth.stage, GuestStage.review);
    expect((await booth.record()).photos, hasLength(2));
    await booth.close(tester);
  });

  testWidgets('a finished photo that fails is kept for a retry, and one '
      'left behind is finished later (AC-0707)', (tester) async {
    final booth = await _Booth.open(tester);
    await booth.toReview(tester);
    booth.exports.failure = const ExportFailure(ExportFailureCode.writeFailed);
    booth.session.keep();
    await booth.settle(tester);
    expect(booth.stage, GuestStage.failed);
    expect(booth.flow.problem!.kind, GuestProblemKind.render);
    expect(booth.session.lastProblem!.code, 'EXPORT_WRITE_FAILED');
    var record = await booth.record();
    expect(record.status, SessionStatus.rendering, reason: 'a checkpoint');
    expect(record.renderAttempts, 1);
    expect(record.photos, hasLength(2), reason: 'the originals are safe');

    // The guest walks away: the session waits to be finished, and the
    // booth finishes it while idle.
    await booth.session.startOver();
    await booth.settle(tester);
    expect(booth.stage, GuestStage.idle);
    record = await booth.record();
    expect(record.status, SessionStatus.completed);
    expect(record.renderAttempts, 2);
    expect(booth.exports.renders, hasLength(2));
    await booth.close(tester);
  });

  testWidgets('Try again makes the finished photo again', (tester) async {
    final booth = await _Booth.open(tester);
    await booth.toReview(tester);
    booth.exports.failure = const ExportFailure(ExportFailureCode.noSpace);
    booth.session.keep();
    await booth.settle(tester);
    expect(booth.stage, GuestStage.failed);
    booth.session.retry();
    await booth.settle(tester);
    expect(booth.stage, GuestStage.completed);
    expect((await booth.record()).renderAttempts, 2);
    await booth.close(tester);
  });

  testWidgets('a finished photo that does not read back intact is never '
      'called saved (AC-0705)', (tester) async {
    final booth = await _Booth.open(tester);
    await booth.toReview(tester);
    booth.exports.corruptNext = true;
    booth.session.keep();
    await booth.settle(tester);
    expect(booth.stage, GuestStage.failed);
    expect(booth.session.lastProblem!.code, 'EXPORT_VERIFY_FAILED');
    expect(booth.session.finishedPhoto, isNull);
    final record = await booth.record();
    expect(record.status, SessionStatus.rendering);
    expect(record.outputId, isNull);

    booth.session.retry();
    await booth.settle(tester);
    expect(booth.stage, GuestStage.completed);
    expect(booth.session.finishedPhoto, isNotNull);
    await booth.close(tester);
  });

  testWidgets('guest-safe timeouts bring the booth back to the welcome', (
    tester,
  ) async {
    final booth = await _Booth.open(
      tester,
      event: (event) => event.copyWith(
        guest: event.guest.copyWith(guestChoosesTemplate: true),
      ),
    );
    const timeouts = BoothTimeouts();

    // Choosing a template.
    await booth.start(tester);
    expect(booth.stage, GuestStage.templateSelection);
    await tester.pump(timeouts.templateChoice);
    await booth.settle(tester);
    expect(booth.stage, GuestStage.idle);
    expect(await booth.sessions.unfinished(), isEmpty);

    // Reviewing: the photos are kept as if the guest tapped Keep, and the
    // finished screen then resets by itself.
    await booth.start(tester);
    booth.session.chooseTemplate(TestIds.revisionB1);
    await booth.settle(tester);
    await booth.countdown(tester);
    await tester.pump(const Duration(seconds: 3));
    await booth.settle(tester);
    await booth.countdown(tester);
    expect(booth.stage, GuestStage.review);
    expect(
      (await booth.record()).plan.templateRevisionId,
      TestIds.revisionB1,
      reason: "the guest's choice is frozen with the session",
    );
    await tester.pump(timeouts.review);
    await booth.settle(tester);
    expect(booth.stage, GuestStage.completed);
    await tester.pump(const Duration(seconds: 30));
    await booth.settle(tester);
    expect(booth.stage, GuestStage.idle);
    await booth.close(tester);
  });

  testWidgets('a pause or a problem left alone ends the session', (
    tester,
  ) async {
    final booth = await _Booth.open(tester);
    await booth.start(tester);
    await booth.inactive(tester);
    await booth.back(tester);
    expect(booth.stage, GuestStage.interrupted);
    await tester.pump(const BoothTimeouts().interrupted);
    await booth.settle(tester);
    expect(booth.stage, GuestStage.idle);
    var record = await booth.record();
    expect(record.status, SessionStatus.abandoned);
    expect(record.endReason, SessionEndReason.timedOut);

    booth.camera.initializeFailure = const CameraFailure(
      CameraFailureCode.cameraUnavailable,
    );
    await booth.start(tester);
    expect(booth.stage, GuestStage.failed);
    expect(booth.flow.problem!.kind, GuestProblemKind.camera);
    await tester.pump(const BoothTimeouts().problem);
    await booth.settle(tester);
    expect(booth.stage, GuestStage.idle);
    record = (await booth.sessions.find(
      'c0000000-0000-4000-8000-000000000002',
    ))!;
    expect(record.status, SessionStatus.abandoned);
    expect(record.endReason, SessionEndReason.problem);
    await booth.close(tester);
  });

  testWidgets('a camera that never opens, or a photo that never arrives, '
      'becomes a problem the guest can retry', (tester) async {
    final booth = await _Booth.open(tester);
    booth.camera.openGate = Completer<void>();
    await booth.start(tester);
    expect(booth.stage, GuestStage.preparing);
    await tester.pump(const BoothTimeouts().cameraOpen);
    await booth.settle(tester);
    expect(booth.stage, GuestStage.failed);
    expect(
      booth.session.lastProblem!.code,
      BoothSessionController.cameraOpenTimeout,
    );
    booth.camera.openGate!.complete();
    booth.camera.openGate = null;
    await booth.settle(tester);
    expect(booth.stage, GuestStage.failed, reason: 'too late to count');

    booth.camera.captureGate = Completer<void>();
    booth.session.retry();
    await booth.settle(tester);
    await booth.countdown(tester);
    expect(booth.stage, GuestStage.capturing);
    await tester.pump(const BoothTimeouts().capture);
    await booth.settle(tester);
    expect(booth.stage, GuestStage.failed);
    expect(
      booth.session.lastProblem!.code,
      BoothSessionController.captureTimeout,
    );
    // The photo arrives late: stored, but not used.
    booth.camera.captureGate!.complete();
    booth.camera.captureGate = null;
    await booth.settle(tester);
    expect(booth.camera.store.stills, hasLength(1));
    expect((await booth.record()).photos, isEmpty);
    expect(booth.stage, GuestStage.failed);
    await booth.close(tester);
  });

  testWidgets('a full tablet starts no session', (tester) async {
    final booth = await _Booth.open(tester);
    booth.space.free = 50 * 1024 * 1024;
    await booth.start(tester);
    expect(booth.stage, GuestStage.failed);
    expect(booth.flow.problem!.kind, GuestProblemKind.storage);
    expect(booth.flow.problem!.recoverable, isFalse);
    booth.session.retry();
    expect(booth.stage, GuestStage.failed);
    await booth.session.startOver();
    await booth.settle(tester);
    expect(booth.stage, GuestStage.idle);
    expect(await booth.sessions.find(_Booth.sessionId), isNull);
    expect(booth.camera.initializations, 0);
    await booth.close(tester);
  });

  testWidgets("the operator's exit waits for a photo being saved, then "
      'ends the session', (tester) async {
    final booth = await _Booth.open(tester);
    booth.camera.captureGate = Completer<void>();
    await booth.start(tester);
    await booth.countdown(tester);
    expect(booth.stage, GuestStage.capturing);

    var left = false;
    unawaited(booth.session.leaveForOperator().then((_) => left = true));
    await booth.settle(tester);
    expect(left, isFalse);
    booth.camera.captureGate!.complete();
    await booth.settle(tester);
    expect(left, isTrue);
    expect(booth.stage, GuestStage.idle);
    final record = await booth.record();
    expect(record.status, SessionStatus.abandoned);
    expect(record.endReason, SessionEndReason.operatorExit);
    expect(record.photos, hasLength(1), reason: 'the photo is kept');
    expect(booth.camera.status.lifecycle, CameraLifecycle.suspended);
    await booth.close(tester);
  });
}
