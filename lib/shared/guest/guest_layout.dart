import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/experience/guest_experience.dart';
import '../../core/experience/guest_theme.dart';
import '../widgets/floral_spray.dart';
import 'guest_decorations.dart';

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
/// Guest layouts have these slots and nothing else: no back, settings,
/// share, save or print controls exist at this level (AC-0210).
class GuestLayout extends StatelessWidget {
  const GuestLayout({
    super.key,
    required this.message,
    required this.action,
    this.header,
    this.preview,
    this.footer,
  });

  /// The booth's wordmark, at the top.
  final Widget? header;

  /// Greeting, title and explanation.
  final Widget message;

  /// The one primary guest action.
  final Widget action;

  /// A picture beside the message, such as the event's template.
  final Widget? preview;

  /// Quiet guide and notices at the bottom.
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
                    header: header,
                    message: message,
                    action: action,
                    preview: preview,
                    footer: footer,
                    constraints: constraints,
                  )
                : PortraitGuestLayout(
                    header: header,
                    message: message,
                    action: action,
                    preview: preview,
                    footer: footer,
                    constraints: constraints,
                  );
          },
        ),
      ),
    );
  }
}

/// Wordmark at the top; the preview on the left with the message and the
/// action beside it, the action in easy reach; the guide at the bottom.
/// On a window narrower than [narrowWidth] (a phone opening the web test
/// build) the preview sits above the message instead, so the title and
/// the action keep the whole width. Scrolls only if text is enlarged
/// beyond what fits.
class PortraitGuestLayout extends StatelessWidget {
  const PortraitGuestLayout({
    super.key,
    required this.message,
    required this.action,
    required this.constraints,
    this.header,
    this.preview,
    this.footer,
  });

  final Widget? header;
  final Widget message;
  final Widget action;
  final Widget? preview;
  final Widget? footer;
  final BoxConstraints constraints;

  static const narrowWidth = 600.0;

  @override
  Widget build(BuildContext context) {
    final scale = GuestScale.forSize(constraints.biggest);
    final preview = this.preview;
    final narrow = constraints.maxWidth < narrowWidth;
    final core = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        message,
        SizedBox(height: scale(PorcelainSpace.xxl)),
        action,
      ],
    );
    return _FillOrScroll(
      constraints: constraints,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: narrow ? PorcelainSpace.xl : scale(PorcelainSpace.giant),
          vertical: scale(PorcelainSpace.xxl),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            header ?? const SizedBox.shrink(),
            if (preview == null)
              core
            else if (narrow)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * 0.24,
                    ),
                    child: preview,
                  ),
                  SizedBox(height: scale(PorcelainSpace.xl)),
                  core,
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: constraints.maxHeight * 0.42,
                        ),
                        child: preview,
                      ),
                    ),
                  ),
                  SizedBox(width: scale(PorcelainSpace.xl)),
                  Expanded(flex: 6, child: core),
                ],
              ),
            footer ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

/// Wordmark at the top; the preview on the left, message and action in
/// the middle; the guide along the bottom.
class LandscapeGuestLayout extends StatelessWidget {
  const LandscapeGuestLayout({
    super.key,
    required this.message,
    required this.action,
    required this.constraints,
    this.header,
    this.preview,
    this.footer,
  });

  final Widget? header;
  final Widget message;
  final Widget action;
  final Widget? preview;
  final Widget? footer;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final scale = GuestScale.forSize(constraints.biggest);
    final preview = this.preview;
    return _FillOrScroll(
      constraints: constraints,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: scale(PorcelainSpace.giant + PorcelainSpace.xl),
          vertical: scale(PorcelainSpace.xl),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            header ?? const SizedBox.shrink(),
            Row(
              children: [
                if (preview != null) ...[
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: constraints.maxHeight * 0.5,
                        ),
                        child: preview,
                      ),
                    ),
                  ),
                  SizedBox(width: scale(PorcelainSpace.xl)),
                ],
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      message,
                      SizedBox(height: scale(PorcelainSpace.xl)),
                      action,
                    ],
                  ),
                ),
                if (preview != null) const Spacer(flex: 2),
              ],
            ),
            footer ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

/// Fills the screen when the content fits, spreading the space between
/// its parts, and scrolls instead of overflowing when large text needs
/// more room. No intrinsic measuring: text in a narrowed measure would be
/// under-measured by it.
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
        child: child,
      ),
    );
  }
}

/// The guest canvas: a soft porcelain glaze with painted cream blossoms
/// spilling in from two corners, behind the content and away from the
/// controls (CR-002). A [dense] screen (a keypad, a consent box and
/// buttons from top to bottom) keeps only two small corner sprays, so no
/// blossom sits behind words.
class GuestBackdrop extends StatelessWidget {
  const GuestBackdrop({super.key, required this.child, this.dense = false});

  final Widget child;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    final experience = GuestExperience.maybeOf(context)?.experience;
    if (experience != null &&
        GuestTheme.originalAppearance(experience) == null) {
      // A pack's own look (EP06): its backdrop and decorations. The glow
      // stays between the two grounds every text colour is checked on, so
      // words near the edges keep their contrast (EP09).
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.2),
            radius: 1.1,
            colors: [colors.surface, colors.canvas],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: GuestDecorationLayer(dense: dense)),
            child,
          ],
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final landscape = size.width > size.height;
        final spray =
            size.shortestSide * (landscape ? 0.42 : 0.44) * (dense ? 0.55 : 1);
        final small = spray * (dense ? 1 : 0.8);
        final vine = size.shortestSide * 0.14;
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
              if (landscape) ...[
                Positioned(
                  left: -spray * 0.08,
                  top: -spray * 0.06,
                  child: FloralSpray(
                    kind: FloralSprayKind.corner,
                    width: spray,
                    height: spray,
                  ),
                ),
                if (!dense)
                  Positioned(
                    right: -vine * 0.2,
                    top: size.height * 0.08,
                    child: FloralSpray(
                      kind: FloralSprayKind.garland,
                      width: vine,
                      height: size.height * 0.5,
                      mirrorX: true,
                    ),
                  ),
                Positioned(
                  right: -small * 0.06,
                  bottom: -small * 0.08,
                  child: FloralSpray(
                    kind: FloralSprayKind.corner,
                    width: small,
                    height: small,
                    seed: 4,
                    mirrorX: true,
                    mirrorY: true,
                  ),
                ),
              ] else ...[
                Positioned(
                  left: -vine * 0.2,
                  top: size.height * 0.24,
                  child: FloralSpray(
                    kind: FloralSprayKind.garland,
                    width: vine,
                    height: size.height * 0.5,
                  ),
                ),
                if (!dense)
                  Positioned(
                    right: -spray * 0.08,
                    top: -spray * 0.06,
                    child: FloralSpray(
                      kind: FloralSprayKind.corner,
                      width: spray,
                      height: spray,
                      mirrorX: true,
                    ),
                  ),
                Positioned(
                  left: -small * 0.08,
                  bottom: -small * 0.04,
                  child: FloralSpray(
                    kind: FloralSprayKind.corner,
                    width: small,
                    height: small,
                    seed: 4,
                    mirrorY: true,
                  ),
                ),
              ],
              Positioned.fill(child: child),
            ],
          ),
        );
      },
    );
  }
}
