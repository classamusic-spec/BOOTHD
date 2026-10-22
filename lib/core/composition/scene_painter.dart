/// The single painter behind every preview, editor view and print export
/// (A-06, ADR-0003, ADR-0010).
///
/// It paints a compiled scene in page pixels; previews scale the canvas
/// rather than re-laying anything out, so text wraps identically at every
/// size. Each photo is clipped to its own slot shape and nothing else is
/// clipped by slots (AC-0403, AC-0404). Opacity applies to a layer as one
/// group, so a translucent shape's line never shows its fill through.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../domain/services/composition_renderer.dart';
import '../../domain/template/document_scene.dart';
import '../../domain/template/geometry.dart';
import '../../domain/template/template_assets.dart';
import '../../domain/template/template_layers.dart';
import 'scene_images.dart';
import 'template_fonts.dart';

/// Decoded images and resolved fonts for one scene.
final class SceneResources {
  SceneResources({required this.images, required this.fonts});

  final Map<ImageSourceRef, DecodedImage> images;
  final Map<FontRef, ResolvedFont> fonts;

  void dispose() {
    for (final image in images.values) {
      image.dispose();
    }
  }
}

/// Paints [scene] with the page's top-left corner at [origin] and [scale]
/// device pixels per page pixel. With [clipToPage], nothing is drawn
/// outside the page (exports); without it, artwork beyond the page edge
/// shows (the editor workspace). Returns what the operator should know:
/// fonts that fell back and text that overflowed its frame.
///
/// [include] limits painting to some nodes (by index and node) without
/// changing how any node is painted: the Live Template Camera paints the
/// nodes below the active slot, then the live picture, then the rest
/// (EP06). Exports never pass it.
List<RenderWarning> paintScene(
  ui.Canvas canvas,
  DocumentScene scene,
  SceneResources resources, {
  ui.Offset origin = ui.Offset.zero,
  double scale = 1,
  bool clipToPage = true,
  bool Function(int index, SceneNode node)? include,
}) {
  final warnings = <RenderWarning>[];
  canvas
    ..save()
    ..translate(origin.dx, origin.dy)
    ..scale(scale);
  if (clipToPage) {
    canvas.clipRect(
      ui.Rect.fromLTWH(
        0,
        0,
        scene.widthPx.toDouble(),
        scene.heightPx.toDouble(),
      ),
    );
  }
  for (final (index, node) in scene.nodes.indexed) {
    if (include != null && !include(index, node)) continue;
    _paintNode(canvas, node, resources, warnings);
  }
  canvas.restore();
  return warnings;
}

ui.Rect _rect(PixelRect rect) =>
    ui.Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height);

ui.Color _color(ArgbColor color) => ui.Color(color.value);

final _imagePaint = ui.Paint()..filterQuality = ui.FilterQuality.high;

void _paintNode(
  ui.Canvas canvas,
  SceneNode node,
  SceneResources resources,
  List<RenderWarning> warnings,
) {
  final placement = node.placement;
  canvas.save();
  if (placement.rotationRadians != 0) {
    final pivot = placement.pivot;
    canvas
      ..translate(pivot.x, pivot.y)
      ..rotate(placement.rotationRadians)
      ..translate(-pivot.x, -pivot.y);
  }
  final grouped = node.opacity < 1;
  if (grouped) {
    canvas.saveLayer(
      // Text may overflow its frame, so its group is unbounded.
      node is TextNode ? null : _rect(placement.rect),
      ui.Paint()..color = ui.Color.fromRGBO(0, 0, 0, node.opacity),
    );
  }
  switch (node) {
    case FillNode(:final fill):
      _paintFill(canvas, _rect(placement.rect), fill, resources);
    case PhotoNode():
      _paintPhoto(canvas, node, resources);
    case ImageNode(:final source, :final sourceCrop, :final destRect):
      final image = resources.images[source]!;
      canvas.drawImageRect(
        image.image,
        image.decodedRect(sourceCrop),
        _rect(destRect),
        _imagePaint,
      );
    case TextNode():
      _paintText(canvas, node, resources, warnings);
    case ShapeNode():
      _paintShape(canvas, node);
  }
  if (grouped) canvas.restore();
  canvas.restore();
}

