/// Template documents as JSON (A-06, ADR-0010).
///
/// Reading is strict: unknown fields, unknown layer types and values of the
/// wrong type are errors, so a document is never half-understood and then
/// re-saved without the parts this app could not read. Writing is
/// canonical: every field, in a fixed order, two-space indented, so the
/// same document always produces the same bytes and the same checksum.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'document_issues.dart';
import 'geometry.dart';
import 'page_spec.dart';
import 'template_assets.dart';
import 'template_document.dart';
import 'template_layers.dart';
import 'template_migrations.dart';

abstract final class TemplateJson {
  /// Largest document accepted, in UTF-8 bytes.
  static const maxDocumentBytes = 1024 * 1024;

  /// Reads a document from JSON [source], upgrading older schema versions.
  /// Throws [TemplateDocumentException] listing every problem found. Does
  /// not check meaning; see [decodeValid].
  static TemplateDocument decode(String source) {
    if (utf8.encode(source).length > maxDocumentBytes) {
      throw const TemplateDocumentException([
        DocumentIssue(
          DocumentIssueCode.tooLarge,
          '',
          'The document is larger than 1 MB.',
        ),
      ]);
    }
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException {
      throw const TemplateDocumentException([
        DocumentIssue(
          DocumentIssueCode.notAnObject,
          '',
          'The document is not valid JSON.',
        ),
      ]);
    }
    return fromJson(json);
  }

  /// [decode], then refuses documents with validation errors.
  static TemplateDocument decodeValid(String source) {
    final document = decode(source);
    final errors = document.errors;
    if (errors.isNotEmpty) throw TemplateDocumentException(errors);
    return document;
  }

