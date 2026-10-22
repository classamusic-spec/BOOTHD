import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/experience/guest_experience.dart';
import '../../domain/experience/experience_catalog.dart';
import '../widgets/porcelain_spinner.dart';
import '../widgets/pressable.dart';
import 'guest_button_faces.dart';

/// How much a guest button asks for attention: the one thing to do next,
/// or a quieter alternative beside it.
enum GuestButtonEmphasis { primary, secondary }

/// Guest button heights. Every size is at least the pack's touch minimum
/// (72 or more); larger where the layout has room.
enum GuestButtonSize {
  regular(72, 22),
  large(88, 26),
  hero(112, 32);

  const GuestButtonSize(this.height, this.fontSize);

  final double height;
  final double fontSize;
}

/// The one guest button (EP02): a single semantic API whatever the pack,
/// drawn by the pack's button family (porcelain, wood, toy arcade, retro
/// game, gala or neon party). Every family keeps the same states: raised,
/// pressed (with travel), keyboard focus, disabled with a reason, busy and
/// selected. Primary buttons are the pack's accent with its readable
/// on-accent text; secondary ones its panel with its ink, so contrast
/// never depends on the family. Depth never stands alone: every face has
/// an edge and a label.
class GuestButton extends StatelessWidget {
  const GuestButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.emphasis = GuestButtonEmphasis.primary,
    this.size = GuestButtonSize.regular,
    this.busy = false,
    this.disabledReason,
    this.selected,
    this.semanticHint,
    this.expand = false,
    this.style,
  });

  final String label;

  /// Null disables the button; say why in [disabledReason].
  final VoidCallback? onPressed;
  final IconData? icon;
  final GuestButtonEmphasis emphasis;
  final GuestButtonSize size;

  /// Work is running: presses are ignored and a spinner replaces the icon;
  /// the label stays.
  final bool busy;

  /// Read out to screen readers when the button cannot be used.
  final String? disabledReason;

  /// For choices: null when the button is not one.
  final bool? selected;
  final String? semanticHint;

  /// Fill the available width.
  final bool expand;

  /// Draw with this family instead of the pack's (previews and goldens).
  final GuestButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final tokens = GuestExperience.tokensOf(context);
    final face = GuestButtonFace.of(style ?? tokens.buttonStyle);
    final motion = PorcelainMotion.of(context);
    final height = math.max(size.height, tokens.minTouchTarget);
    return Pressable(
      onPressed: busy ? null : onPressed,
      busy: busy,
      disabledReason: busy ? null : disabledReason,
      selected: selected,
      semanticLabel: label,
      semanticHint: semanticHint,
      builder: (context, state) {
        final look = GuestButtonLook(
          // A busy button is working, not unavailable.
          enabled: state.enabled || (busy && onPressed != null),
          pressed: state.pressed && !busy,
          focused: state.focused,
          primary: emphasis == GuestButtonEmphasis.primary,
          selected: selected ?? false,
        );
        final ink = face.ink(tokens, look);
        final iconSize = size.fontSize * 1.15;
        final content = Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: PorcelainSpinner(color: ink, size: iconSize),
              )
            else if (icon != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: Icon(icon, size: iconSize, color: ink),
              ),
            Flexible(
              child: Text(
                face.transformLabel(label),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: face
                    .labelStyle(tokens, size.fontSize)
                    .copyWith(color: ink),
              ),
            ),
          ],
        );
        return TweenAnimationBuilder<double>(
          tween: Tween(end: look.pressed ? 1 : 0),
          duration: look.pressed ? motion.press : motion.release,
          curve: PorcelainMotion.ease,
          builder: (context, press, _) => CustomPaint(
            painter: GuestButtonPainter(
              face: face,
              tokens: tokens,
              look: look,
              press: press,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: height,
                minWidth: height * 1.6,
              ),
              child: Padding(
                padding: face
                    .contentPadding(height)
                    .add(EdgeInsets.only(top: face.travel(press))),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    content,
                    if (look.selected)
                      PositionedDirectional(
                        top: -height * 0.32,
                        end: -face.contentPadding(height).right * 0.75,
                        child: _SelectedMark(tokens: tokens),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The check on a chosen option: selection never relies on colour alone.
class _SelectedMark extends StatelessWidget {
  const _SelectedMark({required this.tokens});

  final GuestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: tokens.ink,
          border: Border.all(color: tokens.panel, width: 2),
        ),
        child: Icon(PorcelainIcons.check, size: 18, color: tokens.panel),
      ),
    );
  }
}
