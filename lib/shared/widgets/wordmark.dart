import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_depth.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import 'botanical_ornament.dart';
import 'tactile_surface.dart';

/// How much of the wordmark shows.
enum WordmarkLayout {
  /// Title over subtitle, with a botanical flourish.
  full,

  /// Only a porcelain medallion with the monogram.
  medallion,

  /// A small medallion beside the title and subtitle, for a top bar.
  bar,
}

/// The product wordmark: a serif [title] over a spaced gold [subtitle],
/// with a botanical flourish, or shorter forms of it (see [layout]). Read
/// by screen readers as [semanticLabel].
class PorcelainWordmark extends StatelessWidget {
  const PorcelainWordmark({
    super.key,
    required this.title,
    required this.subtitle,
    required this.monogram,
    required this.semanticLabel,
    this.layout = WordmarkLayout.full,
  });

  final String title;
  final String subtitle;
  final String monogram;
  final String semanticLabel;
  final WordmarkLayout layout;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    Widget medallion(double size, TextStyle style) => SizedBox.square(
      dimension: size,
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
            style: style.copyWith(height: 1, color: colors.ink),
          ),
        ),
      ),
    );
    final Widget mark;
    if (layout == WordmarkLayout.medallion) {
      mark = Center(child: medallion(56, theme.text.headlineMedium));
    } else if (layout == WordmarkLayout.bar) {
      mark = Row(
        children: [
          medallion(40, theme.text.headlineSmall),
          const SizedBox(width: PorcelainSpace.sm),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text.headlineSmall.copyWith(height: 1.1),
                ),
                Text(
                  subtitle.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text.eyebrow,
                ),
              ],
            ),
          ),
        ],
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
