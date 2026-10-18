import 'package:flutter/material.dart';

import '../../core/design_system/porcelain_depth.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/design_system/porcelain_theme_data.dart';
import '../../core/design_system/theme_profiles.dart';
import 'botanical_ornament.dart';
import 'porcelain_card.dart';

/// A selectable theme profile: a small still life drawn with the profile's
/// own tokens, its name and description, and an optional badge (S01, S17).
class ThemeProfileCard extends StatelessWidget {
  const ThemeProfileCard({
    super.key,
    required this.profile,
    required this.title,
    required this.description,
    required this.selected,
    required this.onPressed,
    this.badge,
  });

  final PorcelainThemeProfile profile;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onPressed;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return PorcelainCard(
      selected: selected,
      onPressed: onPressed,
      padding: const EdgeInsets.all(PorcelainSpace.md),
      child: Row(
        children: [
          SizedBox(
            width: 136,
            child: Theme(
              data: porcelainThemeData(
                profile,
                highContrast: theme.highContrast,
              ),
              child: const ThemeSwatch(),
            ),
          ),
          const SizedBox(width: PorcelainSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.text.titleMedium),
                const SizedBox(height: PorcelainSpace.xxs),
                Text(
                  description,
                  style: theme.text.bodyMedium.copyWith(
                    color: theme.colors.inkMuted,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(height: PorcelainSpace.sm),
                  badge!,
                ],
              ],
            ),
          ),
          // Room for the selected mark in the corner.
          const SizedBox(width: PorcelainSpace.xl),
        ],
      ),
    );
  }
}

/// A small still life of a theme: its canvas, a raised card, a gold pill and
/// a sprig, drawn with that theme's own tokens.
class ThemeSwatch extends StatelessWidget {
  const ThemeSwatch({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    return ExcludeSemantics(
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: colors.canvas,
          borderRadius: PorcelainRadius.controlAll,
          border: Border.all(color: colors.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            const Positioned(
              right: -6,
              bottom: -8,
              child: BotanicalOrnament.sprig(width: 72, height: 72, leaves: 6),
            ),
            Positioned(
              left: 12,
              top: 12,
              right: 40,
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  border: Border.all(color: colors.hairline),
                  boxShadow: PorcelainDepth.shadows(colors, 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 6,
                  width: 44,
                  decoration: BoxDecoration(
                    color: colors.ink,
                    borderRadius: const BorderRadius.all(Radius.circular(3)),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                width: 64,
                height: 22,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colors.primaryTop, colors.primaryBottom],
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  border: Border.all(color: colors.primaryEdge),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
