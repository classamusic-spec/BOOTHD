/// Copies of template layers with some fields changed: the building block
/// of every edit (A-08). Layers stay immutable; nullable fields use a
/// marker so "leave it" and "clear it" are different.
library;

import '../geometry.dart';
import '../template_assets.dart';
import '../template_layers.dart';

/// Marks a nullable argument as "keep the current value".
const Object keep = _Keep();

final class _Keep {
  const _Keep();
}

T? _pick<T>(Object? value, T? current) =>
    identical(value, keep) ? current : value as T?;

/// [layer] with any of the fields every layer has changed. Frame,
/// rotation and pivot apply to framed layers only.
TemplateLayer copyLayer(
  TemplateLayer layer, {
  String? id,
  int? zIndex,
  String? name,
  double? opacity,
  bool? visible,
  bool? locked,
  NormalizedRect? frame,
  double? rotationDegrees,
  NormalizedPoint? pivot,
}) => switch (layer) {
  BackgroundLayer() => layer.copyWith(
    id: id,
    zIndex: zIndex,
    name: name,
    opacity: opacity,
    visible: visible,
    locked: locked,
  ),
  PhotoSlotLayer() => layer.copyWith(
    id: id,
    zIndex: zIndex,
    name: name,
    opacity: opacity,
    visible: visible,
    locked: locked,
    frame: frame,
    rotationDegrees: rotationDegrees,
    pivot: pivot,
  ),
  ImageLayer() => layer.copyWith(
    id: id,
    zIndex: zIndex,
    name: name,
    opacity: opacity,
    visible: visible,
    locked: locked,
    frame: frame,
    rotationDegrees: rotationDegrees,
    pivot: pivot,
  ),
  TextLayer() => layer.copyWith(
    id: id,
    zIndex: zIndex,
    name: name,
    opacity: opacity,
    visible: visible,
    locked: locked,
    frame: frame,
    rotationDegrees: rotationDegrees,
    pivot: pivot,
  ),
  ShapeLayer() => layer.copyWith(
    id: id,
    zIndex: zIndex,
    name: name,
    opacity: opacity,
    visible: visible,
    locked: locked,
    frame: frame,
    rotationDegrees: rotationDegrees,
    pivot: pivot,
  ),
};

extension BackgroundLayerCopy on BackgroundLayer {
  BackgroundLayer copyWith({
    String? id,
    int? zIndex,
    String? name,
    double? opacity,
    bool? visible,
    bool? locked,
    BackgroundFill? fill,
  }) => BackgroundLayer(
    id: id ?? this.id,
    zIndex: zIndex ?? this.zIndex,
    name: name ?? this.name,
    opacity: opacity ?? this.opacity,
    visible: visible ?? this.visible,
    locked: locked ?? this.locked,
    fill: fill ?? this.fill,
  );
}

extension PhotoSlotLayerCopy on PhotoSlotLayer {
  PhotoSlotLayer copyWith({
    String? id,
    int? zIndex,
    String? name,
    double? opacity,
    bool? visible,
    bool? locked,
    NormalizedRect? frame,
    double? rotationDegrees,
    NormalizedPoint? pivot,
    int? slotIndex,
    PhotoFit? fit,
    NormalizedPoint? focal,
    SlotClip? clip,
    Object? border = keep,
  }) => PhotoSlotLayer(
    id: id ?? this.id,
    zIndex: zIndex ?? this.zIndex,
    name: name ?? this.name,
    opacity: opacity ?? this.opacity,
    visible: visible ?? this.visible,
    locked: locked ?? this.locked,
    frame: frame ?? this.frame,
    rotationDegrees: rotationDegrees ?? this.rotationDegrees,
    pivot: pivot ?? this.pivot,
    slotIndex: slotIndex ?? this.slotIndex,
    fit: fit ?? this.fit,
    focal: focal ?? this.focal,
    clip: clip ?? this.clip,
    border: _pick<Stroke>(border, this.border),
  );
}

extension ImageLayerCopy on ImageLayer {
  ImageLayer copyWith({
    String? id,
    int? zIndex,
    String? name,
    double? opacity,
    bool? visible,
    bool? locked,
    NormalizedRect? frame,
    double? rotationDegrees,
    NormalizedPoint? pivot,
    String? assetId,
    ImageFit? fit,
    NormalizedRect? crop,
  }) => ImageLayer(
    id: id ?? this.id,
    zIndex: zIndex ?? this.zIndex,
    name: name ?? this.name,
    opacity: opacity ?? this.opacity,
    visible: visible ?? this.visible,
    locked: locked ?? this.locked,
    frame: frame ?? this.frame,
    rotationDegrees: rotationDegrees ?? this.rotationDegrees,
    pivot: pivot ?? this.pivot,
    assetId: assetId ?? this.assetId,
    fit: fit ?? this.fit,
    crop: crop ?? this.crop,
  );
}

extension TextLayerCopy on TextLayer {
  TextLayer copyWith({
    String? id,
    int? zIndex,
    String? name,
    double? opacity,
    bool? visible,
    bool? locked,
    NormalizedRect? frame,
    double? rotationDegrees,
    NormalizedPoint? pivot,
    String? text,
    FontRef? font,
    double? sizePt,
    ArgbColor? color,
    TextAlignment? align,
    VerticalAlignment? verticalAlign,
    double? lineHeight,
    double? letterSpacingPt,
  }) => TextLayer(
    id: id ?? this.id,
    zIndex: zIndex ?? this.zIndex,
    name: name ?? this.name,
    opacity: opacity ?? this.opacity,
    visible: visible ?? this.visible,
    locked: locked ?? this.locked,
    frame: frame ?? this.frame,
    rotationDegrees: rotationDegrees ?? this.rotationDegrees,
    pivot: pivot ?? this.pivot,
    text: text ?? this.text,
    font: font ?? this.font,
    sizePt: sizePt ?? this.sizePt,
    color: color ?? this.color,
    align: align ?? this.align,
    verticalAlign: verticalAlign ?? this.verticalAlign,
    lineHeight: lineHeight ?? this.lineHeight,
    letterSpacingPt: letterSpacingPt ?? this.letterSpacingPt,
  );
}

extension ShapeLayerCopy on ShapeLayer {
  ShapeLayer copyWith({
    String? id,
    int? zIndex,
    String? name,
    double? opacity,
    bool? visible,
    bool? locked,
    NormalizedRect? frame,
    double? rotationDegrees,
    NormalizedPoint? pivot,
    ShapeKind? shape,
    double? cornerRadius,
    Object? fill = keep,
    Object? stroke = keep,
  }) => ShapeLayer(
    id: id ?? this.id,
    zIndex: zIndex ?? this.zIndex,
    name: name ?? this.name,
    opacity: opacity ?? this.opacity,
    visible: visible ?? this.visible,
    locked: locked ?? this.locked,
    frame: frame ?? this.frame,
    rotationDegrees: rotationDegrees ?? this.rotationDegrees,
    pivot: pivot ?? this.pivot,
    shape: shape ?? this.shape,
    cornerRadius: cornerRadius ?? this.cornerRadius,
    fill: _pick<ArgbColor>(fill, this.fill),
    stroke: _pick<Stroke>(stroke, this.stroke),
  );
}
