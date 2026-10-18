import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../core/composition/scene_images.dart';
import '../../core/composition/scene_painter.dart';
import '../../core/composition/template_fonts.dart';
import '../../core/templates/slot_placeholder.dart';
import '../../core/templates/template_library.dart';
import '../../domain/repositories/template_store.dart';
import '../../domain/template/document_issues.dart';
import '../../domain/template/document_scene.dart';
import '../../domain/template/editing/document_edits.dart';
import '../../domain/template/editing/edit_history.dart';
import '../../domain/template/editing/layer_copy.dart';
import '../../domain/template/editing/snapping.dart';
import '../../domain/template/geometry.dart';
import '../../domain/template/template_assets.dart';
import '../../domain/template/template_document.dart';
import '../../domain/template/template_layers.dart';

/// What a drag on the canvas does where it does not start on a handle.
enum EditorTool {
  /// Drags move layers; drags on empty space pan.
  select,

  /// Every drag pans, so a layer cannot be moved by accident.
  pan,
}

/// The state of unsaved work in the draft store (A-08 autosave).
enum DraftState {
  /// Nothing unsaved.
  clean,

  /// Changes are waiting to be written.
  pending,
  writing,

  /// The latest changes are in the draft.
  written,

  /// The draft could not be written; the changes are only in memory.
  failed,
}

/// An edit that would break the template rules; nothing changed.
final class InvalidEdit implements Exception {
  const InvalidEdit(this.issues);

  final List<DocumentIssue> issues;

  @override
  String toString() => 'InvalidEdit(${issues.map((i) => i.code).join(', ')})';
}

/// The Template Studio's working state (S07): one template's document with
/// undo history, the selection, the canvas scene and its decoded images,
/// autosave to the draft store and explicit saves as new revisions.
///
/// Owned by the editor screen, not its layout, so rotating the tablet keeps
/// the selection, history and view (UX-03).
final class TemplateEditorController extends ChangeNotifier {
  TemplateEditorController({
    required this.library,
    required this.assets,
    required StoredTemplateRevision revision,
    TemplateDraft? restoredDraft,
    this.autosaveDelay = const Duration(milliseconds: 1200),
    TemplateFontLoader? fonts,
  }) : _revision = revision,
       history = EditHistory(revision.document),
       _fonts = fonts ?? TemplateFontLoader() {
    if (restoredDraft != null) {
      history.reset(restoredDraft.document, saved: revision.document);
      _draftStored = true;
      _lastDraft = restoredDraft.document;
      _draftState = DraftState.written;
    }
    _refreshScene();
  }

  final TemplateLibrary library;
  final AssetRepository assets;
  final Duration autosaveDelay;
  final EditHistory history;
  final TemplateFontLoader _fonts;

  StoredTemplateRevision _revision;

  /// The revision the document was opened from, or last saved as.
  StoredTemplateRevision get revision => _revision;
  String get templateId => _revision.summary.templateId;
  String get templateName => _revision.summary.templateName;

  TemplateDocument get document => history.current;
  bool get hasUnsavedChanges => history.hasUnsavedChanges;

  // Selection.

  var _selection = const <String>[];

  /// Selected layer ids, in the order they were selected.
  List<String> get selection => _selection;

  List<TemplateLayer> get selectedLayers => [
    for (final id in _selection) ?_layer(id),
  ];

  TemplateLayer? get singleSelection =>
      _selection.length == 1 ? _layer(_selection.single) : null;

  bool isSelected(String id) => _selection.contains(id);

  void select(String? id) {
    final next = id == null ? const <String>[] : [id];
    if (listEquals(next, _selection)) return;
    _selection = next;
    notifyListeners();
  }

  /// Adds [id] to the selection, or takes it out (multi-selection).
  void toggleSelected(String id) {
    _selection = _selection.contains(id)
        ? [
            for (final s in _selection)
              if (s != id) s,
          ]
        : [..._selection, id];
    notifyListeners();
  }

  TemplateLayer? _layer(String id) {
    for (final layer in document.layers) {
      if (layer.id == id) return layer;
    }
    return null;
  }

  // View options.

  var _tool = EditorTool.select;
  EditorTool get tool => _tool;
  set tool(EditorTool value) {
    if (value == _tool) return;
    _tool = value;
    notifyListeners();
  }

