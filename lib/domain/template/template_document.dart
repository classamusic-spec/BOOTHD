/// The template document, schema version 1 (A-06, ADR-0010).
///
/// A document is immutable and identified by the template revision that
/// stores it; editing produces a new document and, when saved, a new
/// revision (A-15).
library;

import 'dart:math' as math;

import 'package:collection/collection.dart';

import 'document_issues.dart';
import 'geometry.dart';
import 'page_spec.dart';
import 'template_assets.dart';
import 'template_layers.dart';

final class TemplateDocument {
  const TemplateDocument({
    required this.page,
    required this.layers,
    this.assets = const {},
    this.schemaVersion = currentSchemaVersion,
  });

  static const currentSchemaVersion = 1;
  static const maxLayers = 200;
  static const maxAssets = 200;

  final int schemaVersion;
  final PageSpec page;

  /// Layers in document order; paint order comes from
  /// [TemplateLayer.zIndex] ([paintOrder]).
  final List<TemplateLayer> layers;

  /// Every asset the layers refer to, by asset id.
  final Map<String, TemplateAsset> assets;

  /// Layers bottom first: ascending z-index, ties in document order. The
  /// one global order for every layer type (A-06).
  List<TemplateLayer> get paintOrder {
    final indexed = [for (var i = 0; i < layers.length; i++) (i, layers[i])]
      ..sort((a, b) {
        final byZ = a.$2.zIndex.compareTo(b.$2.zIndex);
        return byZ != 0 ? byZ : a.$1.compareTo(b.$1);
      });
    return [for (final (_, layer) in indexed) layer];
  }

  /// Photo slots in slot order.
  List<PhotoSlotLayer> get photoSlots =>
      layers.whereType<PhotoSlotLayer>().toList()
        ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

  int get photoSlotCount => layers.whereType<PhotoSlotLayer>().length;

  BackgroundLayer? get background =>
      layers.whereType<BackgroundLayer>().firstOrNull;

  /// Asset ids the layers refer to.
  Set<String> get referencedAssetIds => {
    for (final layer in layers) ...layer.assetIds,
  };

  /// Errors and warnings. Errors make the document unusable: it cannot be
  /// saved as a revision or rendered.
  List<DocumentIssue> validate() => _Validator(this).run();

  List<DocumentIssue> get errors => [
    for (final issue in validate())
      if (issue.isError) issue,
  ];

  bool get isValid => errors.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is TemplateDocument &&
      other.schemaVersion == schemaVersion &&
      other.page == page &&
      const ListEquality<TemplateLayer>().equals(other.layers, layers) &&
      const MapEquality<String, TemplateAsset>().equals(other.assets, assets);

  @override
  int get hashCode => Object.hash(
    schemaVersion,
    page,
    Object.hashAll(layers),
    const MapEquality<String, TemplateAsset>().hash(assets),
  );
}

final _layerId = RegExp(r'^[A-Za-z0-9_.:-]{1,64}$');

/// Limits on layer geometry. Frames may leave the page (A-06) but not by
/// absurd amounts.
abstract final class GeometryLimits {
  static const maxOffset = 10.0;
  static const maxSize = 20.0;
  static const maxRotation = 3600.0;
  static const maxNameLength = 80;
}

final class _Validator {
  _Validator(this.document);

  final TemplateDocument document;
  final issues = <DocumentIssue>[];

  void error(DocumentIssueCode code, String path, String message) =>
      issues.add(DocumentIssue(code, path, message));

  void warn(DocumentIssueCode code, String path, String message) =>
      issues.add(DocumentIssue.warning(code, path, message));

  List<DocumentIssue> run() {
    if (document.schemaVersion != TemplateDocument.currentSchemaVersion) {
      error(
        DocumentIssueCode.unsupportedVersion,
        'schemaVersion',
        'This app reads version ${TemplateDocument.currentSchemaVersion} '
            'documents, not version ${document.schemaVersion}.',
      );
    }
    for (final problem in document.page.problems) {
      error(DocumentIssueCode.invalidPage, 'page', 'The page: $problem.');
    }
    _assets();
    _layers();
    return issues;
  }

