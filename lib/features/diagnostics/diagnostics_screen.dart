import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/di/service_providers.dart';
import '../../core/diagnostics/device_self_test.dart';
import '../../core/platform/app_environment.dart';
import '../../core/platform/app_info.dart';
import '../../core/routing/route_paths.dart';
import '../../domain/value_objects/orientation.dart';
import '../../shared/formatters/date_format.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/porcelain_list_row.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/studio_page.dart';
import '../../shared/widgets/tone.dart';
import 'self_test_copy.dart';

/// Device diagnostics (S18): what this build can verify about itself, the
/// camera test, and a self-test that measures the camera, file writing and
/// free storage with repair steps for anything that fails. Developer tools
/// appear in debug and profile builds only.
class DiagnosticsScreen extends ConsumerStatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen> {
  /// Results of the last run, by check; a check without one has not run.
  final _results = <SelfTestCheck, SelfTestResult>{};
  var _running = false;
  DateTime? _ranAt;

  Future<void> _runSelfTest() async {
    final selfTest = ref.read(deviceSelfTestProvider);
    setState(() {
      _running = true;
      _results.clear();
    });
    try {
      for (final check in SelfTestCheck.values) {
        final result = await selfTest.check(check);
        if (!mounted) return;
        setState(() => _results[check] = result);
      }
    } finally {
      if (mounted) {
        setState(() {
          _running = false;
          _ranAt = ref.read(clockProvider).now();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final environment = ref.watch(appEnvironmentProvider);
    final theme = context.porcelain;
    final media = MediaQuery.of(context);
    final size = media.size;
    final viewport = ViewportOrientation.fromLogicalSize(
      width: size.width,
      height: size.height,
    );
    final devTools = environment.buildMode != BuildMode.release;
    String onOff(bool value) => value ? 'On' : 'Off';

    return StudioPage(
      header: const StudioPageHeader(
        eyebrow: 'Studio',
        title: 'Diagnostics',
        subtitle: 'Facts this build can verify about itself.',
      ),
      children: [
        PorcelainCard(
          child: Column(
            children: [
              _Fact(
                icon: PorcelainIcons.tablet,
                label: 'Platform',
                value: environment.platformLabel,
              ),
              _Fact(
                icon: PorcelainIcons.info,
                label: 'Version',
                value:
                    '${AppInfo.version} (${AppInfo.buildNumber}) · '
                    '${environment.buildMode.name}',
              ),
              _Fact(
                icon: PorcelainIcons.orientation,
                label: 'Window',
                value:
                    '${size.width.round()} × ${size.height.round()} '
                    '${environment.platform == TargetPlatform.iOS ? 'pt' : 'dp'}'
                    ' · ${viewport.name}',
              ),
              _Fact(
                icon: PorcelainIcons.textSize,
                label: 'Text size',
                value: '${(media.textScaler.scale(100)).round()} %',
              ),
              _Fact(
                icon: PorcelainIcons.motion,
                label: 'Reduce motion',
                value: onOff(media.disableAnimations),
              ),
              _Fact(
                icon: PorcelainIcons.contrast,
                label: 'High contrast',
                value: onOff(theme.highContrast),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(
              title: 'Camera',
              subtitle:
                  'The live picture, mirroring and a test photo saved like '
                  "a guest's.",
            ),
            PorcelainCard(
              child: PorcelainListRow(
                icon: PorcelainIcons.camera,
                title: 'Camera test',
                subtitle:
                    'Allow the camera, choose front or rear, and save a '
                    'test photo',
                onPressed: () => context.push(RoutePaths.cameraTest),
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: 'Self-test',
              subtitle:
                  'Measures the camera, file writing and free storage, with '
                  'repair steps for anything that fails.',
              trailing: PorcelainButton(
                label: _ranAt == null ? 'Run self-test' : 'Run again',
                icon: _ranAt == null
                    ? PorcelainIcons.start
                    : PorcelainIcons.retry,
                busy: _running,
                busyLabel: 'Testing…',
                onPressed: _running ? null : () => unawaited(_runSelfTest()),
              ),
            ),
            PorcelainCard(
              child: Column(
                children: [
                  for (final check in SelfTestCheck.values)
                    _Check(
                      check: check,
                      result: _results[check],
                      running: _running,
                      platform: environment.platform,
                    ),
                ],
              ),
            ),
            const SizedBox(height: PorcelainSpace.sm),
            Text(
              switch (_ranAt) {
                null =>
                  'Nothing is asked for, opened or kept: the camera test '
                      'does that on purpose.',
                final ranAt =>
                  'Last run ${formatTimestamp(ranAt.toLocal())}. Nothing was asked '
                      'for, opened or kept.',
              },
              style: theme.text.bodyMedium.copyWith(
                color: theme.colors.inkMuted,
              ),
            ),
          ],
        ),
        if (devTools)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(
                title: 'Developer tools',
                subtitle: 'Debug and profile builds only; absent from release.',
              ),
              PorcelainCard(
                child: Column(
                  children: [
                    PorcelainListRow(
                      icon: PorcelainIcons.layers,
                      title: 'Render lab',
                      subtitle: 'Renderer fixtures, parity and failure checks',
                      onPressed: () => context.push(RoutePaths.renderLab),
                    ),
                    PorcelainListRow(
                      icon: PorcelainIcons.components,
                      title: 'Component gallery',
                      subtitle: 'Every Porcelain component in every state',
                      onPressed: () =>
                          context.push(RoutePaths.componentGallery),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
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
        style: theme.text.numeric.copyWith(color: theme.colors.inkMuted),
      ),
    );
  }
}

/// One self-test check: waiting, checking, or its measured outcome.
class _Check extends StatelessWidget {
  const _Check({
    required this.check,
    required this.result,
    required this.running,
    required this.platform,
  });

  final SelfTestCheck check;
  final SelfTestResult? result;
  final bool running;
  final TargetPlatform platform;

  @override
  Widget build(BuildContext context) {
    final result = this.result;
    return PorcelainListRow(
      icon: switch (check) {
        SelfTestCheck.camera => PorcelainIcons.camera,
        SelfTestCheck.fileWrite => PorcelainIcons.fileWrite,
        SelfTestCheck.freeStorage => PorcelainIcons.storage,
      },
      title: SelfTestCopy.title(check),
      subtitle: result == null
          ? SelfTestCopy.waiting(check)
          : SelfTestCopy.outcome(result, platform),
      trailing: switch (result) {
        null when running => const StatusBadge(label: 'Checking'),
        null => const StatusBadge(label: 'Not run'),
        SelfTestResult(passed: true) => const StatusBadge(
          label: 'Passed',
          tone: PorcelainTone.success,
          icon: PorcelainIcons.success,
        ),
        SelfTestResult(:final problemCode) => StatusBadge(
          label: problemCode == 'STORAGE_LOW' ? 'Low' : 'Problem',
          tone: problemCode == 'STORAGE_LOW'
              ? PorcelainTone.warning
              : PorcelainTone.danger,
          icon: PorcelainIcons.warning,
        ),
      },
    );
  }
}