  var _showGrid = false;
  bool get showGrid => _showGrid;
  set showGrid(bool value) {
    if (value == _showGrid) return;
    _showGrid = value;
    notifyListeners();
  }

  var _snapping = true;
  bool get snapping => _snapping;
  set snapping(bool value) {
    if (value == _snapping) return;
    _snapping = value;
    notifyListeners();
  }

  var _showSafeArea = true;
  bool get showSafeArea => _showSafeArea;
  set showSafeArea(bool value) {
    if (value == _showSafeArea) return;
    _showSafeArea = value;
    notifyListeners();
  }

  /// Whether the inspector shows lengths in the page's unit (inches or
  /// millimetres) rather than print pixels.
  var _pageUnits = false;
  bool get pageUnits => _pageUnits;
  set pageUnits(bool value) {
    if (value == _pageUnits) return;
    _pageUnits = value;
    notifyListeners();
  }

  /// Grid spacing in page pixels: an eighth of an inch.
  double get gridSpacingPx => document.page.dpi / 8;

  /// The print-safe margin in page pixels: an eighth of an inch inside the
  /// trim, where cutters and printers may drift.
  double get safeMarginPx => document.page.dpi / 8;

  /// Guides to draw while a drag snaps (page pixels).
  var _guides = const <SnapGuide>[];
  List<SnapGuide> get guides => _guides;
  set guides(List<SnapGuide> value) {
    if (listEquals(value, _guides)) return;
    _guides = value;
    notifyListeners();
  }

  // Edits.

  /// Applies [edit] to the document as one undo step (or as part of the
  /// gesture in progress). Throws [EditRefused] or [InvalidEdit]; the
  /// document is then unchanged.
  void apply(TemplateDocument Function(TemplateDocument document) edit) {
    _commit(edit(document));
  }

  void _commit(TemplateDocument next) {
    final errors = next.errors;
    if (errors.isNotEmpty) throw InvalidEdit(errors);
    history.commit(next);
    _afterChange();
  }

  void beginGesture() => history.beginGesture();

  /// One step of a drag, pinch or slider: replaces the gesture's document.
  /// A step that would break the rules is skipped.
  void updateGesture(TemplateDocument next) {
    if (next.errors.isNotEmpty) return;
    history.commit(next);
    _afterChange(autosave: false);
  }

  void endGesture() {
    history.endGesture();
    _guides = const [];
    _afterChange();
  }

  void cancelGesture() {
    history.cancelGesture();
    _guides = const [];
    _afterChange();
  }

  bool get canUndo => history.canUndo;
  bool get canRedo => history.canRedo;

  void undo() {
    if (history.undo() != null) _afterChange();
  }

  void redo() {
    if (history.redo() != null) _afterChange();
  }

  void _afterChange({bool autosave = true}) {
    // Drop selected ids the document no longer has (after undo, delete).
    final ids = {for (final layer in document.layers) layer.id};
    if (_selection.any((id) => !ids.contains(id))) {
      _selection = [
        for (final id in _selection)
          if (ids.contains(id)) id,
      ];
    }
    _refreshScene();
    if (autosave) _scheduleDraft();
    notifyListeners();
  }

  /// A layer id not yet used: `<prefix>-<n>`.
  String newLayerId(String prefix) {
    final used = {for (final layer in document.layers) layer.id};
    for (var n = 1; ; n++) {
      final id = '$prefix-$n';
      if (!used.contains(id)) return id;
    }
  }

  void addPhotoSlot() =>
      _add(NewLayers.photoSlot(document, newLayerId('photo')));

  void addText() => _add(NewLayers.text(document, newLayerId('text')));

  void addShape(ShapeKind kind) =>
      _add(NewLayers.shape(document, newLayerId('shape'), kind));

  /// Adds [asset] as an image layer, once its pixels are ready to draw.
  Future<void> addImage(StoredAsset asset) async {
    await _preload(AssetImageRef(asset.id), asset.asset);
    _add(
      NewLayers.image(document, newLayerId('image'), asset.id, asset.asset),
      assets: {asset.id: asset.asset},
    );
  }

