import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_depth.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import 'botanical_ornament.dart';
import 'tactile_surface.dart';

/// The product wordmark: a serif [title] over a spaced gold [subtitle],
/// with a botanical flourish. [compact] shows only a porcelain medallion
/// with [monogram]. Read by screen readers as [semanticLabel].
class PorcelainWordmark extends StatelessWidget {
  const PorcelainWordmark({
    super.key,
    required this.title,
    required this.subtitle,
    required this.monogram,
    required this.semanticLabel,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final String monogram;
  final String semanticLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final Widget mark;
    if (compact) {
      mark = Center(
        child: SizedBox.square(
          dimension: 56,
          child: TactileSurface(
            duration: Duration.zero,
            shape: TactileShape.circle,
            look: TactileLook(
              fillTop: colors.raised,
              fillBottom: colors.raisedShade,
              border: colors.primaryEdge,
              borderWidth: 1.5,
              elevation: PorcelainDepth.raised,
              highlight: 1,
            ),
            child: Center(
              child: Text(
                monogram,
                style: theme.text.headlineMedium.copyWith(
                  height: 1,
                  color: colors.ink,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      mark = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: theme.text.headlineLarge.copyWith(letterSpacing: 0.4),
          ),
          const SizedBox(height: 2),
          Text(subtitle.toUpperCase(), style: theme.text.eyebrow),
          const SizedBox(height: PorcelainSpace.sm),
          const BotanicalOrnament.flourish(width: 120, height: 20),
        ],
      );
    }
    return Semantics(
      label: semanticLabel,
      header: true,
      child: ExcludeSemantics(child: mark),
    );
  }
}
