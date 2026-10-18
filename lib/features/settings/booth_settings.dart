import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/porcelain_list_row.dart';
import '../../shared/widgets/status_badge.dart';

/// Booth identity and operator security (M03, M10), listed with their
/// arrival so nothing looks available before it is.
class BoothSettings extends StatelessWidget {
  const BoothSettings({super.key});

  static const storageReason =
      'Booth settings arrive with booth storage in M03.';
  static const kioskReason = 'Kiosk lock guidance arrives in M10.';

  @override
  Widget build(BuildContext context) {
    return const PorcelainCard(
      child: Column(
        children: [
          PorcelainListRow(
            icon: PorcelainIcons.tablet,
            title: 'Booth name',
            subtitle: 'Shown to operators, never to guests.',
            trailing: StatusBadge(label: 'M03'),
            disabledReason: storageReason,
          ),
          PorcelainListRow(
            icon: PorcelainIcons.orientation,
            title: 'Guest orientation',
            subtitle:
                'Portrait or landscape. Screens always adapt to the window '
                'the tablet actually gives them.',
            trailing: StatusBadge(label: 'M03'),
            disabledReason: storageReason,
          ),
          PorcelainListRow(
            icon: PorcelainIcons.security,
            title: 'Operator PIN',
            subtitle: 'Protects the Studio while the booth runs.',
            trailing: StatusBadge(label: 'M03'),
            disabledReason: storageReason,
          ),
          PorcelainListRow(
            icon: PorcelainIcons.locked,
            title: 'Kiosk lock',
            subtitle: 'Guided Access on iPad, lock task on Android.',
            trailing: StatusBadge(label: 'M10'),
            disabledReason: kioskReason,
          ),
        ],
      ),
    );
  }
}
