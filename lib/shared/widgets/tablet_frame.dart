import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_depth.dart';
import '../../core/design_system/porcelain_theme.dart';

/// Shows [child] laid out at a real tablet [logicalSize] and scaled into a
/// device bezel: a faithful miniature of a full screen (for example what
/// guests will see), not a screenshot. The miniature is not interactive and
/// is announced as one image named [semanticLabel].
class TabletFrame extends StatelessWidget {
  const TabletFrame({
    super.key,
    required this.logicalSize,
    required this.child,
    required this.semanticLabel,
  });

  final Size logicalSize;
  final Widget child;
  final String semanticLabel;

  static const _bezel = 9.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    final bezel = colors.isDark ? colors.raised : colors.ink;
    final media = MediaQuery.of(context);
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final aspect = logicalSize.width / logicalSize.height;
            var screenWidth = constraints.maxWidth - 2 * _bezel;
            if (constraints.hasBoundedHeight) {
              screenWidth = math.min(
                screenWidth,
                (constraints.maxHeight - 2 * _bezel) * aspect,
              );
            }
            screenWidth = math.max(0, screenWidth);
            final screenHeight = screenWidth / aspect;
            return SizedBox(
              width: screenWidth + 2 * _bezel,
              height: screenHeight + 2 * _bezel,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: bezel,
                  borderRadius: const BorderRadius.all(Radius.circular(22)),
                  border: Border.all(color: colors.outline, width: 0.8),
                  boxShadow: PorcelainDepth.shadows(colors, 1.4),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(_bezel),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(14)),
                    child: IgnorePointer(
                      child: FittedBox(
                        fit: BoxFit.fill,
                        child: SizedBox.fromSize(
                          size: logicalSize,
                          child: MediaQuery(
                            data: media.copyWith(
                              size: logicalSize,
                              padding: EdgeInsets.zero,
                              viewPadding: EdgeInsets.zero,
                              viewInsets: EdgeInsets.zero,
                              textScaler: TextScaler.noScaling,
                            ),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
