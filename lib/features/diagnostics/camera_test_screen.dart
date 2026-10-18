import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/booth/booth_providers.dart';
import '../../core/camera/camera_session.dart';
import '../../core/design_system/porcelain_colors.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/di/service_providers.dart';
import '../../core/platform/app_environment.dart';
import '../../core/routing/route_paths.dart';
import '../../domain/models/booth_profile.dart';
import '../../domain/services/camera_service.dart';
import '../../shared/formatters/date_format.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/porcelain_list_row.dart';
import '../../shared/widgets/porcelain_segmented_control.dart';
import '../../shared/widgets/porcelain_spinner.dart';
import '../../shared/widgets/porcelain_switch.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/tone.dart';
import 'camera_copy.dart';

/// The camera test (S18, AC-0601..AC-0608): permission with its repair,
/// the tablet's cameras, the live preview at its own shape, preview and
/// saved-photo mirroring, and a test photo saved like a guest's: read back
/// from the booth's storage, checked and described. Earlier test photos
/// prove that saved photos survive a restart. Operator only.
class CameraTestScreen extends ConsumerStatefulWidget {
  const CameraTestScreen({super.key});

  @override
  ConsumerState<CameraTestScreen> createState() => _CameraTestScreenState();
}

class _CameraTestScreenState extends ConsumerState<CameraTestScreen> {
  late final CameraSessionController _session;
  late final CapturedStillStore _store;
  late final ProviderSubscription<AsyncValue<BoothProfile>> _profile;
  final _defaults = Completer<EventDefaults>();

  List<CameraDescriptor>? _cameras;
  CameraLens? _lens;
  var _mirrorPreview = true;
  var _mirrorOutput = false;
  var _defaultsRead = false;

  CapturedStill? _latest;
  Future<Uint8List>? _latestBytes;
  final _savedKey = GlobalKey();
  CameraFailure? _captureFailure;
  Future<List<CapturedStill>>? _earlier;

