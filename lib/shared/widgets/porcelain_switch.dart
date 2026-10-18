import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_colors.dart';
import '../../core/design_system/porcelain_depth.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import 'porcelain_toast.dart';
import 'pressable.dart';
import 'tactile_surface.dart';

/// The visual of a switch: an inset well with a porcelain knob. On is shown
/// by the gold fill, the knob position and a check mark, never by colour
/// alone.
class PorcelainSwitchVisual extends StatelessWidget {
  const PorcelainSwitchVisual({
    super.key,
    required this.value,
    required this.enabled,
    this.focused = false,
  });

  final bool value;
  final bool enabled;
  final bool focused;

  static const _trackWidth = 60.0;
  static const _trackHeight = 34.0;
  static const _knob = 26.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    final motion = PorcelainMotion.of(context);
    final TactileLook track;
    if (!enabled) {
      track = TactileLook(
        fillTop: colors.disabledFill,
        fillBottom: colors.disabledFill,
        border: colors.hairline,
      );
    } else if (value) {
      track = TactileLook(
        fillTop: colors.primaryBottom,
        fillBottom: colors.primaryTop,
        border: colors.primaryEdge,
        borderWidth: 1.2,
        inset: 0.5,
      );
    } else {
      track = TactileLook(
        fillTop: colors.inset,
        fillBottom: colors.inset,
        border: colors.outline,
        inset: 0.7,
      );
    }
    return SizedBox(
      width: _trackWidth,
      height: _trackHeight,
      child: TactileSurface(
        look: track,
        shape: TactileShape.stadium,
        focused: focused,
        duration: motion.standard,
        child: AnimatedAlign(
          alignment: value
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          duration: motion.standard,
          curve: PorcelainMotion.ease,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: SizedBox.square(
              dimension: _knob,
              child: TactileSurface(
                look: TactileLook(
                  fillTop: enabled ? colors.raised : colors.disabledFill,
                  fillBottom: enabled
                      ? colors.raisedShade
                      : colors.disabledFill,
                  border: enabled ? colors.outline : colors.hairline,
                  elevation: enabled ? PorcelainDepth.raised : 0,
                  highlight: enabled ? 1 : 0,
                ),
                shape: TactileShape.circle,
                duration: motion.standard,
                child: AnimatedOpacity(
                  opacity: value ? 1 : 0,
                  duration: motion.standard,
                  child: Icon(
                    PorcelainIcons.check,
                    size: 16,
                    weight: 600,
                    color: enabled ? _checkColor(colors) : colors.inkDisabled,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _checkColor(PorcelainColors colors) => colors.accentText;
}

/// A switch with its own 48 dp touch target; [semanticLabel] names the
/// setting.
class PorcelainSwitch extends StatelessWidget {
  const PorcelainSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.disabledReason,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    final reason = disabledReason;
    return Pressable(
      onPressed: onChanged == null ? null : () => onChanged(!value),
      semanticLabel: semanticLabel,
      toggled: value,
      disabledReason: reason,
      onDisabledTap: reason == null
          ? null
          : () => PorcelainToast.show(
              context,
              reason,
              icon: PorcelainIcons.locked,
            ),
      builder: (context, state) => SizedBox(
        height: PorcelainSize.minTouchTarget,
        width: 72,
        child: Center(
          child: PorcelainSwitchVisual(
            value: value,
            enabled: state.enabled,
            focused: state.focused,
          ),
        ),
      ),
    );
  }
}

/// A full-width setting row that toggles when any part of it is tapped:
/// the large target operators need on a standing kiosk.
class PorcelainSwitchRow extends StatelessWidget {
  const PorcelainSwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
    this.disabledReason,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final motion = PorcelainMotion.of(context);
    final onChanged = this.onChanged;
    final reason = disabledReason;
    return Pressable(
      onPressed: onChanged == null ? null : () => onChanged(!value),
      semanticLabel: title,
      semanticHint: subtitle,
      toggled: value,
      disabledReason: reason,
      onDisabledTap: reason == null
          ? null
          : () => PorcelainToast.show(
              context,
              reason,
              icon: PorcelainIcons.locked,
            ),
      builder: (context, state) {
        final clear = colors.canvas.withValues(alpha: 0);
        final look = state.pressed
            ? TactileLook(
                fillTop: colors.inset,
                fillBottom: colors.inset,
                inset: 0.4,
              )
            : TactileLook(
                fillTop: state.hovered ? colors.selected : clear,
                fillBottom: state.hovered ? colors.selected : clear,
              );
        final foreground = state.enabled ? colors.ink : colors.inkDisabled;
        return TactileSurface(
          look: look,
          focused: state.focused,
          duration: state.pressed ? motion.press : motion.release,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PorcelainSpace.md,
                vertical: PorcelainSpace.sm,
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: foreground, size: PorcelainSize.icon),
                    const SizedBox(width: PorcelainSpace.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: theme.text.titleSmall.copyWith(
                            color: foreground,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: theme.text.bodyMedium.copyWith(
                              color: state.enabled
                                  ? colors.inkMuted
                                  : colors.inkDisabled,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: PorcelainSpace.md),
                  PorcelainSwitchVisual(value: value, enabled: state.enabled),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