  void _assets() {
    if (document.assets.length > TemplateDocument.maxAssets) {
      error(
        DocumentIssueCode.tooLarge,
        'assets',
        'At most ${TemplateDocument.maxAssets} assets per template.',
      );
    }
    final used = document.referencedAssetIds;
    for (final MapEntry(key: id, value: asset) in document.assets.entries) {
      final path = 'assets[$id]';
      if (!isAssetId(id)) {
        error(
          DocumentIssueCode.invalidAsset,
          path,
          'An asset id must be 64 lowercase hex digits (its SHA-256).',
        );
      }
      for (final problem in asset.problems) {
        error(DocumentIssueCode.invalidAsset, path, 'The asset: $problem.');
      }
      if (!used.contains(id)) {
        warn(DocumentIssueCode.unusedAsset, path, 'No layer uses this asset.');
      }
    }
  }

  void _asset(String path, String assetId, AssetKind kind) {
    final asset = document.assets[assetId];
    if (asset == null) {
      error(
        DocumentIssueCode.missingAsset,
        path,
        'The asset is not listed in the document.',
      );
    } else if (asset.kind != kind) {
      error(
        DocumentIssueCode.wrongAssetKind,
        path,
        'This needs ${kind == AssetKind.image ? 'an image' : 'a font'}.',
      );
    }
  }

  void _layers() {
    final layers = document.layers;
    if (layers.length > TemplateDocument.maxLayers) {
      error(
        DocumentIssueCode.tooManyLayers,
        'layers',
        'At most ${TemplateDocument.maxLayers} layers per template.',
      );
    }
    final ids = <String>{};
    final slots = <int>{};
    final backgrounds = <int>[];
    for (var i = 0; i < layers.length; i++) {
      final layer = layers[i];
      final path = 'layers[$i]';
      if (!_layerId.hasMatch(layer.id)) {
        error(
          DocumentIssueCode.invalidLayerId,
          '$path.id',
          'Layer ids are 1 to 64 letters, digits or _ . : -.',
        );
      } else if (!ids.add(layer.id)) {
        error(
          DocumentIssueCode.duplicateLayerId,
          '$path.id',
          'Another layer already uses the id "${layer.id}".',
        );
      }
      if (layer.name.length > GeometryLimits.maxNameLength) {
        error(
          DocumentIssueCode.invalidValue,
          '$path.name',
          'Layer names are at most ${GeometryLimits.maxNameLength} '
              'characters.',
        );
      }
      if (!layer.opacity.isFinite || layer.opacity < 0 || layer.opacity > 1) {
        error(
          DocumentIssueCode.invalidValue,
          '$path.opacity',
          'Opacity must be 0 to 1.',
        );
      }
      if (layer is FramedLayer) _framed(path, layer);
      switch (layer) {
        case BackgroundLayer():
          backgrounds.add(i);
          _background(path, layer);
        case PhotoSlotLayer():
          if (layer.slotIndex < 0 ||
              layer.slotIndex >= PhotoSlotLayer.maxSlots) {
            error(
              DocumentIssueCode.invalidSlotIndex,
              '$path.slotIndex',
              'Slot numbers run from 0 to ${PhotoSlotLayer.maxSlots - 1}.',
            );
          } else if (!slots.add(layer.slotIndex)) {
            error(
              DocumentIssueCode.duplicateSlotIndex,
              '$path.slotIndex',
              'Another slot already takes photo ${layer.slotIndex + 1}.',
            );
          }
          _photoSlot(path, layer);
        case ImageLayer():
          _asset('$path.assetId', layer.assetId, AssetKind.image);
          _crop('$path.crop', layer.crop);
        case TextLayer():
          _text(path, layer);
        case ShapeLayer():
          _shape(path, layer);
      }
    }
    if (backgrounds.length > 1) {
      error(
        DocumentIssueCode.multipleBackgrounds,
        'layers[${backgrounds[1]}]',
        'A template has at most one background.',
      );
    }
    if (backgrounds.isNotEmpty) {
      final background = layers[backgrounds.first];
      for (final other in layers) {
        if (!identical(other, background) &&
            other.zIndex <= background.zIndex) {
          error(
            DocumentIssueCode.backgroundNotLowest,
            'layers[${backgrounds.first}].z',
            'The background must be below every other layer.',
          );
          break;
        }
      }
    }
    if (slots.isNotEmpty &&
        !const SetEquality<int>().equals(slots, {
          for (var i = 0; i < slots.length; i++) i,
        })) {
      error(
        DocumentIssueCode.slotsNotContiguous,
        'layers',
        'Photo slots must be numbered from 1 without gaps.',
      );
    }
  }