  void _add(TemplateLayer layer, {Map<String, TemplateAsset>? assets}) {
    _commit(DocumentEdits.add(document, layer, assets: assets ?? const {}));
    _selection = [layer.id];
    notifyListeners();
  }

  /// Gives the page [fill], adding a background layer if it has none.
  Future<void> setBackground(BackgroundFill fill, {StoredAsset? image}) async {
    if (image != null) await _preload(AssetImageRef(image.id), image.asset);
    final assets = {if (image != null) image.id: image.asset};
    final existing = document.background;
    _commit(
      existing == null
          ? DocumentEdits.add(
              document,
              NewLayers.background(newLayerId('background'), fill),
              assets: assets,
            )
          : DocumentEdits.update(
              document,
              existing.id,
              (layer) => (layer as BackgroundLayer).copyWith(fill: fill),
              assets: assets,
            ),
    );
  }

  void updateLayer(
    String id,
    TemplateLayer Function(TemplateLayer layer) change,
  ) => _commit(DocumentEdits.update(document, id, change));

  /// [updateLayer] as one step of a gesture (sliders).
  void updateLayerInGesture(
    String id,
    TemplateLayer Function(TemplateLayer layer) change,
  ) => updateGesture(DocumentEdits.update(document, id, change));

  void setVisible(String id, {required bool visible}) =>
      updateLayer(id, (layer) => copyLayer(layer, visible: visible));

  void setLocked(String id, {required bool locked}) =>
      updateLayer(id, (layer) => copyLayer(layer, locked: locked));

  void renameLayer(String id, String name) => updateLayer(
    id,
    (layer) => copyLayer(
      layer,
      name: name.trim().substring(
        0,
        math.min(name.trim().length, GeometryLimits.maxNameLength),
      ),
    ),
  );

  void deleteSelected() {
    if (_selection.isEmpty) return;
    _commit(DocumentEdits.remove(document, _selection.toSet()));
  }

  void duplicateSelected() {
    final ids = [
      for (final layer in selectedLayers)
        if (layer is! BackgroundLayer) layer.id,
    ];
    if (ids.isEmpty) return;
    final (next, copies) = DocumentEdits.duplicate(
      document,
      ids,
      newId: () => _uniqueCopyId(ids),
    );
    _commit(next);
    _selection = copies;
    notifyListeners();
  }

  var _copyCounter = 0;
  String _uniqueCopyId(List<String> originals) {
    final used = {for (final layer in document.layers) layer.id};
    while (true) {
      final id = 'copy-${++_copyCounter}';
      if (!used.contains(id)) return id;
    }
  }

  void bringForward(String id) =>
      _commit(DocumentEdits.bringForward(document, id));
  void sendBackward(String id) =>
      _commit(DocumentEdits.sendBackward(document, id));
  void bringToFront(String id) =>
      _commit(DocumentEdits.bringToFront(document, id));
  void sendToBack(String id) => _commit(DocumentEdits.sendToBack(document, id));

  /// Moves layer [id] to [paintIndex] (0 is the bottom).
  void moveLayer(String id, int paintIndex) =>
      _commit(DocumentEdits.move(document, id, paintIndex));

  void renumberSlot(String id, int slotIndex) =>
      _commit(DocumentEdits.renumberSlot(document, id, slotIndex));

  /// Moves the unlocked selected layers by [dx], [dy] page pixels.
  void nudge(double dx, double dy) {
    final ids = {
      for (final layer in selectedLayers)
        if (layer is FramedLayer && !layer.locked) layer.id,
    };
    if (ids.isEmpty) return;
    final page = document.page;
    _commit(
      DocumentEdits.translate(
        document,
        ids,
        dx / page.widthPx,
        dy / page.heightPx,
      ),
    );
  }

  // Scene and images.

  static final _placeholderBinding = SlotBinding(
    photoId: slotPlaceholderPhotoId,
    size: const PixelSize(slotPlaceholderSizePx, slotPlaceholderSizePx),
  );

  late DocumentScene _scene;
  var _paintable = const DocumentScene(
    widthPx: 1,
    heightPx: 1,
    nodes: [],
    imageSizes: {},
  );

  /// The document compiled with the placeholder in every slot, limited to
  /// what can be drawn now (images still decoding are left out).
  DocumentScene get scene => _paintable;

