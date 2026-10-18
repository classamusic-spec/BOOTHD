import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/responsive_grid.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/studio_page.dart';
import '../../shared/widgets/template_thumbnail.dart';

/// A supported print size (ARCHITECTURE A-07: nominal 300 dpi).
@immutable
final class PageFormat {
  const PageFormat({
    required this.name,
    required this.orientation,
    required this.widthInches,
    required this.heightInches,
    required this.slots,
    required this.icon,
  });

  final String name;
  final String orientation;
  final IconData icon;
  final double widthInches;
  final double heightInches;

  /// Example slot arrangement for the schematic thumbnail.
  final List<Rect> slots;

  int get widthPx => (widthInches * 300).round();
  int get heightPx => (heightInches * 300).round();
}

const pageFormats = [
  PageFormat(
    name: '2 × 6 strip',
    orientation: 'Portrait',
    icon: PorcelainIcons.portrait,
    widthInches: 2,
    heightInches: 6,
    slots: [
      Rect.fromLTWH(0.1, 0.05, 0.8, 0.26),
      Rect.fromLTWH(0.1, 0.34, 0.8, 0.26),
      Rect.fromLTWH(0.1, 0.63, 0.8, 0.26),
    ],
  ),
  PageFormat(
    name: '4 × 6',
    orientation: 'Portrait',
    icon: PorcelainIcons.portrait,
    widthInches: 4,
    heightInches: 6,
    slots: [
      Rect.fromLTWH(0.08, 0.06, 0.84, 0.42),
      Rect.fromLTWH(0.08, 0.52, 0.84, 0.34),
    ],
  ),
  PageFormat(
    name: '6 × 4',
    orientation: 'Landscape',
    icon: PorcelainIcons.landscape,
    widthInches: 6,
    heightInches: 4,
    slots: [
      Rect.fromLTWH(0.05, 0.1, 0.44, 0.72),
      Rect.fromLTWH(0.51, 0.1, 0.44, 0.72),
    ],
  ),
  PageFormat(
    name: '4 × 4',
    orientation: 'Square',
    icon: PorcelainIcons.square,
    widthInches: 4,
    heightInches: 4,
    slots: [Rect.fromLTWH(0.1, 0.1, 0.8, 0.66)],
  ),
];

/// Template library (S06). Shows the print formats templates are designed
/// for; designing and importing templates are disabled with their reasons
/// until the renderer (M04) and the template editor (M05) exist.
class TemplateLibraryScreen extends StatelessWidget {
  const TemplateLibraryScreen({super.key});

  static const newTemplateReason = 'The template editor arrives in M05.';
  static const importReason = 'Template import arrives in M04.';

  @override
  Widget build(BuildContext context) {
    return StudioPage(
      header: const StudioPageHeader(
        eyebrow: 'Studio',
        title: 'Templates',
        subtitle:
            'Layered designs with photo slots, transparent artwork and text.',
        actions: [
          PorcelainButton(
            label: 'Import',
            icon: PorcelainIcons.import,
            onPressed: null,
            disabledReason: importReason,
          ),
          PorcelainButton(
            label: 'New template',
            icon: PorcelainIcons.add,
            variant: PorcelainButtonVariant.primary,
            onPressed: null,
            disabledReason: newTemplateReason,
          ),
        ],
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(
              title: 'Page formats',
              subtitle:
                  'Every template is designed for one of these sizes and '
                  'exported at 300 dpi.',
            ),
            ResponsiveGrid(
              minTileWidth: 170,
              balanced: true,
              children: [for (final format in pageFormats) _FormatCard(format)],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            SectionHeader(title: 'Your templates'),
            EmptyState(
              icon: PorcelainIcons.templates,
              title: 'No templates yet',
              message:
                  'Templates you design or import appear here with their page '
                  'size and the events that use them.',
              footnote: '$importReason $newTemplateReason',
            ),
          ],
        ),
      ],
    );
  }
}

class _FormatCard extends StatelessWidget {
  const _FormatCard(this.format);

  final PageFormat format;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return MergeSemantics(
      child: PorcelainCard(
        padding: const EdgeInsets.all(PorcelainSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 176,
              child: Center(
                child: TemplateThumbnail(
                  pageWidth: format.widthInches,
                  pageHeight: format.heightInches,
                  slots: format.slots,
                  height: format.heightInches >= format.widthInches ? 168 : 120,
                  semanticLabel: '${format.name} page with photo slots',
                ),
              ),
            ),
            const SizedBox(height: PorcelainSpace.lg),
            Text(format.name, style: theme.text.titleMedium),
            const SizedBox(height: PorcelainSpace.xxs),
            Text(
              '${format.widthPx} × ${format.heightPx} px',
              style: theme.text.numeric.copyWith(color: theme.colors.inkMuted),
            ),
            const SizedBox(height: PorcelainSpace.sm),
            StatusBadge(label: format.orientation, icon: format.icon),
          ],
        ),
      ),
    );
  }
}
