import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/routing/route_paths.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_list_row.dart';
import '../../shared/widgets/studio_page.dart';
import 'about_settings.dart';
import 'appearance_settings.dart';
import 'booth_settings.dart';
import 'camera_settings.dart';
import 'output_settings.dart';
import 'storage_settings.dart';

/// Settings sections; [id] is the value of the `section` query parameter.
enum SettingsSection {
  appearance(
    'appearance',
    'Appearance',
    'Theme, contrast, motion and guest screen',
    PorcelainIcons.appearance,
  ),
  camera(
    'camera',
    'Camera',
    'Lens, mirroring and capture quality',
    PorcelainIcons.camera,
  ),
  output(
    'output',
    'Output and printing',
    'Print sizes, file formats and printer',
    PorcelainIcons.outputFormat,
  ),
  storage(
    'storage',
    'Storage',
    'Space photos use, upkeep and clean-up',
    PorcelainIcons.storage,
  ),
  booth(
    'booth',
    'Booth and security',
    'Booth name, orientation and operator PIN',
    PorcelainIcons.security,
  ),
  about(
    'about',
    'About',
    'Version, licences and asset sources',
    PorcelainIcons.info,
  );

  const SettingsSection(this.id, this.title, this.subtitle, this.icon);

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  static SettingsSection? fromId(String? id) =>
      values.where((section) => section.id == id).firstOrNull;
}

/// Settings (S15–S17, part of S18): two panes when the content area is wide
/// enough, otherwise a list that opens one section at a time. The open
/// section lives in the route, so rotating the tablet keeps it.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.section});

  final SettingsSection? section;

  static const twoPaneWidth = 840.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= twoPaneWidth) {
          final open = section ?? SettingsSection.appearance;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 320,
                child: _SectionList(selected: open, showSelection: true),
              ),
              VerticalDivider(
                width: 1,
                color: context.porcelain.colors.divider,
              ),
              Expanded(child: _SectionDetail(section: open)),
            ],
          );
        }
        final open = section;
        if (open == null) {
          return const _SectionList(selected: null, showSelection: false);
        }
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) context.go(RoutePaths.settings);
          },
          child: _SectionDetail(section: open, showBack: true),
        );
      },
    );
  }
}

class _SectionList extends StatelessWidget {
  const _SectionList({required this.selected, required this.showSelection});

  final SettingsSection? selected;
  final bool showSelection;

  @override
  Widget build(BuildContext context) {
    return StudioPage(
      spacing: PorcelainSpace.xl,
      header: const StudioPageHeader(eyebrow: 'Studio', title: 'Settings'),
      children: [
        Column(
          children: [
            for (final section in SettingsSection.values)
              Padding(
                padding: const EdgeInsets.only(bottom: PorcelainSpace.xxs),
                child: PorcelainListRow(
                  icon: section.icon,
                  title: section.title,
                  subtitle: section.subtitle,
                  selected: showSelection && section == selected,
                  showChevron: !showSelection,
                  onPressed: () =>
                      context.go(RoutePaths.settingsSection(section.id)),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SectionDetail extends StatelessWidget {
  const _SectionDetail({required this.section, this.showBack = false});

  final SettingsSection section;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final body = switch (section) {
      SettingsSection.appearance => const AppearanceSettings(),
      SettingsSection.camera => const CameraSettings(),
      SettingsSection.output => const OutputSettings(),
      SettingsSection.storage => const StorageSettings(),
      SettingsSection.booth => const BoothSettings(),
      SettingsSection.about => const AboutSettings(),
    };
    return StudioPage(
      key: ValueKey(section),
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBack) ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: PorcelainButton(
                label: 'All settings',
                icon: PorcelainIcons.back,
                variant: PorcelainButtonVariant.quiet,
                size: PorcelainButtonSize.compact,
                onPressed: () => context.go(RoutePaths.settings),
              ),
            ),
            const SizedBox(height: PorcelainSpace.md),
          ],
          StudioPageHeader(
            eyebrow: 'Settings',
            title: section.title,
            subtitle: section.subtitle,
          ),
        ],
      ),
      children: [body],
    );
  }
}
