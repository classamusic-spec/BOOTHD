/// Immutable scene graph compiled from a [TemplateDocument] (A-06,
/// ADR-0003, ADR-0010).
///
/// The scene holds every visible layer's geometry in page pixels, in paint
/// order, with fit, crop, clip and mirroring already resolved. Previews,
/// the editor workspace and full-resolution exports all paint the same
/// scene (previews just scale it), so they cannot disagree about layout.
library;

import 'dart:math' as math;

import 'package:collection/collection.dart';

import 'document_issues.dart';
import 'geometry.dart';
import 'template_assets.dart';
import 'template_document.dart';
import 'template_layers.dart';

/// An image a scene draws.
sealed class ImageSourceRef {
  const ImageSourceRef();
}

/// An image asset of the template, by its content id.
final class AssetImageRef extends ImageSourceRef {
  const AssetImageRef(this.assetId);

  final String assetId;

  @override
  bool operator ==(Object other) =>
      other is AssetImageRef && other.assetId == assetId;

  @override
  int get hashCode => assetId.hashCode;

  @override
  String toString() => 'asset:$assetId';
}

/// A guest photo (a session original), by its id.
final class PhotoImageRef extends ImageSourceRef {
  const PhotoImageRef(this.photoId);

  final String photoId;

  @override
  bool operator ==(Object other) =>
      other is PhotoImageRef && other.photoId == photoId;

  @override
  int get hashCode => photoId.hashCode;

  @override
  String toString() => 'photo:$photoId';
}

/// The photo that fills one slot in one render.
final class SlotBinding {
  const SlotBinding({
    required this.photoId,
    required this.size,
    this.mirrored = false,
  });

  final String photoId;

  /// The photo's size as decoded, with its EXIF orientation applied by the
  /// decoder (ADR-0007): orientation is applied once, never again.
  final PixelSize size;

  /// Output mirroring (P-05): guests see the photo flipped left to right.
  final bool mirrored;

  @override
  bool operator ==(Object other) =>
      other is SlotBinding &&
      other.photoId == photoId &&
      other.size == size &&
      other.mirrored == mirrored;

  @override
  int get hashCode => Object.hash(photoId, size, mirrored);
}

/// Where a node is drawn: [rect] in page pixels before rotation, turned
/// [rotationRadians] clockwise about [pivot].
final class NodePlacement {
  const NodePlacement({
    required this.rect,
    this.rotationRadians = 0,
    this._pivot,
  });

  final PixelRect rect;
  final double rotationRadians;
  final PixelPoint? _pivot;

  PixelPoint get pivot => _pivot ?? PixelPoint(rect.centerX, rect.centerY);

  /// Maps a point in the node's unrotated page coordinates to the page.
  PixelPoint toPage(PixelPoint local) =>
      local.rotatedAbout(pivot, rotationRadians);

  /// The node's footprint on the page.
  PixelRect get bounds => rect.rotatedBounds(pivot, rotationRadians);
}

sealed class SceneFill {
  const SceneFill();
}

final class SceneSolidFill extends SceneFill {
  const SceneSolidFill(this.color);

  final ArgbColor color;
}

/// A linear gradient from [start] to [end] (page pixels).
final class SceneGradientFill extends SceneFill {
  const SceneGradientFill({
    required this.start,
    required this.end,
    required this.colors,
    required this.offsets,
  });

  final PixelPoint start;
  final PixelPoint end;
  final List<ArgbColor> colors;
  final List<double> offsets;
}

final class SceneImageFill extends SceneFill {
  const SceneImageFill({
    required this.source,
    required this.sourceCrop,
    required this.destRect,
  });

  final AssetImageRef source;
  final PixelRect sourceCrop;
  final PixelRect destRect;
}

sealed class SceneClip {
  const SceneClip();
}

final class SceneRectClip extends SceneClip {
  const SceneRectClip();
}

final class SceneRoundedRectClip extends SceneClip {
  const SceneRoundedRectClip(this.radiusPx);

  final double radiusPx;
}

final class SceneEllipseClip extends SceneClip {
  const SceneEllipseClip();
}

/// The photo shows where [mask] is opaque; the mask fills the slot.
final class SceneMaskClip extends SceneClip {
  const SceneMaskClip(this.mask);

  final AssetImageRef mask;
}

final class SceneStroke {
  const SceneStroke({required this.widthPx, required this.color});