  final _images = <ImageSourceRef, DecodedImage>{};
  final _decodedScale = <ImageSourceRef, double>{};
  final _loading = <ImageSourceRef>{};
  final _fontsResolved = <FontRef, ResolvedFont>{};

  /// Images whose files could not be read; drawn as a hatched stand-in.
  final missingAssets = <String>{};

  var _resourcesVersion = 0;

  /// Changes whenever [resources] does.
  int get resourcesVersion => _resourcesVersion;

  SceneResources get resources =>
      SceneResources(images: _images, fonts: _fontsResolved);

  /// Whether every image and font of the document is ready.
  bool get ready =>
      _scene.imageSizes.keys.every(_images.containsKey) &&
      _scene.fonts.every(_fontsResolved.containsKey);

  var _disposed = false;

  void _refreshScene() {
    _scene = compileScene(
      document,
      bindings: {
        for (final slot in document.photoSlots)
          slot.slotIndex: _placeholderBinding,
      },
    );
    _paintable = _drawable(_scene);
    unawaited(_loadResources(_scene));
  }

  DocumentScene _drawable(DocumentScene scene) {
    bool has(ImageSourceRef ref) => _images.containsKey(ref);
    final nodes = [
      for (final node in scene.nodes)
        if (switch (node) {
          FillNode(fill: SceneImageFill(:final source)) => has(source),
          PhotoNode(:final source, :final clip) =>
            has(source) && (clip is! SceneMaskClip || has(clip.mask)),
          ImageNode(:final source) => has(source),
          _ => true,
        })
          node,
    ];
    return DocumentScene(
      widthPx: scene.widthPx,
      heightPx: scene.heightPx,
      nodes: nodes,
      imageSizes: scene.imageSizes,
    );
  }

  Future<void> _loadResources(DocumentScene scene) async {
    // Fonts first (bundled ones resolve at once), so text never shows in
    // a stand-in font while images decode.
    var fontsChanged = false;
    for (final font in scene.fonts) {
      if (_fontsResolved.containsKey(font)) continue;
      _fontsResolved[font] = await _fonts.resolve(font, assets.read);
      fontsChanged = true;
    }
    if (_disposed) return;
    if (fontsChanged) _publishResources();
    // Images decode side by side; each appears as soon as it is ready.
    await Future.wait([
      for (final MapEntry(key: ref, value: size) in scene.imageSizes.entries)
        _loadImage(scene, ref, size),
    ]);
  }

  Future<void> _loadImage(
    DocumentScene scene,
    ImageSourceRef ref,
    PixelSize size,
  ) async {
    final needed = math.min(1.0, math.max(scene.drawScale(ref), 0.05));
    final decoded = _decodedScale[ref];
    if (decoded != null && decoded >= math.min(1, needed * 0.8)) return;
    if (!_loading.add(ref)) return;
    try {
      final image = await _decode(ref, size, needed);
      if (_disposed) {
        image.dispose();
        return;
      }
      _replaceImage(ref, image);
      _decodedScale[ref] = needed;
      if (ref case AssetImageRef(:final assetId)) missingAssets.remove(assetId);
    } on Object {
      if (_disposed) return;
      if (!_images.containsKey(ref)) {
        _replaceImage(ref, DecodedImage(await _hatch(), sourceSize: size));
      }
      _decodedScale[ref] = 1;
      if (ref case AssetImageRef(:final assetId)) missingAssets.add(assetId);
    } finally {
      _loading.remove(ref);
    }
    if (!_disposed) _publishResources();
  }

  void _publishResources() {
    _resourcesVersion++;
    _paintable = _drawable(_scene);
    notifyListeners();
  }

  Future<DecodedImage> _decode(
    ImageSourceRef ref,
    PixelSize size,
    double scale,
  ) async {
    final bytes = switch (ref) {
      AssetImageRef(:final assetId) => await assets.read(assetId),
      PhotoImageRef() => await slotPlaceholderPng(),
    };
    // The file must still be the one the document recorded.
    if (await probeImageSize(bytes) != size) {
      throw const ImageDecodeException('the image changed');
    }
    return DecodedImage(
      await decodeImage(bytes, scale: scale),
      sourceSize: size,
    );
  }