void _paintFill(
  ui.Canvas canvas,
  ui.Rect page,
  SceneFill fill,
  SceneResources resources,
) {
  switch (fill) {
    case SceneSolidFill(:final color):
      canvas.drawRect(page, ui.Paint()..color = _color(color));
    case SceneGradientFill(
      :final start,
      :final end,
      :final colors,
      :final offsets,
    ):
      canvas.drawRect(
        page,
        ui.Paint()
          ..shader = ui.Gradient.linear(
            ui.Offset(start.x, start.y),
            ui.Offset(end.x, end.y),
            [for (final color in colors) _color(color)],
            offsets,
          ),
      );
    case SceneImageFill(:final source, :final sourceCrop, :final destRect):
      final image = resources.images[source]!;
      canvas.drawImageRect(
        image.image,
        image.decodedRect(sourceCrop),
        _rect(destRect),
        _imagePaint,
      );
  }
}

/// Fills the photo's slot shape (when contained, only the part the photo
/// covers) through an image shader, so every edge is anti-aliased once. A
/// clip and an image edge on the same line would each cover a pixel the
/// edge cuts, multiplying their coverage into a pale seam wherever a slot
/// edge falls between pixels.
void _paintPhoto(ui.Canvas canvas, PhotoNode node, SceneResources resources) {
  final slot = _rect(node.placement.rect);
  final dest = _rect(node.destRect);
  final clip = node.clip;
  final shape = switch (clip) {
    SceneRectClip() || SceneMaskClip() => ui.Path()..addRect(slot),
    SceneRoundedRectClip(:final radiusPx) =>
      ui.Path()..addRRect(
        ui.RRect.fromRectAndRadius(slot, ui.Radius.circular(radiusPx)),
      ),
    SceneEllipseClip() => ui.Path()..addOval(slot),
  };
  final area = _contains(dest, slot)
      ? shape
      : ui.Path.combine(
          ui.PathOperation.intersect,
          shape,
          ui.Path()..addRect(dest),
        );
  final photo = resources.images[node.source]!;
  final photoShader = _imageShader(
    photo.image,
    photo.decodedRect(node.sourceCrop),
    dest,
    mirrored: node.mirrored,
  );
  if (clip case SceneMaskClip(:final mask)) {
    // The mask keeps the photo where it is opaque. It is applied without
    // anti-aliasing over more than the slot, its edge pixels extended, so
    // it scales the photo's anti-aliased edge instead of cutting it again.
    final maskImage = resources.images[mask]!;
    final maskShader = _imageShader(maskImage.image, maskImage.fullRect, slot);
    canvas
      ..saveLayer(slot, ui.Paint())
      ..drawPath(area, ui.Paint()..shader = photoShader)
      ..drawRect(
        slot.inflate(slot.shortestSide),
        ui.Paint()
          ..shader = maskShader
          ..blendMode = ui.BlendMode.dstIn
          ..isAntiAlias = false,
      )
      ..restore();
    maskShader.dispose();
  } else {
    canvas.drawPath(area, ui.Paint()..shader = photoShader);
  }
  photoShader.dispose();

  final border = node.border;
  if (border != null) {
    _strokeShape(canvas, slot, border, switch (clip) {
      SceneEllipseClip() => ShapeKind.ellipse,
      SceneRoundedRectClip() => ShapeKind.roundedRect,
      _ => ShapeKind.rect,
    }, clip is SceneRoundedRectClip ? clip.radiusPx : 0);
  }
}

/// Whether [outer] covers [inner], allowing for rounding in the fit.
bool _contains(ui.Rect outer, ui.Rect inner) =>
    outer.left <= inner.left + 1e-6 &&
    outer.top <= inner.top + 1e-6 &&
    outer.right >= inner.right - 1e-6 &&
    outer.bottom >= inner.bottom - 1e-6;

/// A shader drawing [source] (decoded pixels of [image]) into [dest],
/// flipped left to right when [mirrored]. Outside [source] it repeats the
/// edge pixels, which only ever reach the sub-pixel fringe of an edge.
ui.ImageShader _imageShader(
  ui.Image image,
  ui.Rect source,
  ui.Rect dest, {
  bool mirrored = false,
}) {
  final scaleX = dest.width / source.width;
  final scaleY = dest.height / source.height;
  final matrix = Float64List(16)
    ..[0] = mirrored ? -scaleX : scaleX
    ..[5] = scaleY
    ..[10] = 1
    ..[12] = mirrored
        ? dest.right + source.left * scaleX
        : dest.left - source.left * scaleX
    ..[13] = dest.top - source.top * scaleY
    ..[15] = 1;
  return ui.ImageShader(
    image,
    ui.TileMode.clamp,
    ui.TileMode.clamp,
    matrix,
    filterQuality: ui.FilterQuality.high,
  );
}

