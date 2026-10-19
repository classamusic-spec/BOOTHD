import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/access/access_controller.dart';
import '../../core/booth/booth_providers.dart';
import '../../core/booth/booth_session_controller.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/di/service_providers.dart';
import '../../core/routing/route_paths.dart';
import '../../core/templates/template_thumbnails.dart';
import '../../domain/models/booth_event.dart';
import '../../domain/services/camera_service.dart';
import '../../domain/session/guest_flow.dart';
import '../../domain/value_objects/orientation.dart';
import '../../shared/guest/event_welcome_copy.dart';
import '../../shared/guest/guest_layout.dart';
import '../../shared/guest/guest_welcome.dart';
import '../../shared/widgets/porcelain_spinner.dart';
import 'booth_copy.dart';
import 'booth_event_theme.dart';
import 'guest_camera_stage.dart';
import 'guest_finished.dart';
import 'guest_notices.dart';
import 'guest_review.dart';
import 'guest_template_choice.dart';
import 'hidden_operator_exit.dart';

/// Booth Mode (S20 to S29) for the running event, in the event's theme
/// ([BoothEventTheme]): the guest welcome and every step of a session.
/// There is no back, no settings and nothing that leads elsewhere; system
/// back does nothing. The only way off is the operator's hidden hold,
/// which ends the session first.
class BoothScreen extends ConsumerWidget {
  const BoothScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventId = ref.watch(accessControllerProvider).boothEventId;
    final event = eventId == null
        ? const AsyncData<BoothEvent?>(null)
        : ref.watch(eventProvider(eventId));
    void toOperator() => context.go(RoutePaths.boothOperator);

    final Widget body = switch (event) {
      // Once read, the event's session keeps running through any reload.
      AsyncValue(value: final event?) => BoothSessionView(
        key: ValueKey(event.id),
        event: event,
        onOperator: toOperator,
      ),
      AsyncLoading() => _WithExit(
        onOperator: toOperator,
        child: const _GuestWaiting(),
      ),
      // A missing or unreadable event: a calm notice, no details.
      _ => _WithExit(
        onOperator: toOperator,
        child: const _GuestNotice(message: BoothCopy.notReady),
      ),
    };

    return BoothEventTheme(
      child: PopScope(canPop: false, child: Scaffold(body: body)),
    );
  }
}

/// The guest screens of one event's sessions, driven by a
/// [BoothSessionController] that lives as long as Booth Mode shows them.
///
/// Each step has its own screen; changes cross-fade (instantly with
/// reduced motion), except the return to the welcome, which drops the last
/// guest's screen at once (AC-0709). The booth asks the OS for the event's
/// preferred orientation, but every screen lays itself out from the space
/// it actually gets (ADR-0004).
class BoothSessionView extends ConsumerStatefulWidget {
  const BoothSessionView({
    super.key,
    required this.event,
    required this.onOperator,
  });

  final BoothEvent event;

  /// Opens the operator's PIN screen (S28), after the session has ended.
  final VoidCallback onOperator;

  @override
  ConsumerState<BoothSessionView> createState() => _BoothSessionViewState();
}

enum _Screen {
  welcome,
  choice,
  camera,
  review,
  rendering,
  finished,
  paused,
  problem,
}

class _BoothSessionViewState extends ConsumerState<BoothSessionView> {
  late final BoothSessionController _session;

  @override
  void initState() {
    super.initState();
    _session = BoothSessionController(
      event: widget.event,
      camera: ref.read(cameraServiceProvider),
      originals: ref.read(capturedStillStoreProvider),
      sessions: ref.read(sessionRepositoryProvider),
      export: ref.read(exportServiceProvider),
      finished: ref.read(finishedPhotosProvider),
      templates: ref.read(templateRepositoryProvider),
      assets: ref.read(assetRepositoryProvider),
      space: ref.read(deviceStorageInfoProvider),
      clock: ref.read(clockProvider),
      ids: ref.read(idGeneratorProvider),
    );
    // Finished photos an earlier run could not finish (AC-0707).
    unawaited(_session.finishPending());
    // A request only: the OS may keep another orientation (ADR-0004).
    unawaited(
      SystemChrome.setPreferredOrientations(
        switch (widget.event.capture.orientation) {
          GuestOrientationPreference.portrait => const [
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ],
          GuestOrientationPreference.landscape => const [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ],
        },
      ),
    );
  }

  @override
  void dispose() {
    _session.dispose();
    unawaited(SystemChrome.setPreferredOrientations(const []));
    super.dispose();
  }

