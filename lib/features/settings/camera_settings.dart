import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/booth/booth_providers.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/di/service_providers.dart';
import '../../core/routing/route_paths.dart';
import '../../domain/models/booth_profile.dart';
import '../../domain/services/camera_service.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/porcelain_list_row.dart';
import '../../shared/widgets/porcelain_segmented_control.dart';
import '../../shared/widgets/porcelain_switch.dart';
import '../../shared/widgets/porcelain_toast.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/tone.dart';

/// The built-in cameras this tablet reports.
final _tabletCamerasProvider =
    FutureProvider.autoDispose<List<CameraDescriptor>>(
      (ref) => ref.watch(cameraServiceProvider).availableCameras(),
    );

/// Camera settings (S15): the camera and mirroring new events start with,
/// the cameras this tablet reports, and the way into the camera test.
/// Preview and saved-photo mirroring are separate (CR-001 fix 5).
class CameraSettings extends ConsumerWidget {
  const CameraSettings({super.key});

  static const saveFailed =
      "That change couldn't be saved on the tablet. Try again.";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.porcelain;
    final profile = ref.watch(boothProfileProvider);
    final defaults = profile.value?.defaults;

    Future<void> save(EventDefaults next) async {
      try {
        await ref.read(boothSettingsRepositoryProvider).saveEventDefaults(next);
      } on Exception {
        if (context.mounted) {
          PorcelainToast.show(context, saveFailed, tone: PorcelainTone.danger);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Defaults for new events',
          subtitle:
              'Each event keeps its own copy, so changing these never alters '
              'an existing event.',
        ),
        if (defaults == null)
          const SkeletonList(semanticLabel: 'Loading camera defaults')
        else
          PorcelainCard(
            padding: const EdgeInsets.all(PorcelainSpace.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Camera', style: theme.text.titleSmall),
                const SizedBox(height: PorcelainSpace.xs),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: PorcelainSegmentedControl<CameraLens>(
                    selected: defaults.lens,
                    onChanged: (lens) => save(defaults.copyWith(lens: lens)),
                    segments: const [
                      PorcelainSegment(
                        value: CameraLens.front,
                        label: 'Front camera',
                        icon: PorcelainIcons.camera,
                      ),
                      PorcelainSegment(
                        value: CameraLens.back,
                        label: 'Rear camera',
                        icon: PorcelainIcons.camera,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: PorcelainSpace.lg),
                PorcelainSwitchRow(
                  title: 'Mirror the live preview',
                  subtitle: 'How guests see themselves while posing.',
                  icon: PorcelainIcons.preview,
                  value: defaults.mirrorPreview,
                  onChanged: (on) => save(defaults.copyWith(mirrorPreview: on)),
                ),
                PorcelainSwitchRow(
                  title: 'Mirror saved photos',
                  subtitle: 'Usually off, so text in photos reads correctly.',
                  icon: PorcelainIcons.gallery,
                  value: defaults.mirrorOutput,
                  onChanged: (on) => save(defaults.copyWith(mirrorOutput: on)),
                ),
              ],
            ),
          ),
        const SizedBox(height: PorcelainSpace.xxxl),
        const SectionHeader(
          title: 'This tablet',
          subtitle: 'What the cameras can do, tested on the device.',
        ),
        PorcelainCard(
          child: Column(
            children: [
              PorcelainListRow(
                icon: PorcelainIcons.camera,
                title: 'Cameras on this tablet',
                subtitle: 'Built-in cameras the tablet reports.',
                trailing: switch (ref.watch(_tabletCamerasProvider)) {
                  AsyncData(:final value) => _CamerasBadge(value),
                  AsyncError() => const StatusBadge(
                    label: "Couldn't list",
                    tone: PorcelainTone.danger,
                  ),
                  _ => const StatusBadge(label: 'Checking'),
                },
              ),
              PorcelainListRow(
                icon: PorcelainIcons.preview,
                title: 'Camera test',
                subtitle: 'Preview, mirroring and a test photo.',
                onPressed: () => context.push(RoutePaths.cameraTest),
              ),
              const PorcelainListRow(
                icon: PorcelainIcons.outputFormat,
                title: 'Capture quality',
                subtitle:
                    "The camera's full-resolution still, never a picture of "
                    'the screen.',
                trailing: StatusBadge(label: 'Highest'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CamerasBadge extends StatelessWidget {
  const _CamerasBadge(this.cameras);

  final List<CameraDescriptor> cameras;

  @override
  Widget build(BuildContext context) {
    final front = cameras.any((c) => c.lens == CameraLens.front);
    final back = cameras.any((c) => c.lens == CameraLens.back);
    return StatusBadge(
      label: switch ((front, back)) {
        (true, true) => 'Front and rear',
        (true, false) => 'Front only',
        (false, true) => 'Rear only',
        (false, false) => 'None found',
      },
      tone: front || back ? PorcelainTone.success : PorcelainTone.warning,
    );
  }
}
