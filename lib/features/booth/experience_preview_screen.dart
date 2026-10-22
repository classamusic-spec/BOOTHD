import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/booth/booth_providers.dart';
import '../../core/design_system/porcelain_depth.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/di/service_providers.dart';
import '../../core/experience/guest_theme.dart';
import '../../core/experience/preview_services.dart';
import '../../core/routing/route_paths.dart';
import '../../domain/experience/experience_registry.dart';
import '../../domain/models/booth_event.dart';
import '../../domain/value_objects/orientation.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_segmented_control.dart';
import '../../shared/widgets/pressable.dart';
import 'booth_screen.dart';

/// Full Experience Preview (EP08): the event's whole guest journey on the
/// real guest screens (welcome, template choice, the camera with the
/// template, the countdown, the photo, review, texting and the finished
/// photo) with a sample camera and sample photos, in portrait or
/// landscape, in any pack.
///
/// Everything runs on stand-ins kept in memory (`preview_services.dart`):
/// no session, photo or finished photo reaches the booth's database or
/// files, the real camera is never opened, and Send on the texting screen
/// submits nothing. The ribbon says so on every screen. Changing the pack
/// here changes only the preview; the event keeps its own choice.
class ExperiencePreviewScreen extends StatefulWidget {
  const ExperiencePreviewScreen({super.key, required this.event});

  /// The event as the operator is editing it; null when the page was
  /// reached without one (a restored location).
  final BoothEvent? event;

  @override
  State<ExperiencePreviewScreen> createState() =>
      _ExperiencePreviewScreenState();
}