  /// Reads a decoded JSON value.
  static TemplateDocument fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw const TemplateDocumentException([
        DocumentIssue(
          DocumentIssueCode.notAnObject,
          '',
          'A template document is a JSON object.',
        ),
      ]);
    }
    final current = TemplateMigrations.upgrade(json);
    final reader = _Reader();
    final document = reader.document(current);
    if (reader.issues.isNotEmpty) {
      throw TemplateDocumentException(List.unmodifiable(reader.issues));
    }
    return document;
  }

  /// The canonical JSON value of [document].
  static Map<String, Object?> toJson(TemplateDocument document) => {
    'schemaVersion': document.schemaVersion,
    'page': {
      'width': document.page.width,
      'height': document.page.height,
      'unit': document.page.unit.code,
      'dpi': document.page.dpi,
    },
    'assets': {
      for (final id in document.assets.keys.toList()..sort())
        id: _asset(document.assets[id]!),
    },
    'layers': [for (final layer in document.layers) _layer(layer)],
  };

  /// The canonical text of [document], ending in a newline.
  static String encode(TemplateDocument document) =>
      '${const JsonEncoder.withIndent('  ').convert(toJson(document))}\n';

  /// [encode] as UTF-8; the bytes a revision's checksum covers.
  static Uint8List encodeBytes(TemplateDocument document) =>
      utf8.encode(encode(document));

  /// The revision checksum: lowercase hex SHA-256 of [encodeBytes].
  static String checksumOf(TemplateDocument document) =>
      sha256.convert(encodeBytes(document)).toString();

  static Map<String, Object?> _asset(TemplateAsset asset) => {
    'mimeType': asset.mediaType.mimeType,
    'byteLength': asset.byteLength,
    if (asset.widthPx != null) 'widthPx': asset.widthPx,
    if (asset.heightPx != null) 'heightPx': asset.heightPx,
    if (asset.name != null) 'name': asset.name,
  };

  static Map<String, Object?> _rect(NormalizedRect rect) => {
    'x': rect.x,
    'y': rect.y,
    'w': rect.width,
    'h': rect.height,
  };

  static Map<String, Object?> _point(NormalizedPoint point) => {
    'x': point.x,
    'y': point.y,
  };

  static Map<String, Object?> _stroke(Stroke stroke) => {
    'width': stroke.widthPt,
    'color': stroke.color.toHex(),
  };

  static Map<String, Object?> _layer(TemplateLayer layer) {
    final common = <String, Object?>{
      'type': _typeOf(layer),
      'id': layer.id,
      'name': layer.name,
      'z': layer.zIndex,
      'opacity': layer.opacity,
      'visible': layer.visible,
      'locked': layer.locked,
    };
    if (layer is FramedLayer) {
      common
        ..['frame'] = _rect(layer.frame)
        ..['rotation'] = layer.rotationDegrees
        ..['pivot'] = _point(layer.pivot);
    }
    return {
      ...common,
      ...switch (layer) {
        BackgroundLayer(:final fill) => {'fill': _fill(fill)},
        PhotoSlotLayer() => {
          'slotIndex': layer.slotIndex,
          'fit': layer.fit.name,
          'focal': _point(layer.focal),
          'clip': switch (layer.clip) {
            RectClip() => {'shape': 'rect'},
            RoundedRectClip(:final cornerRadius) => {
              'shape': 'roundedRect',
              'cornerRadius': cornerRadius,
            },
            EllipseClip() => {'shape': 'ellipse'},
            MaskClip(:final assetId) => {'shape': 'mask', 'assetId': assetId},
          },
          'border': layer.border == null ? null : _stroke(layer.border!),
        },
        ImageLayer() => {
          'assetId': layer.assetId,
          'fit': layer.fit.name,
          'crop': _rect(layer.crop),
        },
        TextLayer() => {
          'text': layer.text,
          'font': switch (layer.font) {
            BundledFont(:final family, :final weight) => {
              'family': family.family,
              'weight': weight,
            },
            AssetFont(:final assetId) => {'assetId': assetId},
          },
          'size': layer.sizePt,
          'color': layer.color.toHex(),
          'align': layer.align.name,
          'verticalAlign': layer.verticalAlign.name,
          'lineHeight': layer.lineHeight,
          'letterSpacing': layer.letterSpacingPt,
        },
        ShapeLayer() => {
          'shape': layer.shape.name,
          'cornerRadius': layer.cornerRadius,
          'fill': layer.fill?.toHex(),
          'stroke': layer.stroke == null ? null : _stroke(layer.stroke!),
        },
      },
    };
  }

  static Map<String, Object?> _fill(BackgroundFill fill) => switch (fill) {
    SolidFill(:final color) => {'type': 'solid', 'color': color.toHex()},
    LinearGradientFill(:final angleDegrees, :final stops) => {
      'type': 'linearGradient',
      'angle': angleDegrees,
      'stops': [
        for (final stop in stops)
          {'offset': stop.offset, 'color': stop.color.toHex()},
      ],
    },
    ImageFill(:final assetId, :final fit) => {
      'type': 'image',
      'assetId': assetId,
      'fit': fit.name,
    },
  };

  static String _typeOf(TemplateLayer layer) => switch (layer) {
    BackgroundLayer() => 'background',
    PhotoSlotLayer() => 'photoSlot',
    ImageLayer() => 'image',
    TextLayer() => 'text',
    ShapeLayer() => 'shape',
  };
}

/// Walks a JSON value, recording every problem with its path and returning
/// placeholders so reading can continue.
final class _Reader {
  final issues = <DocumentIssue>[];

  void _issue(DocumentIssueCode code, String path, String message) =>
      issues.add(DocumentIssue(code, path, message));

  Map<String, Object?> _object(Object? value, String path) {
    if (value is Map<String, Object?>) return value;
    _issue(DocumentIssueCode.wrongType, path, 'Expected an object.');
    return const {};
  }

  /// Records unknown keys of [map] and missing [required] keys.
  void _keys(
    Map<String, Object?> map,
    String path, {
    Set<String> required = const {},
    Set<String> optional = const {},
  }) {
    for (final key in map.keys) {
      if (!required.contains(key) && !optional.contains(key)) {
        _issue(
          DocumentIssueCode.unknownField,
          _join(path, key),
          'This field is not part of the format.',
        );
      }
    }
    for (final key in required) {
      if (!map.containsKey(key)) {
        _issue(
          DocumentIssueCode.missingField,
          _join(path, key),
          'This field is required.',
        );
      }
    }
  }

