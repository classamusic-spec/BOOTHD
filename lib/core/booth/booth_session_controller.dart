import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../domain/models/booth_event.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/repositories/template_store.dart';
import '../../domain/services/booth_capabilities.dart';
import '../../domain/services/camera_service.dart';
import '../../domain/services/composition_renderer.dart';
import '../../domain/services/export_service.dart';
import '../../domain/services/finished_photos.dart';
import '../../domain/session/guest_flow.dart';
import '../../domain/session/session_plan.dart';
import '../../domain/session/session_shots.dart';
import '../../domain/template/template_document.dart';
import '../../domain/value_objects/clock.dart';
import '../../domain/value_objects/entity_id.dart';
import '../camera/camera_session.dart';
import 'session_recovery.dart';
import 'session_renderer.dart';

/// How long a guest-facing step waits before the booth moves on by itself
/// (guest-safe timeouts, ADR-0013).
@immutable
final class BoothTimeouts {
  const BoothTimeouts({
    this.templateChoice = const Duration(seconds: 60),
    this.review = const Duration(seconds: 90),
    this.interrupted = const Duration(seconds: 60),
    this.problem = const Duration(seconds: 90),
    this.cameraOpen = const Duration(seconds: 20),
    this.capture = const Duration(seconds: 30),
  });

  /// Choosing a template: then back to the welcome screen.
  final Duration templateChoice;

  /// Looking at the photos: then they are kept and the finished photo is
  /// made, as if the guest had tapped Keep.
  final Duration review;

  /// Paused after an interruption: then the session ends.
  final Duration interrupted;

  /// A problem screen: then the session ends and the booth welcomes the
  /// next guest.
  final Duration problem;

  /// Recording the session and opening the camera before a countdown:
  /// then a camera problem the guest can retry, never an endless wait.
  final Duration cameraOpen;

  /// Taking and saving one photo: then a capture problem. A photo that
  /// arrives later stays in storage but is not used.
  final Duration capture;
}

/// Runs the booth's guest sessions (A-10, P-09; S20 to S29) for one event.
///
/// The [GuestFlow] value decides what may happen next; this controller
/// does the work around it: the free-space check, freezing the session,
/// the camera, a countdown on timers (monotonic, never the wall clock)
/// that stops whenever the booth leaves the foreground, captures that are
/// recorded only once their original is durably saved, retakes, rendering
/// with a checkpoint, the finished photo read back and checked, guest-safe
/// timeouts and the reset that leaves nothing of the last guest on screen
/// or in memory. Unfinished renders from earlier sessions are finished
/// while the booth is idle.
final class BoothSessionController extends ChangeNotifier {
  BoothSessionController({
    required this.event,
    required CameraService camera,
    required this._originals,
    required this._sessions,
    required ExportService export,
    required FinishedPhotos finished,
    required this._templates,
    required AssetRepository assets,
    required this._space,
    required this._clock,
    required this._ids,
    this.timeouts = const BoothTimeouts(),
  }) : _cameraService = camera,
       _camera = CameraSessionController(camera),
       _renderer = SessionRenderer(
         export: export,
         finished: finished,
         templates: _templates,
         assets: assets,
         originals: _originals,
       ) {
    _camera.addListener(_onCamera);
    _lifecycle = AppLifecycleListener(onStateChange: _onAppState);
    final state = WidgetsBinding.instance.lifecycleState;
    _appActive = state == null || state == AppLifecycleState.resumed;
  }

  /// Operator diagnostics for problems the controller detects itself.
  static const cameraOpenTimeout = 'CAMERA_OPEN_TIMEOUT';
  static const captureTimeout = 'CAMERA_CAPTURE_TIMEOUT';
  static const unexpected = 'BOOTH_UNEXPECTED_ERROR';

  /// The running event; the booth cannot be reconfigured while it runs.
  final BoothEvent event;
  final BoothTimeouts timeouts;

  final CameraService _cameraService;
  final CameraSessionController _camera;
  final CapturedStillStore _originals;
  final SessionRepository _sessions;
  final TemplateRepository _templates;
  final DeviceStorageInfo _space;
  final Clock _clock;
  final IdGenerator _ids;
  final SessionRenderer _renderer;
  late final AppLifecycleListener _lifecycle;

  var _flow = GuestFlow.idle;
  var _epoch = 0;
  var _appActive = true;
  var _disposed = false;
  var _pendingRunning = false;
  String? _sessionId;
  TemplateDocument? _document;
  SessionOutput? _output;
  Uint8List? _finishedPhoto;
  final _photos = <String, Future<Uint8List>>{};
  final _stills = <String, CapturedStill>{};
  Timer? _ticker;
  Timer? _timer;

