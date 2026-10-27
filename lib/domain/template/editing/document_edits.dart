/// Edits to a template document (A-08, AC-0502, AC-0504). Every function
/// returns a new document and leaves its input untouched, so any earlier
/// document is a complete undo step.
///
/// Edited documents keep their layers in paint order (bottom first) with
/// z-indexes 0, 1, 2…, the background (if any) first; photo slots stay
/// numbered 0 to n-1 without gaps; the asset table lists exactly the assets
/// the layers use.
library;

import 'dart:math' as math;

import '../geometry.dart';
import '../page_spec.dart';
import '../template_assets.dart';
import '../template_document.dart';
import '../template_layers.dart';
import 'layer_copy.dart';
import 'sticker_placement.dart';

/// Why an edit was refused. The document is unchanged.
enum EditRefusal {
  /// The document already has [TemplateDocument.maxLayers] layers.
  tooManyLayers,

  /// The template already has [PhotoSlotLayer.maxSlots] photo slots.
  tooManySlots,

  /// No layer has that id.
  notFound,

  /// The layer is locked.
  locked,

  /// The background is always the lowest layer and there is only one.
  backgroundFixed,
}

final class EditRefused implements Exception {
  const EditRefused(this.reason);

  final EditRefusal reason;

  @override
  String toString() => 'EditRefused(${reason.name})';
}

abstract final class DocumentEdits {
  /// [document] in canonical edited form: paint order, dense z-indexes,
  /// contiguous slot numbers and only the assets in use.
  static TemplateDocument normalize(TemplateDocument document) {
    final ordered = document.paintOrder;
    final background = ordered.whereType<BackgroundLayer>().firstOrNull;
    final rest = [
      for (final layer in ordered)
        if (layer is! BackgroundLayer) layer,
    ];
    final layers = [?background, ...rest];

    // Slots keep their relative capture order, renumbered from 0.
    final slots = layers.whereType<PhotoSlotLayer>().toList()
      ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
    final slotNumber = {for (final (i, slot) in slots.indexed) slot.id: i};

    final normalized = [
      for (final (z, layer) in layers.indexed)
        switch (layer) {
          PhotoSlotLayer() => layer.copyWith(
            zIndex: z,
            slotIndex: slotNumber[layer.id],
          ),
          _ => copyLayer(layer, zIndex: z),
        },
    ];
    final used = {for (final layer in normalized) ...layer.assetIds};
    return TemplateDocument(
      page: document.page,
      schemaVersion: document.schemaVersion,
      layers: normalized,
      assets: {
        for (final MapEntry(:key, :value) in document.assets.entries)
          if (used.contains(key)) key: value,
      },
    );
  }

  /// Adds [layer] on top (a background goes to the bottom, replacing any
  /// other). [assets] describes any asset the layer uses.
  static TemplateDocument add(
    TemplateDocument document,
    TemplateLayer layer, {
    Map<String, TemplateAsset> assets = const {},
  }) {
    if (layer is BackgroundLayer) {
      return normalize(
        TemplateDocument(
          page: document.page,
          schemaVersion: document.schemaVersion,
          layers: [
            layer,
            for (final existing in document.layers)
              if (existing is! BackgroundLayer) existing,
          ],
          assets: {...document.assets, ...assets},
        ),
      );
    }
    if (document.layers.length >= TemplateDocument.maxLayers) {
      throw const EditRefused(EditRefusal.tooManyLayers);
    }
    if (layer is PhotoSlotLayer &&
        document.photoSlotCount >= PhotoSlotLayer.maxSlots) {
      throw const EditRefused(EditRefusal.tooManySlots);
    }
    final top = document.layers.fold<int>(
      -1,
      (z, existing) => math.max(z, existing.zIndex),
    );
    return normalize(
      TemplateDocument(
        page: document.page,
        schemaVersion: document.schemaVersion,
        layers: [
          ...document.layers,
          copyLayer(layer, zIndex: top + 1),
        ],
        assets: {...document.assets, ...assets},
      ),
    );
  }

  /// Removes the layers with [ids]. Locked layers are removed too: the
  /// caller asks first.
  static TemplateDocument remove(TemplateDocument document, Set<String> ids) =>
      normalize(
        TemplateDocument(
          page: document.page,
          schemaVersion: document.schemaVersion,
          layers: [
            for (final layer in document.layers)
              if (!ids.contains(layer.id)) layer,
          ],
          assets: document.assets,
        ),
      );

  /// Replaces the layer with [layer]'s id. [assets] describes any new asset
  /// it uses.
  static TemplateDocument replace(
    TemplateDocument document,
    TemplateLayer layer, {
    Map<String, TemplateAsset> assets = const {},
  }) {
    if (!document.layers.any((existing) => existing.id == layer.id)) {
      throw const EditRefused(EditRefusal.notFound);
    }
    return normalize(
      TemplateDocument(
        page: document.page,
        schemaVersion: document.schemaVersion,
        layers: [
          for (final existing in document.layers)
            existing.id == layer.id ? layer : existing,
        ],
        assets: {...document.assets, ...assets},
      ),
    );
  }

