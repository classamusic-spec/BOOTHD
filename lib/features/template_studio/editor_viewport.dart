import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../domain/template/geometry.dart';

/// Where the page sits in the canvas (S07): [scale] logical pixels per
/// page pixel, with the page's top-left corner at [origin]. Survives
/// layout changes: a fitted view refits, a zoomed one keeps the page point
/// at the centre of the view where it was (UX-03).
final class EditorViewport extends ChangeNotifier {
  EditorViewport({required this.pageWidth, required this.pageHeight});

  double pageWidth;
  double pageHeight;

  /// Zoom limits, as page pixels shown 1:1 on logical pixels.
  static const maxScale = 8.0;

  /// Space kept around the fitted page, for handles and off-page artwork.
  static const fitMargin = 40.0;

  var _scale = 1.0;
  var _origin = Offset.zero;
  var _view = Size.zero;
  var _fitted = true;

  double get scale => _scale;
  Offset get origin => _origin;
  Size get viewSize => _view;

  /// Whether the view is fitted to the page (it then refits on resize).
  bool get fitted => _fitted;

  /// The zoom as a percentage of page pixels per logical pixel.
  int get percent => (_scale * 100).round();

  double get fitScale {
    if (_view.isEmpty) return 1;
    final room = Size(
      math.max(1, _view.width - fitMargin * 2),
      math.max(1, _view.height - fitMargin * 2),
    );
    return math.min(room.width / pageWidth, room.height / pageHeight);
  }

  /// A quarter of the fitted size, or less if the fitted size is tiny.
  double get minScale => math.min(fitScale * 0.25, 0.05);

  Offset toPage(Offset view) => (view - _origin) / _scale;

  Offset toView(PixelPoint page) =>
      _origin + Offset(page.x * _scale, page.y * _scale);

  Rect get pageRect => _origin & Size(pageWidth * _scale, pageHeight * _scale);

  /// Called by the canvas with its size on every layout. Listeners hear
  /// of a change after the frame: the canvas is mid-build.
  void resize(Size view) {
    if (view == _view) return;
    final previous = _view;
    _view = view;
    if (_fitted || previous.isEmpty) {
      _fit();
    } else {
      // Keep the page point at the old centre at the new centre.
      final centre = toPage(previous.center(Offset.zero));
      _origin = view.center(Offset.zero) - centre * _scale;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) notifyListeners();
    });
  }

  var _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void fit() {
    _fit();
    notifyListeners();
  }

  void _fit() {
    _fitted = true;
    _scale = fitScale;
    _origin = Offset(
      (_view.width - pageWidth * _scale) / 2,
      (_view.height - pageHeight * _scale) / 2,
    );
  }

  /// Zooms to [scale], keeping the page point under [focal] (view
  /// coordinates; the view's centre by default) where it is.
  void zoomTo(double scale, {Offset? focal}) {
    final point = focal ?? _view.center(Offset.zero);
    final clamped = scale.clamp(minScale, maxScale).toDouble();
    final page = toPage(point);
    _scale = clamped;
    _origin = point - page * clamped;
    _fitted = false;
    notifyListeners();
  }

  /// Steps through comfortable zoom levels.
  void zoomIn() => zoomTo(_scale * 1.25);
  void zoomOut() => zoomTo(_scale / 1.25);

  /// Places the page so that [page] (page pixels) shows at [view] at
  /// [scale]: one step of a pinch.
  void pinch({
    required Offset page,
    required Offset view,
    required double scale,
  }) {
    _scale = scale.clamp(minScale, maxScale).toDouble();
    _origin = view - page * _scale;
    _fitted = false;
    notifyListeners();
  }

  void panBy(Offset delta) {
    if (delta == Offset.zero) return;
    _origin += delta;
    _fitted = false;
    notifyListeners();
  }

  /// A new page size (another template); refits.
  void setPage(double width, double height) {
    if (width == pageWidth && height == pageHeight) return;
    pageWidth = width;
    pageHeight = height;
    fit();
  }
}
