import 'dart:ui' as ui;

import '../../domain/template/document_scene.dart';
import '../../domain/template/geometry.dart';

/// A decoded input image and the ratio between its decoded size and the
/// source size the scene was compiled against (inputs may be decoded smaller
/// to bound memory).
final class DecodedAsset {
  DecodedAsset(this.image, {required PixelSize sourceSize})
    : _scaleX = image.width / sourceSize.width,
      _scaleY = image.height / sourceSize.height;

  final ui.Image image;
  final double _scaleX;
  final double _scaleY;

  /// [sourceRect], given in source pixels, in decoded-image pixels.
  ui.Rect decodedRect(PixelRect sourceRect) => ui.Rect.fromLTWH(
    sourceRect.left * _scaleX,
    sourceRect.top * _scaleY,
    sourceRect.width * _scaleX,
    sourceRect.height * _scaleY,
  );

  ui.Rect get fullRect =>
      ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
}

/// Paints [scene] with the page's top-left corner at [origin].
///
/// The single painter behind every preview, workspace and export render
/// (ADR-0003). Each photo is clipped to its own slot shape; image layers are
/// never clipped by slots. When [clipToPage] is true, nothing is drawn
/// outside the page.
void paintScene(
  ui.Canvas canvas,
  DocumentScene scene,
  Map<String, DecodedAsset> assets, {
  ui.Offset origin = ui.Offset.zero,
  bool clipToPage = true,
}) {
  final page = ui.Rect.fromLTWH(
    0,
    0,
    scene.widthPx.toDouble(),
    scene.heightPx.toDouble(),
  );
  canvas
    ..save()
    ..translate(origin.dx, origin.dy);
  if (clipToPage) canvas.clipRect(page);
  canvas.drawRect(page, ui.Paint()..color = ui.Color(scene.backgroundArgb));

  for (final node in scene.nodes) {
    final asset = assets[node.assetId]!;
    final local = ui.Rect.fromCenter(
      center: ui.Offset.zero,
      width: node.rect.width,
      height: node.rect.height,
    );
    final paint = ui.Paint()
      ..filterQuality = ui.FilterQuality.high
      ..color = ui.Color.fromRGBO(0, 0, 0, node.opacity);
    canvas
      ..save()
      ..translate(node.rect.centerX, node.rect.centerY)
      ..rotate(node.rotationRadians);
    switch (node) {
      case PhotoNode(:final sourceCrop, :final cornerRadiusPx):
        canvas
          ..clipRRect(
            ui.RRect.fromRectAndRadius(
              local,
              ui.Radius.circular(cornerRadiusPx),
            ),
          )
          ..drawImageRect(
            asset.image,
            asset.decodedRect(sourceCrop),
            local,
            paint,
          );
      case ImageNode():
        canvas.drawImageRect(asset.image, asset.fullRect, local, paint);
    }
    canvas.restore();
  }
  canvas.restore();
}