  /// Applies [change] to the layer [id].
  static TemplateDocument update(
    TemplateDocument document,
    String id,
    TemplateLayer Function(TemplateLayer layer) change, {
    Map<String, TemplateAsset> assets = const {},
  }) => replace(document, change(layerById(document, id)), assets: assets);

  static TemplateLayer layerById(TemplateDocument document, String id) =>
      document.layers.firstWhere(
        (layer) => layer.id == id,
        orElse: () => throw const EditRefused(EditRefusal.notFound),
      );

  /// Copies of the layers [ids], each placed just above its original and
  /// moved by [offset] of the page. Photo slot copies take the next slot
  /// numbers. Returns the document and the new ids, in the same order.
  static (TemplateDocument, List<String>) duplicate(
    TemplateDocument document,
    List<String> ids, {
    required String Function() newId,
    double offset = 0.02,
  }) {
    final originals = [for (final id in ids) layerById(document, id)];
    if (originals.any((layer) => layer is BackgroundLayer)) {
      throw const EditRefused(EditRefusal.backgroundFixed);
    }
    if (document.layers.length + originals.length >
        TemplateDocument.maxLayers) {
      throw const EditRefused(EditRefusal.tooManyLayers);
    }
    final newSlots = originals.whereType<PhotoSlotLayer>().length;
    if (document.photoSlotCount + newSlots > PhotoSlotLayer.maxSlots) {
      throw const EditRefused(EditRefusal.tooManySlots);
    }
    var nextSlot = document.photoSlotCount;
    final copies = <String, TemplateLayer>{};
    final newIds = <String>[];
    for (final original in originals) {
      final id = newId();
      newIds.add(id);
      final framed = original as FramedLayer;
      final frame = NormalizedRect(
        x: framed.frame.x + offset,
        y: framed.frame.y + offset,
        width: framed.frame.width,
        height: framed.frame.height,
      );
      copies[original.id] = switch (framed) {
        PhotoSlotLayer() => framed.copyWith(
          id: id,
          frame: frame,
          slotIndex: nextSlot++,
          name: _copyName(framed.name),
          locked: false,
        ),
        _ => copyLayer(
          framed,
          id: id,
          frame: frame,
          name: _copyName(framed.name),
          locked: false,
        ),
      };
    }
    // Insert each copy right after its original in paint order.
    final ordered = document.paintOrder;
    final layers = <TemplateLayer>[
      for (final layer in ordered) ...[layer, ?copies[layer.id]],
    ];
    return (
      normalize(
        TemplateDocument(
          page: document.page,
          schemaVersion: document.schemaVersion,
          layers: [
            for (final (z, layer) in layers.indexed)
              copyLayer(layer, zIndex: z),
          ],
          assets: document.assets,
        ),
      ),
      newIds,
    );
  }

  static String _copyName(String name) => name.isEmpty
      ? ''
      : name.length > 74
      ? name
      : '$name copy';

  /// Moves layer [id] to [paintIndex] in paint order (0 is the bottom).
  /// The background stays at the bottom.
  static TemplateDocument move(
    TemplateDocument document,
    String id,
    int paintIndex,
  ) {
    final layer = layerById(document, id);
    if (layer is BackgroundLayer) {
      throw const EditRefused(EditRefusal.backgroundFixed);
    }
    final ordered = normalize(document).layers.toList();
    final lowest = ordered.first is BackgroundLayer ? 1 : 0;
    ordered.removeWhere((existing) => existing.id == id);
    final target = paintIndex.clamp(lowest, ordered.length);
    ordered.insert(target, layer);
    return normalize(
      TemplateDocument(
        page: document.page,
        schemaVersion: document.schemaVersion,
        layers: [
          for (final (z, existing) in ordered.indexed)
            copyLayer(existing, zIndex: z),
        ],
        assets: document.assets,
      ),
    );
  }

  static int paintIndexOf(TemplateDocument document, String id) =>
      document.paintOrder.indexWhere((layer) => layer.id == id);

  static TemplateDocument bringForward(TemplateDocument document, String id) =>
      move(document, id, paintIndexOf(document, id) + 1);

  static TemplateDocument sendBackward(TemplateDocument document, String id) =>
      move(document, id, paintIndexOf(document, id) - 1);

  static TemplateDocument bringToFront(TemplateDocument document, String id) =>
      move(document, id, document.layers.length);

  static TemplateDocument sendToBack(TemplateDocument document, String id) =>
      move(document, id, 0);

  /// Moves the framed layers [ids] by [dx], [dy] (fractions of the page).
  static TemplateDocument translate(
    TemplateDocument document,
    Set<String> ids,
    double dx,
    double dy,
  ) => TemplateDocument(
    page: document.page,
    schemaVersion: document.schemaVersion,
    layers: [
      for (final layer in document.layers)
        if (ids.contains(layer.id) && layer is FramedLayer)
          copyLayer(
            layer,
            frame: NormalizedRect(
              x: layer.frame.x + dx,
              y: layer.frame.y + dy,
              width: layer.frame.width,
              height: layer.frame.height,
            ),
          )
        else
          layer,
    ],
    assets: document.assets,
  );

