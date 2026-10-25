import 'package:flutter/material.dart';

import '../../core/design_system/porcelain_theme.dart';
import '../../core/templates/template_thumbnails.dart';
import 'rendered_thumbnail.dart';

/// Real starter prints, rendered by the same scene graph as an export.
/// Decorative and non-interactive; selecting designs happens in the library.
class AtelierShowcase extends StatelessWidget {
  const AtelierShowcase({super.key, this.height = 400});

  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final printHeight = height * 0.78;
            final width = printHeight * 2 / 3;
            return DecoratedBox(
              decoration: BoxDecoration(
                color: colors.inset.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: colors.hairline),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (final (id, angle, offset, scale) in [
                    ('atelier_hydrangea', -0.13, -0.24, 0.86),
                    ('atelier_baby_sage', 0.12, 0.24, 0.86),
                    ('atelier_rose', -0.025, 0.0, 1.0),
                  ])
                    Transform.translate(
                      offset: Offset(constraints.maxWidth * offset, 0),
                      child: Transform.rotate(
                        angle: angle,
                        child: SizedBox(
                          width: width * scale,
                          height: printHeight * scale,
                          child: RenderedThumbnail(
                            thumbnail: starterThumbnailProvider(id),
                            aspectRatio: 2 / 3,
                            semanticLabel: '',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
