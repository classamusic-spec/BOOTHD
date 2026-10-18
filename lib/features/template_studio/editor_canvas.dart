import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/composition/scene_painter.dart';
import '../../core/design_system/porcelain_colors.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/templates/document_colors.dart';
import '../../domain/template/editing/document_edits.dart';
import '../../domain/template/editing/editor_geometry.dart';
import '../../domain/template/editing/layer_copy.dart';
import '../../domain/template/editing/snapping.dart';
import '../../domain/template/geometry.dart';
import '../../domain/template/template_document.dart';
import '../../domain/template/template_layers.dart';
import 'editor_controller.dart';
import 'editor_viewport.dart';

/// The Template Studio canvas (S07, AC-0503, AC-0505): the page drawn by
/// the print painter, with the artwork beyond its edge shown faded, and
/// direct manipulation on top.
///
/// One finger: tap selects, drag moves the selection (or pans on empty
/// space and with the pan tool), drag a handle to resize or rotate, long
/// press adds to or removes from the selection. Two fingers pinch to zoom
/// and pan. A mouse wheel pans; with Ctrl or Cmd it zooms.
class EditorCanvas extends StatefulWidget {
  const EditorCanvas({
    super.key,
    required this.controller,
    required this.viewport,
    required this.onRefused,
  });

  final TemplateEditorController controller;
  final EditorViewport viewport;

  /// An edit was refused (locked layer, limits); show why.
  final ValueChanged<Object> onRefused;

  /// Handles are drawn this big, and hit this far from their centre.
  static const handleRadius = 9.0;
  static const handleHitRadius = 24.0;

  /// The rotation handle's distance above the top edge, in logical pixels.
  static const rotateHandleDistance = 40.0;

  /// Edges closer than this (logical pixels) snap.
  static const snapDistance = 8.0;

  @override
  State<EditorCanvas> createState() => _EditorCanvasState();
}

enum _Mode { none, move, resize, rotate, pan, zoom }

class _EditorCanvasState extends State<EditorCanvas> {
  TemplateEditorController get _controller => widget.controller;
  EditorViewport get _viewport => widget.viewport;

  var _mode = _Mode.none;
  var _pointers = 0;
  var _multiTouch = false;

  // Move.
  TemplateDocument? _startDocument;
  var _moving = <String>{};
  PixelRect? _startBounds;
  Offset _startFocal = Offset.zero;
  SnapTargets? _targets;

  // Resize and rotate.
  FramedLayer? _startLayer;
  LayerGeometry? _startGeometry;
  HandleKind? _handle;
  PixelPoint? _rotateFrom;

  // Pinch.
  var _pinchStartScale = 1.0;
  var _pinchPage = Offset.zero;

  PixelPoint _pagePoint(Offset view) {
    final p = _viewport.toPage(view);
    return PixelPoint(p.dx, p.dy);
  }

  double get _pageSlop => EditorCanvas.snapDistance / _viewport.scale;

  // Hit testing.

  /// The handle under [view] on the single selected layer, if any; null
  /// handle with a true flag is the rotation handle.
  ({HandleKind? handle, bool rotate})? _handleAt(Offset view) {
    final layer = _controller.singleSelection;
    if (layer is! FramedLayer || layer.locked || !layer.visible) return null;
    final geometry = LayerGeometry.of(layer, _controller.document.page);
    final scale = _viewport.scale;
    final rotate = _viewport.toView(
      geometry.rotationHandle(EditorCanvas.rotateHandleDistance / scale),
    );
    if ((rotate - view).distance <= EditorCanvas.handleHitRadius) {
      return (handle: null, rotate: true);
    }
    HandleKind? best;
    var bestDistance = EditorCanvas.handleHitRadius;
    for (final kind in visibleHandles(geometry, scale)) {
      final distance =
          (_viewport.toView(geometry.handle(kind)) - view).distance;
      if (distance <= bestDistance) {
        best = kind;
        bestDistance = distance;
      }
    }
    return best == null ? null : (handle: best, rotate: false);
  }

  // Gestures.