void _paintShape(ui.Canvas canvas, ShapeNode node) {
  final rect = _rect(node.placement.rect);
  final fill = node.fill;
  if (fill != null) {
    final paint = ui.Paint()..color = _color(fill);
    switch (node.shape) {
      case ShapeKind.rect:
        canvas.drawRect(rect, paint);
      case ShapeKind.roundedRect:
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(
            rect,
            ui.Radius.circular(node.cornerRadiusPx),
          ),
          paint,
        );
      case ShapeKind.ellipse:
        canvas.drawOval(rect, paint);
    }
  }
  final stroke = node.stroke;
  if (stroke != null) {
    _strokeShape(canvas, rect, stroke, node.shape, node.cornerRadiusPx);
  }
}

/// Strokes [shape] inside [rect]: the line's outer edge is the shape's edge.
void _strokeShape(
  ui.Canvas canvas,
  ui.Rect rect,
  SceneStroke stroke,
  ShapeKind shape,
  double cornerRadius,
) {
  final half = stroke.widthPx / 2;
  final inner = rect.deflate(half);
  final paint = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = stroke.widthPx
    ..color = _color(stroke.color);
  switch (shape) {
    case ShapeKind.rect:
      canvas.drawRect(inner, paint);
    case ShapeKind.roundedRect:
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          inner,
          ui.Radius.circular((cornerRadius - half).clamp(0, double.infinity)),
        ),
        paint,
      );
    case ShapeKind.ellipse:
      canvas.drawOval(inner, paint);
  }
}

void _paintText(
  ui.Canvas canvas,
  TextNode node,
  SceneResources resources,
  List<RenderWarning> warnings,
) {
  final rect = node.placement.rect;
  var font = resources.fonts[node.font];
  if (font == null || font.fellBack) {
    font ??= const ResolvedFont(
      fallbackFontFamily,
      ui.FontWeight.w400,
      fellBack: true,
    );
    warnings.add(
      RenderWarning(
        RenderWarningCode.fontFallback,
        node.layerId,
        'The font could not be loaded; $fallbackFontFamily was used.',
      ),
    );
  }
  final paragraph = layoutText(node, font);
  final factor = switch (node.verticalAlign) {
    VerticalAlignment.top => 0.0,
    VerticalAlignment.middle => 0.5,
    VerticalAlignment.bottom => 1.0,
  };
  canvas.drawParagraph(
    paragraph,
    ui.Offset(rect.left, rect.top + (rect.height - paragraph.height) * factor),
  );
  if (paragraph.height > rect.height + 0.5) {
    warnings.add(
      RenderWarning(
        RenderWarningCode.textOverflow,
        node.layerId,
        'The text is taller than its frame; the extra lines are still drawn.',
      ),
    );
  }
  paragraph.dispose();
}

/// Lays [node]'s text out at its frame's width, in page pixels. The strut
/// fixes every line's height to the chosen font and line height, so a
/// fallback glyph cannot move the lines.
ui.Paragraph layoutText(TextNode node, ResolvedFont font) {
  final builder =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            textAlign: switch (node.align) {
              TextAlignment.left => ui.TextAlign.left,
              TextAlignment.center => ui.TextAlign.center,
              TextAlignment.right => ui.TextAlign.right,
            },
            textDirection: ui.TextDirection.ltr,
            strutStyle: ui.StrutStyle(
              fontFamily: font.family,
              fontSize: node.sizePx,
              height: node.lineHeight,
              fontWeight: font.weight,
              leadingDistribution: ui.TextLeadingDistribution.even,
              forceStrutHeight: true,
            ),
          ),
        )
        ..pushStyle(
          ui.TextStyle(
            color: _color(node.color),
            fontFamily: font.family,
            fontFamilyFallback: const [fallbackFontFamily],
            fontSize: node.sizePx,
            fontWeight: font.weight,
            letterSpacing: node.letterSpacingPx,
            height: node.lineHeight,
            leadingDistribution: ui.TextLeadingDistribution.even,
          ),
        )
        ..addText(node.text);
  return builder.build()
    ..layout(ui.ParagraphConstraints(width: node.placement.rect.width));
}
