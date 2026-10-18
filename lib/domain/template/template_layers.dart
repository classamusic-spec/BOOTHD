/// Template layers (A-06, P-07, ADR-0010): background, photo slot, image,
/// text and shape, all in one global z-order.
///
/// Geometry is page-normalised ([NormalizedRect]); frames may extend past
/// the page so the editor can show off-page artwork, while exports crop at
/// the page edge. Rotation is in degrees, clockwise, about [TemplateLayer.pivot]
/// (a point given as fractions of the frame; the centre by default). Sizes
/// meant to look the same at any resolution, such as text and strokes, are
/// in typographic points (1/72 inch).
library;

import 'package:collection/collection.dart';

import 'geometry.dart';
import 'template_assets.dart';

/// Anything a layer can be painted with.
sealed class TemplateLayer {
  const TemplateLayer({
    required this.id,
    required this.zIndex,
    this.name = '',
    this.opacity = 1,
    this.visible = true,
    this.locked = false,
  });

  /// Stable identifier, unique within the document.
  final String id;

  /// Higher values paint later (on top). Ties keep document order.
  final int zIndex;

  /// Operator-facing label; may be empty.
  final String name;

  /// 0 (invisible) to 1 (opaque). Applies to the whole layer as one group.
  final double opacity;

  /// Hidden layers are kept but never rendered.
  final bool visible;

  /// Editor-only: locked layers cannot be selected. Renderers ignore it.
  final bool locked;

  /// Asset ids this layer refers to.
  Set<String> get assetIds;
}

/// A layer with its own frame, rotation and pivot.
sealed class FramedLayer extends TemplateLayer {
  const FramedLayer({
    required super.id,
    required super.zIndex,
    required this.frame,
    super.name,
    super.opacity,
    super.visible,
    super.locked,
    this.rotationDegrees = 0,
    this.pivot = NormalizedPoint.center,
  });

  final NormalizedRect frame;

  /// Clockwise rotation about [pivot].
  final double rotationDegrees;

  /// The rotation centre as fractions of [frame].
  final NormalizedPoint pivot;
}

// ---------------------------------------------------------------- background

/// What fills the page behind every other layer.
sealed class BackgroundFill {
  const BackgroundFill();
}

final class SolidFill extends BackgroundFill {
  const SolidFill(this.color);

  final ArgbColor color;

  @override
  bool operator ==(Object other) => other is SolidFill && other.color == color;

  @override
  int get hashCode => color.hashCode;
}

/// One colour of a gradient at [offset] (0 to 1) along it.
final class GradientStop {
  const GradientStop(this.offset, this.color);

  final double offset;
  final ArgbColor color;

  @override
  bool operator ==(Object other) =>
      other is GradientStop && other.offset == offset && other.color == color;

  @override
  int get hashCode => Object.hash(offset, color);
}

/// A linear gradient across the whole page. [angleDegrees] 0 runs left to
/// right, 90 top to bottom (clockwise); the first and last stops reach the
/// page's corners, as in CSS.
final class LinearGradientFill extends BackgroundFill {
  const LinearGradientFill({required this.angleDegrees, required this.stops});

  static const minStops = 2;
  static const maxStops = 8;

  final double angleDegrees;
  final List<GradientStop> stops;

  @override
  bool operator ==(Object other) =>
      other is LinearGradientFill &&
      other.angleDegrees == angleDegrees &&
      const ListEquality<GradientStop>().equals(other.stops, stops);

  @override
  int get hashCode => Object.hash(angleDegrees, Object.hashAll(stops));
}

/// An image filling the page.
final class ImageFill extends BackgroundFill {
  const ImageFill(this.assetId, {this.fit = ImageFit.cover});

  final String assetId;
  final ImageFit fit;

  @override
  bool operator ==(Object other) =>
      other is ImageFill && other.assetId == assetId && other.fit == fit;

  @override
  int get hashCode => Object.hash(assetId, fit);
}

/// The page background. At most one per document, and always the lowest
/// layer, so backgrounds never compete (A-06). Without one, the page is
/// transparent: PNG exports keep the transparency, JPEG exports are
/// flattened onto the output profile's colour (ADR-0010).
final class BackgroundLayer extends TemplateLayer {
  const BackgroundLayer({
    required super.id,
    required super.zIndex,
    required this.fill,
    super.name,
    super.opacity,
    super.visible,
    super.locked,
  });

  final BackgroundFill fill;

  @override
  Set<String> get assetIds => switch (fill) {
    ImageFill(:final assetId) => {assetId},
    _ => const {},
  };

