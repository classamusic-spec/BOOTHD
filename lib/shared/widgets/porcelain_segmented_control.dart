import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_depth.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import 'porcelain_toast.dart';
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
/// fill alone. When room is tight the segments' side padding gives way
/// first; where even that is not enough (a narrow window, or very large
/// text) the track keeps its natural width and scrolls sideways, so no
/// label breaks inside a word.
class PorcelainSegmentedControl<T> extends StatelessWidget {
  const PorcelainSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.disabledReason,
  }) : assert(segments.length >= 2);

  final List<PorcelainSegment<T>> segments;
  final T selected;

  /// Null disables every segment; give a [disabledReason] then.
  final ValueChanged<T>? onChanged;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final content = _widestContent(context);
    // The track's own padding, and a pixel for rounding.
    const track = 9.0;
    double widthWith(double padding) =>
        ((content + 2 * padding) * segments.length + track).ceilToDouble();
    final natural = widthWith(PorcelainSpace.lg);
    final minimum = widthWith(PorcelainSpace.xs);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth || constraints.maxWidth >= minimum) {
          // When room is tight, the segments' side padding gives way first.
          final width = math.min(constraints.maxWidth, natural);
          final padding = ((width - track) / segments.length - content) / 2;
          return _track(
            context,
            padding.clamp(PorcelainSpace.xs, PorcelainSpace.lg),
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: natural,
            child: _track(context, PorcelainSpace.lg),
          ),
        );
      },
    );
  }

  Widget _track(BuildContext context, double padding) {
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
                        disabledReason: disabledReason,
                        onDisabledTap: disabledReason == null
                            ? null
                            : () => PorcelainToast.show(
                                context,
                                disabledReason!,
                                icon: PorcelainIcons.locked,
                              ),
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
                                padding: EdgeInsets.symmetric(
                                  horizontal: padding,
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

  /// The widest segment's icon and label, in either weight.
  double _widestContent(BuildContext context) {
    final text = context.porcelain.text;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    double measure(String label, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    var widest = 0.0;
    for (final segment in segments) {
      final label = math.max(
        measure(segment.label, text.labelLarge),
        measure(segment.label, text.labelMedium.copyWith(fontSize: 16)),
      );
      final icon = segment.icon == null
          ? 0.0
          : PorcelainSize.iconSmall + PorcelainSpace.xs;
      widest = math.max(widest, icon + label);
    }
    return widest;
  }
}
