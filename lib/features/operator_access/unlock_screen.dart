import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/access/access_controller.dart';
import '../../core/booth/booth_providers.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../shared/guest/guest_layout.dart';
import '../../shared/operator_access/pin_layout.dart';
import '../../shared/operator_access/unlock_panel.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/wordmark.dart';

/// The Studio's lock screen (UX-04): every cold start and every Lock lands
/// here. It shows the booth's name and nothing else about what is behind
/// it.
class UnlockScreen extends ConsumerWidget {
  const UnlockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.porcelain;
    final boothName = ref.watch(startupProvider).value?.profile.name;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: GuestBackdrop(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.all(PorcelainSpace.xl),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 2 * PorcelainSpace.xl,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: pinCardWidth(MediaQuery.sizeOf(context)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PorcelainWordmark(
                            title: 'Porcelain',
                            subtitle: boothName ?? 'Photo Booth Studio',
                            monogram: 'P',
                            semanticLabel: boothName == null
                                ? 'Porcelain Photo Booth'
                                : 'Porcelain Photo Booth, $boothName',
                          ),
                          const SizedBox(height: PorcelainSpace.xl),
                          PorcelainCard(
                            radius: PorcelainRadius.dialog,
                            padding: const EdgeInsets.symmetric(
                              horizontal: PorcelainSpace.xl,
                              vertical: PorcelainSpace.xxl,
                            ),
                            child: UnlockPanel(
                              onUnlocked: (proof) => ref
                                  .read(accessControllerProvider.notifier)
                                  .unlock(proof),
                            ),
                          ),
                          const SizedBox(height: PorcelainSpace.lg),
                          Text(
                            'The Studio is locked.',
                            style: theme.text.bodyMedium.copyWith(
                              color: theme.colors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
