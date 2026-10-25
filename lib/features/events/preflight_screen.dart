import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/access/access_controller.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/di/service_providers.dart';
import '../../core/platform/app_environment.dart';
import '../../core/routing/route_paths.dart';
import '../../domain/models/booth_event.dart';
import '../../domain/models/template_revision_summary.dart';
import '../../domain/services/booth_capabilities.dart';
import '../../domain/services/preflight.dart';
import '../../domain/value_objects/orientation.dart';
import '../../shared/kiosk/kiosk_guide.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/porcelain_entrance.dart';
import '../../shared/widgets/porcelain_sheet.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/tone.dart';
import 'event_copy.dart';
import 'event_editor_screen.dart';

/// Everything the launch checklist needs except the window's shape.
final class PreflightInputs {
  const PreflightInputs({
    required this.event,
    required this.library,
    required this.camera,
    required this.storageWrite,
    required this.freeSpace,
    required this.renderer,
    required this.templateAssets,
    required this.kioskLock,
    required this.pinAvailable,
  });

  final BoothEvent event;
  final Map<String, TemplateRevisionSummary> library;
  final CapabilityStatus camera;
  final CapabilityStatus storageWrite;
  final CapabilityStatus freeSpace;
  final CapabilityStatus renderer;
  final CapabilityStatus templateAssets;
  final CapabilityStatus kioskLock;
  final bool pinAvailable;

  PreflightReport evaluate(ViewportOrientation viewport) => Preflight.evaluate(
    event: event,
    library: library,
    device: DeviceFacts(
      camera: camera,
      storageWrite: storageWrite,
      freeSpace: freeSpace,
      renderer: renderer,
      templateAssets: templateAssets,
      kioskLock: kioskLock,
      viewport: viewport,
      operatorPinAvailable: pinAvailable,
    ),
  );
}

/// Runs the device checks for an event; null when the event is gone.
final preflightInputsProvider = FutureProvider.autoDispose
    .family<PreflightInputs?, String>((ref, eventId) async {
      final event = await ref.watch(eventRepositoryProvider).findById(eventId);
      if (event == null) return null;
      final library = await ref
          .watch(templateCatalogProvider)
          .findRevisions(event.templates.revisionIds);
      final templates = library.values.toList();
      final probe = ref.watch(boothCapabilityProbeProvider);
      final pin = await ref.watch(operatorAuthServiceProvider).pinStatus();
      return PreflightInputs(
        event: event,
        library: library,
        camera: await probe.camera(event.capture),
        storageWrite: await probe.storageWrite(),
        freeSpace: await probe.freeSpace(),
        renderer: await probe.renderer(event.output, templates),
        templateAssets: await probe.templateAssets(templates),
        kioskLock: await probe.kioskLock(),
        pinAvailable: pin.available,
      );
    });

/// The launch checklist (S05, S19): every check with its status and
/// explanation, blockers apart from warnings, a way to the fix, and Start
/// Booth only when nothing blocks. Checks this build cannot make yet say so
/// and block; nothing unchecked is shown as passed.
class PreflightScreen extends ConsumerStatefulWidget {
  const PreflightScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<PreflightScreen> createState() => _PreflightScreenState();
}

