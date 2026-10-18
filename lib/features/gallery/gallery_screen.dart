import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/studio_page.dart';

/// Operator gallery (S13). Sessions exist from M07 and export from M08;
/// until then it explains what will appear here and that guests never see
/// it.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  static const exportReason = 'Export arrives with the gallery in M08.';

  @override
  Widget build(BuildContext context) {
    return const StudioPage(
      header: StudioPageHeader(
        eyebrow: 'Studio',
        title: 'Gallery',
        subtitle:
            "Every session's original photos and finished compositions, "
            'stored on this tablet.',
        actions: [
          PorcelainButton(
            label: 'Export',
            icon: PorcelainIcons.export,
            onPressed: null,
            disabledReason: exportReason,
          ),
        ],
      ),
      children: [
        EmptyState(
          icon: PorcelainIcons.gallery,
          title: 'No sessions yet',
          message:
              'After guests use the booth, each session appears here with its '
              'originals, retakes and finished photo.',
          footnote: 'Guests never see this gallery. $exportReason',
        ),
      ],
    );
  }
}
