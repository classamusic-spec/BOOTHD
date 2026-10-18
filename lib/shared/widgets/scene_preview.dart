import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/composition/scene_painter.dart';
import '../../domain/template/document_scene.dart';

/// A template rendered on screen by the same painter as the print export
/// (ADR-0003, ADR-0010): the scene is fitted to the available space by
/// scaling, never re-laid out, so text wraps and slots crop exactly as in
/// the 300 dpi file. Display only; the export never comes from a widget.
class ScenePreview extends StatelessWidget {
  const ScenePreview({
    super.key,
    required this.scene,
    required this.resources,
    this.showOverflow = false,
    this.semanticLabel = 'Template preview',
  });

  final DocumentScene scene;
  final SceneResources resources;

  /// Show artwork beyond the page edge, as the editor does.
  final bool showOverflow;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    image: true,
    child: AspectRatio(
      aspectRatio: scene.widthPx / scene.heightPx,
      child: CustomPaint(
        painter: _ScenePainter(scene, resources, showOverflow: showOverflow),
      ),
    ),
  );
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.scene, this.resources, {required this.showOverflow});

  final DocumentScene scene;
  final SceneResources resources;
  final bool showOverflow;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / scene.widthPx,
      size.height / scene.heightPx,
    );
    paintScene(
      canvas,
      scene,
      resources,
      origin: Offset(
        (size.width - scene.widthPx * scale) / 2,
        (size.height - scene.heightPx * scale) / 2,
      ),
      scale: scale,
      clipToPage: !showOverflow,
    );
  }

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.scene != scene ||
      old.resources != resources ||
      old.showOverflow != showOverflow;
}
