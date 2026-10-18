import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_depth.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../widgets/botanical_ornament.dart';
import '../widgets/pressable.dart';
import '../widgets/tactile_surface.dart';

/// The guest's one primary action: a round champagne-gold control, like a
/// shutter release, inside a botanical wreath. At least 155 dp across even
/// on the smallest window (guest minimum 72 dp), with ink lettering at
/// >=7:1 (CR-001).
class GuestStartButton extends StatelessWidget {
  const GuestStartButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.semanticHint,
    this.scale = 1,
  });

  final String label;
  final VoidCallback onPressed;
  final String? semanticHint;

  /// From `GuestScale`, so the control shrinks with the window.
  final double scale;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final motion = PorcelainMotion.of(context);
    final diameter = PorcelainSize.guestStartDiameter * scale;
    final style = theme.text.guestAction;
    return SizedBox.square(
      dimension: diameter * 1.6,
      child: Stack(
        alignment: Alignment.center,
        children: [
          BotanicalOrnament.wreath(diameter: diameter * 1.6, leaves: 12),
          Pressable(
            onPressed: onPressed,
            semanticLabel: label,
            semanticHint: semanticHint,
            builder: (context, state) => SizedBox.square(
              dimension: diameter,
              child: TactileSurface(
                shape: TactileShape.circle,
                focused: state.focused,
                duration: state.pressed ? motion.press : motion.release,
                look: state.pressed
                    ? TactileLook(
                        fillTop: Color.lerp(
                          colors.primaryBottom,
                          colors.primaryEdge,
                          0.1,
                        )!,
                        fillBottom: colors.primaryBottom,
                        border: colors.primaryEdge,
                        borderWidth: 2,
                        elevation: 0.3,
                        inset: 1,
                        travel: 2,
                      )
                    : TactileLook(
                        fillTop: state.hovered || state.focused
                            ? Color.lerp(
                                colors.primaryTop,
                                colors.raised,
                                0.18,
                              )!
                            : colors.primaryTop,
                        fillBottom: colors.primaryBottom,
                        border: colors.primaryEdge,
                        borderWidth: 2,
                        elevation: PorcelainDepth.overlay,
                        highlight: 1,
                      ),
                child: Stack(
                  children: [
                    // An engraved inner ring, like a shutter release.
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.all(diameter * 0.075),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.primaryEdge.withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(PorcelainSpace.md),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: style.copyWith(
                            color: colors.onPrimary,
                            fontSize: style.fontSize! * scale,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