class _PreflightScreenState extends ConsumerState<PreflightScreen> {
  var _starting = false;

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.events);
    }
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      await ref
          .read(accessControllerProvider.notifier)
          .startBooth(widget.eventId);
    } on Exception {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final inputs = ref.watch(preflightInputsProvider(widget.eventId));
    final size = MediaQuery.sizeOf(context);
    final viewport = ViewportOrientation.fromLogicalSize(
      width: size.width,
      height: size.height,
    );

    return Scaffold(
      body: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.rail,
              border: Border(bottom: BorderSide(color: colors.divider)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PorcelainSpace.lg,
                  vertical: PorcelainSpace.sm,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // On a narrow window both buttons are their icons
                    // alone, so the heading keeps the room.
                    final narrow = constraints.maxWidth < 560;
                    void again() =>
                        ref.invalidate(preflightInputsProvider(widget.eventId));
                    return Row(
                      children: [
                        if (narrow)
                          PorcelainIconButton(
                            icon: PorcelainIcons.back,
                            semanticLabel: 'Back',
                            onPressed: _back,
                          )
                        else
                          PorcelainButton(
                            label: 'Back',
                            icon: PorcelainIcons.back,
                            variant: PorcelainButtonVariant.quiet,
                            size: PorcelainButtonSize.compact,
                            onPressed: _back,
                          ),
                        const SizedBox(width: PorcelainSpace.md),
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              'Launch checks',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.text.titleLarge,
                            ),
                          ),
                        ),
                        if (narrow)
                          PorcelainIconButton(
                            icon: PorcelainIcons.retry,
                            semanticLabel: 'Check again',
                            onPressed: inputs.isLoading ? null : again,
                            disabledReason: 'The checks are running.',
                          )
                        else
                          PorcelainButton(
                            label: 'Check again',
                            icon: PorcelainIcons.retry,
                            size: PorcelainButtonSize.compact,
                            busy: inputs.isLoading,
                            busyLabel: 'Checking…',
                            onPressed: again,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: switch (inputs) {
              AsyncData(value: final inputs?) => _Report(
                inputs: inputs,
                report: inputs.evaluate(viewport),
                viewport: viewport,
                starting: _starting,
                onStart: _start,
              ),
              AsyncData() => EmptyState(
                icon: PorcelainIcons.events,
                title: 'This event no longer exists',
                message: 'Return to Events and choose another.',
                actions: [
                  PorcelainButton(
                    label: 'Back to Events',
                    icon: PorcelainIcons.back,
                    onPressed: () => context.go(RoutePaths.events),
                  ),
                ],
              ),
              AsyncError() => EmptyState(
                icon: PorcelainIcons.error,
                title: "The checks couldn't run",
                message: 'Something stopped them. Try again.',
                tone: PorcelainTone.danger,
                actions: [
                  PorcelainButton(
                    label: 'Try again',
                    icon: PorcelainIcons.retry,
                    onPressed: () =>
                        ref.invalidate(preflightInputsProvider(widget.eventId)),
                  ),
                ],
              ),
              _ => const Padding(
                padding: EdgeInsets.all(PorcelainSpace.xxl),
                child: SkeletonList(semanticLabel: 'Running launch checks'),
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _Report extends StatelessWidget {
  const _Report({
    required this.inputs,
    required this.report,
    required this.viewport,
    required this.starting,
    required this.onStart,
  });

  final PreflightInputs inputs;
  final PreflightReport report;
  final ViewportOrientation viewport;
  final bool starting;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final event = inputs.event;
    final blockers = report.blockerCount;
    final ready = report.canLaunch;

    return LayoutBuilder(
      builder: (context, constraints) {
        final margin = constraints.maxWidth >= 900
            ? PorcelainSpace.xxxl
            : PorcelainSpace.xl;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(margin, margin, margin, margin * 2),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: PorcelainEntrance(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EntranceItem(
                      index: 0,
                      child: PorcelainCard(
                        radius: PorcelainRadius.dialog,
                        padding: const EdgeInsets.all(PorcelainSpace.xxl),
                        child: _SealBeside(
                          seal: _Seal(ready: ready),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title.toUpperCase(),
                                style: theme.text.eyebrow,
                              ),
                              const SizedBox(height: PorcelainSpace.xs),
                              Semantics(
                                header: true,
                                liveRegion: true,
                                child: Text(
                                  ready
                                      ? 'Ready to start'
                                      : blockers == 1
                                      ? 'Not ready: 1 check blocks the launch'
                                      : 'Not ready: $blockers checks block the '
                                            'launch',
                                  style: theme.text.headlineLarge,
                                ),
                              ),
                              const SizedBox(height: PorcelainSpace.xs),
                              Text(
                                ready
                                    ? 'Booth Mode locks the tablet to the guest '
                                          'screens until an operator exits with the '
                                          'PIN.'
                                    : 'Fix the blocked checks below. Checks marked '
                                          '“Not yet available” arrive in later '
                                          'milestones; until then the booth cannot '
                                          'start.',
                                style: theme.text.bodyLarge.copyWith(
                                  color: colors.inkMuted,
                                ),
                              ),
                              const SizedBox(height: PorcelainSpace.md),
                              _Tally(report: report),
                              const SizedBox(height: PorcelainSpace.xl),
                              PorcelainButton(
                                label: 'Start Booth Mode',
                                icon: PorcelainIcons.start,
                                variant: PorcelainButtonVariant.primary,
                                size: PorcelainButtonSize.large,
                                busy: starting,
                                busyLabel: 'Starting…',
                                onPressed: ready ? onStart : null,
                                disabledReason: blockers == 1
                                    ? 'One check blocks the launch.'
                                    : '$blockers checks block the launch.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    for (final (g, group) in PreflightGroup.values.indexed) ...[
                      const SizedBox(height: PorcelainSpace.xxl),
                      EntranceItem(
                        index: g + 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              EventCopy.group(group),
                              style: theme.text.headlineSmall,
                            ),
                            const SizedBox(height: PorcelainSpace.md),
                            PorcelainCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: PorcelainSpace.lg,
                                vertical: PorcelainSpace.sm,
                              ),
                              child: Column(
                                children: [
                                  for (final (i, check)
                                      in report.checks
                                          .where(
                                            (check) => check.id.group == group,
                                          )
                                          .indexed) ...[
                                    if (i > 0) Divider(color: colors.divider),
                                    _CheckRow(
                                      check: check,
                                      event: event,
                                      viewport: viewport,
                                      library: inputs.library,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The seal beside the report's heading, or above it on a narrow card.
class _SealBeside extends StatelessWidget {
  const _SealBeside({required this.seal, required this.child});

  final Widget seal;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              seal,
              const SizedBox(height: PorcelainSpace.lg),
              child,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: child),
            const SizedBox(width: PorcelainSpace.xl),
            seal,
          ],
        );
      },
    );
  }
}

/// A porcelain seal: gilded, with a check mark, when nothing blocks the
/// launch; otherwise a plain ring with a lock. The heading says the same
/// in words.
class _Seal extends StatelessWidget {
  const _Seal({required this.ready});

  final bool ready;

  static const size = 104.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    final motion = PorcelainMotion.of(context);
    return ExcludeSemantics(
      child: AnimatedSwitcher(
        duration: motion.emphasized,
        switchInCurve: PorcelainMotion.enter,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.85, end: 1.0).animate(animation),
            child: child,
          ),
        ),
        child: Container(
          key: ValueKey(ready),
          width: size,
          height: size,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: ready
                ? SweepGradient(
                    colors: [
                      colors.primaryTop,
                      colors.primaryEdge,
                      colors.primaryBottom,
                      colors.primaryEdge,
                      colors.primaryTop,
                    ],
                  )
                : null,
            color: ready ? null : colors.inset,
            border: ready ? null : Border.all(color: colors.outline),
            boxShadow: [
              BoxShadow(
                color: colors.shadowKey,
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [colors.raised, colors.surface]),
              border: Border.all(
                color: ready ? colors.primaryEdge : colors.hairline,
              ),
            ),
            child: Icon(
              ready ? PorcelainIcons.ready : PorcelainIcons.locked,
              size: 44,
              fill: ready ? 1 : 0,
              color: ready ? colors.accentIcon : colors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// How the checks came out, as counts: passed, to note, blocking.
class _Tally extends StatelessWidget {
  const _Tally({required this.report});

  final PreflightReport report;

  @override
  Widget build(BuildContext context) {
    int count(bool Function(PreflightStatus status) test) =>
        report.checks.where((check) => test(check.status)).length;
    final passed = count(
      (s) => s == PreflightStatus.pass || s == PreflightStatus.info,
    );
    final warnings = report.warningCount;
    final blockers = report.blockerCount;
    return Wrap(
      spacing: PorcelainSpace.xs,
      runSpacing: PorcelainSpace.xs,
      children: [
        StatusBadge(
          label: '$passed passed',
          tone: PorcelainTone.success,
          icon: EventCopy.checkStatusIcon(PreflightStatus.pass),
        ),
        if (warnings > 0)
          StatusBadge(
            label: warnings == 1 ? '1 warning' : '$warnings warnings',
            tone: PorcelainTone.warning,
            icon: EventCopy.checkStatusIcon(PreflightStatus.warning),
          ),
        if (blockers > 0)
          StatusBadge(
            label: '$blockers blocking',
            tone: PorcelainTone.danger,
            icon: EventCopy.checkStatusIcon(PreflightStatus.blocked),
          ),
      ],
    );
  }
}

class _CheckRow extends ConsumerWidget {
  const _CheckRow({
    required this.check,
    required this.event,
    required this.viewport,
    required this.library,
  });

  final PreflightCheck check;
  final BoothEvent event;
  final ViewportOrientation viewport;
  final Map<String, TemplateRevisionSummary> library;

  /// Where to fix a check, when the app can help.
  (String, String)? get _repair => switch ((check.id, check.status)) {
    (_, PreflightStatus.pass) ||
    (_, PreflightStatus.info) ||
    (_, PreflightStatus.notYetAvailable) => null,
    (PreflightCheckId.eventStatus, _) => (
      'Open event',
      RoutePaths.event(event.id),
    ),
    (PreflightCheckId.eventSettings, _) => (
      'Edit settings',
      RoutePaths.event(event.id, tab: EventEditorTab.capture.name),
    ),
    (PreflightCheckId.templates, _) => (
      'Edit templates',
      RoutePaths.event(event.id, tab: EventEditorTab.templates.name),
    ),
    (PreflightCheckId.orientation, _) => (
      'Change orientation',
      RoutePaths.event(event.id, tab: EventEditorTab.capture.name),
    ),
    _ => null,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final tone = EventCopy.checkTone(check.status);
    final details = EventCopy.checkDetail(
      check,
      event,
      viewport: viewport,
      platform: ref.watch(appEnvironmentProvider).platform,
      templateName: (id) => library[id]?.templateName ?? 'A template',
    );
    final repair = _repair;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PorcelainSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              EventCopy.checkIcon(check.id),
              color: colors.accentIcon,
            ),
          ),
          const SizedBox(width: PorcelainSpace.md),
          Expanded(
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: PorcelainSpace.sm,
                    runSpacing: PorcelainSpace.xxs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        EventCopy.checkTitle(check.id),
                        style: theme.text.titleSmall,
                      ),
                      StatusBadge(
                        label: EventCopy.checkStatus(check.status),
                        tone: tone,
                        icon: EventCopy.checkStatusIcon(check.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: PorcelainSpace.xxs),
                  for (final line in details)
                    Text(
                      line,
                      style: theme.text.bodyMedium.copyWith(
                        color: colors.inkMuted,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (repair != null) ...[
            const SizedBox(width: PorcelainSpace.sm),
            PorcelainButton(
              label: repair.$1,
              size: PorcelainButtonSize.compact,
              onPressed: () => unawaited(context.push(repair.$2)),
            ),
          ] else if (check.id == PreflightCheckId.kioskLock &&
              check.status == PreflightStatus.warning) ...[
            // Only the tablet can lock itself: the guide says how.
            const SizedBox(width: PorcelainSpace.sm),
            PorcelainButton(
              label: 'How to lock',
              size: PorcelainButtonSize.compact,
              onPressed: () => unawaited(
                showPorcelainSheet<void>(
                  context: context,
                  title: 'Kiosk lock',
                  body: const KioskGuide(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
