import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// The operator's discreet way out of the guest screens (UX-04, S28):
/// press and hold the top corner at the end of the reading direction (top
/// right in English) for three seconds. Invisible, out of the
/// accessibility tree and too slow for an ordinary tap, so guests do not
/// find it; documented for operators in the manual. It only opens the PIN
/// screen: leaving Booth Mode still needs the PIN.
///
/// Operators who rely on a screen reader leave through the OS kiosk
/// controls (Guided Access or lock task), which take precedence anyway.
class HiddenOperatorExit extends StatelessWidget {
  const HiddenOperatorExit({super.key, required this.onTriggered});

  static const holdDuration = Duration(seconds: 3);
  static const size = 96.0;

  final VoidCallback onTriggered;

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      top: 0,
      end: 0,
      width: size,
      height: size,
      child: ExcludeSemantics(
        child: RawGestureDetector(
          behavior: HitTestBehavior.translucent,
          gestures: {
            LongPressGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                  LongPressGestureRecognizer
                >(
                  () => LongPressGestureRecognizer(duration: holdDuration),
                  (recognizer) => recognizer.onLongPress = onTriggered,
                ),
          },
        ),
      ),
    );
  }
}
