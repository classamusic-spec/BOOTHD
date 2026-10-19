import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import 'porcelain_button.dart';

/// Whole-number stepper (for example shots per session or countdown
/// seconds): minus, the value in tabular figures, plus. The value is also
/// adjustable through accessibility increase and decrease actions.
///
/// At a limit the matching button is disabled; [minimumReason] and
/// [maximumReason] say why when it is tapped (AC-0203).
class PorcelainStepper extends StatelessWidget {
  const PorcelainStepper({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.decreaseLabel,
    required this.increaseLabel,
    this.step = 1,
    this.formatValue,
    this.disabledReason,
    this.minimumReason,
    this.maximumReason,
  }) : assert(min <= max),
       assert(step > 0);

  final String label;
  final int value;
  final int min;
  final int max;

  /// The change per press, clamped to [min] and [max].
  final int step;
  final ValueChanged<int>? onChanged;

  /// Accessible names of the minus and plus buttons.
  final String decreaseLabel;
  final String increaseLabel;

  /// Renders the value, for example `3 s`; defaults to the number.
  final String Function(int value)? formatValue;
  final String? disabledReason;
  final String? minimumReason;
  final String? maximumReason;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final onChanged = this.onChanged;
    final canDecrease = onChanged != null && value > min;
    final canIncrease = onChanged != null && value < max;
    final lower = (value - step).clamp(min, max);
    final higher = (value + step).clamp(min, max);
    String show(int v) => formatValue?.call(v) ?? '$v';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PorcelainIconButton(
          icon: PorcelainIcons.remove,
          semanticLabel: decreaseLabel,
          onPressed: canDecrease ? () => onChanged(lower) : null,
          disabledReason: onChanged == null ? disabledReason : minimumReason,
        ),
        Semantics(
          label: label,
          value: show(value),
          increasedValue: canIncrease ? show(higher) : null,
          decreasedValue: canDecrease ? show(lower) : null,
          onIncrease: canIncrease ? () => onChanged(higher) : null,
          onDecrease: canDecrease ? () => onChanged(lower) : null,
          child: ExcludeSemantics(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 72),
              // Room either side for longer values ("14 days").
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PorcelainSpace.xs,
                ),
                child: AnimatedSwitcher(
                  duration: PorcelainMotion.of(context).standard,
                  child: Text(
                    show(value),
                    key: ValueKey(value),
                    textAlign: TextAlign.center,
                    style: theme.text.numeric.copyWith(
                      fontSize: 22,
                      height: 28 / 22,
                      color: onChanged == null
                          ? colors.inkDisabled
                          : colors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        PorcelainIconButton(
          icon: PorcelainIcons.add,
          semanticLabel: increaseLabel,
          onPressed: canIncrease ? () => onChanged(higher) : null,
          disabledReason: onChanged == null ? disabledReason : maximumReason,
        ),
        const SizedBox(width: PorcelainSpace.xxs),
      ],
    );
  }
}
