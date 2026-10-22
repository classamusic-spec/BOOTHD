// AC-0701 (the flow and its rejected steps), AC-0703 (retakes add photos,
// never replace them), AC-0704 (shots fill the template's photo spaces in
// slot order; counts must match).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_configuration.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_pack.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/domain/session/guest_flow.dart';
import 'package:porcelain_photo_booth/domain/session/session_plan.dart';
import 'package:porcelain_photo_booth/domain/session/session_shots.dart';
import 'package:porcelain_photo_booth/domain/template/geometry.dart';
import 'package:porcelain_photo_booth/domain/template/template_layers.dart';
import 'package:porcelain_photo_booth/domain/value_objects/orientation.dart';

import '../support/template_builders.dart';

BoothEvent _event({
  int shots = 2,
  RetakePolicy policy = RetakePolicy.perShot,
  int limit = 1,
  int countdown = 3,
}) => BoothEvent(
  id: 'event-1',
  title: 'Garden party',
  status: EventStatus.active,
  boothProfileId: 'booth-1',
  createdAt: DateTime.utc(2026, 10, 1),
  updatedAt: DateTime.utc(2026, 10, 1),
  capture: CaptureSettings(
    lens: CameraLens.front,
    mirrorPreview: true,
    mirrorOutput: true,
    orientation: GuestOrientationPreference.portrait,
    shotCount: shots,
    countdownSeconds: countdown,
    retakePolicy: policy,
    retakeLimit: limit,
  ),
  guest: const GuestSettings(finishTimeoutSeconds: 45),
  output: const OutputProfile(format: OutputFormat.png),
  templates: const TemplateSelection(
    revisionIds: ['rev-a', 'rev-b'],
    defaultRevisionId: 'rev-a',
  ),
);

/// Photo spaces numbered [slots], in that document order.
PhotoSlotLayer _slot(int index) => PhotoSlotLayer(
  id: 'slot-$index',
  zIndex: 10 + index,
  slotIndex: index,
  frame: NormalizedRect(x: 0.1, y: 0.1 * index, width: 0.3, height: 0.1),
);

SessionPlan _plan({
  int shots = 2,
  RetakePolicy policy = RetakePolicy.perShot,
  int limit = 1,
  List<int>? slots,
}) => SessionPlan.freeze(
  event: _event(shots: shots, policy: policy, limit: limit),
  templateRevisionId: 'rev-a',
  document: sampleDocument(
    layers: [
      for (final index in slots ?? List.generate(shots, (i) => i)) _slot(index),
    ],
  ),
);

ShotPhoto _photo(int shot, int attempt, {int round = 0, String? id}) =>
    ShotPhoto(
      shot: shot,
      attempt: attempt,
      round: round,
      originalId: id ?? 'shot$shot-attempt$attempt',
      capturedAtUtc: DateTime.utc(2026, 11, 14, 18, shot, attempt),
    );

/// Takes every remaining shot of [flow]'s set, from preparing.
GuestFlow _takeAll(GuestFlow flow, {int round = 0}) {
  var next = flow;
  while (next.stage == GuestStage.preparing ||
      next.stage == GuestStage.shotSaved) {
    next = next.stage == GuestStage.preparing
        ? next.cameraReady()
        : next.nextShot();
    while (next.stage == GuestStage.countdown) {
      next = next.tick();
    }
    final shot = next.shot!;
    next = next.photoSaved(
      _photo(shot, next.shots!.nextAttempt(shot), round: round),
    );
  }
  return next;
}