  /// Decodes [ref] before a layer that draws it is added, so it never
  /// appears blank.
  Future<void> _preload(ImageSourceRef ref, TemplateAsset asset) async {
    if (_images.containsKey(ref)) return;
    final size = PixelSize(asset.widthPx!, asset.heightPx!);
    final page = document.page;
    // New images are at most the page's size.
    final scale = math.min(
      1.0,
      math.max(page.widthPx / size.width, page.heightPx / size.height),
    );
    final image = await _decode(ref, size, scale);
    if (_disposed) {
      image.dispose();
      return;
    }
    _replaceImage(ref, image);
    _decodedScale[ref] = scale;
    _resourcesVersion++;
  }

  void _replaceImage(ImageSourceRef ref, DecodedImage image) {
    final old = _images[ref];
    _images[ref] = image;
    // The current frame may still draw the old one.
    if (old != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
  }

  /// A hatched tile that stands in for an image that cannot be read.
  static Future<ui.Image> _hatch() async => (await missingImageTile()).clone();

  // Drafts and saving.

  Timer? _draftTimer;
  var _draftState = DraftState.clean;
  DraftState get draftState => _draftState;
  TemplateDocument? _lastDraft;
  var _draftStored = false;
  Future<void> _draftWrites = Future.value();

  void _scheduleDraft() {
    _draftTimer?.cancel();
    if (!hasUnsavedChanges && !_draftStored) {
      _draftState = DraftState.clean;
      return;
    }
    _draftState = DraftState.pending;
    _draftTimer = Timer(autosaveDelay, () => unawaited(writeDraft()));
  }

  /// Writes unsaved changes to the draft store now (also on leaving the
  /// app, A-08). Without unsaved changes, a stored draft is removed.
  Future<void> writeDraft() {
    _draftTimer?.cancel();
    return _draftWrites = _draftWrites.then((_) => _writeDraft());
  }

  Future<void> _writeDraft() async {
    if (_disposed && !hasUnsavedChanges) return;
    if (history.inGesture) {
      if (!_disposed) _scheduleDraft();
      return;
    }
    final current = document;
    try {
      if (!hasUnsavedChanges) {
        if (_draftStored) {
          await library.discardDraft(templateId);
          _draftStored = false;
          _lastDraft = null;
        }
        _setDraftState(DraftState.clean);
        return;
      }
      if (identical(current, _lastDraft)) return;
      _setDraftState(DraftState.writing);
      await library.saveDraft(
        templateId,
        baseRevisionId: _revision.summary.revisionId,
        document: current,
      );
      _lastDraft = current;
      _draftStored = true;
      _setDraftState(
        identical(current, document) ? DraftState.written : DraftState.pending,
      );
    } on Object {
      _setDraftState(DraftState.failed);
    }
  }

  void _setDraftState(DraftState state) {
    _draftState = state;
    if (!_disposed) notifyListeners();
  }

  var _saving = false;
  bool get saving => _saving;

  /// Stores the document as the template's next revision and clears the
  /// draft. Throws [TemplateStoreException]; the work stays in memory and
  /// in the draft.
  Future<void> save() async {
    if (_saving) return;
    _draftTimer?.cancel();
    final current = document;
    _saving = true;
    notifyListeners();
    try {
      await _draftWrites;
      final saved = await library.save(templateId, current);
      _revision = saved;
      history.markSaved(current);
      _draftStored = false;
      _lastDraft = null;
      _draftState = hasUnsavedChanges ? DraftState.pending : DraftState.clean;
      if (hasUnsavedChanges) _scheduleDraft();
    } finally {
      _saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Leaves without saving: forgets the changes and the draft.
  Future<void> discardChanges() async {
    _draftTimer?.cancel();
    await _draftWrites;
    await library.discardDraft(templateId);
    _draftStored = false;
    _lastDraft = null;
    history.reset(_revision.document);
    _selection = const [];
    _draftState = DraftState.clean;
    _refreshScene();
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _draftTimer?.cancel();
    // Unsaved work is kept as a draft even if the timer had not fired.
    if (hasUnsavedChanges) unawaited(writeDraft());
    for (final image in _images.values) {
      image.dispose();
    }
    _images.clear();
    super.dispose();
  }
}