  final double widthPx;
  final ArgbColor color;
}

/// One paint step, bottom first. [opacity] applies to the node as a group.
sealed class SceneNode {
  const SceneNode({
    required this.layerId,
    required this.placement,
    required this.opacity,
  });

  final String layerId;
  final NodePlacement placement;
  final double opacity;
}

/// The page background; [placement] covers the page.
final class FillNode extends SceneNode {
  const FillNode({
    required super.layerId,
    required super.placement,
    required super.opacity,
    required this.fill,
  });

  final SceneFill fill;
}

/// Draws [sourceCrop] of a photo into [destRect], clipped to the slot's
/// shape ([placement.rect]); nothing else is ever clipped by it.
final class PhotoNode extends SceneNode {
  const PhotoNode({
    required super.layerId,
    required super.placement,
    required super.opacity,
    required this.source,
    required this.sourceCrop,
    required this.destRect,
    required this.mirrored,
    required this.clip,
    this.border,
  });

  final PhotoImageRef source;

  /// Region of the photo in its own (unmirrored) pixels.
  final PixelRect sourceCrop;
  final PixelRect destRect;

  /// Draw [sourceCrop] flipped left to right within [destRect].
  final bool mirrored;
  final SceneClip clip;

  /// Drawn inside the slot edge, above the photo.
  final SceneStroke? border;
}

/// Draws [sourceCrop] of an image into [destRect]. Never slot-clipped.
final class ImageNode extends SceneNode {
  const ImageNode({
    required super.layerId,
    required super.placement,
    required super.opacity,
    required this.source,
    required this.sourceCrop,
    required this.destRect,
  });

  final AssetImageRef source;
  final PixelRect sourceCrop;
  final PixelRect destRect;
}

/// Text laid out by the painter inside [placement.rect], wrapping at its
/// width. Sizes are in page pixels.
final class TextNode extends SceneNode {
  const TextNode({
    required super.layerId,
    required super.placement,
    required super.opacity,
    required this.text,
    required this.font,
    required this.sizePx,
    required this.color,
    required this.align,
    required this.verticalAlign,
    required this.lineHeight,
    required this.letterSpacingPx,
  });

  final String text;
  final FontRef font;
  final double sizePx;
  final ArgbColor color;
  final TextAlignment align;
  final VerticalAlignment verticalAlign;
  final double lineHeight;
  final double letterSpacingPx;
}

final class ShapeNode extends SceneNode {
  const ShapeNode({
    required super.layerId,
    required super.placement,
    required super.opacity,
    required this.shape,
    required this.cornerRadiusPx,
    this.fill,
    this.stroke,
  });

  final ShapeKind shape;
  final double cornerRadiusPx;
  final ArgbColor? fill;

  /// Drawn inside the shape's edge.
  final SceneStroke? stroke;
}

final class DocumentScene {
  const DocumentScene({
    required this.widthPx,
    required this.heightPx,
    required this.nodes,
    required this.imageSizes,
  });

  final int widthPx;
  final int heightPx;

  /// Nodes in paint order, bottom first.
  final List<SceneNode> nodes;

  /// Every image the scene draws, with the size it was compiled against.
  final Map<ImageSourceRef, PixelSize> imageSizes;

  /// Fonts the text nodes use.
  Set<FontRef> get fonts => {
    for (final node in nodes)
      if (node case TextNode(:final font)) font,
  };

  /// The largest scale at which the scene draws [source] (output pixels per
  /// source pixel), so it can be decoded no larger than needed. Masks are
  /// stretched to their slot.
  double drawScale(ImageSourceRef source) {
    var scale = 0.0;
    void consider(PixelRect crop, PixelRect dest) {
      scale = math.max(
        scale,
        math.max(dest.width / crop.width, dest.height / crop.height),
      );
    }

    for (final node in nodes) {
      switch (node) {
        case FillNode(fill: final SceneImageFill fill)
            when fill.source == source:
          consider(fill.sourceCrop, fill.destRect);
        case PhotoNode():
          if (node.source == source) consider(node.sourceCrop, node.destRect);
          if (node.clip case SceneMaskClip(:final mask) when mask == source) {
            final size = imageSizes[mask]!;
            consider(
              PixelRect(
                left: 0,
                top: 0,
                width: size.width.toDouble(),
                height: size.height.toDouble(),
              ),
              node.placement.rect,
            );
          }
        case ImageNode() when node.source == source:
          consider(node.sourceCrop, node.destRect);
        default:
          break;
      }
    }
    return scale;
  }
}