  GuestFlow get flow => _flow;

  /// The camera as the session uses it: its live picture and status.
  CameraStatus get cameraStatus => _camera.status;

  /// The finished photo's record, once saved (S27).
  SessionOutput? get output => _output;

  /// The finished photo's bytes, read back from storage and checked
  /// before the session was recorded as completed.
  Uint8List? get finishedPhoto => _finishedPhoto;

  /// The last problem a guest met, for the operator (never shown to
  /// guests with its code).
  GuestProblem? lastProblem;

  /// The saved original [originalId] of this session, read back and
  /// checked (S24 thumbnails, S25 review).
  Future<Uint8List> photo(String originalId) =>
      _photos[originalId] ??= _quiet(_renderer.readOriginal(originalId));

  /// Width over height of the original [originalId] as guests see it, when
  /// this session took it.
  double? photoAspect(String originalId) {
    final still = _stills[originalId];
    return still == null ? null : still.widthPx / still.heightPx;
  }

  // Guest actions.

  /// Start (S20): checks space, then a template choice or the camera.
  Future<void> start() async {
    if (_flow.stage != GuestStage.idle) return;
    final epoch = _epoch;
    int? free;
    try {
      free = await _space.freeBytes();
    } on Object {
      // Unknown: the session starts, as the launch checks allowed.
    }
    if (!_current(epoch) || _flow.stage != GuestStage.idle) return;
    if (free != null && free < StorageBudget.minimumSessionFreeBytes) {
      _fail(GuestProblemKind.storage, 'STORAGE_LOW');
      return;
    }
    _set(
      _flow.start(
        templates: event.templates.revisionIds,
        defaultTemplate: event.templates.defaultRevisionId,
        guestChooses: event.guest.guestChoosesTemplate,
      ),
    );
  }

  void chooseTemplate(String revisionId) {
    if (_flow.stage == GuestStage.templateSelection &&
        _flow.templates.contains(revisionId)) {
      _set(_flow.chooseTemplate(revisionId));
    }
  }

  void retakeShot(int shot) {
    if (_flow.stage == GuestStage.review &&
        (_flow.shots?.canRetake(shot) ?? false)) {
      _set(_flow.retakeShot(shot));
    }
  }

  void retakeAll() {
    if (_flow.stage == GuestStage.review &&
        (_flow.shots?.canRetakeAll ?? false)) {
      _set(_flow.retakeAll());
    }
  }

  void keep() {
    if (_flow.stage == GuestStage.review) _set(_flow.keep());
  }

  void retry() {
    if (_flow.stage == GuestStage.failed &&
        (_flow.problem?.recoverable ?? false)) {
      _set(_flow.retry());
    }
  }

  /// Continue after an interruption (the guest is back).
  void resume() {
    if (_flow.stage == GuestStage.interrupted) _set(_flow.resume());
  }

  /// Next guest (S27): back to the welcome screen.
  Future<void> nextGuest() => _endAndReset(SessionEndReason.timedOut);

  /// Start over from a problem screen (S29). The photos so far stay in
  /// storage, and a finished photo that could not be made is made later.
  Future<void> startOver() => _endAndReset(SessionEndReason.problem);

  /// The operator's hidden exit (S28): a photo or the finished photo being
  /// saved finishes first, then the session ends and the camera is
  /// released.
  Future<void> leaveForOperator() async {
    await _whenNotBusy();
    await _endAndReset(SessionEndReason.operatorExit);
  }

  /// Finishes renders earlier sessions left (AC-0707), one at a time,
  /// while the booth is idle. Safe to call repeatedly.
  Future<void> finishPending() async {
    if (_pendingRunning || _disposed) return;
    _pendingRunning = true;
    try {
      final unfinished = await _sessions.unfinished();
      for (final session in unfinished) {
        if (_disposed) return;
        if (session.status != SessionStatus.rendering ||
            session.id == _sessionId) {
          continue;
        }
        if (session.renderAttempts >= SessionRecovery.maxRenderAttempts) {
          await _sessions.end(
            session.id,
            status: SessionStatus.failed,
            reason: SessionEndReason.renderFailed,
          );
          continue;
        }
        try {
          await _sessions.beginRender(session.id);
          final document = (await _templates.loadRevision(
            session.plan.templateRevisionId,
          )).document;
          await _renderSession(session.id, session.shots, document);
        } on Object {
          // Still rendering, one attempt more: tried again later.
        }
      }
    } on SessionStoreException {
      // The records could not be read now; tried again at the next reset.
    } finally {
      _pendingRunning = false;
    }
  }