  bool _finiteIn(double value, double min, double max) =>
      value.isFinite && value >= min && value <= max;

  void _framed(String path, FramedLayer layer) {
    final frame = layer.frame;
    if (!frame.isFinite ||
        !frame.hasPositiveSize ||
        !_finiteIn(
          frame.x,
          -GeometryLimits.maxOffset,
          GeometryLimits.maxOffset,
        ) ||
        !_finiteIn(
          frame.y,
          -GeometryLimits.maxOffset,
          GeometryLimits.maxOffset,
        ) ||
        frame.width > GeometryLimits.maxSize ||
        frame.height > GeometryLimits.maxSize) {
      error(
        DocumentIssueCode.invalidGeometry,
        '$path.frame',
        'The frame needs a positive size within ${GeometryLimits.maxOffset} '
            'pages of the page.',
      );
      return;
    }
    if (!_finiteIn(
      layer.rotationDegrees,
      -GeometryLimits.maxRotation,
      GeometryLimits.maxRotation,
    )) {
      error(
        DocumentIssueCode.invalidGeometry,
        '$path.rotation',
        'Rotation must be a number of degrees within '
            '±${GeometryLimits.maxRotation}.',
      );
      return;
    }
    if (!_finiteIn(
          layer.pivot.x,
          -GeometryLimits.maxOffset,
          GeometryLimits.maxOffset,
        ) ||
        !_finiteIn(
          layer.pivot.y,
          -GeometryLimits.maxOffset,
          GeometryLimits.maxOffset,
        )) {
      error(
        DocumentIssueCode.invalidGeometry,
        '$path.pivot',
        'The pivot must lie within ${GeometryLimits.maxOffset} frames of '
            'the frame.',
      );
      return;
    }
    final page = document.page;
    if (!page.isValid) return;
    final rect = frame.toPixels(
      pageWidthPx: page.widthPx,
      pageHeightPx: page.heightPx,
    );
    final bounds = rect.rotatedBounds(
      rect.pointAt(layer.pivot),
      layer.rotationDegrees * math.pi / 180,
    );
    if (bounds.right <= 0 ||
        bounds.bottom <= 0 ||
        bounds.left >= page.widthPx ||
        bounds.top >= page.heightPx) {
      warn(
        DocumentIssueCode.offPage,
        '$path.frame',
        'This layer lies wholly outside the page, so exports never show it.',
      );
    }
  }

  void _crop(String path, NormalizedRect crop) {
    const epsilon = 1e-9;
    if (!crop.isFinite ||
        !crop.hasPositiveSize ||
        crop.x < 0 ||
        crop.y < 0 ||
        crop.x + crop.width > 1 + epsilon ||
        crop.y + crop.height > 1 + epsilon) {
      error(
        DocumentIssueCode.invalidGeometry,
        path,
        'The crop must be a part of the image (fractions 0 to 1).',
      );
    }
  }

  void _color(String path, ArgbColor? color) {
    if (color != null && !color.isValid) {
      error(DocumentIssueCode.invalidValue, path, 'Not a colour.');
    }
  }

  void _stroke(String path, Stroke? stroke) {
    if (stroke == null) return;
    if (!stroke.widthPt.isFinite ||
        stroke.widthPt <= 0 ||
        stroke.widthPt > Stroke.maxWidthPt) {
      error(
        DocumentIssueCode.invalidValue,
        '$path.width',
        'Line width must be more than 0 and at most ${Stroke.maxWidthPt} pt.',
      );
    }
    _color('$path.color', stroke.color);
  }