/// A document could not be compiled into a scene.
final class SceneCompileException implements Exception {
  const SceneCompileException(this.issues);

  final List<DocumentIssue> issues;

  @override
  String toString() =>
      'SceneCompileException(${issues.map((i) => '$i').join('; ')})';
}

/// Compiles [document] with one [SlotBinding] per photo slot.
///
/// Throws [SceneCompileException] when the document has errors or a slot
/// has no usable photo. Hidden and fully transparent layers are omitted.
DocumentScene compileScene(
  TemplateDocument document, {
  required Map<int, SlotBinding> bindings,
}) {
  final issues = [
    ...document.errors,
    for (final slot in document.photoSlots)
      if (bindings[slot.slotIndex] == null)
        DocumentIssue(
          DocumentIssueCode.missingAsset,
          'slots[${slot.slotIndex}]',
          'Photo ${slot.slotIndex + 1} has no picture.',
        )
      else if (!bindings[slot.slotIndex]!.size.isPositive)
        DocumentIssue(
          DocumentIssueCode.invalidValue,
          'slots[${slot.slotIndex}]',
          'Photo ${slot.slotIndex + 1} has no pixels.',
        ),
  ];
  if (issues.isNotEmpty) throw SceneCompileException(issues);

  final page = document.page;
  final widthPx = page.widthPx;
  final heightPx = page.heightPx;
  final pagePx = PixelRect(
    left: 0,
    top: 0,
    width: widthPx.toDouble(),
    height: heightPx.toDouble(),
  );
  final points = page.pixelsPerPoint;
  final imageSizes = <ImageSourceRef, PixelSize>{};

  AssetImageRef assetRef(String assetId) {
    final asset = document.assets[assetId]!;
    final ref = AssetImageRef(assetId);
    imageSizes[ref] = PixelSize(asset.widthPx!, asset.heightPx!);
    return ref;
  }

  SceneStroke? stroke(Stroke? stroke) => stroke == null
      ? null
      : SceneStroke(widthPx: stroke.widthPt * points, color: stroke.color);

  final nodes = <SceneNode>[];
  for (final layer in document.paintOrder) {
    if (!layer.visible || layer.opacity == 0) continue;
    if (layer is BackgroundLayer) {
      nodes.add(
        FillNode(
          layerId: layer.id,
          placement: NodePlacement(rect: pagePx),
          opacity: layer.opacity,
          fill: switch (layer.fill) {
            SolidFill(:final color) => SceneSolidFill(color),
            LinearGradientFill(:final angleDegrees, :final stops) => _gradient(
              pagePx,
              angleDegrees,
              stops,
            ),
            ImageFill(:final assetId, :final fit) => () {
              final ref = assetRef(assetId);
              final (crop, dest) = _fitImage(
                imageSizes[ref]!,
                NormalizedRect.page,
                pagePx,
                fit,
              );
              return SceneImageFill(
                source: ref,
                sourceCrop: crop,
                destRect: dest,
              );
            }(),
          },
        ),
      );
      continue;
    }
    final framed = layer as FramedLayer;
    final rect = framed.frame.toPixels(
      pageWidthPx: widthPx,
      pageHeightPx: heightPx,
    );
    final placement = NodePlacement(
      rect: rect,
      rotationRadians: framed.rotationDegrees * math.pi / 180,
      pivot: rect.pointAt(framed.pivot),
    );
    switch (framed) {
      case PhotoSlotLayer():
        final binding = bindings[framed.slotIndex]!;
        final source = PhotoImageRef(binding.photoId);
        imageSizes[source] = binding.size;
        final (crop, dest) = _fitPhoto(binding, rect, framed);
        nodes.add(
          PhotoNode(
            layerId: framed.id,
            placement: placement,
            opacity: framed.opacity,
            source: source,
            sourceCrop: crop,
            destRect: dest,
            mirrored: binding.mirrored,
            clip: switch (framed.clip) {
              RectClip() => const SceneRectClip(),
              RoundedRectClip(:final cornerRadius) => SceneRoundedRectClip(
                cornerRadius * rect.shortestSide,
              ),
              EllipseClip() => const SceneEllipseClip(),
              MaskClip(:final assetId) => SceneMaskClip(assetRef(assetId)),
            },
            border: stroke(framed.border),
          ),
        );
      case ImageLayer():
        final ref = assetRef(framed.assetId);
        final (crop, dest) = _fitImage(
          imageSizes[ref]!,
          framed.crop,
          rect,
          framed.fit,
        );
        nodes.add(
          ImageNode(
            layerId: framed.id,
            placement: placement,
            opacity: framed.opacity,
            source: ref,
            sourceCrop: crop,
            destRect: dest,
          ),
        );
      case TextLayer():
        nodes.add(
          TextNode(
            layerId: framed.id,
            placement: placement,
            opacity: framed.opacity,
            text: framed.text,
            font: framed.font,
            sizePx: framed.sizePt * points,
            color: framed.color,
            align: framed.align,
            verticalAlign: framed.verticalAlign,
            lineHeight: framed.lineHeight,
            letterSpacingPx: framed.letterSpacingPt * points,
          ),
        );
      case ShapeLayer():
        nodes.add(
          ShapeNode(
            layerId: framed.id,
            placement: placement,
            opacity: framed.opacity,
            shape: framed.shape,
            cornerRadiusPx: framed.shape == ShapeKind.roundedRect
                ? framed.cornerRadius * rect.shortestSide
                : 0,
            fill: framed.fill,
            stroke: stroke(framed.stroke),
          ),
        );
    }
  }
  return DocumentScene(
    widthPx: widthPx,
    heightPx: heightPx,
    nodes: List.unmodifiable(nodes),
    imageSizes: Map.unmodifiable(imageSizes),
  );
}

