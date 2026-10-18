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

/// A porcelain card. Static by default; with [onPressed] (or a
/// [disabledReason]) it becomes one tactile control whose text is read as a
/// single accessible button. [selected] adds a gilded edge and check mark,
/// so selection never relies on the fill colour alone.
class PorcelainCard extends StatelessWidget {
  const PorcelainCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(PorcelainSpace.xl),
    this.onPressed,
    this.disabledReason,
    this.selected = false,
    this.semanticLabel,
    this.radius = PorcelainRadius.card,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onPressed;
  final String? disabledReason;
  final bool selected;
  final String? semanticLabel;
  final double radius;

  bool get _interactive => onPressed != null || disabledReason != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    if (!_interactive) {
      return TactileSurface(
        duration: PorcelainMotion.of(context).standard,
        radius: radius,
        look: _restLook(colors),
        child: Padding(padding: padding, child: child),
      );
    }
    final motion = PorcelainMotion.of(context);
    final reason = disabledReason;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      disabledReason: reason,
      selected: selected,
      onDisabledTap: reason == null
          ? null
          : () => PorcelainToast.show(
              context,
              reason,
              icon: PorcelainIcons.locked,
            ),
      builder: (context, state) {
        final TactileLook look;
        if (!state.enabled) {
          look = TactileLook(
            fillTop: colors.disabledFill,
            fillBottom: colors.disabledFill,
            border: colors.hairline,
          );
        } else if (state.pressed) {
          look = TactileLook(
            fillTop: colors.inset,
            fillBottom: selected ? colors.selected : colors.surface,
            border: selected ? colors.primaryEdge : colors.outline,
            borderWidth: selected ? 2 : 1,
            elevation: 0.2,
            inset: 0.6,
            travel: 1,
          );
        } else if (selected) {
          look = TactileLook(
            fillTop: colors.selected,
            fillBottom: colors.selected,
            border: colors.primaryEdge,
            borderWidth: 2,
            elevation: PorcelainDepth.raised,
            highlight: 0.6,
          );
        } else if (state.hovered || state.focused) {
          look = _restLook(colors)
              .withElevation(PorcelainDepth.lifted, border: colors.outline);
        } else {
          look = _restLook(colors);
        }
        return TactileSurface(
          look: look,
          radius: radius,
          focused: state.focused,
          duration: state.pressed ? motion.press : motion.release,
          child: Stack(
            children: [
              Padding(padding: padding, child: child),
              if (selected)
                PositionedDirectional(
                  top: PorcelainSpace.sm,
                  end: PorcelainSpace.sm,
                  child: _SelectedMark(colors: colors),
                ),
            ],
          ),
        );
      },
    );
  }

  TactileLook _restLook(PorcelainColors colors) => TactileLook(
    fillTop: colors.raised,
    fillBottom: colors.surface,
    border: colors.hairline,
    elevation: PorcelainDepth.resting,
    highlight: 0.8,
  );
}

extension on TactileLook {
  TactileLook withElevation(double elevation, {Color? border}) => TactileLook(
    fillTop: fillTop,
    fillBottom: fillBottom,
    border: border ?? this.border,
    borderWidth: borderWidth,
    elevation: elevation,
    inset: inset,
    highlight: highlight,
    travel: travel,
  );
}

class _SelectedMark extends StatelessWidget {
  const _SelectedMark({required this.colors});

  final PorcelainColors colors;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.primaryTop, colors.primaryBottom],
          ),
          border: Border.all(color: colors.primaryEdge, width: 1.2),
        ),
        child: Icon(
          PorcelainIcons.check,
          size: 18,
          color: colors.onPrimary,
          weight: 600,
        ),
      ),
    );
  }
}
