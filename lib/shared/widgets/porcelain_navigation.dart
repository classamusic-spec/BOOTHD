import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_colors.dart';
import '../../core/design_system/porcelain_depth.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import 'pressable.dart';
import 'studio_material.dart';
import 'tactile_surface.dart';

/// One section in [PorcelainNavigation].
@immutable
final class PorcelainDestination {
  const PorcelainDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Studio navigation in two densities: a full sidebar (icon and label side
/// by side, with [header] and [footer]) and a compact rail (label under the
/// icon). The caller picks the density from the window it actually has.
///
/// The selected section is shown by a raised porcelain key, a gold bar or
/// pill edge, a filled icon and a bolder label, and is exposed to
/// accessibility as selected.
class PorcelainNavigation extends StatelessWidget {
  const PorcelainNavigation({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.extended,
    this.header,
    this.footer,
  });

  final List<PorcelainDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool extended;
  final Widget? header;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final width = extended
        ? PorcelainBreakpoints.sidebarWidth
        : (PorcelainBreakpoints.compactRailWidth * textScale).clamp(
            PorcelainBreakpoints.compactRailWidth,
            180.0,
          );
    final items = [
      for (var i = 0; i < destinations.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: PorcelainSpace.xxs),
          child: extended
              ? _SidebarItem(
                  destination: destinations[i],
                  selected: i == selectedIndex,
                  onPressed: () => onSelected(i),
                )
              : _RailItem(
                  destination: destinations[i],
                  selected: i == selectedIndex,
                  onPressed: () => onSelected(i),
                ),
        ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.rail,
        border: BorderDirectional(end: BorderSide(color: colors.divider)),
      ),
      child: SizedBox(
        width: width,
        child: StudioMaterial(
          area: StudioMaterialArea.rail,
          child: SafeArea(
            right: false,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: extended
                            ? PorcelainSpace.lg
                            : PorcelainSpace.xs,
                        vertical: PorcelainSpace.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (header != null) ...[
                            header!,
                            SizedBox(
                              height: extended
                                  ? PorcelainSpace.xxl
                                  : PorcelainSpace.xl,
                            ),
                          ],
                          ...items,
                          const Spacer(),
                          if (footer != null) ...[
                            const SizedBox(height: PorcelainSpace.xl),
                            footer!,
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Studio navigation along the bottom edge, for windows too narrow for a
/// rail: the sections side by side, icon over label, the selected one on a
/// raised porcelain key as in the rail. [selectedIndex] is null while the
/// Studio shows a section reached another way.
class PorcelainBottomNavigation extends StatelessWidget {
  const PorcelainBottomNavigation({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<PorcelainDestination> destinations;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.rail,
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      child: StudioMaterial(
        area: StudioMaterialArea.rail,
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: PorcelainSpace.xxs),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PorcelainSpace.xxs,
              vertical: PorcelainSpace.xxs,
            ),
            // Labels grow with the text size, but not past what a bar of
            // equal slots can hold.
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: Row(
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    Expanded(
                      child: _RailItem(
                        destination: destinations[i],
                        selected: i == selectedIndex,
                        onPressed: () => onSelected(i),
                        dense: true,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

TactileLook _itemLook(
  PorcelainColors colors,
  PressState state, {
  required bool selected,
}) {
  final clear = colors.rail.withValues(alpha: 0);
  if (state.pressed) {
    return TactileLook(
      fillTop: colors.inset,
      fillBottom: colors.inset,
      inset: 0.6,
      travel: 1,
      border: selected ? colors.hairline : null,
    );
  }
  if (selected) {
    return TactileLook(
      fillTop: colors.raised,
      fillBottom: colors.raisedShade,
      border: colors.hairline,
      elevation: PorcelainDepth.resting,
      highlight: 1,
    );
  }
  if (state.hovered || state.focused) {
    return TactileLook(fillTop: colors.selected, fillBottom: colors.selected);
  }
  return TactileLook(fillTop: clear, fillBottom: clear);
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.onPressed,
  });

  final PorcelainDestination destination;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final motion = PorcelainMotion.of(context);
    return Pressable(
      onPressed: onPressed,
      semanticLabel: destination.label,
      selected: selected,
      builder: (context, state) => TactileSurface(
        look: _itemLook(colors, state, selected: selected),
        focused: state.focused,
        duration: state.pressed ? motion.press : motion.release,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              AnimatedContainer(
                duration: motion.standard,
                width: 4,
                height: 24,
                margin: const EdgeInsetsDirectional.only(
                  start: PorcelainSpace.xs,
                  end: PorcelainSpace.sm,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? colors.accentIcon
                      : colors.accentIcon.withValues(alpha: 0),
                  borderRadius: const BorderRadius.all(Radius.circular(2)),
                ),
              ),
              Icon(
                destination.icon,
                size: PorcelainSize.icon,
                fill: selected ? 1 : 0,
                color: selected ? colors.accentIcon : colors.inkMuted,
              ),
              const SizedBox(width: PorcelainSpace.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    top: PorcelainSpace.xs,
                    bottom: PorcelainSpace.xs,
                    end: PorcelainSpace.md,
                  ),
                  child: Text(
                    destination.label,
                    style: selected
                        ? theme.text.titleSmall
                        : theme.text.labelLarge.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.onPressed,
    this.dense = false,
  });

  final PorcelainDestination destination;
  final bool selected;
  final VoidCallback onPressed;

  /// In a bottom bar: a shorter key, and the label on one line.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final motion = PorcelainMotion.of(context);
    return Pressable(
      onPressed: onPressed,
      semanticLabel: destination.label,
      selected: selected,
      builder: (context, state) => ConstrainedBox(
        constraints: BoxConstraints(minHeight: dense ? 60 : 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: PorcelainSpace.xxs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: dense ? 56 : 64,
                height: dense ? 32 : 36,
                child: TactileSurface(
                  look: _itemLook(colors, state, selected: selected),
                  shape: TactileShape.stadium,
                  focused: state.focused,
                  duration: state.pressed ? motion.press : motion.release,
                  child: Center(
                    child: Icon(
                      destination.icon,
                      size: PorcelainSize.icon,
                      fill: selected ? 1 : 0,
                      color: selected ? colors.accentIcon : colors.inkMuted,
                    ),
                  ),
                ),
              ),
              SizedBox(height: dense ? PorcelainSpace.xxs : PorcelainSpace.xs),
              Text(
                destination.label,
                textAlign: TextAlign.center,
                maxLines: dense ? 1 : null,
                overflow: dense ? TextOverflow.ellipsis : null,
                style: selected
                    ? theme.text.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      )
                    : theme.text.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
