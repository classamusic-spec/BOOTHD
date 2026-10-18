import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/platform/app_environment.dart';
import '../../core/platform/app_info.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/porcelain_list_row.dart';
import '../../shared/widgets/status_badge.dart';

/// Version facts, open-source licences and where the bundled type, icons
/// and artwork come from (AC-0211).
class AboutSettings extends ConsumerWidget {
  const AboutSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final environment = ref.watch(appEnvironmentProvider);
    final version = '${AppInfo.version} (${AppInfo.buildNumber})';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PorcelainCard(
          child: Column(
            children: [
              PorcelainListRow(
                icon: PorcelainIcons.info,
                title: AppInfo.name,
                subtitle: 'Version $version',
                trailing: StatusBadge(label: environment.buildMode.name),
              ),
              PorcelainListRow(
                icon: PorcelainIcons.tablet,
                title: 'Platform',
                trailing: StatusBadge(label: environment.platformLabel),
              ),
            ],
          ),
        ),
        const SizedBox(height: PorcelainSpace.xxxl),
        SectionHeader(
          title: 'Licences',
          subtitle: 'Every package, font and icon set this app ships.',
          trailing: PorcelainButton(
            label: 'Open licences',
            icon: PorcelainIcons.licence,
            onPressed: () => showLicensePage(
              context: context,
              applicationName: AppInfo.name,
              applicationVersion: version,
            ),
          ),
        ),
        const PorcelainCard(
          child: Column(
            children: [
              PorcelainListRow(
                icon: PorcelainIcons.textSize,
                title: 'Cormorant Garamond and Inter',
                subtitle:
                    'Display and interface type. SIL Open Font License 1.1.',
              ),
              PorcelainListRow(
                icon: PorcelainIcons.components,
                title: 'Material Symbols Rounded',
                subtitle: 'Icons by Google. Apache License 2.0.',
              ),
              PorcelainListRow(
                icon: PorcelainIcons.templates,
                title: 'Botanical line art',
                subtitle: 'Original to this app, drawn in code.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
