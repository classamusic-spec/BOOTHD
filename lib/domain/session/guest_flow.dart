import 'package:meta/meta.dart';

import 'session_shots.dart';

/// Where a guest is in the booth (A-10, P-09; screens S20 to S29).
enum GuestStage {
  /// The welcome screen (A-10 idle).
  idle,

  /// Choosing the session's template (S21), when the event lets guests.
  templateSelection,

  /// Recording the session and opening the camera before a countdown
  /// (A-10 preparing; S22 shows the live picture).
  preparing,

  /// Counting down to a photo (S23).
  countdown,

  /// The shutter is open: the photo is being taken and saved (S24).
  capturing,

  /// A photo was saved and the next one follows after a pause (A-10
  /// capturedIntermission).
  shotSaved,

  /// Looking at the photos: keep them or retake (S25).
  review,

  /// Making and saving the finished photo (S26).
  rendering,

  /// The finished photo is saved (S27).
  completed,

  /// The app left the foreground or the camera stopped; the guest carries
  /// on with a tap, so no photo is ever taken late (A-10 interrupted).
  interrupted,

  /// Something went wrong (S29); [GuestProblem.recoverable] says whether
  /// the guest can try again (A-10 recoverable and terminal failures).
  failed,
}

/// What went wrong for a guest, in kinds guest copy can explain.
enum GuestProblemKind {
  /// The camera would not open or stopped working.
  camera,

  /// A photo could not be taken or saved.
  capture,

  /// The finished photo could not be made or saved.
  render,

  /// The tablet is too full for another session.
  storage,

  /// The event or its template cannot run a session.
  setup,
}

@immutable
final class GuestProblem {
  const GuestProblem(this.kind, {this.code});

  final GuestProblemKind kind;

  /// The operator's diagnostic code (`CAMERA_*`, `RENDER_*`, `EXPORT_*`,
  /// `STORAGE_*`, `SESSION_*`). Never shown to guests.
  final String? code;

  /// Whether the guest may simply try again.
  bool get recoverable => switch (kind) {
    GuestProblemKind.camera ||
    GuestProblemKind.capture ||
    GuestProblemKind.render => true,
    GuestProblemKind.storage || GuestProblemKind.setup => false,
  };

  @override
  bool operator ==(Object other) =>
      other is GuestProblem && other.kind == kind && other.code == code;

  @override
  int get hashCode => Object.hash(kind, code);
}

/// A step the flow does not allow from where the guest is (A-10: invalid
/// transitions are rejected).
final class InvalidGuestTransition implements Exception {
  const InvalidGuestTransition(this.from, this.step);

  final GuestStage from;
  final String step;

  @override
  String toString() => 'InvalidGuestTransition(${from.name} -> $step)';
}

/// The guest's journey as a value (A-10): every step is a method that
/// returns the next flow or throws [InvalidGuestTransition]. Side effects
/// (the camera, storage, timers, rendering) belong to the controller that
/// drives it; this class only decides what may happen next.
///
/// Welcome → template (optional) → preparing → countdown → capturing →
/// (pause → countdown …) → review → (retake → preparing …) → rendering →
/// completed → welcome. A shot is only ever taken from a countdown that
/// ran while the booth was in front: an interruption returns to preparing
/// through an explicit [resume].
@immutable
final class GuestFlow {
  const GuestFlow._(
    this.stage, {
    this.templates = const [],
    this.templateRevisionId,
    this.shots,
    this.shot,
    this.secondsLeft = 0,
    this.problem,
    this.outputId,
  });

  static const idle = GuestFlow._(GuestStage.idle);

  final GuestStage stage;

  /// The templates a guest may choose between, in [GuestStage.templateSelection].
  final List<String> templates;

  /// The session's template revision, once known.
  final String? templateRevisionId;

  /// The session's photos, once the session is recorded.
  final SessionShots? shots;

  /// The shot being prepared, counted down, taken or just saved.
  final int? shot;

  /// Seconds left in a countdown; the number guests see.
  final int secondsLeft;

  final GuestProblem? problem;

  /// The saved finished photo, once completed.
  final String? outputId;

  /// Whether a session is recorded and not yet finished.
  bool get inSession =>
      shots != null &&
      stage != GuestStage.completed &&
      stage != GuestStage.idle;

  /// Whether work is in flight that a reset must not interrupt: a photo
  /// being taken and saved, or the finished photo being made (P-09).
  bool get busy =>
      stage == GuestStage.capturing || stage == GuestStage.rendering;

  GuestFlow _to(
    GuestStage stage, {
    List<String>? templates,
    SessionShots? shots,
    int? shot,
    int secondsLeft = 0,
    GuestProblem? problem,
    String? outputId,
  }) => GuestFlow._(
    stage,
    templates: templates ?? this.templates,
    templateRevisionId: templateRevisionId,
    shots: shots ?? this.shots,
    shot: shot,
    secondsLeft: secondsLeft,
    problem: problem,
    outputId: outputId,
  );

  void _expect(String step, Set<GuestStage> allowed, [bool also = true]) {
    if (!allowed.contains(stage) || !also) {
      throw InvalidGuestTransition(stage, step);
    }
  }

