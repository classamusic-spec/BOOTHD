import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/routing/route_paths.dart';
import '../../shared/guest/guest_welcome.dart';
import '../../shared/guest/guest_welcome_sample.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_toast.dart';

/// Operator preview of the guest welcome screen (S20 skeleton), full size
/// and adapting to the window. Not Booth Mode: an operator bar above the
/// guest area offers Close, and Start only explains that sessions arrive in
/// M07. The guest area itself has no other controls (AC-0210).
class GuestPreviewScreen extends StatelessWidget {
  const GuestPreviewScreen({super.key});

  static const startMessage =
      'Preview only. Guests start their session here once Booth Mode '
      'arrives in M07.';

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    return Scaffold(
      body: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.rail,
              border: Border(bottom: BorderSide(color: colors.divider)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PorcelainSpace.xl,
                  vertical: PorcelainSpace.sm,
                ),
                child: Row(
                  children: [
                    Icon(PorcelainIcons.preview, color: colors.accentIcon),
                    const SizedBox(width: PorcelainSpace.sm),
                    Expanded(
                      child: Text(
                        'Guest screen preview',
                        style: theme.text.titleSmall,
                      ),
                    ),
                    PorcelainButton(
                      label: 'Close preview',
                      icon: PorcelainIcons.close,
                      size: PorcelainButtonSize.compact,
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go(RoutePaths.dashboard),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GuestWelcome(
              copy: sampleGuestWelcomeCopy,
              onStart: () => PorcelainToast.show(context, startMessage),
            ),
          ),
        ],
      ),
    );
  }
}
