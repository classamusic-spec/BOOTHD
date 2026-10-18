import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/porcelain_list_row.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/tone.dart';

/// Output and printing (S16). Print sizes are fixed facts of the renderer;
/// output profiles arrive in M04/M08 and printing waits for a chosen printer,
/// so the printer is shown as not configured rather than offered.
class OutputSettings extends StatelessWidget {
  const OutputSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Printer',
          subtitle: 'This release saves print-ready files; it does not print.',
        ),
        PorcelainCard(
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
        SizedBox(height: PorcelainSpace.xxxl),
        SectionHeader(
          title: 'Print sizes',
          subtitle: 'Exported at 300 dpi. Output profiles arrive in M04.',
        ),
        PorcelainCard(
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