  static String _join(String path, String key) =>
      path.isEmpty ? key : '$path.$key';

  double _double(
    Map<String, Object?> map,
    String key,
    String path, [
    double? fallback,
  ]) {
    // Absent fields: required ones are reported by _keys.
    if (!map.containsKey(key)) return fallback ?? 0;
    final value = map[key];
    if (value is num && value.isFinite) return value.toDouble();
    _issue(DocumentIssueCode.wrongType, _join(path, key), 'Expected a number.');
    return fallback ?? 0;
  }

  int _int(Map<String, Object?> map, String key, String path, [int? fallback]) {
    if (!map.containsKey(key)) return fallback ?? 0;
    final value = map[key];
    if (value is int) return value;
    _issue(
      DocumentIssueCode.wrongType,
      _join(path, key),
      'Expected a whole number.',
    );
    return fallback ?? 0;
  }

  String _string(
    Map<String, Object?> map,
    String key,
    String path, [
    String? fallback,
  ]) {
    if (!map.containsKey(key)) return fallback ?? '';
    final value = map[key];
    if (value is String) return value;
    _issue(DocumentIssueCode.wrongType, _join(path, key), 'Expected text.');
    return fallback ?? '';
  }

  bool _bool(Map<String, Object?> map, String key, String path, bool fallback) {
    if (!map.containsKey(key)) return fallback;
    final value = map[key];
    if (value is bool) return value;
    _issue(
      DocumentIssueCode.wrongType,
      _join(path, key),
      'Expected true or false.',
    );
    return fallback;
  }

  T _enum<T extends Enum>(
    Map<String, Object?> map,
    String key,
    String path,
    List<T> values, [
    T? fallback,
  ]) {
    if (!map.containsKey(key)) return fallback ?? values.first;
    final value = map[key];
    if (value is String) {
      for (final candidate in values) {
        if (candidate.name == value) return candidate;
      }
    }
    _issue(
      DocumentIssueCode.invalidValue,
      _join(path, key),
      'Expected one of ${values.map((v) => v.name).join(', ')}.',
    );
    return fallback ?? values.first;
  }

  ArgbColor _color(Object? value, String path, {bool present = true}) {
    if (!present) return const ArgbColor(0);
    if (value is String) {
      final color = ArgbColor.tryParse(value);
      if (color != null) return color;
    }
    _issue(
      DocumentIssueCode.invalidValue,
      path,
      'Expected a #AARRGGBB colour.',
    );
    return const ArgbColor(0);
  }

  String _assetId(Map<String, Object?> map, String key, String path) {
    final id = _string(map, key, path);
    if (map.containsKey(key) && map[key] is String && !isAssetId(id)) {
      _issue(
        DocumentIssueCode.invalidValue,
        _join(path, key),
        'An asset id is 64 lowercase hex digits.',
      );
    }
    return id;
  }

  NormalizedRect _rect(Object? value, String path) {
    final map = _object(value, path);
    _keys(map, path, required: const {'x', 'y', 'w', 'h'});
    return NormalizedRect(
      x: _double(map, 'x', path),
      y: _double(map, 'y', path),
      width: _double(map, 'w', path),
      height: _double(map, 'h', path),
    );
  }

  NormalizedPoint _point(Map<String, Object?> parent, String key, String path) {
    if (!parent.containsKey(key)) return NormalizedPoint.center;
    final pointPath = _join(path, key);
    final map = _object(parent[key], pointPath);
    _keys(map, pointPath, required: const {'x', 'y'});
    return NormalizedPoint(
      _double(map, 'x', pointPath),
      _double(map, 'y', pointPath),
    );
  }

  Stroke? _stroke(Map<String, Object?> parent, String key, String path) {
    final value = parent[key];
    if (value == null) return null;
    final strokePath = _join(path, key);
    final map = _object(value, strokePath);
    _keys(map, strokePath, required: const {'width', 'color'});
    return Stroke(
      widthPt: _double(map, 'width', strokePath),
      color: _color(
        map['color'],
        _join(strokePath, 'color'),
        present: map.containsKey('color'),
      ),
    );
  }