/// Photo placement: cover crops around the focal point as guests see the
/// photo (after mirroring); contain shows the whole photo centred.
(PixelRect, PixelRect) _fitPhoto(
  SlotBinding binding,
  PixelRect slot,
  PhotoSlotLayer layer,
) {
  final width = binding.size.width.toDouble();
  final height = binding.size.height.toDouble();
  switch (layer.fit) {
    case PhotoFit.contain:
      return (
        PixelRect(left: 0, top: 0, width: width, height: height),
        containRect(slot, width / height),
      );
    case PhotoFit.cover:
      final shown = coverCrop(
        sourceWidth: width,
        sourceHeight: height,
        targetWidth: slot.width,
        targetHeight: slot.height,
        focal: layer.focal,
      );
      final crop = binding.mirrored
          ? PixelRect(
              left: width - shown.right,
              top: shown.top,
              width: shown.width,
              height: shown.height,
            )
          : shown;
      return (crop, slot);
  }
}

/// Image placement within [box] for [fit], using the [crop] part of an
/// image of [size].
(PixelRect, PixelRect) _fitImage(
  PixelSize size,
  NormalizedRect crop,
  PixelRect box,
  ImageFit fit,
) {
  final region = crop.toPixels(
    pageWidthPx: size.width,
    pageHeightPx: size.height,
  );
  switch (fit) {
    case ImageFit.fill:
      return (region, box);
    case ImageFit.contain:
      return (region, containRect(box, region.width / region.height));
    case ImageFit.cover:
      final inner = coverCrop(
        sourceWidth: region.width,
        sourceHeight: region.height,
        targetWidth: box.width,
        targetHeight: box.height,
      );
      return (
        PixelRect(
          left: region.left + inner.left,
          top: region.top + inner.top,
          width: inner.width,
          height: inner.height,
        ),
        box,
      );
  }
}

/// A CSS-style linear gradient across [page]: the first and last colours
/// reach the corners along the gradient line.
SceneGradientFill _gradient(
  PixelRect page,
  double angleDegrees,
  List<GradientStop> stops,
) {
  final radians = angleDegrees * math.pi / 180;
  final dx = math.cos(radians);
  final dy = math.sin(radians);
  final half = (page.width / 2 * dx).abs() + (page.height / 2 * dy).abs();
  return SceneGradientFill(
    start: PixelPoint(page.centerX - dx * half, page.centerY - dy * half),
    end: PixelPoint(page.centerX + dx * half, page.centerY + dy * half),
    colors: [for (final stop in stops) stop.color],
    offsets: [for (final stop in stops) stop.offset],
  );
}

extension DocumentSceneQueries on DocumentScene {
  /// The node drawn for [layerId], if visible.
  SceneNode? nodeFor(String layerId) =>
      nodes.firstWhereOrNull((node) => node.layerId == layerId);
}