  @override
  void initState() {
    super.initState();
    _session = CameraSessionController(ref.read(cameraServiceProvider))
      ..addListener(_changed);
    _store = ref.read(capturedStillStoreProvider);
    _earlier = _loadEarlier();
    // Listened to, not read once: an unlistened provider is paused.
    _profile = ref.listenManual(boothProfileProvider, (_, next) {
      if (_defaults.isCompleted) return;
      switch (next) {
        case AsyncData(:final value):
          _defaults.complete(value.defaults);
        case AsyncError():
          // The test still works from the standard defaults.
          _defaults.complete(const EventDefaults());
        case _:
          break;
      }
    }, fireImmediately: true);
    unawaited(_open());
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _profile.close();
    _session
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  Future<List<CapturedStill>> _loadEarlier() async => [
    for (final still in await _store.listCommitted(limit: 12))
      if (still.origin == CaptureOrigin.diagnostics) still,
  ].take(6).toList();

  /// Reads the booth's defaults once, lists the cameras and opens the
  /// chosen one (which waits for "Allow camera" if access was never
  /// asked for).
  Future<void> _open() async {
    final defaults = await _defaults.future;
    if (!mounted) return;
    setState(() {
      _lens ??= defaults.lens;
      _mirrorPreview = defaults.mirrorPreview;
      _mirrorOutput = defaults.mirrorOutput;
      _defaultsRead = true;
    });
    await _listCameras();
    await _openCamera();
  }

  Future<void> _listCameras() async {
    List<CameraDescriptor> cameras;
    try {
      cameras = await ref.read(cameraServiceProvider).availableCameras();
    } on CameraFailure {
      cameras = const [];
    }
    if (mounted) setState(() => _cameras = cameras);
  }

  CameraRequest? get _request {
    final lens = _lens;
    final camera = lens == null
        ? null
        : CameraChoice.of(_cameras ?? const [], lens).camera;
    return camera == null
        ? null
        : CameraRequest(
            cameraId: camera.id,
            mirrorPreview: _mirrorPreview,
            mirrorOutput: _mirrorOutput,
          );
  }

  Future<void> _openCamera() async {
    final request = _request;
    if (request != null && mounted) await _session.open(request);
  }

  Future<void> _allow() async {
    final permission = await _session.allow();
    // Some tablets list their cameras only once access is allowed.
    if (permission == CameraPermission.granted &&
        mounted &&
        (_cameras?.isEmpty ?? true)) {
      await _listCameras();
      await _openCamera();
    }
  }

  Future<void> _capture() async {
    setState(() => _captureFailure = null);
    final outcome = await _session.capture(origin: CaptureOrigin.diagnostics);
    if (!mounted) return;
    switch (outcome) {
      case CaptureSaved(:final still):
        setState(() {
          _latest = still;
          _latestBytes = _store.read(still);
          _earlier = _loadEarlier();
        });
        // Bring the result into view: it is the answer to the press.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final saved = _savedKey.currentContext;
          if (saved == null || !saved.mounted) return;
          unawaited(
            Scrollable.ensureVisible(
              saved,
              alignment: 0.1,
              duration: PorcelainMotion.of(saved).emphasized,
              curve: Curves.easeOutCubic,
            ),
          );
        });
      case CaptureFailed(:final failure):
        setState(() => _captureFailure = failure);
      case CaptureIgnored():
        break;
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.diagnostics);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final status = _session.status;
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
                child: Row(
                  children: [
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
                          'Camera test',
                          style: theme.text.titleLarge,
                        ),
                      ),
                    ),
                    StatusBadge(
                      label: _session.permissionKnown
                          ? CameraCopy.permission(status.permission)
                          : 'Checking access',
                      tone: !_session.permissionKnown
                          ? PorcelainTone.neutral
                          : status.permission == CameraPermission.granted
                          ? PorcelainTone.success
                          : PorcelainTone.warning,
                      icon: PorcelainIcons.camera,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1000;
                final margin = constraints.maxWidth >= 900
                    ? PorcelainSpace.xxxl
                    : PorcelainSpace.xl;
                final viewer = _Viewer(
                  status: status,
                  permissionKnown: _session.permissionKnown,
                  lens: _lens,
                  mirror: _mirrorPreview,
                  onRetry: _openCamera,
                  // Side by side the viewer may use the height; stacked, it
                  // leaves room to reach the controls without scrolling.
                  maxHeight: wide
                      ? constraints.maxHeight - 2 * margin - 96
                      : constraints.maxHeight * 0.46,
                );
                final permission = _permissionCard(status);
                final controls = _controls(status);
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(margin, margin, margin, margin),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: viewer),
                                const SizedBox(width: PorcelainSpace.xxl),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (permission != null) ...[
                                        permission,
                                        const SizedBox(
                                          height: PorcelainSpace.xl,
                                        ),
                                      ],
                                      controls,
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // The repair comes first: without it there
                                // is nothing to test.
                                if (permission != null) ...[
                                  permission,
                                  const SizedBox(height: PorcelainSpace.xl),
                                ],
                                viewer,
                                const SizedBox(height: PorcelainSpace.xxl),
                                controls,
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// How to allow the camera, when it is not allowed.
  Widget? _permissionCard(CameraStatus status) {
    final permission = status.permission;
    if (!_session.permissionKnown || permission == CameraPermission.granted) {
      return null;
    }
    return _PermissionCard(
      permission: permission,
      platform: ref.watch(appEnvironmentProvider).platform,
      onAllow: permission.canAsk ? _allow : null,
      onOpenSettings:
          permission == CameraPermission.denied ||
              permission == CameraPermission.permanentlyDenied
          ? _session.openSettings
          : null,
    );
  }

  Widget _controls(CameraStatus status) {
    final theme = context.porcelain;
    final permission = status.permission;
    final cameras = _cameras;
    final builtIn = [
      for (final lens in [CameraLens.front, CameraLens.back])
        if (cameras?.any((c) => c.lens == lens) ?? false) lens,
    ];
    final ready = status.isReady;
    final failure = _captureFailure;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PorcelainCard(
          padding: const EdgeInsets.all(PorcelainSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Camera', style: theme.text.titleSmall),
              const SizedBox(height: PorcelainSpace.xs),
              if (cameras == null)
                Text(
                  'Looking for cameras…',
                  style: theme.text.bodyMedium.copyWith(
                    color: theme.colors.inkMuted,
                  ),
                )
              else if (builtIn.isEmpty)
                Text(
                  'This tablet reports no built-in camera.',
                  style: theme.text.bodyMedium,
                )
              else if (builtIn.length == 1)
                Text(
                  'This tablet has only a '
                  '${CameraCopy.lens(builtIn.single).toLowerCase()}.',
                  style: theme.text.bodyMedium,
                )
              else
                PorcelainSegmentedControl<CameraLens>(
                  selected: builtIn.contains(_lens) ? _lens! : builtIn.first,
                  onChanged: (lens) {
                    setState(() => _lens = lens);
                    unawaited(_openCamera());
                  },
                  segments: [
                    for (final lens in builtIn)
                      PorcelainSegment(
                        value: lens,
                        label: CameraCopy.lens(lens),
                        icon: PorcelainIcons.camera,
                      ),
                  ],
                ),
              const SizedBox(height: PorcelainSpace.lg),
              PorcelainSwitchRow(
                title: 'Mirror the live preview',
                subtitle: 'Guests see themselves as in a mirror.',
                icon: PorcelainIcons.preview,
                value: _mirrorPreview,
                onChanged: _defaultsRead
                    ? (on) {
                        setState(() => _mirrorPreview = on);
                        if (ready) unawaited(_openCamera());
                      }
                    : null,
                disabledReason: 'Reading the booth settings…',
              ),
              PorcelainSwitchRow(
                title: 'Mirror saved photos',
                subtitle: 'Usually off, so text in photos reads correctly.',
                icon: PorcelainIcons.gallery,
                value: _mirrorOutput,
                onChanged: _defaultsRead
                    ? (on) {
                        setState(() => _mirrorOutput = on);
                        if (ready) unawaited(_openCamera());
                      }
                    : null,
                disabledReason: 'Reading the booth settings…',
              ),
              const SizedBox(height: PorcelainSpace.xs),
              Text(
                'These change this test only. New events start from '
                'Settings > Camera.',
                style: theme.text.bodySmall.copyWith(
                  color: theme.colors.inkMuted,
                ),
              ),
              const SizedBox(height: PorcelainSpace.xl),
              PorcelainButton(
                label: 'Take test photo',
                icon: PorcelainIcons.camera,
                variant: PorcelainButtonVariant.primary,
                size: PorcelainButtonSize.large,
                busy: _session.capturing,
                busyLabel: 'Saving…',
                onPressed: ready ? _capture : null,
                disabledReason: switch (status.lifecycle) {
                  _ when !_session.permissionKnown => 'Checking camera access.',
                  _ when permission != CameraPermission.granted =>
                    'Allow the camera first.',
                  CameraLifecycle.initializing => 'The camera is starting.',
                  CameraLifecycle.failed => 'The camera is not working.',
                  _ => 'The camera is not open.',
                },
              ),
              if (failure != null) ...[
                const SizedBox(height: PorcelainSpace.md),
                _Problem(failure: failure),
              ],
            ],
          ),
        ),
        if (_latest case final latest?) ...[
          const SizedBox(height: PorcelainSpace.xl),
          _SavedPhoto(key: _savedKey, still: latest, bytes: _latestBytes!),
        ],
        const SizedBox(height: PorcelainSpace.xl),
        _Earlier(stills: _earlier, store: _store),
      ],
    );
  }
}