  TemplateDocument document(Map<String, Object?> json) {
    _keys(
      json,
      '',
      required: const {'schemaVersion', 'page', 'layers'},
      optional: const {'assets'},
    );
    final page = _page(json['page']);
    final assets = _assets(json['assets']);
    final rawLayers = json['layers'];
    final layers = <TemplateLayer>[];
    if (rawLayers is List<Object?>) {
      if (rawLayers.length > TemplateDocument.maxLayers) {
        _issue(
          DocumentIssueCode.tooManyLayers,
          'layers',
          'At most ${TemplateDocument.maxLayers} layers per template.',
        );
      } else {
        for (var i = 0; i < rawLayers.length; i++) {
          final layer = _layer(rawLayers[i], 'layers[$i]');
          if (layer != null) layers.add(layer);
        }
      }
    } else if (json.containsKey('layers')) {
      _issue(DocumentIssueCode.wrongType, 'layers', 'Expected a list.');
    }
    return TemplateDocument(
      schemaVersion: _int(json, 'schemaVersion', ''),
      page: page,
      layers: List.unmodifiable(layers),
      assets: Map.unmodifiable(assets),
    );
  }

  PageSpec _page(Object? value) {
    final map = _object(value, 'page');
    _keys(map, 'page', required: const {'width', 'height', 'unit', 'dpi'});
    final unitCode = _string(map, 'unit', 'page');
    final unit = LengthUnit.fromCode(unitCode);
    if (unit == null && map['unit'] is String) {
      _issue(DocumentIssueCode.invalidValue, 'page.unit', 'Expected in or mm.');
    }
    return PageSpec(
      width: _double(map, 'width', 'page'),
      height: _double(map, 'height', 'page'),
      unit: unit ?? LengthUnit.inch,
      dpi: _int(map, 'dpi', 'page'),
    );
  }

  Map<String, TemplateAsset> _assets(Object? value) {
    if (value == null) return const {};
    final map = _object(value, 'assets');
    if (map.length > TemplateDocument.maxAssets) {
      _issue(
        DocumentIssueCode.tooLarge,
        'assets',
        'At most ${TemplateDocument.maxAssets} assets per template.',
      );
      return const {};
    }
    final assets = <String, TemplateAsset>{};
    for (final MapEntry(key: id, value: raw) in map.entries) {
      final path = 'assets[$id]';
      if (!isAssetId(id)) {
        _issue(
          DocumentIssueCode.invalidValue,
          path,
          'An asset id is 64 lowercase hex digits.',
        );
      }
      final asset = _object(raw, path);
      _keys(
        asset,
        path,
        required: const {'mimeType', 'byteLength'},
        optional: const {'widthPx', 'heightPx', 'name'},
      );
      final mimeType = _string(asset, 'mimeType', path);
      final mediaType = AssetMediaType.fromMimeType(mimeType);
      if (mediaType == null && asset['mimeType'] is String) {
        _issue(
          DocumentIssueCode.invalidValue,
          '$path.mimeType',
          'Expected image/png, image/jpeg, font/ttf or font/otf.',
        );
      }
      assets[id] = TemplateAsset(
        mediaType: mediaType ?? AssetMediaType.png,
        byteLength: _int(asset, 'byteLength', path),
        widthPx: asset.containsKey('widthPx')
            ? _int(asset, 'widthPx', path)
            : null,
        heightPx: asset.containsKey('heightPx')
            ? _int(asset, 'heightPx', path)
            : null,
        name: asset.containsKey('name') ? _string(asset, 'name', path) : null,
      );
    }
    return assets;
  }

  static const _common = {'type', 'id', 'z'};
  static const _commonOptional = {'name', 'opacity', 'visible', 'locked'};
  static const _framedRequired = {..._common, 'frame'};
  static const _framedOptional = {..._commonOptional, 'rotation', 'pivot'};

