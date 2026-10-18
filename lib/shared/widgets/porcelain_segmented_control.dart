import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_depth.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import 'pressable.dart';
import 'tactile_surface.dart';

/// One option of a [PorcelainSegmentedControl].
@immutable
final class PorcelainSegment<T> {
  const PorcelainSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Mutually exclusive choice: equal-width segments in an inset track with a
/// raised porcelain thumb that slides to the selection. The selected
/// segment also has a gilded edge and bolder label, so it never relies on
/// fill alone.
class PorcelainSegmentedControl<T> extends StatelessWidget {
  const PorcelainSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  }) : assert(segments.length >= 2);

  final List<PorcelainSegment<T>> segments;
  final T selected;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final motion = PorcelainMotion.of(context);
    final index = segments.indexWhere((s) => s.value == selected);
    final count = segments.length;
    final onChanged = this.onChanged;

    return IntrinsicWidth(
      child: TactileSurface(
        duration: motion.standard,
        shape: TactileShape.stadium,
        look: TactileLook(
          fillTop: colors.inset,
          fillBottom: colors.inset,
          border: colors.outline,
          inset: 0.6,
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Stack(
            children: [
              if (index >= 0)
                Positioned.fill(
                  child: AnimatedAlign(
                    duration: motion.standard,
                    curve: PorcelainMotion.ease,
                    alignment: Alignment(
                      count == 1 ? 0 : -1 + 2 * index / (count - 1),
                      0,
                    ),
                    child: FractionallySizedBox(
                      widthFactor: 1 / count,
                      heightFactor: 1,
                      child: TactileSurface(
                        duration: motion.standard,
                        shape: TactileShape.stadium,
                        look: TactileLook(
                          fillTop: colors.raised,
                          fillBottom: colors.raisedShade,
                          border: colors.primaryEdge,
                          borderWidth: 1.5,
                          elevation: PorcelainDepth.raised,
                          highlight: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  for (final segment in segments)
                    Expanded(
                      child: Pressable(
                        onPressed: onChanged == null
                            ? null
                            : () => onChanged(segment.value),
                        semanticLabel: segment.label,
                        selected: segment.value == selected,
                        inMutuallyExclusiveGroup: true,
                        builder: (context, state) {
                          final isSelected = segment.value == selected;
                          final color = !state.enabled
                              ? colors.inkDisabled
                              : isSelected
                              ? colors.ink
                              : colors.inkMuted;
                          return TactileSurface(
                            duration: motion.standard,
                            shape: TactileShape.stadium,
                            focused: state.focused,
                            look: TactileLook(
                              fillTop: colors.inset.withValues(alpha: 0),
                              fillBottom: colors.inset.withValues(alpha: 0),
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: PorcelainSize.minTouchTarget,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: PorcelainSpace.lg,
                                  vertical: PorcelainSpace.xs,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (segment.icon != null) ...[
                                      Icon(
                                        segment.icon,
                                        size: PorcelainSize.iconSmall,
                                        color: color,
                                        fill: isSelected ? 1 : 0,
                                      ),
                                      const SizedBox(width: PorcelainSpace.xs),
                                    ],
                                    Flexible(
                                      child: Text(
                                        segment.label,
                                        textAlign: TextAlign.center,
                                        style:
                                            (isSelected
                                                    ? theme.text.labelLarge
                                                    : theme.text.labelMedium
                                                          .copyWith(
                                                            fontSize: 16,
                                                          ))
                                                .copyWith(color: color),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
