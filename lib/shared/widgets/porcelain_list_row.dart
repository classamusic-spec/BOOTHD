import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_depth.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import 'porcelain_toast.dart';
import 'pressable.dart';
import 'tactile_surface.dart';

/// A list or settings row: optional icon, title, subtitle and trailing
/// widget. With [onPressed] (or a [disabledReason]) the whole row is one
/// control with a chevron; [selected] marks the current item of a
/// master-detail list with a raised key and a gold bar.
class PorcelainListRow extends StatelessWidget {
  const PorcelainListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onPressed,
    this.disabledReason,
    this.selected = false,
    this.showChevron = true,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onPressed;
  final String? disabledReason;
  final bool selected;
  final bool showChevron;

  bool get _interactive => onPressed != null || disabledReason != null;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final motion = PorcelainMotion.of(context);

    Widget content(PressState? state) {
      final enabled = state?.enabled ?? true;
      final foreground = enabled ? colors.ink : colors.inkDisabled;
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PorcelainSpace.md,
            vertical: PorcelainSpace.sm,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: PorcelainSize.icon,
                  fill: selected ? 1 : 0,
                  color: !enabled
                      ? colors.inkDisabled
                      : selected
                      ? colors.accentIcon
                      : colors.inkMuted,
                ),
                const SizedBox(width: PorcelainSpace.md),
              ],
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.text.titleSmall.copyWith(color: foreground),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.text.bodyMedium.copyWith(
                          color: enabled ? colors.inkMuted : colors.inkDisabled,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: PorcelainSpace.md),
                // At the row's end; may shrink (badges wrap) when large
                // text needs the room.
                Flexible(
                  flex: 2,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: trailing,
                  ),
                ),
              ],
              if (_interactive && showChevron) ...[
                const SizedBox(width: PorcelainSpace.xs),
                Icon(
                  enabled ? PorcelainIcons.chevron : PorcelainIcons.locked,
                  size: enabled ? PorcelainSize.icon : PorcelainSize.iconSmall,
                  color: enabled ? colors.inkMuted : colors.inkDisabled,
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (!_interactive) return MergeSemantics(child: content(null));

    final reason = disabledReason;
    return Pressable(
      onPressed: onPressed,
      selected: selected,
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
        final TactileLook look;
        if (state.pressed) {
          look = TactileLook(
            fillTop: colors.inset,
            fillBottom: colors.inset,
            inset: 0.5,
            travel: 1,
          );
        } else if (selected) {
          look = TactileLook(
            fillTop: colors.raised,
            fillBottom: colors.raisedShade,
            border: colors.hairline,
            elevation: PorcelainDepth.resting,
            highlight: 1,
          );
        } else if (state.hovered || state.focused) {
          look = TactileLook(
            fillTop: colors.selected,
            fillBottom: colors.selected,
          );
        } else {
          look = TactileLook(fillTop: clear, fillBottom: clear);
        }
        return TactileSurface(
          look: look,
          focused: state.focused,
          duration: state.pressed ? motion.press : motion.release,
          child: Stack(
            children: [
              content(state),
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: AnimatedContainer(
                    duration: motion.standard,
                    width: 4,
                    height: selected ? 28 : 0,
                    decoration: BoxDecoration(
                      color: colors.accentIcon,
                      borderRadius: const BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