  /// Gives slot [id] the number [slotIndex] (0-based), swapping with the
  /// slot that had it.
  static TemplateDocument renumberSlot(
    TemplateDocument document,
    String id,
    int slotIndex,
  ) {
    final slot = layerById(document, id);
    if (slot is! PhotoSlotLayer) {
      throw const EditRefused(EditRefusal.notFound);
    }
    final target = slotIndex.clamp(0, document.photoSlotCount - 1);
    return normalize(
      TemplateDocument(
        page: document.page,
        schemaVersion: document.schemaVersion,
        layers: [
          for (final layer in document.layers)
            if (layer.id == id)
              slot.copyWith(slotIndex: target)
            else if (layer is PhotoSlotLayer && layer.slotIndex == target)
              layer.copyWith(slotIndex: slot.slotIndex)
            else
              layer,
        ],
        assets: document.assets,
      ),
    );
  }
}

/// New layers with sensible defaults, centred on the page.
abstract final class NewLayers {
  /// A slot for the next photo: a 4:3 landscape frame as wide as fits.
  static PhotoSlotLayer photoSlot(TemplateDocument document, String id) {
    final page = document.page;
    final slot = document.photoSlotCount;
    final frame = _centred(
      page,
      aspect: 4 / 3,
      widthShare: 0.8,
      heightShare: 0.4,
    );
    return PhotoSlotLayer(
      id: id,
      zIndex: 0,
      slotIndex: slot,
      name: 'Photo ${slot + 1}',
      frame: frame,
    );
  }

  static TextLayer text(
    TemplateDocument document,
    String id, {
    String text = 'Your words here',
    FontRef font = const BundledFont(
      BundledFontFamily.cormorantGaramond,
      weight: 600,
    ),
    ArgbColor color = const ArgbColor(0xFF33291F),
  }) {
    final page = document.page;
    // About two lines of 24 pt text, most of the page wide.
    final sizePt = 24.0;
    final heightPx = sizePt * page.pixelsPerPoint * 1.2 * 2;
    final height = math.min(0.3, heightPx / page.heightPx);
    return TextLayer(
      id: id,
      zIndex: 0,
      name: 'Text',
      frame: NormalizedRect(
        x: 0.1,
        y: (1 - height) / 2,
        width: 0.8,
        height: height,
      ),
      text: text,
      font: font,
      sizePt: sizePt,
      color: color,
    );
  }

  static ShapeLayer shape(
    TemplateDocument document,
    String id,
    ShapeKind kind, {
    ArgbColor fill = const ArgbColor(0xFFE6CD9B),
  }) => ShapeLayer(
    id: id,
    zIndex: 0,
    name: switch (kind) {
      ShapeKind.rect => 'Rectangle',
      ShapeKind.roundedRect => 'Rounded rectangle',
      ShapeKind.ellipse => 'Ellipse',
    },
    frame: _centred(
      document.page,
      aspect: 1,
      widthShare: 0.3,
      heightShare: 0.3,
    ),
    shape: kind,
    cornerRadius: kind == ShapeKind.roundedRect ? 0.15 : 0,
    fill: fill,
  );

  /// General images start centred at most half-page size. Stickers start
  /// smaller in clear space and retain their proportions if an edge is resized.
  static ImageLayer image(
    TemplateDocument document,
    String id,
    String assetId,
    TemplateAsset asset, {
    bool sticker = false,
  }) {
    final aspect = (asset.widthPx ?? 1) / (asset.heightPx ?? 1);
    return ImageLayer(
      id: id,
      zIndex: 0,
      name: asset.name ?? 'Image',
      assetId: assetId,
      fit: sticker ? ImageFit.contain : ImageFit.fill,
      frame: sticker
          ? StickerPlacement.initialFrame(document, aspect: aspect)
          : _centred(
              document.page,
              aspect: aspect,
              widthShare: 0.5,
              heightShare: 0.5,
            ),
    );
  }

  static BackgroundLayer background(String id, BackgroundFill fill) =>
      BackgroundLayer(id: id, zIndex: 0, name: 'Background', fill: fill);

  /// A frame of [aspect] (width over height, in page pixels) as large as
  /// fits within the given shares of the page, centred.
  static NormalizedRect _centred(
    PageSpec page, {
    required double aspect,
    required double widthShare,
    required double heightShare,
  }) {
    final maxWidth = page.widthPx * widthShare;
    final maxHeight = page.heightPx * heightShare;
    var width = maxWidth;
    var height = width / aspect;
    if (height > maxHeight) {
      height = maxHeight;
      width = height * aspect;
    }
    final w = width / page.widthPx;
    final h = height / page.heightPx;
    return NormalizedRect(x: (1 - w) / 2, y: (1 - h) / 2, width: w, height: h);
  }
}