  @override
  bool operator ==(Object other) =>
      other is BackgroundLayer && _sameBase(this, other) && other.fill == fill;

  @override
  int get hashCode => Object.hash(_baseHash(this), fill);
}

// ---------------------------------------------------------------- photo slot

/// How a photo fills its slot.
enum PhotoFit {
  /// Fill the slot, cropping the photo around the focal point.
  cover,

  /// Show the whole photo inside the slot, leaving empty bands.
  contain,
}

/// The outline a slot clips its photo to.
sealed class SlotClip {
  const SlotClip();
}

final class RectClip extends SlotClip {
  const RectClip();

  @override
  bool operator ==(Object other) => other is RectClip;

  @override
  int get hashCode => (RectClip).hashCode;
}

/// A rounded rectangle; [cornerRadius] is a fraction of the slot's shorter
/// side (0 to 0.5).
final class RoundedRectClip extends SlotClip {
  const RoundedRectClip(this.cornerRadius);

  final double cornerRadius;

  @override
  bool operator ==(Object other) =>
      other is RoundedRectClip && other.cornerRadius == cornerRadius;

  @override
  int get hashCode => cornerRadius.hashCode;
}

/// An ellipse inscribed in the slot.
final class EllipseClip extends SlotClip {
  const EllipseClip();

  @override
  bool operator ==(Object other) => other is EllipseClip;

  @override
  int get hashCode => (EllipseClip).hashCode;
}

/// Any shape: the photo shows where the mask image is opaque. The mask is
/// stretched to the slot.
final class MaskClip extends SlotClip {
  const MaskClip(this.assetId);

  final String assetId;

  @override
  bool operator ==(Object other) =>
      other is MaskClip && other.assetId == assetId;

  @override
  int get hashCode => assetId.hashCode;
}

/// A line along a shape's edge; [widthPt] in points.
final class Stroke {
  const Stroke({required this.widthPt, required this.color});

  static const maxWidthPt = 200.0;

  final double widthPt;
  final ArgbColor color;

  @override
  bool operator ==(Object other) =>
      other is Stroke && other.widthPt == widthPt && other.color == color;

  @override
  int get hashCode => Object.hash(widthPt, color);
}

/// Where a guest photo goes. Only that photo is clipped to the slot; no
/// other layer is ever clipped by it (ADR-008, AC-0403).
final class PhotoSlotLayer extends FramedLayer {
  const PhotoSlotLayer({
    required super.id,
    required super.zIndex,
    required super.frame,
    required this.slotIndex,
    super.name,
    super.opacity,
    super.visible,
    super.locked,
    super.rotationDegrees,
    super.pivot,
    this.fit = PhotoFit.cover,
    this.focal = NormalizedPoint.center,
    this.clip = const RectClip(),
    this.border,
  });

  /// Most photos one session can take (P-05: 1 to 4; the schema allows 8).
  static const maxSlots = 8;

  /// Which captured photo fills this slot (0-based, in capture order).
  final int slotIndex;

  final PhotoFit fit;

  /// The point of the photo kept centred when cropping, as fractions of
  /// the photo as guests see it (after any output mirroring).
  final NormalizedPoint focal;

  final SlotClip clip;

  /// Drawn inside the slot's edge, above the photo. Not available with a
  /// mask clip.
  final Stroke? border;

  @override
  Set<String> get assetIds => switch (clip) {
    MaskClip(:final assetId) => {assetId},
    _ => const {},
  };

  @override
  bool operator ==(Object other) =>
      other is PhotoSlotLayer &&
      _sameFramed(this, other) &&
      other.slotIndex == slotIndex &&
      other.fit == fit &&
      other.focal == focal &&
      other.clip == clip &&
      other.border == border;

  @override
  int get hashCode =>
      Object.hash(_framedHash(this), slotIndex, fit, focal, clip, border);
}

// --------------------------------------------------------------------- image

/// How an image layer fills its frame.
enum ImageFit {
  /// Stretch to the frame exactly.
  fill,

  /// Keep the aspect ratio and show all of it, centred.
  contain,

  /// Keep the aspect ratio and fill the frame, cropping the edges.
  cover,
}

/// A decoration such as a transparent PNG. Drawn whole and never clipped by
/// photo slots, even where it overlaps them (AC-0403).
final class ImageLayer extends FramedLayer {
  const ImageLayer({
    required super.id,
    required super.zIndex,
    required super.frame,
    required this.assetId,
    super.name,
    super.opacity,
    super.visible,
    super.locked,
    super.rotationDegrees,
    super.pivot,
    this.fit = ImageFit.fill,
    this.crop = NormalizedRect.page,
  });

