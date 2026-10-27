import 'package:flutter/material.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../shared/widgets/atelier_showcase.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/studio_material.dart';

/// Editorial first impression, with setup actions always before artwork
/// in the reading order and a single-column layout for narrow windows.
class WelcomeAtelier extends StatelessWidget {
  const WelcomeAtelier({super.key, required this.onBegin, this.onRestore});

  final VoidCallback onBegin;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    return StudioMaterial(
      area: StudioMaterialArea.canvas,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final padding = constraints.maxWidth < 600 ? 28.0 : 56.0;
            final introduction = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WELCOME TO YOUR STUDIO', style: theme.text.eyebrow),
                const SizedBox(height: 20),
                Semantics(
                  header: true,
                  child: Text(
                    'Beautiful moments.\nMade to keep.',
                    style: theme.text.displayLarge.copyWith(
                      fontSize: wide ? 64 : 46,
                      height: 1.04,
                      letterSpacing: -1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Your celebration, your signature style. Create a photo '
                  'booth with beautiful artwork and memories worth keeping.',
                  style: theme.text.bodyLarge.copyWith(color: colors.inkMuted),
                ),
                const SizedBox(height: 28),
                PorcelainButton(
                  label: 'Begin setup',
                  icon: PorcelainIcons.chevron,
                  variant: PorcelainButtonVariant.primary,
                  size: PorcelainButtonSize.large,
                  onPressed: onBegin,
                ),
                const SizedBox(height: 16),
                Text(
                  'A few simple steps. No account needed.',
                  style: theme.text.bodySmall.copyWith(color: colors.inkMuted),
                ),
                if (onRestore != null) ...[
                  const SizedBox(height: 12),
                  PorcelainButton(
                    label: 'Restore from a backup',
                    icon: PorcelainIcons.restoreBackup,
                    variant: PorcelainButtonVariant.quiet,
                    onPressed: onRestore,
                  ),
                ],
              ],
            );
            return SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Semantics(
                              label: 'Porcelain Photo Booth',
                              child: ExcludeSemantics(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Porcelain',
                                      style: theme.text.headlineLarge,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'PHOTO BOOTH STUDIO',
                                      style: theme.text.eyebrow,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Icon(
                            PorcelainIcons.camera,
                            color: colors.accentIcon,
                            size: 32,
                          ),
                        ],
                      ),
                      SizedBox(height: wide ? 72 : 40),
                      if (wide)
                        Row(
                          children: [
                            Expanded(child: introduction),
                            const SizedBox(width: 56),
                            const Expanded(child: AtelierShowcase(height: 460)),
                          ],
                        )
                      else ...[
                        introduction,
                        const SizedBox(height: 32),
                        const AtelierShowcase(height: 260),
                      ],
                      const SizedBox(height: 32),
                      Divider(color: colors.divider),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 32,
                        runSpacing: 16,
                        children: [
                          _Note(
                            icon: PorcelainIcons.templates,
                            label: 'Artfully designed templates',
                          ),
                          _Note(
                            icon: PorcelainIcons.security,
                            label: 'Private by design',
                          ),
                          _Note(
                            icon: PorcelainIcons.gallery,
                            label: 'Full-resolution keepsakes',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: theme.colors.accentText),
        const SizedBox(width: 10),
        Flexible(child: Text(label, style: theme.text.bodySmall)),
      ],
    );
  }
}
