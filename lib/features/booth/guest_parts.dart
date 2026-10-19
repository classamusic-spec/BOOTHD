import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/design_system/porcelain_colors.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../shared/guest/guest_layout.dart';
import '../../shared/widgets/porcelain_spinner.dart';

/// A guest screen's heading (CR-002): an optional spaced eyebrow, the
/// title, and an optional subtitle. The title is the serif display in the
/// guest gold, or, with [caps], spaced capitals as on the template choice.
class GuestHeading extends StatelessWidget {
  const GuestHeading({
    super.key,
    required this.title,
    required this.scale,
    this.eyebrow,
    this.subtitle,
    this.caps = false,
  });

  final String title;
  final GuestScale scale;
  final String? eyebrow;
  final String? subtitle;
  final bool caps;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final eyebrow = this.eyebrow;
    final subtitle = this.subtitle;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (eyebrow != null) ...[
          Semantics(
            label: eyebrow,
            child: ExcludeSemantics(
              child: Text(
                eyebrow.toUpperCase(),
                textAlign: TextAlign.center,
                style: scale.text(
                  theme.text.guestLabel.copyWith(
                    fontSize: 16,
                    letterSpacing: 3,
                    color: colors.guestAccentText,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: scale(PorcelainSpace.xs)),
        ],
        Semantics(
          header: true,
          label: title,
          child: ExcludeSemantics(
            child: Text(
              caps ? title.toUpperCase() : title,
              textAlign: TextAlign.center,
              style: scale.text(
                caps
                    ? theme.text.guestLabel.copyWith(
                        fontSize: 30,
                        height: 1.2,
                        letterSpacing: 5,
                        fontWeight: FontWeight.w500,
                        color: colors.ink,
                      )
                    : theme.text.guestTitle.copyWith(
                        color: colors.guestAccentText,
                      ),
              ),
            ),
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: scale(PorcelainSpace.xs)),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: scale.text(theme.text.guestBody),
          ),
        ],
      ],
    );
  }
}

/// The porcelain plaque under the live picture (S22 to S24, CR-002): a
/// pearl cartouche in a gilded edge with an engraved inner line.
class GuestPlaque extends StatelessWidget {
  const GuestPlaque({
    super.key,
    required this.width,
    required this.height,
    required this.child,
  });

  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    final radius = height * 0.34;
    final inset = height * 0.055;
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.surface, colors.raised, colors.raisedShade],
          ),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: colors.primaryEdge, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: colors.shadowKey,
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: colors.shadowAmbient,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(inset),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius - inset),
              border: Border.all(
                color: colors.primaryEdge.withValues(alpha: 0.45),
              ),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// The live picture's frame: a porcelain rim with a gilded hairline and a
/// soft shadow, dark inside until the picture arrives.
class GuestViewfinder extends StatelessWidget {
  const GuestViewfinder({super.key, required this.scale, required this.child});

  final GuestScale scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    final rim = scale(10);
    final radius = scale(30);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colors.primaryEdge.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: colors.shadowKey,
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(rim),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - rim),
          child: ColoredBox(
            color: PorcelainViewfinder.background,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A photo or finished photo lying on the table: a white border, a soft
/// shadow and a slight turn.
class GuestPrint extends StatelessWidget {
  const GuestPrint({
    super.key,
    required this.scale,
    required this.child,
    this.angle = 0,
    this.border = 10,
  });

  final GuestScale scale;
  final Widget child;

  /// Turn in radians.
  final double angle;

  /// White border at full scale.
  final double border;

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    final print = DecoratedBox(
      decoration: BoxDecoration(
        color: PorcelainViewfinder.ink,
        borderRadius: BorderRadius.circular(scale(4)),
        boxShadow: [
          BoxShadow(
            color: colors.shadowKey,
            blurRadius: scale(22),
            offset: Offset(scale(3), scale(10)),
          ),
          BoxShadow(
            color: colors.shadowAmbient,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(padding: EdgeInsets.all(scale(border)), child: child),
    );
    return angle == 0 ? print : Transform.rotate(angle: angle, child: print);
  }
}

/// One of this session's photos, decoded at about the size it is shown
/// (never the full original) and mirrored like the finished photo.
/// While it loads, or if it cannot be read, a quiet well stands in; it
/// never shows an error to guests.
class GuestPhoto extends StatelessWidget {
  const GuestPhoto({
    super.key,
    required this.bytes,
    this.mirrored = false,
    this.fit = BoxFit.cover,
  });

  final Future<Uint8List> bytes;
  final bool mirrored;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    final ratio = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.max(
          constraints.hasBoundedWidth ? constraints.maxWidth : 0.0,
          constraints.hasBoundedHeight ? constraints.maxHeight : 0.0,
        );
        final decodeWidth = math.max(64, (side * ratio).ceil());
        return FutureBuilder<Uint8List>(
          future: bytes,
          builder: (context, snapshot) {
            final data = snapshot.data;
            if (data == null) {
              return SizedBox.expand(child: ColoredBox(color: colors.inset));
            }
            final image = Image.memory(
              data,
              fit: fit,
              width: double.infinity,
              height: double.infinity,
              cacheWidth: decodeWidth,
              gaplessPlayback: true,
              excludeFromSemantics: true,
              filterQuality: FilterQuality.medium,
            );
            return mirrored ? Transform.flip(flipX: true, child: image) : image;
          },
        );
      },
    );
  }
}