  final String assetId;
  final ImageFit fit;

  /// The part of the image used, as fractions of its size.
  final NormalizedRect crop;

  @override
  Set<String> get assetIds => {assetId};

  @override
  bool operator ==(Object other) =>
      other is ImageLayer &&
      _sameFramed(this, other) &&
      other.assetId == assetId &&
      other.fit == fit &&
      other.crop == crop;

  @override
  int get hashCode => Object.hash(_framedHash(this), assetId, fit, crop);
}

// ---------------------------------------------------------------------- text

enum TextAlignment { left, center, right }

enum VerticalAlignment { top, middle, bottom }

/// Text laid out inside its frame, wrapping at the frame's width. Text is a
/// decoration: lines that do not fit are still drawn, and renderers report
/// the overflow (ADR-0010).
final class TextLayer extends FramedLayer {
  const TextLayer({
    required super.id,
    required super.zIndex,
    required super.frame,
    required this.text,
    required this.font,
    required this.sizePt,
    required this.color,
    super.name,
    super.opacity,
    super.visible,
    super.locked,
    super.rotationDegrees,
    super.pivot,
    this.align = TextAlignment.center,
    this.verticalAlign = VerticalAlignment.middle,
    this.lineHeight = 1.2,
    this.letterSpacingPt = 0,
  });

  static const maxLength = 2000;
  static const maxSizePt = 1000.0;

  final String text;
  final FontRef font;

  /// Font size in points.
  final double sizePt;
  final ArgbColor color;
  final TextAlignment align;
  final VerticalAlignment verticalAlign;

  /// Line height as a multiple of the font size.
  final double lineHeight;

  /// Extra space between letters, in points.
  final double letterSpacingPt;

  @override
  Set<String> get assetIds => switch (font) {
    AssetFont(:final assetId) => {assetId},
    BundledFont() => const {},
  };

  @override
  bool operator ==(Object other) =>
      other is TextLayer &&
      _sameFramed(this, other) &&
      other.text == text &&
      other.font == font &&
      other.sizePt == sizePt &&
      other.color == color &&
      other.align == align &&
      other.verticalAlign == verticalAlign &&
      other.lineHeight == lineHeight &&
      other.letterSpacingPt == letterSpacingPt;

  @override
  int get hashCode => Object.hash(
    _framedHash(this),
    text,
    font,
    sizePt,
    color,
    align,
    verticalAlign,
    lineHeight,
    letterSpacingPt,
  );
}

// --------------------------------------------------------------------- shape

enum ShapeKind { rect, roundedRect, ellipse }

/// A basic geometric shape with an optional fill and stroke. The stroke is
/// drawn inside the frame.
final class ShapeLayer extends FramedLayer {
  const ShapeLayer({
    required super.id,
    required super.zIndex,
    required super.frame,
    required this.shape,
    super.name,
    super.opacity,
    super.visible,
    super.locked,
    super.rotationDegrees,
    super.pivot,
    this.cornerRadius = 0,
    this.fill,
    this.stroke,
  });

  final ShapeKind shape;

  /// For [ShapeKind.roundedRect]: a fraction of the shorter side, 0 to 0.5.
  final double cornerRadius;
  final ArgbColor? fill;
  final Stroke? stroke;

  @override
  Set<String> get assetIds => const {};

  @override
  bool operator ==(Object other) =>
      other is ShapeLayer &&
      _sameFramed(this, other) &&
      other.shape == shape &&
      other.cornerRadius == cornerRadius &&
      other.fill == fill &&
      other.stroke == stroke;

  @override
  int get hashCode =>
      Object.hash(_framedHash(this), shape, cornerRadius, fill, stroke);
}

// ------------------------------------------------------------------- helpers

bool _sameBase(TemplateLayer a, TemplateLayer b) =>
    a.id == b.id &&
    a.zIndex == b.zIndex &&
    a.name == b.name &&
    a.opacity == b.opacity &&
    a.visible == b.visible &&
    a.locked == b.locked;

int _baseHash(TemplateLayer layer) => Object.hash(
  layer.id,
  layer.zIndex,
  layer.name,
  layer.opacity,
  layer.visible,
  layer.locked,
);

bool _sameFramed(FramedLayer a, FramedLayer b) =>
    _sameBase(a, b) &&
    a.frame == b.frame &&
    a.rotationDegrees == b.rotationDegrees &&
    a.pivot == b.pivot;

int _framedHash(FramedLayer layer) => Object.hash(
  _baseHash(layer),
  layer.frame,
  layer.rotationDegrees,
  layer.pivot,
);
