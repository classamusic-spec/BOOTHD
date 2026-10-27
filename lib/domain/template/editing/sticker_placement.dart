/// Initial sticker placement in print pixels. Existing layers and the source
/// image are untouched; later dragging, resizing and rotation remain free.
library;

import 'dart:math' as math;

import '../geometry.dart';
import '../template_document.dart';
import '../template_layers.dart';
import 'editor_geometry.dart';

abstract final class StickerPlacement {
  /// A modest size at the source aspect ratio, inside the print-safe margin.
  /// Prefer clear space, then minimize overlap with text, photos and artwork.
  /// Full-page paintings and shape mats are backgrounds, not occupied content.
  static NormalizedRect initialFrame(
    TemplateDocument document, {
    required double aspect,
  }) {
    final page = document.page;
    final pw = page.widthPx.toDouble();
    final ph = page.heightPx.toDouble();
    final side = math.min(pw, ph) * 0.24;
    final width = aspect >= 1 ? side : side * aspect;
    final height = aspect >= 1 ? side / aspect : side;
    final margin = math.min(page.dpi / 8, math.min(pw, ph) * 0.1);
    final gap = page.dpi / 24;
    final occupied =
        <({PixelRect rect, double weight})>[
          for (final layer in document.layers)
            if (layer.visible && layer.opacity > 0 && layer is FramedLayer)
              if (layer is TextLayer ||
                  layer is PhotoSlotLayer ||
                  layer is ImageLayer)
                (
                  rect: LayerGeometry.of(layer, page).bounds,
                  weight: layer is TextLayer
                      ? 20
                      : (layer is PhotoSlotLayer ? 12 : 5),
                ),
        ]..removeWhere(
          (entry) =>
              entry.weight == 5 &&
              entry.rect.width * entry.rect.height >= pw * ph * 0.8,
        );
    final left = margin;
    final right = pw - margin - width;
    final top = margin;
    final bottom = ph - margin - height;
    PixelRect at(double x, double y) =>
        PixelRect(left: x, top: y, width: width, height: height);
    final candidates = [
      if (occupied.isEmpty) at((pw - width) / 2, (ph - height) / 2),
      at(right, bottom),
      at(left, bottom),
      at(right, top),
      at(left, top),
      for (var row = 0; row <= 12; row++)
        for (var col = 0; col <= 8; col++)
          at(
            left + (right - left) * col / 8,
            bottom - (bottom - top) * row / 12,
          ),
    ];
    double score(PixelRect candidate) {
      var result = 0.0;
      for (final entry in occupied) {
        final rect = entry.rect;
        final overlapWidth = math.max(
          0.0,
          math.min(candidate.right, rect.right + gap) -
              math.max(candidate.left, rect.left - gap),
        );
        final overlapHeight = math.max(
          0.0,
          math.min(candidate.bottom, rect.bottom + gap) -
              math.max(candidate.top, rect.top - gap),
        );
        result += overlapWidth * overlapHeight * entry.weight;
      }
      return result;
    }

    var best = candidates.first;
    var bestScore = double.infinity;
    for (final candidate in candidates) {
      final value = score(candidate);
      if (value < bestScore) {
        best = candidate;
        bestScore = value;
      }
      if (value == 0) break;
    }
    return NormalizedRect(
      x: best.left / pw,
      y: best.top / ph,
      width: best.width / pw,
      height: best.height / ph,
    );
  }
}
