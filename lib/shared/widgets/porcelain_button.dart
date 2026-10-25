import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_colors.dart';
import '../../core/design_system/porcelain_depth.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import 'porcelain_spinner.dart';
import 'porcelain_toast.dart';
import 'pressable.dart';
import 'tactile_surface.dart';
import 'tone.dart';

enum PorcelainButtonVariant {
  /// Champagne-gold: the one main action of a screen.
  primary,

  /// Raised porcelain with an outline.
  secondary,

  /// Gold text only, for low-emphasis actions.
  quiet,

  /// Outlined in the danger tone, for destructive actions.
  danger,
}

enum PorcelainButtonSize {
  compact(48, 20, 20),
  regular(56, 24, 20),
  large(64, 32, 22),

  /// Guest primary actions (>=72 dp, UX-01).
  guest(96, 48, 32);

  const PorcelainButtonSize(this.height, this.padding, this.iconSize);

  final double height;
  final double padding;
  final double iconSize;
}

/// The result of the last action, shown on the button until cleared.
enum PorcelainButtonFeedback { success, error }

/// Pill button with tactile press, focus ring, busy and result states, and
/// disabled states that explain themselves (UX-07, AC-0202).
class PorcelainButton extends StatelessWidget {
  const PorcelainButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = PorcelainButtonVariant.secondary,
    this.size = PorcelainButtonSize.regular,
    this.disabledReason,
    this.busy = false,
    this.busyLabel,
    this.feedback,
    this.expand = false,
    this.semanticHint,
    this.autofocus = false,
    this.caps = false,
  });

  final String label;

  /// Null disables the button; give a [disabledReason] whenever the reason
  /// is not already visible next to it.
  final VoidCallback? onPressed;
  final IconData? icon;
  final PorcelainButtonVariant variant;
  final PorcelainButtonSize size;
  final String? disabledReason;

  /// Shows progress and ignores presses, without looking disabled.
  final bool busy;

  /// Announced and shown instead of [label] while [busy].
  final String? busyLabel;
  final PorcelainButtonFeedback? feedback;

  /// Fill the available width.
  final bool expand;
  final String? semanticHint;
  final bool autofocus;

  /// Shows the label in spaced capitals, as guest actions do (CR-002);
  /// screen readers still get [label] as written.
  final bool caps;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final motion = PorcelainMotion.of(context);
    final enabled = onPressed != null && !busy;
    final reason = disabledReason;
    final text = busy ? (busyLabel ?? label) : label;

    return Pressable(
      onPressed: enabled ? onPressed : null,
      busy: busy,
      semanticLabel: text,
      semanticHint: semanticHint,
      disabledReason: busy ? null : reason,
      onDisabledTap: busy || reason == null
          ? null
          : () => PorcelainToast.show(
              context,
              reason,
              icon: PorcelainIcons.locked,
            ),
      autofocus: autofocus,
      builder: (context, state) {
        final active = enabled || busy;
        final foreground = _foreground(colors, active: active);
        final style = switch (size) {
          PorcelainButtonSize.guest => theme.text.guestAction,
          PorcelainButtonSize.large => theme.text.labelLarge.copyWith(
            fontSize: 17,
          ),
          _ => theme.text.labelLarge,
        }.copyWith(color: foreground);
        final leading = busy
            ? PorcelainSpinner(color: foreground, size: size.iconSize)
            : switch (feedback) {
                PorcelainButtonFeedback.success => Icon(
                  PorcelainIcons.success,
                  color: _feedbackColor(colors, PorcelainTone.success),
                  size: size.iconSize,
                  fill: 1,
                ),
                PorcelainButtonFeedback.error => Icon(
                  PorcelainIcons.error,
                  color: _feedbackColor(colors, PorcelainTone.danger),
                  size: size.iconSize,
                  fill: 1,
                ),
                null when icon != null => Icon(
                  icon,
                  color: foreground,
                  size: size.iconSize,
                ),
                null => null,
              };

        return ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: size.height,
            minWidth: size.height,
          ),
          child: TactileSurface(
            look: _look(colors, state, active: active),
            shape: TactileShape.stadium,
            focused: state.focused,
            duration: state.pressed ? motion.press : motion.release,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.padding,
                vertical: PorcelainSpace.xs,
              ),
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leading != null) ...[
                    leading,
                    SizedBox(width: size.iconSize / 2),
                  ],
                  Flexible(
                    child: Text(
                      caps ? text.toUpperCase() : text,
                      style: caps
                          ? style.copyWith(
                              fontSize: style.fontSize! * 0.8,
                              letterSpacing: 2.2,
                            )
                          : style,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _feedbackColor(PorcelainColors colors, PorcelainTone tone) =>
      variant == PorcelainButtonVariant.primary
      ? colors.onPrimary
      : tone.foreground(colors);

  Color _foreground(PorcelainColors colors, {required bool active}) {
    if (!active) return colors.inkDisabled;
    return switch (variant) {
      PorcelainButtonVariant.primary => colors.onPrimary,
      PorcelainButtonVariant.secondary => colors.ink,
      PorcelainButtonVariant.quiet => colors.accentText,
      PorcelainButtonVariant.danger => colors.danger,
    };
  }

  TactileLook _look(
    PorcelainColors colors,
    PressState state, {
    required bool active,
  }) {
    if (!active) {
      return TactileLook(
        fillTop: variant == PorcelainButtonVariant.quiet
            ? colors.canvas.withValues(alpha: 0)
            : colors.disabledFill,
        fillBottom: variant == PorcelainButtonVariant.quiet
            ? colors.canvas.withValues(alpha: 0)
            : colors.disabledFill,
        border: variant == PorcelainButtonVariant.quiet
            ? null
            : colors.hairline,
      );
    }
    final feedbackBorder = switch (feedback) {
      PorcelainButtonFeedback.success => colors.success,
      PorcelainButtonFeedback.error => colors.danger,
      null => null,
    };
    final lifted = state.hovered || state.focused;
    switch (variant) {
      case PorcelainButtonVariant.primary:
        if (state.pressed) {
          return TactileLook(
            fillTop: Color.lerp(colors.primaryBottom, colors.primaryEdge, 0.1)!,
            fillBottom: colors.primaryBottom,
            border: feedbackBorder ?? colors.primaryEdge,
            borderWidth: 1.2,
            elevation: 0.2,
            inset: 0.9,
            travel: 1,
          );
        }
        return TactileLook(
          fillTop: lifted
              ? Color.lerp(colors.primaryTop, colors.raised, 0.18)!
              : colors.primaryTop,
          fillBottom: colors.primaryBottom,
          border: feedbackBorder ?? colors.primaryEdge,
          borderWidth: 1.2,
          elevation: lifted ? PorcelainDepth.lifted : PorcelainDepth.raised,
          highlight: 0.9,
        );
      case PorcelainButtonVariant.secondary:
      case PorcelainButtonVariant.danger:
        final edge = variant == PorcelainButtonVariant.danger
            ? colors.danger
            : colors.outline;
        if (state.pressed) {
          return TactileLook(
            fillTop: colors.inset,
            fillBottom: colors.raisedShade,
            border: feedbackBorder ?? edge,
            elevation: 0.1,
            inset: 0.8,
            travel: 1,
          );
        }
        return TactileLook(
          fillTop: colors.raised,
          fillBottom: colors.raisedShade,
          border: feedbackBorder ?? edge,
          borderWidth: variant == PorcelainButtonVariant.danger ? 1.2 : 1,
          elevation: lifted ? PorcelainDepth.lifted : PorcelainDepth.raised,
          highlight: 1,
        );
      case PorcelainButtonVariant.quiet:
        final clear = colors.canvas.withValues(alpha: 0);
        if (state.pressed) {
          return TactileLook(
            fillTop: colors.inset,
            fillBottom: colors.inset,
            inset: 0.5,
            travel: 1,
            border: feedbackBorder,
          );
        }
        return TactileLook(
          fillTop: lifted ? colors.selected : clear,
          fillBottom: lifted ? colors.selected : clear,
          border: feedbackBorder,
        );
    }
  }
}

/// Round icon-only button; [semanticLabel] is required because there is no
/// visible text.
class PorcelainIconButton extends StatelessWidget {
  const PorcelainIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.disabledReason,
    this.size = PorcelainSize.minTouchTarget,
    this.selected,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final String? disabledReason;
  final double size;

  /// For a button that shows where the operator is (e.g. a section in a
  /// top bar): when true, a gold edge and a filled gold icon. Null for an
  /// ordinary button.
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    final motion = PorcelainMotion.of(context);
    final reason = disabledReason;
    final on = selected ?? false;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
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
        final enabled = state.enabled;
        final look = !enabled
            ? TactileLook(
                fillTop: colors.disabledFill,
                fillBottom: colors.disabledFill,
                border: colors.hairline,
              )
            : state.pressed
            ? TactileLook(
                fillTop: colors.inset,
                fillBottom: colors.raisedShade,
                border: colors.outline,
                inset: 0.8,
                travel: 1,
              )
            : TactileLook(
                fillTop: colors.raised,
                fillBottom: colors.raisedShade,
                border: on ? colors.primaryEdge : colors.outline,
                borderWidth: on ? 1.5 : 1,
                elevation: state.hovered || state.focused
                    ? PorcelainDepth.lifted
                    : PorcelainDepth.raised,
                highlight: 1,
              );
        return SizedBox.square(
          dimension: size,
          child: TactileSurface(
            look: look,
            shape: TactileShape.circle,
            focused: state.focused,
            duration: state.pressed ? motion.press : motion.release,
            child: Center(
              child: Icon(
                icon,
                size: PorcelainSize.icon,
                fill: on ? 1 : 0,
                color: !enabled
                    ? colors.inkDisabled
                    : on
                    ? colors.accentIcon
                    : colors.ink,
              ),
            ),
          ),
        );
      },
    );
  }
}
