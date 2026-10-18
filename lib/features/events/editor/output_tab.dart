import 'package:flutter/widgets.dart';

import '../../../core/design_system/porcelain_icons.dart';
import '../../../core/design_system/porcelain_metrics.dart';
import '../../../core/design_system/porcelain_theme.dart';
import '../../../domain/models/booth_event.dart';
import '../../../domain/models/event_rules.dart';
import '../../../shared/widgets/porcelain_segmented_control.dart';
import '../../../shared/widgets/porcelain_stepper.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/tone.dart';
import '../event_copy.dart';
import 'editor_parts.dart';

/// The finished photo's file format (S04 Output, S16). The page size and
/// resolution come from each template.
class OutputTab extends StatelessWidget {
  const OutputTab({super.key, required this.tab});

  final EditorTabContext tab;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final event = tab.event;
    final output = event.output;
    final reason = tab.readOnlyReason;
    final templates = [
      for (final id in event.templates.revisionIds) ?tab.library[id],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorCard(
          title: 'File format',
          subtitle: 'How finished photos are saved.',
          children: [
            PorcelainSegmentedControl<OutputFormat>(
              selected: output.format,
              onChanged: tab.edit(
                (format) =>
                    event.copyWith(output: output.copyWith(format: format)),
              ),
              disabledReason: reason,
              segments: const [
                PorcelainSegment(value: OutputFormat.jpeg, label: 'JPEG'),
                PorcelainSegment(value: OutputFormat.png, label: 'PNG'),
              ],
            ),
            Text(
              output.format == OutputFormat.jpeg
                  ? 'Smaller files that print well. Transparent areas are '
                        'filled with the page background.'
                  : 'Lossless and larger. Keeps transparency where the '
                        'template has it.',
              style: theme.text.bodyMedium.copyWith(
                color: theme.colors.inkMuted,
              ),
            ),
            EditorSetting(
              title: EventCopy.setting(EventSetting.jpegQuality),
              description: 'Higher keeps more detail in larger files.',
              control: PorcelainStepper(
                label: EventCopy.setting(EventSetting.jpegQuality),
                value: output.jpegQuality,
                min: EventLimits.jpegQuality.min,
                max: EventLimits.jpegQuality.max,
                decreaseLabel: 'Lower quality',
                increaseLabel: 'Higher quality',
                onChanged: output.format == OutputFormat.jpeg
                    ? tab.edit(
                        (quality) => event.copyWith(
                          output: output.copyWith(jpegQuality: quality),
                        ),
                      )
                    : null,
                disabledReason:
                    reason ?? 'PNG is lossless; quality applies to JPEG only.',
                minimumReason:
                    reason ??
                    'Print quality needs at least '
                        '${EventLimits.jpegQuality.min}.',
                maximumReason:
                    reason ??
                    '${EventLimits.jpegQuality.max} is the '
                        'highest quality.',
              ),
            ),
          ],
        ),
        const SizedBox(height: PorcelainSpace.xl),
        EditorCard(
          title: 'Print size',
          subtitle:
              'Each template sets its page size, exported at 300 dots per '
              'inch.',
          children: [
            if (templates.isEmpty)
              Text(
                'Add templates to see their print sizes.',
                style: theme.text.bodyLarge.copyWith(
                  color: theme.colors.inkMuted,
                ),
              )
            else
              for (final template in templates)
                MergeSemantics(
                  child: Row(
                    children: [
                      Icon(
                        PorcelainIcons.outputFormat,
                        color: theme.colors.accentIcon,
                      ),
                      const SizedBox(width: PorcelainSpace.sm),
                      Expanded(
                        child: Text(
                          template.templateName,
                          style: theme.text.titleSmall,
                        ),
                      ),
                      Flexible(
                        child: StatusBadge(
                          label: pageSizeLabel(template),
                          tone: PorcelainTone.info,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
        const SizedBox(height: PorcelainSpace.xl),
        const EditorCard(
          title: 'Printer',
          subtitle:
              'This release saves print-ready files and does not print. '
              'Printing is added once a printer model is chosen and tested.',
          trailing: StatusBadge(
            label: 'Not configured',
            tone: PorcelainTone.neutral,
            icon: PorcelainIcons.printerOff,
          ),
          children: [],
        ),
      ],
    );
  }
}
