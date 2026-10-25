import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_metrics.dart';
import 'porcelain_entrance.dart';

/// Scrolling page body for Studio sections: margins that grow with the
/// window, a maximum content width and even spacing between [children].
/// The header and sections enter one after another when the page first
/// appears ([PorcelainEntrance]).
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

  /// Page margin for a content area [width] wide in a [window] that wide:
  /// the narrowest on a phone-sized window, so panes side by side on a
  /// tablet keep the same margins.
  static double marginFor(double width, {required double window}) =>
      window < 440
      ? PorcelainSpace.md
      : width >= 1000
      ? PorcelainSpace.huge
      : width >= 700
      ? PorcelainSpace.xxxl
      : PorcelainSpace.xl;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final margin = marginFor(
          constraints.maxWidth,
          window: MediaQuery.sizeOf(context).width,
        );
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
                child: PorcelainEntrance(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      EntranceItem(index: 0, child: header),
                      for (final (i, child) in children.indexed) ...[
                        SizedBox(height: spacing),
                        EntranceItem(index: i + 1, child: child),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// [StudioPage] for long, lazily built content (the gallery grid): the
/// same margins, maximum width and spacing, with [slivers] below the
/// [header] so only what is on screen is built.
class StudioSliverPage extends StatelessWidget {
  const StudioSliverPage({
    super.key,
    required this.header,
    required this.slivers,
    this.spacing = PorcelainSpace.xxxl,
    this.controller,
  });

  final Widget header;
  final List<Widget> slivers;
  final double spacing;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final margin = StudioPage.marginFor(
          constraints.maxWidth,
          window: MediaQuery.sizeOf(context).width,
        );
        final side =
            constraints.maxWidth - 2 * margin >
                PorcelainBreakpoints.maxContentWidth
            ? (constraints.maxWidth - PorcelainBreakpoints.maxContentWidth) / 2
            : margin;
        return SafeArea(
          left: false,
          child: PorcelainEntrance(
            child: CustomScrollView(
              controller: controller,
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(side, margin, side, 0),
                  sliver: SliverToBoxAdapter(
                    child: EntranceItem(index: 0, child: header),
                  ),
                ),
                for (final (i, sliver) in slivers.indexed)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(side, spacing, side, 0),
                    sliver: EntranceSliver(index: i + 1, sliver: sliver),
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(height: margin + PorcelainSpace.md),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
