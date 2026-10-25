import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/booth/booth_providers.dart';
import '../../core/design_system/porcelain_colors.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/experience/guest_theme.dart';
import '../../core/templates/template_thumbnails.dart';
import '../../domain/experience/experience_registry.dart';
import '../../domain/models/booth_event.dart';
import '../../shared/guest/guest_decorations.dart';
import '../../shared/widgets/floral_spray.dart';
import '../../shared/widgets/rendered_thumbnail.dart';

/// The top of an event's card (UX-P1): its guest look (canvas, colours
/// and decorations) with the photo designs it offers laid on it like
/// prints, the default one on top. Decorative only: the card says the
/// same in words.
class EventCover extends ConsumerWidget {
  const EventCover({super.key, required this.event, this.height = 136});

  final BoothEvent event;
  final double height;

  /// How many designs are laid out.
  static const maxPrints = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final experience = ExperienceRegistry.bundled.resolve(event.experience);
    final original = GuestTheme.originalAppearance(experience) != null;
    final selection = event.templates;
    final top = selection.defaultRevisionId;
    // Back to front: the others, then the default.
    final ids = [
      ...selection.revisionIds.where((id) => id != top).take(maxPrints - 1),
      ?top,
    ];
    final prints = [
      for (final id in ids)
        if (ref.watch(templateSummaryProvider(id)).value case final summary?)
          (id, summary.pageWidthPx / summary.pageHeightPx),
    ];
    return ExcludeSemantics(
      child: GuestExperienceScope(
        experience: experience,
        child: Builder(
          builder: (context) {
            final colors = context.porcelain.colors;
            final printHeight = height - 36;
            return SizedBox(
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.3),
                    radius: 1.4,
                    colors: [colors.surface, colors.canvas],
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    if (original) ...[
                      const Positioned(
                        right: -12,
                        top: -14,
                        child: FloralSpray(
                          kind: FloralSprayKind.corner,
                          width: 104,
                          height: 104,
                          mirrorX: true,
                        ),
                      ),
                      const Positioned(
                        left: -14,
                        bottom: -18,
                        child: FloralSpray(
                          kind: FloralSprayKind.corner,
                          width: 88,
                          height: 88,
                          mirrorY: true,
                        ),
                      ),
                    ] else
                      const Positioned.fill(
                        child: GuestDecorationLayer(dense: true),
                      ),
                    if (prints.isEmpty)
                      Center(child: _Medallion(colors: colors))
                    else
                      for (final (i, (id, aspect)) in prints.indexed)
                        Center(
                          child: _Print(
                            // Spread around the middle, the default (last)
                            // in front at the centre when there are three.
                            step: switch ((prints.length, i)) {
                              (1, _) => 0,
                              (2, 0) => -0.5,
                              (2, _) => 0.5,
                              (_, 0) => -1,
                              (_, 1) => 1,
                              _ => 0,
                            },
                            child: SizedBox(
                              height: printHeight,
                              width: printHeight * aspect,
                              child: RenderedThumbnail(
                                thumbnail: templateThumbnailProvider(id),
                                aspectRatio: aspect,
                                semanticLabel: '',
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// One design on the cover, turned and moved aside by [step].
class _Print extends StatelessWidget {
  const _Print({required this.step, required this.child});

  final double step;
  final Widget child;

  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: Offset(step * 46, step.abs() * 4),
    child: Transform.rotate(angle: step * 0.09 - 0.025, child: child),
  );
}

/// The start button in the look's colours, for an event without designs.
class _Medallion extends StatelessWidget {
  const _Medallion({required this.colors});

  final PorcelainColors colors;

  @override
  Widget build(BuildContext context) => Container(
    width: 64,
    height: 64,
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: SweepGradient(
        colors: [
          colors.primaryTop,
          colors.primaryEdge,
          colors.primaryBottom,
          colors.primaryTop,
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: colors.shadowKey,
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(shape: BoxShape.circle, color: colors.surface),
      child: Icon(
        PorcelainIcons.camera,
        size: 24,
        color: colors.guestAccentText,
      ),
    ),
  );
}