void main() {
  group('session plan (AC-0704)', () {
    test('freezes the event settings and fills spaces in slot order', () {
      final plan = _plan(shots: 3, slots: [2, 0, 5]);
      expect(plan.slotIndexes, [0, 2, 5]);
      expect([for (var i = 0; i < 3; i++) plan.slotFor(i)], [0, 2, 5]);
      expect(plan.eventId, 'event-1');
      expect(plan.capture.countdownSeconds, 3);
      expect(plan.capture.mirrorOutput, isTrue);
      expect(plan.output.format, OutputFormat.png);
      expect(plan.finishTimeoutSeconds, 45);
    });

    test('refuses a template whose spaces do not match the photos', () {
      for (final (shots, slots) in [
        (2, [0, 1, 2]),
        (3, [0, 1]),
        (2, <int>[]),
      ]) {
        expect(
          () => SessionPlan.freeze(
            event: _event(shots: shots),
            templateRevisionId: 'rev-a',
            document: sampleDocument(layers: [for (final i in slots) _slot(i)]),
          ),
          throwsA(
            isA<SessionPlanException>().having(
              (e) => e.problem,
              'problem',
              SessionPlanProblem.slotsMismatch,
            ),
          ),
          reason: '$shots photos, ${slots.length} spaces',
        );
      }
      expect(
        () => _plan(shots: 5),
        throwsA(
          isA<SessionPlanException>().having(
            (e) => e.problem,
            'problem',
            SessionPlanProblem.shotCountOutOfRange,
          ),
        ),
      );
    });

    test('round-trips through its stored form', () {
      final plan = _plan(shots: 4, policy: RetakePolicy.wholeSession, limit: 2);
      expect(SessionPlan.fromJson(plan.toJson()), plan);
      expect(
        () => SessionPlan.fromJson({...plan.toJson(), 'schemaVersion': 2}),
        throwsFormatException,
      );
      expect(
        () => SessionPlan.fromJson({...plan.toJson(), 'capture': 'x'}),
        throwsFormatException,
      );
    });

    // EP01: the session freezes what the guest will see and hear.
    test('freezes the event experience and keeps it through storage', () {
      final event = _event().copyWith(
        experience: const EventExperienceConfiguration(
          packId: 'retro-game-quest',
          variantId: 'arcade',
          getReadyText: 'Player one?',
        ),
      );
      final plan = SessionPlan.freeze(
        event: event,
        templateRevisionId: 'rev-a',
        document: sampleDocument(layers: [_slot(0), _slot(1)]),
      );
      expect(plan.experience!.packId, 'retro-game-quest');
      expect(plan.experience!.variantId, 'arcade');
      expect(plan.experience!.copy[GuestCopyKey.getReady], 'Player one?');
      final stored = jsonDecode(jsonEncode(plan.toJson()));
      final again = SessionPlan.fromJson(stored as Map<String, Object?>);
      expect(again, plan);
      expect(again.experience, plan.experience);
    });

    test('a plan from before experiences, or with an unreadable one, '
        'still opens', () {
      final plan = _plan();
      final legacy = {...plan.toJson()}..remove('experience');
      expect(SessionPlan.fromJson(legacy).experience, isNull);
      final garbled = {
        ...plan.toJson(),
        'experience': {'schemaVersion': 99},
      };
      final opened = SessionPlan.fromJson(garbled);
      expect(opened.experience, isNull);
      expect(opened.slotIndexes, plan.slotIndexes);
    });

    test('asks for the event lens, falling back to the other built-in '
        'one', () {
      const front = CameraDescriptor(
        id: 'f',
        lens: CameraLens.front,
        sensorOrientationDegrees: 270,
      );
      const back = CameraDescriptor(
        id: 'b',
        lens: CameraLens.back,
        sensorOrientationDegrees: 90,
      );
      final plan = _plan();
      final request = plan.cameraRequest([back, front])!;
      expect(request.cameraId, 'f');
      expect(request.mirrorPreview, isTrue);
      expect(request.mirrorOutput, isTrue);
      expect(plan.cameraRequest([back])!.cameraId, 'b');
      expect(plan.cameraRequest(const []), isNull);
    });
  });

  group('shots and retakes (AC-0703)', () {
    test('the latest attempt is used; earlier ones stay recorded', () {
      var shots = SessionShots.empty(_plan());
      expect(shots.remaining, [0, 1]);
      shots = shots.withPhoto(_photo(0, 1)).withPhoto(_photo(1, 1));
      expect(shots.isComplete, isTrue);
      expect(shots.retakesLeft(0), 1);
      shots = shots.withPhoto(_photo(0, 2));
      expect(shots.selected(0)!.originalId, 'shot0-attempt2');
      expect(shots.photos.map((p) => p.originalId), [
        'shot0-attempt1',
        'shot1-attempt1',
        'shot0-attempt2',
      ]);
      expect(shots.retakesLeft(0), 0);
      expect(shots.canRetake(0), isFalse);
      expect(shots.canRetake(1), isTrue);
      expect(shots.slotBindings, {0: 'shot0-attempt2', 1: 'shot1-attempt1'});
    });

    test('per-shot limits are enforced', () {
      var shots = SessionShots.empty(_plan(limit: 2))
          .withPhoto(_photo(0, 1))
          .withPhoto(_photo(1, 1))
          .withPhoto(_photo(1, 2))
          .withPhoto(_photo(1, 3));
      expect(shots.retakesLeft(1), 0);
      expect(
        () => shots.withPhoto(_photo(1, 4)),
        throwsA(isA<InvalidShotPhoto>()),
      );
      shots = shots.withPhoto(_photo(0, 2));
      expect(shots.retakesLeft(0), 1);
    });

    test('photos must be the next attempt of a real shot, in this round', () {
      final shots = SessionShots.empty(_plan());
      for (final bad in [
        _photo(2, 1),
        _photo(-1, 1),
        _photo(0, 2),
        _photo(0, 1, round: 1),
      ]) {
        expect(() => shots.withPhoto(bad), throwsA(isA<InvalidShotPhoto>()));
      }
      final one = shots.withPhoto(_photo(0, 1, id: 'same'));
      expect(
        () => one.withPhoto(_photo(1, 1, id: 'same')),
        throwsA(isA<InvalidShotPhoto>()),
        reason: 'an original belongs to one shot',
      );
      expect(
        () => one.withPhoto(_photo(0, 2)),
        throwsA(isA<InvalidShotPhoto>()),
        reason: 'no retake before the set is complete',
      );
      expect(() => one.slotBindings, throwsA(isA<InvalidShotPhoto>()));
    });

    test('whole-session retakes take every shot again, up to the limit', () {
      final plan = _plan(policy: RetakePolicy.wholeSession);
      var shots = SessionShots.empty(plan)
          .withPhoto(_photo(0, 1))
          .withPhoto(_photo(1, 1));
      expect(shots.canRetake(0), isFalse, reason: 'not per shot');
      expect(shots.roundsLeft, 1);
      shots = shots.retakeAll();
      expect(shots.round, 1);
      expect(shots.remaining, [0, 1]);
      expect(shots.selected(0)!.originalId, 'shot0-attempt1');
      shots = shots
          .withPhoto(_photo(0, 2, round: 1))
          .withPhoto(_photo(1, 2, round: 1));
      expect(shots.isComplete, isTrue);
      expect(shots.canRetakeAll, isFalse);
      expect(() => shots.retakeAll(), throwsA(isA<InvalidShotPhoto>()));
      expect(shots.slotBindings, {0: 'shot0-attempt2', 1: 'shot1-attempt2'});
      expect(shots.photos, hasLength(4), reason: 'nothing is dropped');
    });

    test('no retakes when the event allows none', () {
      final shots = SessionShots.empty(_plan(policy: RetakePolicy.none))
          .withPhoto(_photo(0, 1))
          .withPhoto(_photo(1, 1));
      expect(shots.canRetake(0), isFalse);
      expect(shots.canRetakeAll, isFalse);
    });

    test('a recorded session restores to the same state', () {
      final plan = _plan(policy: RetakePolicy.wholeSession);
      final photos = [
        _photo(1, 2, round: 1),
        _photo(0, 1),
        _photo(0, 2, round: 1),
        _photo(1, 1),
      ];
      final shots = SessionShots.restore(plan, photos);
      expect(shots.round, 1);
      expect(shots.isComplete, isTrue);
      expect(shots.slotBindings, {0: 'shot0-attempt2', 1: 'shot1-attempt2'});
      final perShot = SessionShots.restore(_plan(), [
        _photo(0, 2),
        _photo(0, 1),
        _photo(1, 1),
      ]);
      expect(perShot.selected(0)!.attempt, 2);
      expect(perShot.retakesLeft(0), 0);
    });
  });

  group('guest flow (AC-0701)', () {
    GuestFlow begin({
      int shots = 2,
      RetakePolicy policy = RetakePolicy.perShot,
    }) {
      final started = GuestFlow.idle.start(
        templates: const ['rev-a', 'rev-b'],
        defaultTemplate: 'rev-a',
        guestChooses: false,
      );
      return started.sessionStarted(
        SessionShots.empty(_plan(shots: shots, policy: policy)),
      );
    }

    test('welcome, countdown, captures with pauses, review, render, '
        'completed, welcome', () {
      var flow = begin(shots: 3);
      expect(flow.stage, GuestStage.preparing);
      expect(flow.shot, 0);
      flow = flow.cameraReady();
      expect(flow.stage, GuestStage.countdown);
      expect(flow.secondsLeft, 3);
      flow = flow.tick();
      expect(flow.secondsLeft, 2);
      flow = flow.tick().tick();
      expect(flow.stage, GuestStage.capturing);
      expect(flow.busy, isTrue);
      flow = flow.photoSaved(_photo(0, 1));
      expect(flow.stage, GuestStage.shotSaved);
      expect(flow.shots!.remaining, [1, 2]);
      flow = flow.nextShot();
      expect(
        (flow.stage, flow.shot, flow.secondsLeft),
        (GuestStage.countdown, 1, 3),
      );
      flow = _takeAll(flow.tick().tick().tick().photoSaved(_photo(1, 1)));
      expect(flow.stage, GuestStage.review);
      expect(flow.shots!.isComplete, isTrue);
      flow = flow.keep();
      expect(flow.stage, GuestStage.rendering);
      expect(() => flow.reset(), throwsA(isA<InvalidGuestTransition>()));
      flow = flow.rendered('output-1');
      expect(flow.stage, GuestStage.completed);
      expect(flow.outputId, 'output-1');
      expect(flow.inSession, isFalse);
      expect(flow.reset().stage, GuestStage.idle);
    });

    test('guests choose a template only when allowed and there is a '
        'choice', () {
      final choosing = GuestFlow.idle.start(
        templates: const ['rev-a', 'rev-b'],
        defaultTemplate: 'rev-a',
        guestChooses: true,
      );
      expect(choosing.stage, GuestStage.templateSelection);
      expect(choosing.templates, ['rev-a', 'rev-b']);
      expect(
        () => choosing.chooseTemplate('rev-z'),
        throwsA(isA<InvalidGuestTransition>()),
      );
      final chosen = choosing.chooseTemplate('rev-b');
      expect(chosen.stage, GuestStage.preparing);
      expect(chosen.templateRevisionId, 'rev-b');
      final single = GuestFlow.idle.start(
        templates: const ['rev-a'],
        defaultTemplate: 'rev-a',
        guestChooses: true,
      );
      expect(single.stage, GuestStage.preparing);
      final none = GuestFlow.idle.start(
        templates: const [],
        defaultTemplate: null,
        guestChooses: true,
      );
      expect(none.stage, GuestStage.failed);
      expect(none.problem!.recoverable, isFalse);
      expect(none.problem!.code, 'SESSION_NO_TEMPLATE');
    });

    test('a per-shot retake counts down that shot and returns to '
        'review', () {
      var flow = _takeAll(begin());
      flow = flow.retakeShot(1);
      expect((flow.stage, flow.shot), (GuestStage.preparing, 1));
      flow = flow.cameraReady().tick().tick().tick();
      flow = flow.photoSaved(_photo(1, 2));
      expect(flow.stage, GuestStage.review);
      expect(flow.shots!.selected(1)!.attempt, 2);
      expect(flow.shots!.selected(0)!.attempt, 1);
      expect(
        () => flow.retakeShot(1),
        throwsA(isA<InvalidGuestTransition>()),
        reason: 'its one retake is used',
      );
    });

    test('a whole-session retake takes every shot again', () {
      var flow = _takeAll(begin(policy: RetakePolicy.wholeSession));
      expect(() => flow.retakeShot(0), throwsA(isA<InvalidGuestTransition>()));
      flow = flow.retakeAll();
      expect((flow.stage, flow.shot), (GuestStage.preparing, 0));
      flow = _takeAll(flow, round: 1);
      expect(flow.stage, GuestStage.review);
      expect(flow.shots!.slotBindings, {
        0: 'shot0-attempt2',
        1: 'shot1-attempt2',
      });
      expect(() => flow.retakeAll(), throwsA(isA<InvalidGuestTransition>()));
    });

    test('an interruption stops the countdown; only an explicit resume '
        'counts down again, from the top', () {
      var flow = begin().cameraReady().tick();
      flow = flow.interrupt();
      expect((flow.stage, flow.shot), (GuestStage.interrupted, 0));
      expect(() => flow.tick(), throwsA(isA<InvalidGuestTransition>()));
      expect(() => flow.cameraReady(), throwsA(isA<InvalidGuestTransition>()));
      flow = flow.resume();
      expect(flow.stage, GuestStage.preparing);
      flow = flow.cameraReady();
      expect(flow.secondsLeft, 3, reason: 'a fresh countdown');

      // Between photos: the next shot waits for the guest too.
      var between = flow.tick().tick().tick().photoSaved(_photo(0, 1));
      between = between.interrupt();
      expect((between.stage, between.shot), (GuestStage.interrupted, 1));

      // A photo being taken cannot be interrupted; it finishes first.
      final capturing = flow.tick().tick().tick();
      expect(
        () => capturing.interrupt(),
        throwsA(isA<InvalidGuestTransition>()),
      );
    });

    test('problems keep the photos; recoverable ones can be retried', () {
      var flow = begin().cameraReady().tick().tick().tick();
      flow = flow.fail(
        const GuestProblem(
          GuestProblemKind.capture,
          code: 'CAMERA_CAPTURE_FAILED',
        ),
      );
      expect(flow.stage, GuestStage.failed);
      expect(flow.shot, 0);
      flow = flow.retry();
      expect((flow.stage, flow.shot), (GuestStage.preparing, 0));

      final rendering = _takeAll(begin()).keep();
      final failed = rendering.fail(
        const GuestProblem(GuestProblemKind.render, code: 'EXPORT_NO_SPACE'),
      );
      expect(failed.shots!.isComplete, isTrue);
      expect(failed.retry().stage, GuestStage.rendering);

      final storage = GuestFlow.idle.fail(
        const GuestProblem(GuestProblemKind.storage, code: 'STORAGE_LOW'),
      );
      expect(() => storage.retry(), throwsA(isA<InvalidGuestTransition>()));
      expect(storage.reset().stage, GuestStage.idle);
    });

    test('steps out of order are rejected', () {
      final idle = GuestFlow.idle;
      for (final step in <GuestFlow Function()>[
        idle.cameraReady,
        idle.tick,
        idle.keep,
        idle.nextShot,
        idle.resume,
        idle.retry,
        idle.interrupt,
        () => idle.rendered('x'),
        () => idle.photoSaved(_photo(0, 1)),
        () => idle.retakeShot(0),
        idle.retakeAll,
        () => idle.chooseTemplate('rev-a'),
      ]) {
        expect(step, throwsA(isA<InvalidGuestTransition>()));
      }
      final review = _takeAll(begin());
      expect(review.tick, throwsA(isA<InvalidGuestTransition>()));
      expect(
        () => review.photoSaved(_photo(0, 2)),
        throwsA(isA<InvalidGuestTransition>()),
      );
      final counting = begin().cameraReady();
      expect(
        () => counting.photoSaved(_photo(0, 1)),
        throwsA(isA<InvalidGuestTransition>()),
        reason: 'no photo without the countdown reaching zero',
      );
      expect(
        () => counting.tick().tick().tick().photoSaved(_photo(1, 1)),
        throwsA(isA<InvalidGuestTransition>()),
        reason: 'the photo must be for the shot counted down',
      );
      expect(
        () => begin().sessionStarted(SessionShots.empty(_plan())),
        throwsA(isA<InvalidGuestTransition>()),
        reason: 'one session per guest',
      );
    });
  });
}
