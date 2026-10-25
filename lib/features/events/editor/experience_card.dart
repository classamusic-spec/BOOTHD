import 'package:flutter/widgets.dart';

import '../../../core/design_system/porcelain_icons.dart';
import '../../../core/design_system/porcelain_metrics.dart';
import '../../../core/design_system/porcelain_motion.dart';
import '../../../core/design_system/porcelain_theme.dart';
import '../../../core/experience/guest_theme.dart';
import '../../../domain/experience/experience_registry.dart';
import '../../../shared/guest/guest_decorations.dart';
import '../../../shared/widgets/floral_spray.dart';
import '../../../shared/widgets/pressable.dart';

/// One guest experience, as the reference board's Event Setup shows it: a
/// small emblem in that theme's own colours, its name, a gold edge and a
/// check mark when chosen.
class ExperienceCard extends StatelessWidget {
  const ExperienceCard({
    super.key,
    required this.experience,
    required this.title,
    required this.selected,
    required this.onPressed,
    this.disabledReason,
  });

  final ResolvedExperience experience;
  final String title;
  final bool selected;
  final VoidCallback? onPressed;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final motion = PorcelainMotion.of(context);
    return Pressable(
      onPressed: onPressed,
      semanticLabel: title,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      disabledReason: disabledReason,
      builder: (context, state) => AnimatedContainer(
        duration: motion.press,
        width: 148,
        padding: const EdgeInsets.all(PorcelainSpace.sm),
        decoration: BoxDecoration(
          color: colors.raised,
          borderRadius: PorcelainRadius.cardAll,
          border: Border.all(
            color: selected
                ? colors.accentIcon
                : state.focused
                ? colors.focusRing
                : colors.hairline,
            width: selected || state.focused ? 2.5 : 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                GuestExperienceScope(
                  experience: experience,
                  child: ExperienceEmblem(
                    original: GuestTheme.originalAppearance(experience) != null,
                  ),
                ),
                const SizedBox(height: PorcelainSpace.sm),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.text.labelLarge.copyWith(color: colors.ink),
                ),
              ],
            ),
            if (selected)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [colors.primaryTop, colors.primaryBottom],
                    ),
                    border: Border.all(color: colors.primaryEdge),
                  ),
                  child: Icon(
                    PorcelainIcons.check,
                    size: 16,
                    color: colors.onPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A theme in miniature: its guest canvas, its decorations (a sprig of
/// blossoms for the original looks) and the start button in its colours.
class ExperienceEmblem extends StatelessWidget {
  const ExperienceEmblem({super.key, required this.original});

  final bool original;

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    return ExcludeSemantics(
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 1.1,
            colors: [colors.surface, colors.canvas],
          ),
          borderRadius: PorcelainRadius.controlAll,
          border: Border.all(color: colors.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (original)
              const Positioned(
                right: -10,
                top: -8,
                child: FloralSpray(
                  kind: FloralSprayKind.corner,
                  width: 64,
                  height: 64,
                  mirrorX: true,
                ),
              )
            else
              const Positioned.fill(child: GuestDecorationLayer(dense: true)),
            Center(
              child: Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      colors.primaryTop,
                      colors.primaryEdge,
                      colors.primaryBottom,
                      colors.primaryTop,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadowKey,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surface,
                  ),
                  child: Icon(
                    PorcelainIcons.camera,
                    size: 20,
                    color: colors.guestAccentText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
