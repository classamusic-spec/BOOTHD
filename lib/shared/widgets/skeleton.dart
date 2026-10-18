import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';

/// Loading placeholder: soft porcelain bars with a slow sheen (still with
/// reduced motion). [semanticLabel] announces what is loading.
class SkeletonList extends StatefulWidget {
  const SkeletonList({super.key, required this.semanticLabel, this.rows = 3});

  final String semanticLabel;
  final int rows;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late final _sheen = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (PorcelainMotion.of(context).isReduced) {
      _sheen.stop();
    } else if (!_sheen.isAnimating) {
      _sheen.repeat();
    }
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    final reduced = PorcelainMotion.of(context).isReduced;
    Widget bar(double widthFactor, double height) => FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: widthFactor,
      child: AnimatedBuilder(
        animation: _sheen,
        builder: (context, _) {
          final t = reduced ? 0.5 : _sheen.value;
          return Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(height / 2)),
              gradient: LinearGradient(
                begin: Alignment(-1.5 + 3 * t, 0),
                end: Alignment(-0.5 + 3 * t, 0),
                colors: [colors.inset, colors.raised, colors.inset],
              ),
            ),
          );
        },
      ),
    );
    return Semantics(
      label: widget.semanticLabel,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Column(
          children: [
            for (var i = 0; i < widget.rows; i++)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: PorcelainSpace.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.inset,
                        borderRadius: PorcelainRadius.controlAll,
                      ),
                    ),
                    const SizedBox(width: PorcelainSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          bar(0.6 - 0.1 * (i % 2), 14),
                          const SizedBox(height: PorcelainSpace.xs),
                          bar(0.85 - 0.15 * (i % 3), 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
