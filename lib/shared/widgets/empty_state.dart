import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_depth.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import 'botanical_ornament.dart';
import 'tactile_surface.dart';
import 'tone.dart';

/// A calm, centred message for empty, error and not-yet-available states:
/// an icon medallion between two sprigs, a serif title, an explanation and
/// optional actions. [tone] colours the medallion icon for errors and
/// warnings; the words carry the meaning.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actions = const [],
    this.footnote,
    this.tone = PorcelainTone.info,
  });

  final IconData icon;
  final String title;
  final String message;
  final List<Widget> actions;
  final String? footnote;
  final PorcelainTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final iconColor = tone == PorcelainTone.info
        ? colors.accentIcon
        : tone.foreground(colors);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: PorcelainSpace.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BotanicalOrnament.sprig(
                    width: 76,
                    height: 56,
                    leaves: 5,
                    flip: true,
                  ),
                  const SizedBox(width: PorcelainSpace.xs),
                  SizedBox.square(
                    dimension: 88,
                    child: TactileSurface(
                      duration: Duration.zero,
                      shape: TactileShape.circle,
                      look: TactileLook(
                        fillTop: colors.raised,
                        fillBottom: colors.raisedShade,
                        border: colors.hairline,
                        elevation: PorcelainDepth.raised,
                        highlight: 1,
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          size: 36,
                          color: iconColor,
                          weight: 300,
                          opticalSize: 40,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: PorcelainSpace.xs),
                  const BotanicalOrnament.sprig(
                    width: 76,
                    height: 56,
                    leaves: 5,
                  ),
                ],
              ),
              const SizedBox(height: PorcelainSpace.xl),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.text.headlineMedium,
                ),
              ),
              const SizedBox(height: PorcelainSpace.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.text.bodyLarge.copyWith(color: colors.inkMuted),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: PorcelainSpace.xl),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: PorcelainSpace.sm,
                  runSpacing: PorcelainSpace.sm,
                  children: actions,
                ),
              ],
              if (footnote != null) ...[
                const SizedBox(height: PorcelainSpace.lg),
                Text(
                  footnote!,
                  textAlign: TextAlign.center,
                  style: theme.text.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
