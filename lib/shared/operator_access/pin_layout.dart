import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_metrics.dart';

/// Arranges a PIN screen: its words beside the keypad when the space is
/// wide enough (landscape tablets, so nothing scrolls off), above it
/// otherwise.
class PinLayout extends StatelessWidget {
  const PinLayout({
    super.key,
    required this.header,
    required this.pad,
    this.footer,
  });

  /// Width from which the words sit beside the keypad.
  static const sideBySideWidth = 720.0;

  final Widget header;
  final Widget pad;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final keypad = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            pad,
            if (footer != null) ...[
              const SizedBox(height: PorcelainSpace.md),
              footer!,
            ],
          ],
        );
        if (constraints.maxWidth >= sideBySideWidth) {
          return Row(
            children: [
              Expanded(child: header),
              const SizedBox(width: PorcelainSpace.huge),
              keypad,
            ],
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [header, keypad],
        );
      },
    );
  }
}

/// The card width for a PIN screen in a window of [size]: wide enough for
/// [PinLayout]'s side-by-side arrangement on landscape tablets.
double pinCardWidth(Size size) =>
    size.width > size.height && size.width >= 900 ? 860 : 520;
