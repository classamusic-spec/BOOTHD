import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../widgets/pressable.dart';

/// The guest's one primary action (S20, CR-002): a large pearl button in a
/// polished gold rim, like a shutter release, reading "TAP TO", a camera
/// and "START". At least 180 dp across even on the smallest window (guest
/// minimum 72 dp), with lettering at >=7:1 against the pearl (CR-001).
class GuestStartButton extends StatelessWidget {
  const GuestStartButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.prompt,
    this.semanticHint,
    this.scale = 1,
  });

  /// The main word, e.g. "Start".
  final String label;

  /// The small line above it, e.g. "Tap to".
  final String? prompt;
  final VoidCallback onPressed;
  final String? semanticHint;

  /// From `GuestScale`, so the control shrinks with the window.
  final double scale;

  /// Diameter at full scale, in logical pixels.
  static const diameter = 248.0;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final motion = PorcelainMotion.of(context);
    final size = diameter * scale;
    final rim = size * 0.075;
    final prompt = this.prompt;
    return Pressable(
      onPressed: onPressed,
      // "Tap to" is for the eye; a screen reader already says "button".
      semanticLabel: label,
      semanticHint: semanticHint,
      builder: (context, state) => AnimatedScale(
        scale: state.pressed ? 0.975 : 1,
        duration: state.pressed ? motion.press : motion.release,
        child: SizedBox.square(
          dimension: size,
          child: DecoratedBox(
            // The gold rim: polished metal catching light at the top.
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                transform: const GradientRotation(-math.pi / 2),
                colors: [
                  colors.primaryTop,
                  colors.primaryEdge,
                  colors.primaryBottom,
                  colors.primaryTop,
                  colors.primaryEdge,
                  colors.primaryTop,
                ],
              ),
              border: Border.all(
                color: state.focused ? colors.focusRing : colors.primaryEdge,
                width: state.focused ? 3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadowKey,
                  blurRadius: state.pressed ? 10 : 26,
                  offset: Offset(0, state.pressed ? 3 : 10),
                ),
                BoxShadow(
                  color: colors.shadowAmbient,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(rim),
              // The pearl face, softly domed.
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.45),
                    radius: 1.05,
                    colors: state.pressed
                        ? [colors.raised, colors.raisedShade]
                        : [colors.surface, colors.raised, colors.raisedShade],
                  ),
                  border: Border.all(
                    color: colors.primaryEdge.withValues(alpha: 0.55),
                    width: 1.2,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(size * 0.05),
                  // An engraved inner line.
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.primaryEdge.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: EdgeInsets.all(size * 0.04),
                          // A long word wraps within the ring; the
                          // FittedBox only shrinks what still cannot fit.
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: label.length > 8
                                  ? size * 0.7
                                  : double.infinity,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (prompt != null)
                                  Text(
                                    prompt.toUpperCase(),
                                    style: theme.text.guestLabel.copyWith(
                                      fontSize: 15 * scale,
                                      letterSpacing: 3 * scale,
                                      color: colors.guestAccentText,
                                    ),
                                  ),
                                SizedBox(height: size * 0.025),
                                Icon(
                                  PorcelainIcons.camera,
                                  size: size * 0.15,
                                  color: colors.guestAccentText,
                                ),
                                SizedBox(height: size * 0.01),
                                // A long word (a pack's "Once upon a
                                // photo") wraps rather than shrinking to
                                // an unreadable single line.
                                Text(
                                  label.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  style: theme.text.guestTitle.copyWith(
                                    fontSize:
                                        (label.length > 8 ? 34 : 46) * scale,
                                    height: 1.05,
                                    letterSpacing: 2 * scale,
                                    color: colors.guestAccentText,
                                  ),
                                ),
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
          ),
        ),
      ),
    );
  }
}
