/// Immutable scene graph compiled from a [TemplateDocument] (ADR-0003).
///
/// The scene holds every layer's pixel geometry in paint order. Preview,
/// editor workspace and export renderers all paint the same scene, so they
/// cannot disagree about layout.
library;

import 'dart:math' as math;

import 'geometry.dart';
import 'template_document.dart';

/// The photo that fills one slot in one render.
final class SlotBinding {
  const SlotBinding({required this.assetId, required this.sourceSize});

  final String assetId;
  final PixelSize sourceSize;
}

/// One paint step. [rect] is in page pixels before rotation; rotation turns
/// clockwise about the rect's centre.
sealed class SceneNode {
  const SceneNode({
    required this.layerId,
    required this.assetId,
    required this.rect,
    required this.rotationRadians,
    required this.opacity,
  });

  final String layerId;
  final String assetId;
  final PixelRect rect;
  final double rotationRadians;
  final double opacity;
}

/// Draws [sourceCrop] of a photo into [rect], clipped to the slot shape.
final class PhotoNode extends SceneNode {
  const PhotoNode({
    required super.layerId,
    required super.assetId,
    required super.rect,
    required super.rotationRadians,
    required super.opacity,
    required this.sourceCrop,
    required this.cornerRadiusPx,
  });

  /// Region of the source photo, in source pixels.
  final PixelRect sourceCrop;
  final double cornerRadiusPx;
}

/// Draws a whole image into [rect]. Never clipped by photo slots.
final class ImageNode extends SceneNode {
  const ImageNode({
    required super.layerId,
    required super.assetId,
    required super.rect,
    required super.rotationRadians,
    required super.opacity,
  });
}

final class DocumentScene {
  const DocumentScene({
    required this.widthPx,
    required this.heightPx,
    required this.backgroundArgb,
    required this.nodes,
  });

  final int widthPx;
  final int heightPx;
  final int backgroundArgb;

  /// Nodes in paint order, bottom first.
  final List<SceneNode> nodes;

  Set<String> get assetIds => {for (final node in nodes) node.assetId};
}

/// A document could not be compiled into a scene.
final class SceneCompileException implements Exception {
  const SceneCompileException(this.problems);

  final List<String> problems;

  @override
  String toString() => 'SceneCompileException(${problems.join('; ')})';
}

/// Compiles [document] with one [SlotBinding] per photo slot.
///
/// Paint order is ascending [TemplateLayer.zIndex]; equal values keep
/// document order. Hidden and fully transparent layers are omitted.
DocumentScene compileScene(
  TemplateDocument document, {
  required Map<int, SlotBinding> bindings,
}) {
  final problems = [
    ...document.validate(),
    for (final slot in document.slotIndexes)
      if (!bindings.containsKey(slot)) 'slot $slot has no photo bound',
    for (final MapEntry(:key, :value) in bindings.entries)
      if (value.sourceSize.width <= 0 || value.sourceSize.height <= 0)
        'photo for slot $key has no pixels',
  ];
  if (problems.isNotEmpty) throw SceneCompileException(problems);

  final widthPx = document.page.widthPx;
  final heightPx = document.page.heightPx;
  final ordered =
      [for (var i = 0; i < document.layers.length; i++) (i, document.layers[i])]
        ..sort((a, b) {
          final byZ = a.$2.zIndex.compareTo(b.$2.zIndex);
          return byZ != 0 ? byZ : a.$1.compareTo(b.$1);
        });

  final nodes = <SceneNode>[];
  for (final (_, layer) in ordered) {
    if (!layer.visible || layer.opacity == 0) continue;
    final rect = layer.frame.toPixels(
      pageWidthPx: widthPx,
      pageHeightPx: heightPx,
    );
    final rotation = layer.rotationDegrees * math.pi / 180;
    switch (layer) {
      case PhotoSlotLayer():
        final binding = bindings[layer.slotIndex]!;
        nodes.add(
          PhotoNode(
            layerId: layer.id,
            assetId: binding.assetId,
            rect: rect,
            rotationRadians: rotation,
            opacity: layer.opacity,
            sourceCrop: coverCrop(
              source: binding.sourceSize,
              targetWidth: rect.width,
              targetHeight: rect.height,
              focalX: layer.focalX,
              focalY: layer.focalY,
            ),
            cornerRadiusPx: layer.cornerRadius * widthPx,
          ),
        );
      case ImageLayer():
        nodes.add(
          ImageNode(
            layerId: layer.id,
            assetId: layer.assetId,
            rect: rect,
            rotationRadians: rotation,
            opacity: layer.opacity,
          ),
        );
    }
  }
  return DocumentScene(
    widthPx: widthPx,
    heightPx: heightPx,
    backgroundArgb: document.backgroundArgb,
    nodes: List.unmodifiable(nodes),
  );
}

/// The region of [source] that fills a [targetWidth] x [targetHeight] box
/// when scaled uniformly to cover it, keeping the focal point (fractions of
/// the source size) as central as the image edges allow.
PixelRect coverCrop({
  required PixelSize source,
  required double targetWidth,
  required double targetHeight,
  double focalX = 0.5,
  double focalY = 0.5,
}) {
  final scale = math.max(
    targetWidth / source.width,
    targetHeight / source.height,
  );
  final cropWidth = math.min(source.width.toDouble(), targetWidth / scale);
  final cropHeight = math.min(source.height.toDouble(), targetHeight / scale);
  final left = (focalX * source.width - cropWidth / 2).clamp(
    0.0,
    source.width - cropWidth,
  );
  final top = (focalY * source.height - cropHeight / 2).clamp(
    0.0,
    source.height - cropHeight,
  );
  return PixelRect(left: left, top: top, width: cropWidth, height: cropHeight);
}
