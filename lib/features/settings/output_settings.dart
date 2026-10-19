import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/booth/booth_providers.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/di/service_providers.dart';
import '../../core/gallery/gallery_providers.dart';
import '../../domain/gallery/gallery_models.dart';
import '../../domain/models/booth_event.dart';
import '../../domain/models/booth_profile.dart';
import '../../domain/models/event_rules.dart';
import '../../domain/services/booth_capabilities.dart';
import '../../domain/services/print_service.dart';
import '../../domain/template/page_spec.dart';
import '../../domain/value_objects/orientation.dart';
import '../../shared/gallery/gallery_copy.dart';
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
/// printer as the print service reports it (not configured: no print
/// control exists, AC-0806), the print sizes with their exact pixels and
/// resolution (AC-0807), and the space a session's photos use.
class OutputSettings extends ConsumerWidget {
  const OutputSettings({super.key});

  static const saveFailed =
      "That change couldn't be saved on the tablet. Try again.";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaults = ref.watch(boothProfileProvider).value?.defaults;
    final printer = ref.watch(printCapabilitiesProvider).value;
    final usage = ref.watch(storageUsageProvider(null)).value;

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
        PorcelainCard(
          child: PorcelainListRow(
            icon: PorcelainIcons.printerOff,
            title: 'Printer',
            subtitle: switch (printer) {
              PrintCapabilities(configured: false) || null =>
                'Printing is added after a printer model is chosen and '
                    'tested. Finished photos are saved at full print '
                    'resolution and can be exported from the gallery.',
              PrintCapabilities(:final adapterName) =>
                adapterName ?? 'Configured',
            },
            showChevron: false,
            trailing: StatusBadge(
              label: printer?.configured ?? false
                  ? 'Configured'
                  : 'Not configured',
              tone: PorcelainTone.neutral,
            ),
          ),
        ),
        const SizedBox(height: PorcelainSpace.xxxl),
        const SectionHeader(
          title: 'Print sizes',
          subtitle:
              'Each template sets its page; finished photos are exported '
              'at exactly that size, tagged with their print resolution.',
        ),
        PorcelainCard(
          child: Column(
            children: [
              for (final preset in PagePreset.all) _Size(preset: preset),
            ],
          ),
        ),
        const SizedBox(height: PorcelainSpace.xxxl),
        const SectionHeader(
          title: 'Space per session',
          subtitle: 'Measured from the photos on this tablet.',
        ),
        PorcelainCard(
          child: PorcelainListRow(
            icon: PorcelainIcons.storage,
            title: 'Finished photo',
            subtitle: switch (usage) {
              StorageUsage(:final finishedCount, :final finishedBytes)
                  when finishedCount > 0 =>
                'About ${GalleryCopy.bytes(finishedBytes ~/ finishedCount)} '
                    'each, over $finishedCount finished photos. Camera '
                    'photos add more.',
              StorageUsage() =>
                'No finished photos yet to measure. A booth reserves about '
                    '${GalleryCopy.bytes(StorageBudget.bytesPerSession)} per '
                    'session, camera photos included.',
              null => 'Measuring…',
            },
            showChevron: false,
          ),
        ),
      ],
    );
  }
}

class _Size extends StatelessWidget {
  const _Size({required this.preset});

  final PagePreset preset;

  @override
  Widget build(BuildContext context) {
    final page = preset.page;
    return PorcelainListRow(
      icon: switch (page.orientation) {
        PageOrientation.portrait => PorcelainIcons.portrait,
        PageOrientation.landscape => PorcelainIcons.landscape,
        PageOrientation.square => PorcelainIcons.square,
      },
      title: preset.name,
      subtitle: '${page.orientation.name}, ${page.dpi} dpi',
      showChevron: false,
      trailing: StatusBadge(
        label: '${page.widthPx} × ${page.heightPx} px',
        tone: PorcelainTone.info,
      ),
    );
  }
}
