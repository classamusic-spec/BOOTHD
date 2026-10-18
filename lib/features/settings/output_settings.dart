import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/booth/booth_providers.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/di/service_providers.dart';
import '../../domain/models/booth_event.dart';
import '../../domain/models/booth_profile.dart';
import '../../domain/models/event_rules.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/porcelain_list_row.dart';
import '../../shared/widgets/porcelain_segmented_control.dart';
import '../../shared/widgets/porcelain_stepper.dart';
import '../../shared/widgets/porcelain_toast.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/tone.dart';

/// Output and printing (S16): the file format new events start with, the
/// print sizes the renderer produces, and the printer, shown as not
/// configured rather than offered until a printer is chosen.
class OutputSettings extends ConsumerWidget {
  const OutputSettings({super.key});

  static const saveFailed =
      "That change couldn't be saved on the tablet. Try again.";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaults = ref.watch(boothProfileProvider).value?.defaults;

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
          subtitle: 'Each event keeps its own copy.',
        ),
        if (defaults == null)
          const SkeletonList(semanticLabel: 'Loading output defaults')
        else
          PorcelainCard(
            padding: const EdgeInsets.all(PorcelainSpace.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PorcelainSegmentedControl<OutputFormat>(
                  selected: defaults.output.format,
                  onChanged: (format) => save(
                    defaults.copyWith(
                      output: defaults.output.copyWith(format: format),
                    ),
                  ),
                  segments: const [
                    PorcelainSegment(value: OutputFormat.jpeg, label: 'JPEG'),
                    PorcelainSegment(value: OutputFormat.png, label: 'PNG'),
                  ],
                ),
                const SizedBox(height: PorcelainSpace.lg),
                PorcelainStepper(
                  label: 'JPEG quality',
                  value: defaults.output.jpegQuality,
                  min: EventLimits.jpegQuality.min,
                  max: EventLimits.jpegQuality.max,
                  decreaseLabel: 'Lower quality',
                  increaseLabel: 'Higher quality',
                  onChanged: defaults.output.format == OutputFormat.jpeg
                      ? (quality) => save(
                          defaults.copyWith(
                            output: defaults.output.copyWith(
                              jpegQuality: quality,
                            ),
                          ),
                        )
                      : null,
                  disabledReason:
                      'PNG is lossless; quality applies to JPEG only.',
                  minimumReason:
                      'Print quality needs at least '
                      '${EventLimits.jpegQuality.min}.',
                  maximumReason:
                      '${EventLimits.jpegQuality.max} is the highest quality.',
                ),
              ],
            ),
          ),
        const SizedBox(height: PorcelainSpace.xxxl),
        const SectionHeader(
          title: 'Printer',
          subtitle: 'This release saves print-ready files; it does not print.',
        ),
        const PorcelainCard(
          child: PorcelainListRow(
            icon: PorcelainIcons.printerOff,
            title: 'Printer',
            subtitle:
                'Printing is added after a printer model is chosen and '
                'tested. Finished photos are saved at full print resolution.',
            trailing: StatusBadge(
              label: 'Not configured',
              tone: PorcelainTone.neutral,
            ),
          ),
        ),
        const SizedBox(height: PorcelainSpace.xxxl),
        const SectionHeader(
          title: 'Print sizes',
          subtitle: 'Exported at 300 dpi. Each template sets its own size.',
        ),
        const PorcelainCard(
          child: Column(
            children: [
              _Size(name: '2 × 6 strip', pixels: '600 × 1800 px'),
              _Size(name: '4 × 6 portrait', pixels: '1200 × 1800 px'),
              _Size(name: '6 × 4 landscape', pixels: '1800 × 1200 px'),
              _Size(name: '4 × 4 square', pixels: '1200 × 1200 px'),
            ],
          ),
        ),
      ],
    );
  }
}

class _Size extends StatelessWidget {
  const _Size({required this.name, required this.pixels});

  final String name;
  final String pixels;

  @override
  Widget build(BuildContext context) {
    return PorcelainListRow(
      icon: PorcelainIcons.outputFormat,
      title: name,
      trailing: StatusBadge(label: pixels, tone: PorcelainTone.info),
    );
  }
}
