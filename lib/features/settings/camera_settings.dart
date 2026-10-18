import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/porcelain_list_row.dart';
import '../../shared/widgets/status_badge.dart';

/// Camera settings (S15) arrive with the production camera service (M06).
/// Listed here so operators know what will be configurable, including the
/// two separate mirroring settings (CR-001 fix 5).
class CameraSettings extends StatelessWidget {
  const CameraSettings({super.key});

  static const reason =
      'Camera settings arrive with the camera service in M06.';

  @override
  Widget build(BuildContext context) {
    return const PorcelainCard(
      child: Column(
        children: [
          PorcelainListRow(
            icon: PorcelainIcons.camera,
            title: 'Camera and lens',
            subtitle: 'Front or rear, from the cameras this tablet reports.',
            trailing: StatusBadge(label: 'M06'),
            disabledReason: reason,
          ),
          PorcelainListRow(
            icon: PorcelainIcons.preview,
            title: 'Mirror the live preview',
            subtitle: 'How guests see themselves while posing.',
            trailing: StatusBadge(label: 'M06'),
            disabledReason: reason,
          ),
          PorcelainListRow(
            icon: PorcelainIcons.gallery,
            title: 'Mirror saved photos',
            subtitle: 'Set separately from the preview, per event.',
            trailing: StatusBadge(label: 'M06'),
            disabledReason: reason,
          ),
          PorcelainListRow(
            icon: PorcelainIcons.outputFormat,
            title: 'Capture quality',
            subtitle: 'Only the resolutions the camera supports.',
            trailing: StatusBadge(label: 'M06'),
            disabledReason: reason,
          ),
        ],
      ),
    );
  }
}