  TemplateLayer? _layer(Object? value, String path) {
    final map = _object(value, path);
    if (map.isEmpty && value is! Map) return null;
    final type = map['type'];
    final keys = switch (type) {
      'background' => (
        required: {..._common, 'fill'},
        optional: _commonOptional,
      ),
      'photoSlot' => (
        required: {..._framedRequired, 'slotIndex'},
        optional: {..._framedOptional, 'fit', 'focal', 'clip', 'border'},
      ),
      'image' => (
        required: {..._framedRequired, 'assetId'},
        optional: {..._framedOptional, 'fit', 'crop'},
      ),
      'text' => (
        required: {..._framedRequired, 'text', 'font', 'size', 'color'},
        optional: {
          ..._framedOptional,
          'align',
          'verticalAlign',
          'lineHeight',
          'letterSpacing',
        },
      ),
      'shape' => (
        required: {..._framedRequired, 'shape'},
        optional: {..._framedOptional, 'cornerRadius', 'fill', 'stroke'},
      ),
      _ => null,
    };
    if (keys == null) {
      _issue(
        DocumentIssueCode.unknownLayerType,
        '$path.type',
        type is String
            ? 'This app does not know "$type" layers.'
            : 'Every layer needs a type.',
      );
      return null;
    }
    _keys(map, path, required: keys.required, optional: keys.optional);

    final id = _string(map, 'id', path);
    final zIndex = _int(map, 'z', path);
    final name = _string(map, 'name', path, '');
    final opacity = _double(map, 'opacity', path, 1);
    final visible = _bool(map, 'visible', path, true);
    final locked = _bool(map, 'locked', path, false);

    if (type == 'background') {
      return BackgroundLayer(
        id: id,
        zIndex: zIndex,
        name: name,
        opacity: opacity,
        visible: visible,
        locked: locked,
        fill: _fill(map['fill'], '$path.fill'),
      );
    }

    final frame = _rect(map['frame'], '$path.frame');
    final rotation = _double(map, 'rotation', path, 0);
    final pivot = _point(map, 'pivot', path);

    return switch (type) {
      'photoSlot' => PhotoSlotLayer(
        id: id,
        zIndex: zIndex,
        name: name,
        opacity: opacity,
        visible: visible,
        locked: locked,
        frame: frame,
        rotationDegrees: rotation,
        pivot: pivot,
        slotIndex: _int(map, 'slotIndex', path),
        fit: _enum(map, 'fit', path, PhotoFit.values, PhotoFit.cover),
        focal: _point(map, 'focal', path),
        clip: _clip(map, path),
        border: _stroke(map, 'border', path),
      ),
      'image' => ImageLayer(
        id: id,
        zIndex: zIndex,
        name: name,
        opacity: opacity,
        visible: visible,
        locked: locked,
        frame: frame,
        rotationDegrees: rotation,
        pivot: pivot,
        assetId: _assetId(map, 'assetId', path),
        fit: _enum(map, 'fit', path, ImageFit.values, ImageFit.fill),
        crop: map.containsKey('crop')
            ? _rect(map['crop'], '$path.crop')
            : NormalizedRect.page,
      ),
      'text' => TextLayer(
        id: id,
        zIndex: zIndex,
        name: name,
        opacity: opacity,
        visible: visible,
        locked: locked,
        frame: frame,
        rotationDegrees: rotation,
        pivot: pivot,
        text: _string(map, 'text', path),
        font: _font(map['font'], '$path.font'),
        sizePt: _double(map, 'size', path),
        color: _color(
          map['color'],
          '$path.color',
          present: map.containsKey('color'),
        ),
        align: _enum(
          map,
          'align',
          path,
          TextAlignment.values,
          TextAlignment.center,
        ),
        verticalAlign: _enum(
          map,
          'verticalAlign',
          path,
          VerticalAlignment.values,
          VerticalAlignment.middle,
        ),
        lineHeight: _double(map, 'lineHeight', path, 1.2),
        letterSpacingPt: _double(map, 'letterSpacing', path, 0),
      ),
      _ => ShapeLayer(
        id: id,
        zIndex: zIndex,
        name: name,
        opacity: opacity,
        visible: visible,
        locked: locked,
        frame: frame,
        rotationDegrees: rotation,
        pivot: pivot,
        shape: _enum(map, 'shape', path, ShapeKind.values),
        cornerRadius: _double(map, 'cornerRadius', path, 0),
        fill: map['fill'] == null ? null : _color(map['fill'], '$path.fill'),
        stroke: _stroke(map, 'stroke', path),
      ),
    };
  }

