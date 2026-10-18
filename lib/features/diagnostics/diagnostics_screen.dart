import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/platform/app_environment.dart';
import '../../core/platform/app_info.dart';
import '../../core/routing/route_paths.dart';
import '../../domain/value_objects/orientation.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/porcelain_list_row.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/studio_page.dart';
import '../../shared/widgets/tone.dart';

/// Device diagnostics (S18). Today it reports what this build can verify
/// about itself; the measured self-test arrives with the camera service
/// (M06). Developer tools appear in debug and profile builds only.
class DiagnosticsScreen extends ConsumerWidget {
  const DiagnosticsScreen({super.key});

  static const selfTestReason =
      'The self-test arrives with the camera service in M06.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              title: 'Self-test',
              subtitle:
                  'Measures the camera, file writing and free storage, with '
                  'repair steps for anything that fails.',
              trailing: PorcelainButton(
                label: 'Run self-test',
                icon: PorcelainIcons.start,
                onPressed: null,
                disabledReason: selfTestReason,
              ),
            ),
            const PorcelainCard(
              child: Column(
                children: [
                  _Check(icon: PorcelainIcons.camera, label: 'Camera'),
                  _Check(icon: PorcelainIcons.fileWrite, label: 'File write'),
                  _Check(icon: PorcelainIcons.storage, label: 'Free storage'),
                ],
              ),
            ),
            const SizedBox(height: PorcelainSpace.sm),
            Text(
              selfTestReason,
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
                      icon: PorcelainIcons.camera,
                      title: 'Camera spike',
                      subtitle: 'M01: one still into managed storage',
                      onPressed: () => context.push(RoutePaths.cameraSpike),
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

class _Check extends StatelessWidget {
  const _Check({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return PorcelainListRow(
      icon: icon,
      title: label,
      trailing: const StatusBadge(
        label: 'Not run',
        tone: PorcelainTone.neutral,
      ),
    );
  }
}
