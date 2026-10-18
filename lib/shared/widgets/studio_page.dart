import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_metrics.dart';

/// Scrolling page body for Studio sections: margins that grow with the
/// window, a maximum content width and even spacing between [children].
class StudioPage extends StatelessWidget {
  const StudioPage({
    super.key,
    required this.header,
    required this.children,
    this.spacing = PorcelainSpace.xxxl,
  });

  final Widget header;
  final List<Widget> children;
  final double spacing;

  /// Horizontal page margin for a content area [width] wide.
  static double marginFor(double width) => width >= 1000
      ? PorcelainSpace.huge
      : width >= 700
      ? PorcelainSpace.xxxl
      : PorcelainSpace.xl;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final margin = marginFor(constraints.maxWidth);
        return SafeArea(
          left: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              margin,
              margin,
              margin,
              margin + PorcelainSpace.md,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: PorcelainBreakpoints.maxContentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    for (final child in children) ...[
                      SizedBox(height: spacing),
                      child,
                    ],
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
