import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../widgets/botanical_ornament.dart';

/// Scales guest typography and controls to the space a guest screen
/// actually has: 1.0 on a typical 11-inch tablet, down to 0.72 on the
/// smallest supported window. Guest primary actions stay above 72 dp.
@immutable
final class GuestScale {
  const GuestScale(this.factor);

  factory GuestScale.forSize(Size size) =>
      GuestScale((math.min(size.width, size.height) / 820).clamp(0.72, 1.0));

  final double factor;

  double call(double value) => value * factor;

  TextStyle text(TextStyle style) => style.copyWith(
    fontSize: style.fontSize! * factor,
    letterSpacing: (style.letterSpacing ?? 0) * factor,
  );
}

/// Chooses [PortraitGuestLayout] or [LandscapeGuestLayout] from the
/// constraints the screen actually receives (ADR-0004), never from the
/// operator's preferred orientation or an assumed lock.
///
/// Guest layouts have three slots and nothing else: no back, settings,
/// share, save or print controls exist at this level (AC-0210).
class GuestLayout extends StatelessWidget {
  const GuestLayout({
    super.key,
    required this.message,
    required this.action,
    this.footer,
  });

  /// Greeting, title and explanation.
  final Widget message;

  /// The one primary guest action.
  final Widget action;

  /// Quiet notice at the bottom, such as the privacy line.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    // Its own semantics container, so the guest area can be audited (and
    // announced) separately from anything an operator preview adds.
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: GuestBackdrop(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscape = constraints.maxWidth > constraints.maxHeight;
            return landscape
                ? LandscapeGuestLayout(
                    message: message,
                    action: action,
                    footer: footer,
                    constraints: constraints,
                  )
                : PortraitGuestLayout(
                    message: message,
                    action: action,
                    footer: footer,
                    constraints: constraints,
                  );
          },
        ),
      ),
    );
  }
}

/// Message above, action in the lower half within easy reach, footer at the
/// bottom. Scrolls only if text is enlarged beyond what fits.
class PortraitGuestLayout extends StatelessWidget {
  const PortraitGuestLayout({
    super.key,
    required this.message,
    required this.action,
    required this.constraints,
    this.footer,
  });

  final Widget message;
  final Widget action;
  final Widget? footer;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final scale = GuestScale.forSize(constraints.biggest);
    return _FillOrScroll(
      constraints: constraints,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: scale(PorcelainSpace.giant),
          vertical: scale(PorcelainSpace.huge),
        ),
        child: Column(
          children: [
            const Spacer(flex: 3),
            message,
            const Spacer(flex: 2),
            action,
            const Spacer(flex: 3),
            ?footer,
          ],
        ),
      ),
    );
  }
}

/// Message on the left, action on the right, footer along the bottom.
class LandscapeGuestLayout extends StatelessWidget {
  const LandscapeGuestLayout({
    super.key,
    required this.message,
    required this.action,
    required this.constraints,
    this.footer,
  });

  final Widget message;
  final Widget action;
  final Widget? footer;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final scale = GuestScale.forSize(constraints.biggest);
    return _FillOrScroll(
      constraints: constraints,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: scale(PorcelainSpace.giant + PorcelainSpace.xl),
          vertical: scale(PorcelainSpace.huge),
        ),
        child: Column(
          children: [
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 11, child: message),
                SizedBox(width: scale(PorcelainSpace.huge)),
                Expanded(flex: 9, child: Center(child: action)),
              ],
            ),
            const Spacer(),
            ?footer,
          ],
        ),
      ),
    );
  }
}

/// Fills the screen exactly when the content fits, and scrolls instead of
/// overflowing when large text needs more room.
class _FillOrScroll extends StatelessWidget {
  const _FillOrScroll({required this.constraints, required this.child});

  final BoxConstraints constraints;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: constraints.maxHeight,
          minWidth: constraints.maxWidth,
          maxWidth: constraints.maxWidth,
        ),
        child: IntrinsicHeight(child: child),
      ),
    );
  }
}

/// The guest canvas: a soft porcelain glaze with botanical sprigs in two
/// corners, behind the content and away from the controls.
class GuestBackdrop extends StatelessWidget {
  const GuestBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final sprig = constraints.biggest.shortestSide * 0.19;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.2),
              radius: 1.1,
              colors: [colors.surface, colors.canvas],
            ),
          ),
          child: Stack(
            children: [
              PositionedDirectional(
                start: sprig * 0.12,
                top: sprig * 0.12,
                child: Transform.rotate(
                  angle: math.pi,
                  child: BotanicalOrnament.sprig(
                    width: sprig,
                    height: sprig,
                    leaves: 7,
                    seed: 3,
                  ),
                ),
              ),
              PositionedDirectional(
                end: sprig * 0.12,
                bottom: sprig * 0.12,
                child: BotanicalOrnament.sprig(
                  width: sprig,
                  height: sprig,
                  leaves: 7,
                  seed: 7,
                ),
              ),
              Positioned.fill(child: child),
            ],
          ),
        );
      },
    );
  }
}