  void _background(String path, BackgroundLayer layer) {
    switch (layer.fill) {
      case SolidFill(:final color):
        _color('$path.fill.color', color);
      case LinearGradientFill(:final angleDegrees, :final stops):
        if (!angleDegrees.isFinite) {
          error(
            DocumentIssueCode.invalidValue,
            '$path.fill.angle',
            'The gradient angle must be a number of degrees.',
          );
        }
        if (stops.length < LinearGradientFill.minStops ||
            stops.length > LinearGradientFill.maxStops) {
          error(
            DocumentIssueCode.invalidValue,
            '$path.fill.stops',
            'A gradient has ${LinearGradientFill.minStops} to '
                '${LinearGradientFill.maxStops} colours.',
          );
        }
        var previous = 0.0;
        for (var i = 0; i < stops.length; i++) {
          final offset = stops[i].offset;
          if (!_finiteIn(offset, previous, 1)) {
            error(
              DocumentIssueCode.invalidValue,
              '$path.fill.stops[$i].offset',
              'Stop positions run from 0 to 1 in order.',
            );
          } else {
            previous = offset;
          }
          _color('$path.fill.stops[$i].color', stops[i].color);
        }
      case ImageFill(:final assetId):
        _asset('$path.fill.assetId', assetId, AssetKind.image);
    }
  }

  void _photoSlot(String path, PhotoSlotLayer layer) {
    if (!_finiteIn(layer.focal.x, 0, 1) || !_finiteIn(layer.focal.y, 0, 1)) {
      error(
        DocumentIssueCode.invalidGeometry,
        '$path.focal',
        'The focal point is a fraction of the photo, 0 to 1.',
      );
    }
    switch (layer.clip) {
      case RoundedRectClip(:final cornerRadius):
        if (!_finiteIn(cornerRadius, 0, 0.5)) {
          error(
            DocumentIssueCode.invalidGeometry,
            '$path.clip.cornerRadius',
            'Corner radius is a fraction of the shorter side, 0 to 0.5.',
          );
        }
      case MaskClip(:final assetId):
        _asset('$path.clip.assetId', assetId, AssetKind.image);
        if (layer.border != null) {
          error(
            DocumentIssueCode.borderWithMask,
            '$path.border',
            'Mask-shaped slots cannot have a border.',
          );
        }
      case RectClip() || EllipseClip():
        break;
    }
    _stroke('$path.border', layer.border);
  }

  void _text(String path, TextLayer layer) {
    if (layer.text.runes.length > TextLayer.maxLength) {
      error(
        DocumentIssueCode.tooLarge,
        '$path.text',
        'Text is at most ${TextLayer.maxLength} characters.',
      );
    }
    if (layer.text.trim().isEmpty) {
      warn(DocumentIssueCode.emptyText, '$path.text', 'The text is empty.');
    }
    switch (layer.font) {
      case BundledFont(:final family, :final weight):
        if (!family.weights.contains(weight)) {
          error(
            DocumentIssueCode.unsupportedFontWeight,
            '$path.font.weight',
            '${family.family} is available at weights '
                '${family.weights.join(', ')}.',
          );
        }
      case AssetFont(:final assetId):
        _asset('$path.font.assetId', assetId, AssetKind.font);
    }
    if (!layer.sizePt.isFinite ||
        layer.sizePt <= 0 ||
        layer.sizePt > TextLayer.maxSizePt) {
      error(
        DocumentIssueCode.invalidValue,
        '$path.size',
        'Text size must be more than 0 and at most ${TextLayer.maxSizePt} pt.',
      );
    }
    _color('$path.color', layer.color);
    if (!_finiteIn(layer.lineHeight, 0.5, 5)) {
      error(
        DocumentIssueCode.invalidValue,
        '$path.lineHeight',
        'Line height is 0.5 to 5 times the text size.',
      );
    }
    if (!_finiteIn(layer.letterSpacingPt, -50, 200)) {
      error(
        DocumentIssueCode.invalidValue,
        '$path.letterSpacing',
        'Letter spacing is -50 to 200 pt.',
      );
    }
  }

  void _shape(String path, ShapeLayer layer) {
    if (!_finiteIn(layer.cornerRadius, 0, 0.5)) {
      error(
        DocumentIssueCode.invalidGeometry,
        '$path.cornerRadius',
        'Corner radius is a fraction of the shorter side, 0 to 0.5.',
      );
    }
    _color('$path.fill', layer.fill);
    _stroke('$path.stroke', layer.stroke);
    if (layer.fill == null && layer.stroke == null) {
      warn(
        DocumentIssueCode.invisibleShape,
        path,
        'The shape has neither a fill nor a line.',
      );
    }
  }
}