  BackgroundFill _fill(Object? value, String path) {
    final map = _object(value, path);
    switch (map['type']) {
      case 'solid':
        _keys(map, path, required: const {'type', 'color'});
        return SolidFill(
          _color(
            map['color'],
            '$path.color',
            present: map.containsKey('color'),
          ),
        );
      case 'linearGradient':
        _keys(map, path, required: const {'type', 'angle', 'stops'});
        final rawStops = map['stops'];
        final stops = <GradientStop>[];
        if (rawStops is List<Object?> &&
            rawStops.length <= LinearGradientFill.maxStops) {
          for (var i = 0; i < rawStops.length; i++) {
            final stopPath = '$path.stops[$i]';
            final stop = _object(rawStops[i], stopPath);
            _keys(stop, stopPath, required: const {'offset', 'color'});
            stops.add(
              GradientStop(
                _double(stop, 'offset', stopPath),
                _color(
                  stop['color'],
                  '$stopPath.color',
                  present: stop.containsKey('color'),
                ),
              ),
            );
          }
        } else {
          _issue(
            DocumentIssueCode.invalidValue,
            '$path.stops',
            'Expected a list of ${LinearGradientFill.minStops} to '
                '${LinearGradientFill.maxStops} stops.',
          );
        }
        return LinearGradientFill(
          angleDegrees: _double(map, 'angle', path),
          stops: List.unmodifiable(stops),
        );
      case 'image':
        _keys(
          map,
          path,
          required: const {'type', 'assetId'},
          optional: const {'fit'},
        );
        return ImageFill(
          _assetId(map, 'assetId', path),
          fit: _enum(map, 'fit', path, ImageFit.values, ImageFit.cover),
        );
      default:
        _issue(
          DocumentIssueCode.invalidValue,
          '$path.type',
          'Expected solid, linearGradient or image.',
        );
        return const SolidFill(ArgbColor(0));
    }
  }

  SlotClip _clip(Map<String, Object?> parent, String path) {
    if (!parent.containsKey('clip')) return const RectClip();
    final clipPath = '$path.clip';
    final map = _object(parent['clip'], clipPath);
    switch (map['shape']) {
      case 'rect':
        _keys(map, clipPath, required: const {'shape'});
        return const RectClip();
      case 'roundedRect':
        _keys(map, clipPath, required: const {'shape', 'cornerRadius'});
        return RoundedRectClip(_double(map, 'cornerRadius', clipPath));
      case 'ellipse':
        _keys(map, clipPath, required: const {'shape'});
        return const EllipseClip();
      case 'mask':
        _keys(map, clipPath, required: const {'shape', 'assetId'});
        return MaskClip(_assetId(map, 'assetId', clipPath));
      default:
        _issue(
          DocumentIssueCode.invalidValue,
          '$clipPath.shape',
          'Expected rect, roundedRect, ellipse or mask.',
        );
        return const RectClip();
    }
  }

  FontRef _font(Object? value, String path) {
    final map = _object(value, path);
    if (map.containsKey('assetId')) {
      _keys(map, path, required: const {'assetId'});
      return AssetFont(_assetId(map, 'assetId', path));
    }
    _keys(map, path, required: const {'family'}, optional: const {'weight'});
    final familyName = _string(map, 'family', path);
    final family = BundledFontFamily.fromFamily(familyName);
    if (family == null && map['family'] is String) {
      _issue(
        DocumentIssueCode.invalidValue,
        '$path.family',
        'Bundled families are '
            '${BundledFontFamily.values.map((f) => f.family).join(' and ')}; '
            'other fonts are imported as assets.',
      );
    }
    return BundledFont(
      family ?? BundledFontFamily.inter,
      weight: _int(map, 'weight', path, 400),
    );
  }
}
