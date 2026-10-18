import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_colors.dart';
import '../../core/design_system/porcelain_depth.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_theme.dart';
import 'botanical_ornament.dart';

/// A simple, aspect-exact miniature of a print page: paper, photo-slot
/// placeholders and (optionally) a sprig crossing a slot edge, the way
/// decoration layers overlap slots in real templates.
///
/// It is a schematic, not a render; real template thumbnails come from the
/// renderer (M04/M05).
class TemplateThumbnail extends StatelessWidget {
  const TemplateThumbnail({
    super.key,
    required this.pageWidth,
    required this.pageHeight,
    required this.slots,
    required this.semanticLabel,
    this.height = 168,
    this.decorated = true,
  });

  /// Page size in any unit; only the ratio matters.
  final double pageWidth;
  final double pageHeight;

  /// Photo slots in page-normalised coordinates (0 to 1).
  final List<Rect> slots;
  final String semanticLabel;
  final double height;
  final bool decorated;

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    final width = height * pageWidth / pageHeight;
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.raised,
                    border: Border.all(color: colors.hairline),
                    borderRadius: const BorderRadius.all(Radius.circular(3)),
                    boxShadow: PorcelainDepth.shadows(colors, 1.2),
                  ),
                ),
              ),
              for (final slot in slots)
                Positioned(
                  left: slot.left * width,
                  top: slot.top * height,
                  width: slot.width * width,
                  height: slot.height * height,
                  child: _Slot(colors: colors),
                ),
              if (decorated && slots.isNotEmpty)
                Positioned(
                  left: (slots.first.right * width) - height * 0.16,
                  top: (slots.first.bottom * height) - height * 0.16,
                  child: BotanicalOrnament.sprig(
                    width: height * 0.3,
                    height: height * 0.3,
                    leaves: 5,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.colors});

  final PorcelainColors colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.inset, colors.selected],
        ),
        borderRadius: const BorderRadius.all(Radius.circular(2)),
        border: Border.all(color: colors.hairline, width: 0.8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 28
            ? const SizedBox.shrink()
            : Center(
                child: Icon(
                  PorcelainIcons.camera,
                  size: (constraints.biggest.shortestSide * 0.36).clamp(
                    12.0,
                    28.0,
                  ),
                  color: colors.accentIcon,
                  weight: 300,
                ),
              ),
      ),
    );
  }
}