  Future<void> _leave() async {
    await _session.leaveForOperator();
    if (mounted) widget.onOperator();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _session,
      builder: (context, _) => _WithExit(
        onOperator: () => unawaited(_leave()),
        child: _guestScreen(context),
      ),
    );
  }

  Widget _guestScreen(BuildContext context) {
    final flow = _session.flow;
    final screen = switch (flow.stage) {
      GuestStage.idle => _Screen.welcome,
      GuestStage.templateSelection => _Screen.choice,
      GuestStage.preparing ||
      GuestStage.countdown ||
      GuestStage.capturing ||
      GuestStage.shotSaved => _Screen.camera,
      GuestStage.review => _Screen.review,
      GuestStage.rendering => _Screen.rendering,
      GuestStage.completed => _Screen.finished,
      GuestStage.interrupted => _Screen.paused,
      GuestStage.failed => _Screen.problem,
    };
    final motion = PorcelainMotion.of(context);
    final welcome = screen == _Screen.welcome;
    return AnimatedSwitcher(
      duration: motion.emphasized,
      switchInCurve: PorcelainMotion.enter,
      switchOutCurve: PorcelainMotion.exit,
      transitionBuilder: _transition,
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.expand,
        children: [
          // Back at the welcome, nothing of the last guest stays on
          // screen, not even fading out (AC-0709).
          if (!welcome) ...previous,
          ?current,
        ],
      ),
      child: KeyedSubtree(
        key: ValueKey(screen),
        child: _screenFor(context, screen, flow),
      ),
    );
  }

  /// The welcome appears at once; other screens fade in over it.
  static Widget _transition(Widget child, Animation<double> animation) =>
      child.key == const ValueKey(_Screen.welcome)
      ? child
      : FadeTransition(opacity: animation, child: child);

  Widget _screenFor(BuildContext context, _Screen screen, GuestFlow flow) {
    final event = widget.event;
    final photosSoFar = flow.shots?.photos.isNotEmpty ?? false;
    return switch (screen) {
      _Screen.welcome => _Welcome(
        event: event,
        onStart: () => unawaited(_session.start()),
      ),
      _Screen.choice => GuestTemplateChoice(
        templates: flow.templates,
        initial: event.templates.defaultRevisionId,
        onChosen: _session.chooseTemplate,
      ),
      _Screen.camera => _cameraStage(context, flow),
      _Screen.review => GuestReview(
        shots: flow.shots!,
        photo: _session.photo,
        aspect: _session.photoAspect,
        mirrored: flow.shots!.plan.capture.mirrorOutput,
        onRetake: _session.retakeShot,
        onRetakeAll: _session.retakeAll,
        onKeep: _session.keep,
      ),
      _Screen.rendering => const GuestRendering(),
      _Screen.finished => GuestFinished(
        photo: _session.finishedPhoto!,
        aspect: _session.output!.widthPx / _session.output!.heightPx,
        onNextGuest: () => unawaited(_session.nextGuest()),
      ),
      _Screen.paused => GuestPaused(
        photosSoFar: photosSoFar,
        onContinue: _session.resume,
      ),
      _Screen.problem => GuestProblemNotice(
        problem: flow.problem!,
        photosSoFar: photosSoFar,
        onRetry: _session.retry,
        onStartOver: () => unawaited(_session.startOver()),
      ),
    };
  }

  Widget _cameraStage(BuildContext context, GuestFlow flow) {
    final shots = flow.shots;
    final capture = shots?.plan.capture ?? widget.event.capture;
    final shot = flow.shot ?? shots?.nextShot ?? 0;
    final count = shots?.shotCount ?? capture.shotCount;
    final step = switch (flow.stage) {
      GuestStage.countdown => CameraStep.countdown,
      GuestStage.capturing => CameraStep.capturing,
      GuestStage.shotSaved => CameraStep.saved,
      _ => CameraStep.preparing,
    };
    bool takenThisRound(int i) {
      final selected = shots?.selected(i);
      return selected != null && selected.round == shots!.round;
    }

    final status = _session.cameraStatus;
    final live =
        status.lifecycle == CameraLifecycle.ready ||
        status.lifecycle == CameraLifecycle.capturing;
    return GuestCameraStage(
      step: step,
      secondsLeft: flow.secondsLeft,
      shotNumber: shot + 1,
      shotCount: count,
      retaking: step != CameraStep.saved && takenThisRound(shot),
      marks: [
        for (var i = 0; i < count; i++)
          if (i == shot && step != CameraStep.saved)
            const ShotMark.current()
          else if (takenThisRound(i))
            ShotMark.done(_session.photo(shots!.selected(i)!.originalId))
          else
            const ShotMark.upcoming(),
      ],
      preview: live
          ? ref.watch(cameraPreviewBuilderProvider)(
              context,
              mirror: capture.mirrorPreview,
            )
          : null,
      previewAspect: status.capabilities?.previewAspectRatio ?? 4 / 3,
      mirroredPhotos: capture.mirrorOutput,
      flashKey: '${shots?.photos.length ?? 0}:$shot',
    );
  }
}

/// A guest screen with the operator's hidden corner over it.
class _WithExit extends StatelessWidget {
  const _WithExit({required this.onOperator, required this.child});

  final VoidCallback onOperator;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(child: child),
      HiddenOperatorExit(onTriggered: onOperator),
    ],
  );
}

class _Welcome extends ConsumerWidget {
  const _Welcome({required this.event, required this.onStart});

  final BoothEvent event;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = event.templates;
    final revisionId =
        templates.defaultRevisionId ?? templates.revisionIds.firstOrNull;
    // The event's own print, with sample spaces for the photos: shown once
    // drawn, and not at all if it cannot be. Never a guest's photo.
    final print = revisionId == null
        ? null
        : ref.watch(templateShowcaseProvider(revisionId)).value;
    return GuestWelcome(
      copy: welcomeCopyFor(event),
      preview: print == null
          ? null
          : Semantics(
              label: 'How your photos will be laid out',
              image: true,
              child: Image.memory(
                print,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                excludeFromSemantics: true,
              ),
            ),
      onStart: onStart,
    );
  }
}

class _GuestWaiting extends StatelessWidget {
  const _GuestWaiting();

  @override
  Widget build(BuildContext context) => GuestBackdrop(
    child: Center(
      child: PorcelainSpinner(
        color: context.porcelain.colors.accentIcon,
        size: 32,
      ),
    ),
  );
}

class _GuestNotice extends StatelessWidget {
  const _GuestNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return GuestBackdrop(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(PorcelainSpace.huge),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: theme.text.guestBody,
          ),
        ),
      ),
    );
  }
}
