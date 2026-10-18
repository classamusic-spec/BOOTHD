import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design_system/porcelain_depth.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import 'tactile_surface.dart';
import 'tone.dart';

/// Brief, non-blocking messages. Shown through [ScaffoldMessenger], so they
/// are announced to screen readers and never stack up.
abstract final class PorcelainToast {
  static const displayDuration = Duration(seconds: 4);

  static void show(
    BuildContext context,
    String message, {
    PorcelainTone tone = PorcelainTone.info,
    IconData? icon,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final width = math.min(560.0, MediaQuery.sizeOf(context).width - 48);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: PorcelainToastCard(message: message, tone: tone, icon: icon),
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          behavior: SnackBarBehavior.floating,
          width: width,
          duration: displayDuration,
        ),
        snackBarAnimationStyle: PorcelainMotion.of(context).isReduced
            ? AnimationStyle.noAnimation
            : null,
      );
  }
}

/// The visual of a toast; public so the component gallery can show it.
class PorcelainToastCard extends StatelessWidget {
  const PorcelainToastCard({
    super.key,
    required this.message,
    this.tone = PorcelainTone.info,
    this.icon,
  });

  final String message;
  final PorcelainTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    return TactileSurface(
      duration: Duration.zero,
      radius: PorcelainRadius.control,
      look: TactileLook(
        fillTop: colors.raised,
        fillBottom: colors.surface,
        border: colors.hairline,
        elevation: PorcelainDepth.overlay,
        highlight: 1,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PorcelainSpace.lg,
          vertical: PorcelainSpace.md,
        ),
        child: Row(
          children: [
            Icon(
              icon ?? tone.icon,
              color: tone.foreground(colors),
              size: PorcelainSize.icon,
              fill: 1,
            ),
            const SizedBox(width: PorcelainSpace.sm),
            Expanded(child: Text(message, style: theme.text.bodyLarge)),
          ],
        ),
      ),
    );
  }
}