/// The live picture in a dark viewfinder, at the stream's own shape.
class _Viewer extends ConsumerWidget {
  const _Viewer({
    required this.status,
    required this.permissionKnown,
    required this.lens,
    required this.mirror,
    required this.onRetry,
    required this.maxHeight,
  });

  final CameraStatus status;
  final bool permissionKnown;
  final CameraLens? lens;
  final bool mirror;
  final VoidCallback onRetry;

  /// The tallest the viewfinder may be; it narrows to keep its shape.
  final double maxHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final capabilities = status.capabilities;
    final failure = status.failure;
    final ratio = capabilities?.previewAspectRatio ?? 4 / 3;
    final screen = MediaQuery.sizeOf(context);
    // The viewfinder takes the stream's shape the right way round for the
    // screen; the preview inside keeps its own ratio, never stretched.
    final shape = screen.height > screen.width ? 1 / ratio : ratio;
    final allowed = status.permission == CameraPermission.granted;
    final live =
        status.lifecycle == CameraLifecycle.ready ||
        status.lifecycle == CameraLifecycle.capturing;

    final Widget content = switch (status.lifecycle) {
      _ when live => ref.watch(cameraPreviewBuilderProvider)(
        context,
        mirror: mirror,
      ),
      CameraLifecycle.initializing => const _ViewerMessage(
        icon: PorcelainIcons.camera,
        title: 'Opening the camera…',
        busy: true,
      ),
      _ when !permissionKnown => const _ViewerMessage(
        icon: PorcelainIcons.camera,
        title: 'Checking camera access…',
        busy: true,
      ),
      _ when !allowed => _ViewerMessage(
        icon: PorcelainIcons.privacy,
        title: switch (status.permission) {
          CameraPermission.notDetermined => 'No camera access yet',
          CameraPermission.restricted => 'The camera is blocked',
          _ => 'Camera access is off',
        },
        detail: 'Its picture appears here once the camera is allowed.',
      ),
      CameraLifecycle.failed when failure != null => _ViewerMessage(
        icon: PorcelainIcons.warning,
        title: CameraCopy.failure(failure).$1,
        detail:
            '${CameraCopy.failure(failure).$2} '
            '(${failure.code.diagnostic})',
        action: PorcelainButton(
          label: 'Try again',
          icon: PorcelainIcons.retry,
          onPressed: onRetry,
        ),
      ),
      CameraLifecycle.suspended => const _ViewerMessage(
        icon: PorcelainIcons.pending,
        title: 'Paused while the booth was in the background',
        detail: 'It opens again when the booth is in front.',
      ),
      _ => const _ViewerMessage(
        icon: PorcelainIcons.camera,
        title: 'The camera is closed',
      ),
    };

    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: math.min(
            constraints.maxWidth,
            math.max(maxHeight, 240) * shape,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                label: lens == null
                    ? 'Camera preview'
                    : '${CameraCopy.lens(lens!)} preview',
                child: ClipRRect(
                  borderRadius: PorcelainRadius.cardAll,
                  child: ColoredBox(
                    color: PorcelainViewfinder.background,
                    child: AspectRatio(
                      aspectRatio: shape,
                      child: Center(
                        child: live
                            ? content
                            // Large text may need more room than the
                            // viewfinder has.
                            : SingleChildScrollView(child: content),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: PorcelainSpace.sm),
              Wrap(
                spacing: PorcelainSpace.xs,
                runSpacing: PorcelainSpace.xs,
                children: [
                  StatusBadge(
                    label: switch (status.lifecycle) {
                      _ when permissionKnown && !allowed => 'No access',
                      CameraLifecycle.ready => 'Live',
                      CameraLifecycle.capturing => 'Taking a photo',
                      CameraLifecycle.initializing => 'Starting',
                      CameraLifecycle.suspended => 'Paused',
                      CameraLifecycle.failed => 'Not working',
                      _ => 'Closed',
                    },
                    tone: switch (status.lifecycle) {
                      _ when permissionKnown && !allowed =>
                        PorcelainTone.warning,
                      CameraLifecycle.ready ||
                      CameraLifecycle.capturing => PorcelainTone.success,
                      CameraLifecycle.failed => PorcelainTone.danger,
                      _ => PorcelainTone.neutral,
                    },
                  ),
                  if (capabilities != null) ...[
                    StatusBadge(
                      label: mirror ? 'Mirrored preview' : 'True preview',
                      icon: PorcelainIcons.preview,
                    ),
                    StatusBadge(
                      label:
                          'Stream ${capabilities.previewWidthPx} × '
                          '${capabilities.previewHeightPx}',
                      icon: PorcelainIcons.camera,
                    ),
                    StatusBadge(
                      label:
                          'Sensor '
                          '${capabilities.camera.sensorOrientationDegrees}°',
                      icon: PorcelainIcons.orientation,
                    ),
                    if (capabilities.maxZoom > capabilities.minZoom)
                      StatusBadge(
                        label:
                            'Zoom ${capabilities.minZoom.toStringAsFixed(1)}–'
                            '${capabilities.maxZoom.toStringAsFixed(1)}×',
                        icon: PorcelainIcons.zoomIn,
                      ),
                  ],
                ],
              ),
              const SizedBox(height: PorcelainSpace.xs),
              Text(
                'The preview is only for posing: saved photos come from the '
                "camera's full-resolution still, never from the screen.",
                style: theme.text.bodySmall.copyWith(color: colors.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewerMessage extends StatelessWidget {
  const _ViewerMessage({
    required this.icon,
    required this.title,
    this.detail,
    this.action,
    this.busy = false,
  });

  final IconData icon;
  final String title;
  final String? detail;
  final Widget? action;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    const ink = PorcelainViewfinder.ink;
    return Padding(
      padding: const EdgeInsets.all(PorcelainSpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy)
            const PorcelainSpinner(color: ink, size: 40)
          else
            Icon(icon, size: 40, color: ink),
          const SizedBox(height: PorcelainSpace.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.text.titleSmall.copyWith(color: ink),
          ),
          if (detail != null) ...[
            const SizedBox(height: PorcelainSpace.xs),
            Text(
              detail!,
              textAlign: TextAlign.center,
              style: theme.text.bodyMedium.copyWith(color: ink),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: PorcelainSpace.lg),
            action!,
          ],
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.permission,
    required this.platform,
    required this.onAllow,
    required this.onOpenSettings,
  });

  final CameraPermission permission;
  final TargetPlatform platform;
  final VoidCallback? onAllow;
  final Future<bool> Function()? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final (title, detail) = CameraCopy.permissionHelp(permission, platform);
    final openSettings = onOpenSettings;
    return PorcelainCard(
      padding: const EdgeInsets.all(PorcelainSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PorcelainIcons.privacy, color: theme.colors.accentIcon),
              const SizedBox(width: PorcelainSpace.sm),
              Expanded(child: Text(title, style: theme.text.titleSmall)),
            ],
          ),
          const SizedBox(height: PorcelainSpace.sm),
          Text(detail, style: theme.text.bodyMedium),
          if (onAllow != null || openSettings != null) ...[
            const SizedBox(height: PorcelainSpace.lg),
            Wrap(
              spacing: PorcelainSpace.sm,
              runSpacing: PorcelainSpace.sm,
              children: [
                if (onAllow != null)
                  PorcelainButton(
                    label: 'Allow camera',
                    icon: PorcelainIcons.camera,
                    variant: PorcelainButtonVariant.primary,
                    onPressed: onAllow,
                  ),
                if (openSettings != null)
                  PorcelainButton(
                    label: 'Open Settings',
                    icon: PorcelainIcons.settings,
                    onPressed: () => unawaited(openSettings()),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Problem extends StatelessWidget {
  const _Problem({required this.failure});

  final CameraFailure failure;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final (title, detail) = CameraCopy.failure(failure);
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(PorcelainIcons.warning, color: theme.colors.danger),
          const SizedBox(width: PorcelainSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.text.titleSmall),
                Text(
                  '$detail (${failure.code.diagnostic})',
                  style: theme.text.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The photo just taken, read back from storage and described.
class _SavedPhoto extends StatelessWidget {
  const _SavedPhoto({super.key, required this.still, required this.bytes});

  final CapturedStill still;
  final Future<Uint8List> bytes;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    return PorcelainCard(
      padding: const EdgeInsets.all(PorcelainSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Test photo saved', style: theme.text.titleSmall),
              ),
              const StatusBadge(
                label: 'Checked',
                tone: PorcelainTone.success,
                icon: PorcelainIcons.success,
              ),
            ],
          ),
          const SizedBox(height: PorcelainSpace.md),
          FutureBuilder<Uint8List>(
            future: bytes,
            builder: (context, snapshot) => switch (snapshot) {
              AsyncSnapshot(:final data?) => ClipRRect(
                borderRadius: PorcelainRadius.controlAll,
                child: Semantics(
                  label: still.mirrorOutputRequested
                      ? 'The test photo, mirrored as it will print'
                      : 'The test photo as it will print',
                  image: true,
                  child: Transform.flip(
                    flipX: still.mirrorOutputRequested,
                    child: Image.memory(
                      data,
                      height: 220,
                      fit: BoxFit.contain,
                      cacheHeight: 440,
                    ),
                  ),
                ),
              ),
              AsyncSnapshot(hasError: true) => Text(
                "It couldn't be read back.",
                style: theme.text.bodyMedium.copyWith(color: colors.danger),
              ),
              _ => SizedBox(
                height: 220,
                child: Center(
                  child: Semantics(
                    label: 'Reading the photo',
                    child: PorcelainSpinner(color: colors.accentIcon, size: 28),
                  ),
                ),
              ),
            },
          ),
          const SizedBox(height: PorcelainSpace.md),
          _Fact(
            icon: PorcelainIcons.outputFormat,
            label: 'Size',
            value: CameraCopy.size(still.widthPx, still.heightPx),
          ),
          _Fact(
            icon: PorcelainIcons.storage,
            label: 'File',
            value: '${CameraCopy.bytes(still.byteLength)} JPEG',
          ),
          _Fact(
            icon: PorcelainIcons.camera,
            label: 'Camera',
            value:
                '${CameraCopy.lens(still.lens)} · sensor '
                '${still.sensorOrientationDegrees}°',
          ),
          _Fact(
            icon: PorcelainIcons.orientation,
            label: 'Held',
            value:
                '${CameraCopy.orientation(still.deviceOrientation)}'
                '${still.exifOrientation == null ? '' : ' · EXIF ${still.exifOrientation}'}',
          ),
          _Fact(
            icon: PorcelainIcons.gallery,
            label: 'Prints',
            value: still.mirrorOutputRequested ? 'Mirrored' : 'As taken',
          ),
          const SizedBox(height: PorcelainSpace.xs),
          Text(
            "Saved in the booth's private storage, read back, decoded and "
            'checked against its fingerprint.',
            style: theme.text.bodySmall.copyWith(color: colors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return PorcelainListRow(
      icon: icon,
      title: label,
      trailing: Text(
        value,
        textAlign: TextAlign.end,
        style: theme.text.numeric.copyWith(color: theme.colors.inkMuted),
      ),
    );
  }
}

/// Earlier test photos, each read back and checked: they are still here
/// after the app was closed or the tablet restarted (AC-0608).
class _Earlier extends StatelessWidget {
  const _Earlier({required this.stills, required this.store});

  final Future<List<CapturedStill>>? stills;
  final CapturedStillStore store;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return FutureBuilder<List<CapturedStill>>(
      future: stills,
      builder: (context, snapshot) {
        final list = snapshot.data ?? const <CapturedStill>[];
        return PorcelainCard(
          padding: const EdgeInsets.all(PorcelainSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Earlier test photos', style: theme.text.titleSmall),
              const SizedBox(height: PorcelainSpace.xs),
              Text(
                list.isEmpty
                    ? 'None yet. Test photos stay after the app closes, '
                          'like guest photos.'
                    : 'Each is read back and checked now.',
                style: theme.text.bodySmall.copyWith(
                  color: theme.colors.inkMuted,
                ),
              ),
              for (final still in list) _EarlierRow(still: still, store: store),
            ],
          ),
        );
      },
    );
  }
}

class _EarlierRow extends StatefulWidget {
  const _EarlierRow({required this.still, required this.store});

  final CapturedStill still;
  final CapturedStillStore store;

  @override
  State<_EarlierRow> createState() => _EarlierRowState();
}

class _EarlierRowState extends State<_EarlierRow> {
  late final Future<Uint8List> _bytes = widget.store.read(widget.still);

  @override
  Widget build(BuildContext context) {
    final still = widget.still;
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snapshot) => PorcelainListRow(
        icon: PorcelainIcons.gallery,
        title: formatTimestamp(still.capturedAtUtc.toLocal()),
        subtitle:
            '${CameraCopy.lens(still.lens)} · '
            '${CameraCopy.size(still.widthPx, still.heightPx)}',
        trailing: switch (snapshot) {
          AsyncSnapshot(hasData: true) => const StatusBadge(
            label: 'Intact',
            tone: PorcelainTone.success,
          ),
          AsyncSnapshot(hasError: true) => const StatusBadge(
            label: 'Missing or changed',
            tone: PorcelainTone.danger,
          ),
          _ => const StatusBadge(label: 'Checking'),
        },
      ),
    );
  }
}