/// A round pearl emblem in a gold rim, like the Start button's face: an
/// icon, or a turning arc while the booth works.
class GuestEmblem extends StatelessWidget {
  const GuestEmblem({
    super.key,
    required this.scale,
    this.icon,
    this.busy = false,
    this.size = 168,
  });

  final GuestScale scale;
  final IconData? icon;
  final bool busy;

  /// Diameter at full scale.
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    final diameter = scale(size);
    final rim = diameter * 0.07;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: diameter,
        child: DecoratedBox(
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
            boxShadow: [
              BoxShadow(
                color: colors.shadowKey,
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(rim),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.45),
                  radius: 1.05,
                  colors: [colors.surface, colors.raised, colors.raisedShade],
                ),
              ),
              child: Center(
                child: busy
                    ? PorcelainSpinner(
                        color: colors.guestAccentText,
                        size: diameter * 0.42,
                      )
                    : Icon(
                        icon,
                        size: diameter * 0.4,
                        color: colors.guestAccentText,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A full guest screen that tells the guest something (S26, S29 and the
/// pause after an interruption): an emblem, a heading, words and up to two
/// large actions, centred, scrolling only when text is enlarged.
class GuestNotice extends StatelessWidget {
  const GuestNotice({
    super.key,
    required this.title,
    required this.body,
    this.icon,
    this.busy = false,
    this.actions = const [],
  });

  final String title;
  final String body;
  final IconData? icon;
  final bool busy;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return GuestBackdrop(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = GuestScale.forSize(constraints.biggest);
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
                minWidth: constraints.maxWidth,
                maxWidth: constraints.maxWidth,
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: scale(PorcelainSpace.giant),
                    vertical: scale(PorcelainSpace.xxl),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: scale(640)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GuestEmblem(scale: scale, icon: icon, busy: busy),
                        SizedBox(height: scale(PorcelainSpace.xxl)),
                        GuestHeading(title: title, scale: scale),
                        SizedBox(height: scale(PorcelainSpace.md)),
                        Text(
                          body,
                          textAlign: TextAlign.center,
                          style: scale.text(theme.text.guestBody),
                        ),
                        if (actions.isNotEmpty) ...[
                          SizedBox(height: scale(PorcelainSpace.xxl)),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: scale(PorcelainSpace.lg),
                            runSpacing: scale(PorcelainSpace.md),
                            children: actions,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Still gold confetti for the finished screen (S27, CR-002): scattered
/// along the top and the edges, never behind the words. Painted the same
/// way every time; decoration only.
class GuestConfetti extends StatelessWidget {
  const GuestConfetti({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter([
            colors.primaryTop,
            colors.primaryEdge,
            colors.primaryBottom,
          ]),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.palette);

  final List<Color> palette;

  @override
  void paint(Canvas canvas, Size size) {
    // A small linear congruential generator: the same scatter every time.
    var seed = 20261114;
    double next() {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return seed / 0x7fffffff;
    }

    final unit = size.shortestSide / 100;
    for (var i = 0; i < 72; i++) {
      // Mostly the top band and the two side bands.
      final band = next();
      final Offset at;
      if (band < 0.5) {
        at = Offset(next() * size.width, next() * size.height * 0.22);
      } else if (band < 0.75) {
        at = Offset(next() * size.width * 0.12, next() * size.height);
      } else {
        at = Offset(size.width * (0.88 + next() * 0.12), next() * size.height);
      }
      final color = palette[i % palette.length];
      final paint = Paint()
        ..color = color.withValues(alpha: 0.55 + next() * 0.4);
      canvas
        ..save()
        ..translate(at.dx, at.dy)
        ..rotate(next() * math.pi);
      final kind = i % 3;
      final w = unit * (0.6 + next() * 0.7);
      if (kind == 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: w, height: w * 2),
            Radius.circular(w * 0.2),
          ),
          paint,
        );
      } else if (kind == 1) {
        final path = Path()
          ..moveTo(0, -w)
          ..lineTo(w * 0.7, 0)
          ..lineTo(0, w)
          ..lineTo(-w * 0.7, 0)
          ..close();
        canvas.drawPath(path, paint);
      } else {
        canvas.drawCircle(Offset.zero, w * 0.45, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => !listEquals(old.palette, palette);
}