  /// A guest pressed Start. With several templates and the event's
  /// permission, they choose one; otherwise [defaultTemplate] is used.
  GuestFlow start({
    required List<String> templates,
    required String? defaultTemplate,
    required bool guestChooses,
  }) {
    _expect('start', {GuestStage.idle});
    final template = defaultTemplate ?? templates.firstOrNull;
    if (template == null) {
      return _to(
        GuestStage.failed,
        problem: const GuestProblem(
          GuestProblemKind.setup,
          code: 'SESSION_NO_TEMPLATE',
        ),
      );
    }
    if (guestChooses && templates.length > 1) {
      return GuestFlow._(
        GuestStage.templateSelection,
        templates: List.unmodifiable(templates),
      );
    }
    return GuestFlow._(GuestStage.preparing, templateRevisionId: template);
  }

  GuestFlow chooseTemplate(String revisionId) {
    _expect('chooseTemplate', {
      GuestStage.templateSelection,
    }, templates.contains(revisionId));
    return GuestFlow._(GuestStage.preparing, templateRevisionId: revisionId);
  }

  /// The session is recorded with [shots]; the first shot is next.
  GuestFlow sessionStarted(SessionShots shots) {
    _expect(
      'sessionStarted',
      {GuestStage.preparing},
      this.shots == null &&
          shots.plan.templateRevisionId == templateRevisionId &&
          !shots.isComplete,
    );
    return _to(GuestStage.preparing, shots: shots, shot: shots.nextShot);
  }

  /// The camera is open: the countdown for [shot] begins.
  GuestFlow cameraReady() {
    _expect('cameraReady', {
      GuestStage.preparing,
    }, shots != null && shot != null);
    return _to(
      GuestStage.countdown,
      shot: shot,
      secondsLeft: shots!.plan.capture.countdownSeconds,
    );
  }

  /// One second passed; after the last one the photo is taken.
  GuestFlow tick() {
    _expect('tick', {GuestStage.countdown});
    return secondsLeft > 1
        ? _to(GuestStage.countdown, shot: shot, secondsLeft: secondsLeft - 1)
        : _to(GuestStage.capturing, shot: shot);
  }

  /// [photo] of the current shot is saved: the next shot follows after a
  /// pause, or, with the set complete, the guest reviews it.
  GuestFlow photoSaved(ShotPhoto photo) {
    _expect('photoSaved', {
      GuestStage.capturing,
    }, shots != null && photo.shot == shot);
    final next = shots!.withPhoto(photo);
    return next.isComplete
        ? _to(GuestStage.review, shots: next)
        : _to(GuestStage.shotSaved, shots: next, shot: photo.shot);
  }

  /// The pause after a photo is over: count down to the next one.
  GuestFlow nextShot() {
    _expect('nextShot', {GuestStage.shotSaved});
    return _to(
      GuestStage.countdown,
      shot: shots!.nextShot,
      secondsLeft: shots!.plan.capture.countdownSeconds,
    );
  }

  /// Retake [shot] alone (per-shot policy); back to review after it.
  GuestFlow retakeShot(int shot) {
    _expect('retakeShot', {GuestStage.review}, shots?.canRetake(shot) ?? false);
    return _to(GuestStage.preparing, shot: shot);
  }

  /// Take the whole set again (whole-session policy); the guest confirmed.
  GuestFlow retakeAll() {
    _expect('retakeAll', {GuestStage.review}, shots?.canRetakeAll ?? false);
    final next = shots!.retakeAll();
    return _to(GuestStage.preparing, shots: next, shot: next.nextShot);
  }

  /// The guest keeps the photos: make the finished photo.
  GuestFlow keep() {
    _expect('keep', {GuestStage.review});
    return _to(GuestStage.rendering);
  }

  /// The finished photo [outputId] is saved and verified.
  GuestFlow rendered(String outputId) {
    _expect('rendered', {GuestStage.rendering});
    return _to(GuestStage.completed, outputId: outputId);
  }

  static const _failable = {
    GuestStage.idle,
    GuestStage.templateSelection,
    GuestStage.preparing,
    GuestStage.countdown,
    GuestStage.capturing,
    GuestStage.shotSaved,
    GuestStage.rendering,
  };

  /// Whether [fail] is allowed from here: not once the photos are under
  /// review, finished, paused or already failed.
  bool get canFail => _failable.contains(stage);

  /// Something went wrong; the shot and photos are kept for a retry.
  GuestFlow fail(GuestProblem problem) {
    _expect('fail', _failable);
    return _to(GuestStage.failed, shot: shot, problem: problem);
  }

  /// Try again after a recoverable problem.
  GuestFlow retry() {
    _expect('retry', {GuestStage.failed}, problem?.recoverable ?? false);
    return switch (problem!.kind) {
      GuestProblemKind.render => _to(GuestStage.rendering),
      _ => _to(GuestStage.preparing, shot: shot ?? shots?.nextShot),
    };
  }

  /// The app left the foreground or the camera stopped: stop counting and
  /// wait for the guest. A photo in flight finishes first (it is not
  /// interruptible); review and later steps carry on as they are.
  GuestFlow interrupt() {
    _expect('interrupt', {
      GuestStage.preparing,
      GuestStage.countdown,
      GuestStage.shotSaved,
    });
    final next = stage == GuestStage.shotSaved ? shots!.nextShot : shot;
    return _to(GuestStage.interrupted, shot: next);
  }

  /// The guest tapped Continue: open the camera again and count down anew.
  GuestFlow resume() {
    _expect('resume', {GuestStage.interrupted});
    return _to(GuestStage.preparing, shot: shot ?? shots?.nextShot);
  }

  /// Back to the welcome screen for the next guest. Never while a photo
  /// or the finished photo is being saved (P-09).
  GuestFlow reset() {
    if (busy) throw InvalidGuestTransition(stage, 'reset');
    return idle;
  }
}
