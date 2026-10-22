import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../../domain/repositories/template_store.dart';
import '../../domain/services/composition_renderer.dart';
import '../../domain/session/session_shots.dart';
import '../../domain/template/document_scene.dart';
import '../../domain/template/template_document.dart';
import '../../domain/template/template_layers.dart';
import '../composition/scene_painter.dart';
import '../composition/scene_preparation.dart';
import '../composition/store_render_source.dart';
import '../composition/template_fonts.dart';
import '../templates/slot_placeholder.dart';

/// The template around the live camera (EP06, Full Template mode): the
/// session's template compiled by the export's own scene compiler, with
/// the photos already taken in their slots and the placeholder in the
/// others. The live picture takes the active slot's place: layers below
/// it are painted first, the picture clipped to the slot's shape, then
/// the layers above it, so artwork overlaps the live picture exactly as
/// it will overlap the photo in the print.
///
/// Guest display only; nothing here reaches an export. A slot with an
/// image mask is not attempted live (its cost on tablets is unproven):
/// [load] returns null and the booth shows the camera-focused stage.
final class LiveTemplate {
  LiveTemplate._(this.scene, this.resources, this.activeNode, this.clip);

  final DocumentScene scene;
  final SceneResources resources;

  /// Index in [scene]'s nodes of the active slot's photo.
  final int activeNode;
  final SceneClip clip;

  PhotoNode get _photo => scene.nodes[activeNode] as PhotoNode;

  /// The active slot, in page pixels.
  Rect get slot {
    final rect = _photo.placement.rect;
    return Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height);
  }

  static final _fonts = TemplateFontLoader();

  /// The template of [shots]' plan, ready to show shot [shot] live, or
  /// null when that slot cannot be shown live. Throws [RenderFailure]
  /// when the template cannot be read (the booth then falls back too).
  static Future<LiveTemplate?> load({
    required TemplateDocument document,
    required SessionShots shots,
    required int shot,
    required AssetRepository assets,
    required Future<Uint8List> Function(String originalId) readOriginal,
    double scale = 0.5,
  }) async {
    final plan = shots.plan;
    final slotIndex = plan.slotFor(shot);
    final layer = document.photoSlots
        .where((slot) => slot.slotIndex == slotIndex)
        .firstOrNull;
    if (layer == null || layer.clip is MaskClip) return null;
    final taken = shots.takenBindings;
    final render = TemplateRender(
      document: document,
      photos: {
        for (final slot in document.photoSlots)
          slot.slotIndex: switch (taken[slot.slotIndex]) {
            final originalId? when slot.slotIndex != slotIndex => SlotPhoto(
              originalId,
              mirrored: plan.capture.mirrorOutput,
            ),
            _ => const SlotPhoto(slotPlaceholderPhotoId),
          },
      },
      source: StoreRenderSource(
        assets: assets,
        photos: (id) => id == slotPlaceholderPhotoId
            ? slotPlaceholderPng()
            : readOriginal(id),
      ),
    );
    final compiled = await compileRender(render);
    final resources = await loadRenderResources(
      compiled,
      fonts: _fonts,
      scale: scale,
    );
    final index = compiled.scene.nodes.indexWhere(
      (node) => node is PhotoNode && node.layerId == layer.id,
    );
    if (index < 0) {
      resources.dispose();
      return null;
    }
    return LiveTemplate._(
      compiled.scene,
      resources,
      index,
      (compiled.scene.nodes[index] as PhotoNode).clip,
    );
  }

  void dispose() => resources.dispose();
}

/// Shows [template] with [preview] (the live camera, already mirrored as
/// the event asks) in its active slot, filling the slot as a photo would.
class LiveTemplateStage extends StatelessWidget {
  const LiveTemplateStage({
    super.key,
    required this.template,
    required this.preview,
    required this.previewAspect,
  });

  final LiveTemplate template;
  final Widget preview;

  /// Width over height of the live picture.
  final double previewAspect;

  @override
  Widget build(BuildContext context) {
    final scene = template.scene;
    return AspectRatio(
      aspectRatio: scene.widthPx / scene.heightPx,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / scene.widthPx;
          final slot = template.slot;
          final rect = Rect.fromLTWH(
            slot.left * scale,
            slot.top * scale,
            slot.width * scale,
            slot.height * scale,
          );
          return ClipRect(
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _LayersPainter(template, below: true),
                  ),
                ),
                Positioned.fromRect(
                  rect: rect,
                  child: _clip(
                    template.clip,
                    rect.size,
                    scale,
                    FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        width: previewAspect * 1000,
                        height: 1000,
                        child: preview,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _LayersPainter(template, below: false),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _clip(SceneClip clip, Size size, double scale, Widget child) =>
      switch (clip) {
        SceneRoundedRectClip(:final radiusPx) => ClipRRect(
          borderRadius: BorderRadius.circular(radiusPx * scale),
          child: child,
        ),
        SceneEllipseClip() => ClipOval(child: child),
        _ => ClipRect(child: child),
      };
}

class _LayersPainter extends CustomPainter {
  _LayersPainter(this.template, {required this.below});

  final LiveTemplate template;
  final bool below;

  @override
  void paint(Canvas canvas, Size size) {
    final scene = template.scene;
    paintScene(
      canvas,
      scene,
      template.resources,
      scale: size.width / scene.widthPx,
      include: (index, _) =>
          below ? index < template.activeNode : index > template.activeNode,
    );
  }

  @override
  bool shouldRepaint(_LayersPainter old) =>
      old.template != template || old.below != below;
}
