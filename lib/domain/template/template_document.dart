/// Minimal template document for the M01 render spike (ADR-0003, ADR-0007).
///
/// Spike-grade: covers page size, background, photo slots and image layers
/// with normalised geometry, rotation, opacity and a global z-order. M04
/// adds versioned JSON, text and shape layers, assets and revisions.
library;

import 'geometry.dart';
import 'page_spec.dart';

/// A layer in the template's single global z-order.
sealed class TemplateLayer {
  const TemplateLayer({
    required this.id,
    required this.zIndex,
    required this.frame,
    this.rotationDegrees = 0,
    this.opacity = 1,
    this.visible = true,
  });

  /// Stable identifier, unique within the document.
  final String id;

  /// Higher values paint later (on top). Ties keep document order.
  final int zIndex;

  final NormalizedRect frame;

  /// Clockwise rotation about the frame's centre.
  final double rotationDegrees;

  /// 0 (invisible) to 1 (opaque).
  final double opacity;

  final bool visible;
}

/// Where a guest photo goes. Only that photo is clipped to the slot; no
/// other layer is ever clipped by it (ADR-008).
final class PhotoSlotLayer extends TemplateLayer {
  const PhotoSlotLayer({
    required super.id,
    required super.zIndex,
    required super.frame,
    required this.slotIndex,
    super.rotationDegrees,
    super.opacity,
    super.visible,
    this.cornerRadius = 0,
    this.focalX = 0.5,
    this.focalY = 0.5,
  });

  /// Which captured photo fills this slot (0-based).
  final int slotIndex;

  /// Corner radius as a fraction of the page width.
  final double cornerRadius;

  /// The point of the photo kept centred when cropping to fill the slot,
  /// as fractions of the photo's width and height.
  final double focalX;
  final double focalY;
}

/// A decoration such as a transparent PNG. Drawn whole, never slot-clipped.
final class ImageLayer extends TemplateLayer {
  const ImageLayer({
    required super.id,
    required super.zIndex,
    required super.frame,
    required this.assetId,
    super.rotationDegrees,
    super.opacity,
    super.visible,
  });

  final String assetId;
}

final class TemplateDocument {
  const TemplateDocument({
    required this.id,
    required this.page,
    required this.backgroundArgb,
    required this.layers,
    this.schemaVersion = currentSchemaVersion,
  });

  static const currentSchemaVersion = 1;

  final int schemaVersion;
  final String id;
  final PageSpec page;

  /// Page background colour as 0xAARRGGBB.
  final int backgroundArgb;

  /// Layers in document order; paint order comes from [TemplateLayer.zIndex].
  final List<TemplateLayer> layers;

  /// Problems that make the document unrenderable. Empty when valid.
  List<String> validate() {
    final problems = <String>[];
    if (schemaVersion != currentSchemaVersion) {
      problems.add('unsupported schemaVersion $schemaVersion');
    }
    if (!page.isValid) problems.add('page size and dpi must be positive');
    final ids = <String>{};
    final slots = <int>{};
    for (final layer in layers) {
      if (layer.id.isEmpty) problems.add('layer with empty id');
      if (!ids.add(layer.id)) problems.add('duplicate layer id ${layer.id}');
      if (!layer.frame.hasPositiveSize) {
        problems.add('layer ${layer.id} has a non-positive size');
      }
      if (layer.opacity < 0 || layer.opacity > 1) {
        problems.add('layer ${layer.id} opacity must be within 0..1');
      }
      if (layer case PhotoSlotLayer(:final slotIndex, :final id)) {
        if (slotIndex < 0) problems.add('slot $id has a negative slotIndex');
        if (!slots.add(slotIndex)) {
          problems.add('duplicate slotIndex $slotIndex');
        }
      }
    }
    return problems;
  }

  /// Slot indexes in ascending order.
  List<int> get slotIndexes => [
    for (final layer in layers)
      if (layer is PhotoSlotLayer) layer.slotIndex,
  ]..sort();
}