  // Transitions and their effects.

  bool _current(int epoch) => !_disposed && epoch == _epoch;

  void _set(GuestFlow next) {
    if (_disposed) return;
    final changedStage = next.stage != _flow.stage;
    _flow = next;
    if (next.problem case final problem?) lastProblem = problem;
    _epoch++;
    if (changedStage) _cancelTimers();
    notifyListeners();
    if (changedStage) _enter(next.stage, _epoch);
  }

  /// A problem for the guest, when the flow can still stop for one;
  /// otherwise (the photos are under review or later) only the operator
  /// learns of it.
  void _fail(GuestProblemKind kind, String? code) {
    if (_disposed) return;
    final problem = GuestProblem(kind, code: code);
    if (!_flow.canFail) {
      lastProblem = problem;
      notifyListeners();
      return;
    }
    _set(_flow.fail(problem));
  }

  /// Runs [action] after [delay] unless the guest has moved to another
  /// step meanwhile (every step change cancels these timers).
  void _after(Duration delay, void Function() action) {
    final stage = _flow.stage;
    _timer = Timer(delay, () {
      if (!_disposed && _flow.stage == stage) action();
    });
  }

  void _cancelTimers() {
    _ticker?.cancel();
    _ticker = null;
    _timer?.cancel();
    _timer = null;
  }