class _ExperiencePreviewScreenState extends State<ExperiencePreviewScreen> {
  var _run = 0;
  late var _landscape =
      widget.event?.capture.orientation == GuestOrientationPreference.landscape;
  late var _packId = widget.event?.experience.packId;

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.events);
    }
  }

  void _restart() => setState(() => _run++);

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final source = widget.event;
    if (source == null) {
      return Scaffold(
        backgroundColor: colors.canvas,
        body: Center(
          child: EmptyState(
            icon: PorcelainIcons.preview,
            title: 'Nothing to preview',
            message: 'Open the preview from an event.',
            actions: [
              PorcelainButton(
                label: 'Back to events',
                icon: PorcelainIcons.back,
                onPressed: _close,
              ),
            ],
          ),
        ),
      );
    }
    final packId = _packId ?? source.experience.packId;
    final experience = packId == source.experience.packId
        ? source.experience
        : source.experience.switchPack(
            packId,
            ExperienceRegistry.bundled.pack(packId)!.packVersion,
          );
    final event = source.copyWith(
      experience: experience,
      capture: source.capture.copyWith(
        orientation: _landscape
            ? GuestOrientationPreference.landscape
            : GuestOrientationPreference.portrait,
      ),
    );
    final resolved = ExperienceRegistry.bundled.resolve(experience);
    final logical = _landscape ? const Size(1180, 820) : const Size(820, 1180);

    return Scaffold(
      backgroundColor: colors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Toolbar(
              landscape: _landscape,
              packId: packId,
              onLandscape: (value) => setState(() {
                _landscape = value;
                _run++;
              }),
              onPack: (id) => setState(() {
                _packId = id;
                _run++;
              }),
              onRestart: _restart,
              onClose: _close,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(PorcelainSpace.lg),
                child: Center(
                  child: _Device(
                    logicalSize: logical,
                    child: _PreviewRun(
                      key: ValueKey('$_run'),
                      event: event,
                      experience: resolved,
                      onEnd: _restart,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One run of the journey, on its own stand-in services: a restart, a
/// new pack or a turn starts a new, empty run.
class _PreviewRun extends ConsumerStatefulWidget {
  const _PreviewRun({
    super.key,
    required this.event,
    required this.experience,
    required this.onEnd,
  });

  final BoothEvent event;
  final ResolvedExperience experience;
  final VoidCallback onEnd;

  @override
  ConsumerState<_PreviewRun> createState() => _PreviewRunState();
}

class _PreviewRunState extends ConsumerState<_PreviewRun> {
  late final _stills = PreviewStillStore();
  late final _camera = PreviewCameraService(_stills);
  late final _sessions = MemorySessionRepository();
  late final _export = PreviewExportService(
    ref.read(compositionRendererProvider),
  );

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      cameraServiceProvider.overrideWithValue(_camera),
      capturedStillStoreProvider.overrideWithValue(_stills),
      cameraPreviewBuilderProvider.overrideWithValue(previewCameraPicture),
      sessionRepositoryProvider.overrideWithValue(_sessions),
      exportServiceProvider.overrideWithValue(_export),
      finishedPhotosProvider.overrideWithValue(_export),
      lastGuestProblemProvider.overrideWith(LastGuestProblem.new),
    ],
    child: GuestExperienceScope(
      experience: widget.experience,
      child: BoothSessionView(
        event: widget.event,
        onOperator: widget.onEnd,
        preview: true,
      ),
    ),
  );
}

/// The preview's controls and its ribbon: what this is, the pack, the
/// orientation, Restart and Close.
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.landscape,
    required this.packId,
    required this.onLandscape,
    required this.onPack,
    required this.onRestart,
    required this.onClose,
  });

  final bool landscape;
  final String packId;
  final ValueChanged<bool> onLandscape;
  final ValueChanged<String> onPack;
  final VoidCallback onRestart;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.hairline)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PorcelainSpace.lg,
          vertical: PorcelainSpace.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: PorcelainSpace.md,
              runSpacing: PorcelainSpace.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PorcelainButton(
                  label: 'Close preview',
                  icon: PorcelainIcons.close,
                  variant: PorcelainButtonVariant.secondary,
                  size: PorcelainButtonSize.compact,
                  onPressed: onClose,
                ),
                Semantics(
                  container: true,
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: PorcelainSpace.md,
                      vertical: PorcelainSpace.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.inset,
                      borderRadius: PorcelainRadius.controlAll,
                      border: Border.all(color: colors.accentIcon),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PorcelainIcons.preview,
                          size: 20,
                          color: colors.accentText,
                        ),
                        const SizedBox(width: PorcelainSpace.xs),
                        Flexible(
                          child: Text(
                            'Preview · sample camera · nothing is saved or '
                            'sent',
                            style: theme.text.labelLarge.copyWith(
                              color: colors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PorcelainSegmentedControl<bool>(
                  selected: landscape,
                  onChanged: onLandscape,
                  segments: const [
                    PorcelainSegment(
                      value: false,
                      label: 'Portrait',
                      icon: PorcelainIcons.portrait,
                    ),
                    PorcelainSegment(
                      value: true,
                      label: 'Landscape',
                      icon: PorcelainIcons.landscape,
                    ),
                  ],
                ),
                PorcelainButton(
                  label: 'Restart',
                  icon: PorcelainIcons.restartPreview,
                  variant: PorcelainButtonVariant.secondary,
                  size: PorcelainButtonSize.compact,
                  onPressed: onRestart,
                ),
              ],
            ),
            const SizedBox(height: PorcelainSpace.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text('Experience', style: theme.text.titleSmall),
                  const SizedBox(width: PorcelainSpace.md),
                  for (final pack in ExperienceRegistry.bundled.packs) ...[
                    _PackChip(
                      label: pack.displayName,
                      selected: pack.packId == packId,
                      onPressed: () => onPack(pack.packId),
                    ),
                    const SizedBox(width: PorcelainSpace.xs),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackChip extends StatelessWidget {
  const _PackChip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: label,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      builder: (context, state) => Container(
        constraints: const BoxConstraints(
          minHeight: PorcelainSize.minTouchTarget,
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: PorcelainSpace.md),
        decoration: BoxDecoration(
          color: selected ? colors.raised : colors.inset,
          borderRadius: PorcelainRadius.controlAll,
          border: Border.all(
            color: selected
                ? colors.accentIcon
                : state.focused
                ? colors.focusRing
                : colors.hairline,
            width: selected || state.focused ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: theme.text.labelLarge.copyWith(
            color: colors.ink,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// A tablet in miniature that guests' screens run in, laid out at the
/// tablet's real size and scaled to fit; it takes taps like the booth.
class _Device extends StatelessWidget {
  const _Device({required this.logicalSize, required this.child});

  final Size logicalSize;
  final Widget child;

  static const _bezel = 10.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    final media = MediaQuery.of(context);
    return AspectRatio(
      aspectRatio:
          (logicalSize.width + 2 * _bezel) / (logicalSize.height + 2 * _bezel),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.isDark ? colors.raised : colors.ink,
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          boxShadow: PorcelainDepth.shadows(colors, 1.4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(_bezel),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            child: FittedBox(
              child: SizedBox.fromSize(
                size: logicalSize,
                child: MediaQuery(
                  data: media.copyWith(
                    size: logicalSize,
                    padding: EdgeInsets.zero,
                    viewPadding: EdgeInsets.zero,
                    viewInsets: EdgeInsets.zero,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