  void _onTapUp(TapUpDetails details) {
    final id = layerAt(
      _controller.document,
      _pagePoint(details.localPosition),
      slop: _pageSlop,
    );
    _controller.select(id);
  }

  void _onLongPress(LongPressStartDetails details) {
    final id = layerAt(
      _controller.document,
      _pagePoint(details.localPosition),
      slop: _pageSlop,
    );
    if (id != null) {
      HapticFeedback.selectionClick();
      _controller.toggleSelected(id);
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    final focal = details.localFocalPoint;
    if (details.pointerCount >= 2) {
      _multiTouch = true;
      _mode = _Mode.zoom;
      _pinchStartScale = _viewport.scale;
      _pinchPage = _viewport.toPage(focal);
      return;
    }
    // A finger left after a pinch only pans, never grabs a layer.
    if (_multiTouch || _controller.tool == EditorTool.pan) {
      _mode = _Mode.pan;
      return;
    }

    final handle = _handleAt(focal);
    if (handle != null) {
      final layer = _controller.singleSelection! as FramedLayer;
      _startLayer = layer;
      _startGeometry = LayerGeometry.of(layer, _controller.document.page);
      _targets = _snapTargets({layer.id});
      _controller.beginGesture();
      if (handle.rotate) {
        _mode = _Mode.rotate;
        _rotateFrom = _pagePoint(focal);
      } else {
        _mode = _Mode.resize;
        _handle = handle.handle;
      }
      return;
    }

    final document = _controller.document;
    final hit = layerAt(document, _pagePoint(focal), slop: _pageSlop);
    if (hit == null) {
      _mode = _Mode.pan;
      return;
    }
    if (!_controller.isSelected(hit)) _controller.select(hit);
    final movable = {
      for (final layer in _controller.selectedLayers)
        if (layer is FramedLayer && !layer.locked && layer.visible) layer.id,
    };
    if (movable.isEmpty) {
      // A locked layer: selected so it can be unlocked, never moved.
      _mode = _Mode.pan;
      return;
    }
    _mode = _Mode.move;
    _moving = movable;
    _startDocument = document;
    _startFocal = focal;
    _startBounds = _union([
      for (final layer in document.layers)
        if (movable.contains(layer.id))
          LayerGeometry.of(layer as FramedLayer, document.page).bounds,
    ]);
    _targets = _snapTargets(movable);
    _controller.beginGesture();
  }

  SnapTargets? _snapTargets(Set<String> exclude) => _controller.snapping
      ? SnapTargets.of(
          _controller.document,
          exclude: exclude,
          gridSpacing: _controller.showGrid ? _controller.gridSpacingPx : null,
        )
      : null;

  void _onScaleUpdate(ScaleUpdateDetails details) {
    switch (_mode) {
      case _Mode.zoom:
        _viewport.pinch(
          page: _pinchPage,
          view: details.localFocalPoint,
          scale: _pinchStartScale * details.scale,
        );
      case _Mode.pan:
        _viewport.panBy(details.focalPointDelta);
      case _Mode.move:
        _move(details.localFocalPoint);
      case _Mode.resize:
        _resize(details.localFocalPoint);
      case _Mode.rotate:
        _rotate(details.localFocalPoint);
      case _Mode.none:
        break;
    }
  }

  void _move(Offset focal) {
    final start = _startDocument!;
    final page = start.page;
    final delta = (focal - _startFocal) / _viewport.scale;
    var dx = delta.dx;
    var dy = delta.dy;
    var guides = const <SnapGuide>[];
    final targets = _targets;
    if (targets != null) {
      final bounds = _startBounds!;
      final snap = snapBox(
        PixelRect(
          left: bounds.left + dx,
          top: bounds.top + dy,
          width: bounds.width,
          height: bounds.height,
        ),
        targets,
        _pageSlop,
      );
      dx += snap.dx;
      dy += snap.dy;
      guides = snap.guides;
    }
    _controller
      ..updateGesture(
        DocumentEdits.translate(
          start,
          _moving,
          dx / page.widthPx,
          dy / page.heightPx,
        ),
      )
      ..guides = guides;
  }

  void _resize(Offset focal) {
    final layer = _startLayer!;
    final geometry = _startGeometry!;
    final handle = _handle!;
    final page = _controller.document.page;
    var pointer = _pagePoint(focal);
    final guides = <SnapGuide>[];
    final targets = _targets;
    // Edges snap while the frame is upright.
    if (targets != null && normalizeDegrees(geometry.rotationDegrees) == 0) {
      var x = pointer.x;
      var y = pointer.y;
      if (handle.sx != 0) {
        final (delta, guide) = snapEdge(
          x,
          GuideAxis.vertical,
          targets,
          _pageSlop,
        );
        x += delta;
        if (guide != null) guides.add(guide);
      }
      if (handle.sy != 0) {
        final (delta, guide) = snapEdge(
          y,
          GuideAxis.horizontal,
          targets,
          _pageSlop,
        );
        y += delta;
        if (guide != null) guides.add(guide);
      }
      pointer = PixelPoint(x, y);
    }
    final resized = geometry.resized(
      handle,
      pointer,
      keepAspect: layer is ImageLayer,
      minSize: 8,
    );
    _controller
      ..updateGesture(
        DocumentEdits.replace(
          _controller.document,
          copyLayer(_current(layer), frame: resized.frameOn(page)),
        ),
      )
      ..guides = guides;
  }

  void _rotate(Offset focal) {
    final layer = _startLayer!;
    final degrees = _startGeometry!.rotatedTo(_rotateFrom!, _pagePoint(focal));
    _controller.updateGesture(
      DocumentEdits.replace(
        _controller.document,
        copyLayer(_current(layer), rotationDegrees: degrees),
      ),
    );
  }

  /// The layer as it is now (other fields may have changed since the
  /// gesture began, e.g. by undo in another hand).
  TemplateLayer _current(TemplateLayer layer) => _controller.document.layers
      .firstWhere((l) => l.id == layer.id, orElse: () => layer);

  void _onScaleEnd(ScaleEndDetails details) {
    switch (_mode) {
      case _Mode.move || _Mode.resize || _Mode.rotate:
        _controller.endGesture();
      case _Mode.zoom || _Mode.pan || _Mode.none:
        break;
    }
    _mode = _Mode.none;
    _startDocument = null;
    _startLayer = null;
    _startGeometry = null;
    _targets = null;
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final keys = HardwareKeyboard.instance;
    if (keys.isControlPressed || keys.isMetaPressed) {
      final factor = math.pow(1.002, -event.scrollDelta.dy).toDouble();
      _viewport.zoomTo(_viewport.scale * factor, focal: event.localPosition);
    } else {
      _viewport.panBy(-event.scrollDelta);
    }
  }

  static PixelRect _union(List<PixelRect> rects) {
    var left = rects.first.left;
    var top = rects.first.top;
    var right = rects.first.right;
    var bottom = rects.first.bottom;
    for (final r in rects.skip(1)) {
      left = math.min(left, r.left);
      top = math.min(top, r.top);
      right = math.max(right, r.right);
      bottom = math.max(bottom, r.bottom);
    }
    return PixelRect(
      left: left,
      top: top,
      width: right - left,
      height: bottom - top,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewport.resize(constraints.biggest);
        return Listener(
          onPointerDown: (_) => _pointers++,
          onPointerUp: (_) => _pointerGone(),
          onPointerCancel: (_) => _pointerGone(),
          onPointerSignal: _onPointerSignal,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: _onTapUp,
            onLongPressStart: _onLongPress,
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onScaleEnd: _onScaleEnd,
            child: ListenableBuilder(
              listenable: Listenable.merge([_controller, _viewport]),
              builder: (context, _) => Semantics(
                label: 'Template canvas',
                value: _semanticValue(),
                child: ClipRect(
                  child: CustomPaint(
                    size: constraints.biggest,
                    painter: _ScenePainter(
                      controller: _controller,
                      viewport: _viewport,
                      colors: theme.colors,
                    ),
                    foregroundPainter: EditorOverlayPainter(
                      controller: _controller,
                      viewport: _viewport,
                      colors: theme.colors,
                      labelStyle: theme.text.labelSmall,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _pointerGone() {
    _pointers = math.max(0, _pointers - 1);
    if (_pointers == 0) _multiTouch = false;
  }

  String _semanticValue() {
    final selected = _controller.selectedLayers;
    final zoom = '${_viewport.percent}% zoom';
    if (selected.isEmpty) return 'Nothing selected, $zoom';
    if (selected.length > 1) return '${selected.length} layers selected, $zoom';
    return '${layerLabel(selected.single)} selected, $zoom';
  }
}

/// A layer's name, or what it is when it has none.
String layerLabel(TemplateLayer layer) {
  if (layer.name.trim().isNotEmpty) return layer.name.trim();
  return switch (layer) {
    BackgroundLayer() => 'Background',
    PhotoSlotLayer(:final slotIndex) => 'Photo ${slotIndex + 1}',
    ImageLayer() => 'Image',
    TextLayer(:final text) =>
      text.trim().isEmpty
          ? 'Text'
          : text
                .trim()
                .split('\n')
                .first
                .substring(
                  0,
                  math.min(24, text.trim().split('\n').first.length),
                ),
    ShapeLayer() => 'Shape',
  };
}

/// The resize handles worth showing at [scale]: corners always, edge
/// handles only where the side is long enough to tell them apart.
List<HandleKind> visibleHandles(LayerGeometry geometry, double scale) {
  final width = geometry.rect.width * scale;
  final height = geometry.rect.height * scale;
  return [
    for (final kind in HandleKind.values)
      if (kind.isCorner ||
          (kind.sx == 0 && width >= 64) ||
          (kind.sy == 0 && height >= 64))
        kind,
  ];
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({
    required this.controller,
    required this.viewport,
    required this.colors,
  });

  final TemplateEditorController controller;
  final EditorViewport viewport;
  final PorcelainColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final page = viewport.pageRect;
    canvas
      ..drawRect(
        page.shift(const Offset(0, 3)),
        Paint()
          ..color = colors.shadowKey
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      )
      ..drawRect(page, Paint()..color = paperColor);
    paintScene(
      canvas,
      controller.scene,
      controller.resources,
      origin: viewport.origin,
      scale: viewport.scale,
      clipToPage: false,
    );
    // Artwork beyond the page shows faded: the export clips it.
    canvas
      ..drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(Offset.zero & size)
          ..addRect(page),
        Paint()..color = colors.inset.withValues(alpha: 0.8),
      )
      ..drawRect(
        page,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = colors.outline,
      );
  }

  @override
  bool shouldRepaint(_ScenePainter old) => true;
}

/// Grid, print-safe margin, slot numbers, selection, handles and snap
/// guides, drawn in screen space so their lines stay crisp at any zoom.
class EditorOverlayPainter extends CustomPainter {
  EditorOverlayPainter({
    required this.controller,
    required this.viewport,
    required this.colors,
    required this.labelStyle,
  });

  final TemplateEditorController controller;
  final EditorViewport viewport;
  final PorcelainColors colors;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final document = controller.document;
    final page = document.page;
    final pageRect = viewport.pageRect;
    final scale = viewport.scale;

    if (controller.showGrid) {
      final step = controller.gridSpacingPx * scale;
      if (step >= 6) {
        final line = Paint()
          ..color = colors.focusRing.withValues(alpha: 0.18)
          ..strokeWidth = 1;
        for (var x = pageRect.left + step; x < pageRect.right; x += step) {
          canvas.drawLine(
            Offset(x, pageRect.top),
            Offset(x, pageRect.bottom),
            line,
          );
        }
        for (var y = pageRect.top + step; y < pageRect.bottom; y += step) {
          canvas.drawLine(
            Offset(pageRect.left, y),
            Offset(pageRect.right, y),
            line,
          );
        }
      }
    }

    if (controller.showSafeArea) {
      final inset = controller.safeMarginPx * scale;
      _dashedRect(
        canvas,
        pageRect.deflate(inset),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = colors.inkMuted.withValues(alpha: 0.55),
      );
    }

    // Photo numbers, so the capture order is visible at a glance.
    for (final slot in document.photoSlots) {
      if (!slot.visible) continue;
      final geometry = LayerGeometry.of(slot, page);
      final corner = viewport.toView(geometry.corners.first);
      _badge(canvas, corner + const Offset(14, 14), '${slot.slotIndex + 1}');
    }

    final selected = controller.selectedLayers.whereType<FramedLayer>();
    final single = selected.length == 1 ? selected.single : null;
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = colors.focusRing;
    for (final layer in selected) {
      final geometry = LayerGeometry.of(layer, page);
      final corners = [for (final c in geometry.corners) viewport.toView(c)];
      final path = Path()..addPolygon(corners, true);
      if (layer.locked || !layer.visible) {
        _dashedPath(canvas, corners, outline);
      } else {
        canvas.drawPath(path, outline);
      }
      if (layer.locked) {
        _icon(
          canvas,
          corners.first + const Offset(-2, -22),
          PorcelainIcons.locked,
        );
      }
    }

    final layer = single;
    if (layer != null && !layer.locked && layer.visible) {
      final geometry = LayerGeometry.of(layer, page);
      final top = viewport.toView(geometry.handle(HandleKind.top));
      final rotate = viewport.toView(
        geometry.rotationHandle(EditorCanvas.rotateHandleDistance / scale),
      );
      canvas.drawLine(top, rotate, outline);
      final fill = Paint()..color = colors.surface;
      for (final kind in visibleHandles(geometry, scale)) {
        final centre = viewport.toView(geometry.handle(kind));
        canvas
          ..drawCircle(centre, EditorCanvas.handleRadius, fill)
          ..drawCircle(centre, EditorCanvas.handleRadius, outline);
      }
      canvas
        ..drawCircle(rotate, EditorCanvas.handleRadius + 2, fill)
        ..drawCircle(rotate, EditorCanvas.handleRadius + 2, outline);
      _icon(
        canvas,
        rotate - const Offset(8, 8),
        PorcelainIcons.retry,
        size: 16,
      );
    }

    final guide = Paint()
      ..color = colors.danger
      ..strokeWidth = 1;
    for (final g in controller.guides) {
      if (g.axis == GuideAxis.vertical) {
        final x = viewport.toView(PixelPoint(g.position, 0)).dx;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), guide);
      } else {
        final y = viewport.toView(PixelPoint(0, g.position)).dy;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), guide);
      }
    }
  }

  void _badge(Canvas canvas, Offset centre, String label) {
    canvas
      ..drawCircle(
        centre,
        11,
        Paint()..color = colors.surface.withValues(alpha: 0.92),
      )
      ..drawCircle(
        centre,
        11,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = colors.accentIcon,
      );
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: labelStyle.copyWith(color: colors.accentText, height: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      centre - Offset(painter.width / 2, painter.height / 2),
    );
    painter.dispose();
  }

  void _icon(Canvas canvas, Offset at, IconData icon, {double size = 18}) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: size,
          color: colors.accentText,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
    painter.dispose();
  }

  static void _dashedRect(Canvas canvas, Rect rect, Paint paint) => _dashedPath(
    canvas,
    [rect.topLeft, rect.topRight, rect.bottomRight, rect.bottomLeft],
    paint,
  );

  static void _dashedPath(Canvas canvas, List<Offset> corners, Paint paint) {
    const dash = 6.0;
    const gap = 4.0;
    for (var i = 0; i < corners.length; i++) {
      final a = corners[i];
      final b = corners[(i + 1) % corners.length];
      final length = (b - a).distance;
      if (length == 0) continue;
      final step = (b - a) / length;
      for (var d = 0.0; d < length; d += dash + gap) {
        canvas.drawLine(
          a + step * d,
          a + step * math.min(d + dash, length),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(EditorOverlayPainter old) => true;
}