  void _enter(GuestStage stage, int epoch) {
    switch (stage) {
      case GuestStage.idle:
        break;
      case GuestStage.templateSelection:
        _after(
          timeouts.templateChoice,
          () => unawaited(_endAndReset(SessionEndReason.timedOut)),
        );
      case GuestStage.preparing:
        _after(
          timeouts.cameraOpen,
          () => _fail(GuestProblemKind.camera, cameraOpenTimeout),
        );
        unawaited(_prepare(epoch));
      case GuestStage.countdown:
        _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
          if (_disposed || _flow.stage != GuestStage.countdown) return;
          final next = _flow.tick();
          _haptic(
            next.stage == GuestStage.capturing
                ? HapticFeedback.mediumImpact
                : HapticFeedback.selectionClick,
          );
          _set(next);
        });
      case GuestStage.capturing:
        _after(
          timeouts.capture,
          () => _fail(GuestProblemKind.capture, captureTimeout),
        );
        unawaited(_capture(epoch));
      case GuestStage.shotSaved:
        if (!_appActive) {
          _set(_flow.interrupt());
          return;
        }
        _after(
          Duration(seconds: _flow.shots!.plan.capture.shotIntervalSeconds),
          () => _set(_flow.nextShot()),
        );
      case GuestStage.review:
        unawaited(_markReviewing());
        _after(timeouts.review, keep);
      case GuestStage.rendering:
        unawaited(_render(epoch));
      case GuestStage.completed:
        _after(
          Duration(seconds: _flow.shots!.plan.finishTimeoutSeconds),
          () => unawaited(nextGuest()),
        );
      case GuestStage.interrupted:
        _after(
          timeouts.interrupted,
          () => unawaited(_endAndReset(SessionEndReason.timedOut)),
        );
      case GuestStage.failed:
        _after(
          timeouts.problem,
          () => unawaited(_endAndReset(SessionEndReason.problem)),
        );
    }
  }

  /// Records the session (first time), opens the camera, and starts the
  /// countdown only while the booth is in front.
  Future<void> _prepare(int epoch) async {
    try {
      if (_flow.shots == null) {
        final revisionId = _flow.templateRevisionId!;
        final document = (await _templates.loadRevision(revisionId)).document;
        if (!_current(epoch)) return;
        final plan = SessionPlan.freeze(
          event: event,
          templateRevisionId: revisionId,
          document: document,
        );
        final id = _ids.newId();
        await _sessions.create(id: id, plan: plan, startedAtUtc: _clock.now());
        if (!_current(epoch)) {
          // The guest moved on meanwhile; nothing was taken.
          await _sessions.end(
            id,
            status: SessionStatus.abandoned,
            reason: SessionEndReason.interrupted,
          );
          return;
        }
        _sessionId = id;
        _document = document;
        _set(_flow.sessionStarted(SessionShots.empty(plan)));
        epoch = _epoch;
      }
      final plan = _flow.shots!.plan;
      final request = plan.cameraRequest(
        await _cameraService.availableCameras(),
      );
      if (!_current(epoch)) return;
      if (request == null) {
        _fail(GuestProblemKind.camera, CameraFailureCode.noCamera.diagnostic);
        return;
      }
      await _camera.open(request);
      if (!_current(epoch)) return;
      if (!_appActive) {
        // Left the foreground meanwhile: the guest carries on with a tap.
        _set(_flow.interrupt());
        return;
      }
      // The service's own status: the session controller's copy follows
      // it a moment later.
      final status = _cameraService.status;
      if (!status.isReady) {
        _fail(
          GuestProblemKind.camera,
          status.failure?.code.diagnostic ??
              status.permission.problemCode ??
              CameraFailureCode.notReady.diagnostic,
        );
        return;
      }
      _set(_flow.cameraReady());
    } on TemplateStoreException catch (error) {
      if (_current(epoch)) {
        _fail(GuestProblemKind.setup, error.code.diagnostic);
      }
    } on SessionPlanException catch (error) {
      if (_current(epoch)) {
        _fail(GuestProblemKind.setup, error.problem.diagnostic);
      }
    } on SessionStoreException catch (error) {
      if (_current(epoch)) _fail(GuestProblemKind.setup, error.code);
    } on CameraFailure catch (failure) {
      if (_current(epoch)) {
        _fail(GuestProblemKind.camera, failure.code.diagnostic);
      }
    } on Object {
      if (_current(epoch)) _fail(GuestProblemKind.camera, unexpected);
    }
  }

  /// Takes the photo and records it once its original is saved. A photo
  /// being taken is never interrupted or reset: it finishes first, unless
  /// it takes longer than [BoothTimeouts.capture].
  Future<void> _capture(int epoch) async {
    final shots = _flow.shots!;
    final shot = _flow.shot!;
    final outcome = await _camera.capture();
    // Too late (timed out): the original stays in storage, unused.
    if (!_current(epoch)) return;
    _timer?.cancel();
    switch (outcome) {
      case CaptureSaved(:final still):
        final photo = ShotPhoto(
          shot: shot,
          attempt: shots.nextAttempt(shot),
          round: shots.round,
          originalId: still.id,
          capturedAtUtc: still.capturedAtUtc,
        );
        try {
          await _sessions.addPhoto(_sessionId!, photo);
        } on SessionStoreException catch (error) {
          if (_current(epoch)) _fail(GuestProblemKind.capture, error.code);
          return;
        } on Object {
          if (_current(epoch)) _fail(GuestProblemKind.capture, unexpected);
          return;
        }
        if (!_current(epoch)) return;
        _stills[still.id] = still;
        _photos[still.id] = _quiet(_originals.read(still));
        _set(_flow.photoSaved(photo));
        _forgetReplaced();
      case CaptureFailed(:final failure):
        _fail(GuestProblemKind.capture, failure.code.diagnostic);
      case CaptureIgnored():
        _fail(
          GuestProblemKind.capture,
          CameraFailureCode.captureBusy.diagnostic,
        );
    }
  }

  /// Keeps in memory only the photos the session uses: a retaken photo's
  /// bytes are let go (its original stays in storage), so retakes never
  /// pile up full-size photos.
  void _forgetReplaced() {
    final shots = _flow.shots;
    if (shots == null) return;
    final used = {
      for (var shot = 0; shot < shots.shotCount; shot++)
        ?shots.selected(shot)?.originalId,
    };
    _photos.removeWhere((id, _) => !used.contains(id));
    _stills.removeWhere((id, _) => !used.contains(id));
  }

  Future<void> _markReviewing() async {
    try {
      await _sessions.markReviewing(_sessionId!);
    } on SessionStoreException catch (error) {
      // Only a checkpoint: the session carries on, and the operator can
      // see why.
      lastProblem = GuestProblem(GuestProblemKind.setup, code: error.code);
    } on Object {
      lastProblem = const GuestProblem(
        GuestProblemKind.setup,
        code: unexpected,
      );
    }
  }

  /// Makes and saves the finished photo; "saved" appears only after the
  /// file is verified, read back intact and recorded (AC-0705).
  Future<void> _render(int epoch) async {
    try {
      await _sessions.beginRender(_sessionId!);
      final (output, bytes) = await _renderSession(
        _sessionId!,
        _flow.shots!,
        _document!,
      );
      if (!_current(epoch)) return;
      _output = output;
      _finishedPhoto = bytes;
      _set(_flow.rendered(output.id));
    } on RenderFailure catch (failure) {
      if (_current(epoch)) {
        _fail(GuestProblemKind.render, failure.code.diagnostic);
      }
    } on ExportFailure catch (failure) {
      if (_current(epoch)) {
        _fail(GuestProblemKind.render, failure.code.diagnostic);
      }
    } on SessionStoreException catch (error) {
      if (_current(epoch)) _fail(GuestProblemKind.render, error.code);
    } on Object {
      if (_current(epoch)) _fail(GuestProblemKind.render, unexpected);
    }
  }

  /// Renders and exports the session's finished photo, reads the file back
  /// against its checksum, and only then records the session completed.
  /// Until then the session stays `rendering`, so a retry (or startup
  /// recovery) can make it again.
  Future<(SessionOutput, Uint8List)> _renderSession(
    String sessionId,
    SessionShots shots,
    TemplateDocument document,
  ) async {
    final (exported, bytes) = await _renderer.render(shots, document: document);
    final output = await _sessions.complete(sessionId, exported);
    return (output, bytes);
  }

  /// Ends the session (unless it completed, or still waits to be
  /// rendered again), releases the camera and forgets every image of it.
  Future<void> _endAndReset(SessionEndReason reason) async {
    if (_disposed || _flow.busy) return;
    final id = _sessionId;
    final renderPending =
        _flow.stage == GuestStage.failed &&
        _flow.problem?.kind == GuestProblemKind.render;
    final keep = _flow.stage == GuestStage.completed || renderPending;
    _sessionId = null;
    _document = null;
    _output = null;
    _finishedPhoto = null;
    _photos.clear();
    _stills.clear();
    _set(_flow.reset());
    if (id != null && !keep) {
      try {
        await _sessions.end(
          id,
          status: SessionStatus.abandoned,
          reason: reason,
        );
      } on SessionStoreException {
        // Already ended; startup recovery ends anything left.
      }
    }
    // Nothing of the last guest stays in memory (AC-0709).
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    await _camera.release();
    unawaited(finishPending());
  }

  Future<void> _whenNotBusy() {
    if (!_flow.busy || _disposed) return Future.value();
    final done = Completer<void>();
    void check() {
      if (_flow.busy) return;
      removeListener(check);
      done.complete();
    }

    addListener(check);
    return done.future;
  }

  void _onAppState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    if (_appActive) return;
    // Never a countdown or a next shot while the booth is not in front: a
    // photo would be taken late (AC-0702). A photo in flight finishes
    // first.
    if (_flow.stage == GuestStage.preparing ||
        _flow.stage == GuestStage.countdown ||
        _flow.stage == GuestStage.shotSaved) {
      _set(_flow.interrupt());
    }
  }

  void _onCamera() {
    if (_disposed) return;
    final status = _camera.status;
    final stopped =
        status.lifecycle == CameraLifecycle.failed ||
        status.lifecycle == CameraLifecycle.suspended;
    if (stopped &&
        (_flow.stage == GuestStage.countdown ||
            _flow.stage == GuestStage.shotSaved)) {
      lastProblem = GuestProblem(
        GuestProblemKind.camera,
        code: status.failure?.code.diagnostic,
      );
      _set(_flow.interrupt());
      return;
    }
    notifyListeners();
  }

  /// [future], whose error (if any) is for whoever reads it later, not an
  /// uncaught error now.
  static Future<T> _quiet<T>(Future<T> future) {
    future.ignore();
    return future;
  }

  void _haptic(Future<void> Function() feedback) {
    unawaited(
      feedback().catchError((Object _) {
        // No haptics on this tablet.
      }),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelTimers();
    _lifecycle.dispose();
    _camera
      ..removeListener(_onCamera)
      ..dispose();
    final id = _sessionId;
    final keep =
        _flow.stage == GuestStage.completed ||
        _flow.stage == GuestStage.rendering ||
        (_flow.stage == GuestStage.failed &&
            _flow.problem?.kind == GuestProblemKind.render);
    if (id != null && !keep) {
      // Best effort; startup recovery ends anything left, and finishes a
      // finished photo that was being made.
      unawaited(
        _sessions
            .end(
              id,
              status: SessionStatus.abandoned,
              reason: SessionEndReason.operatorExit,
            )
            .catchError((Object _) {}),
      );
    }
    super.dispose();
  }
}
