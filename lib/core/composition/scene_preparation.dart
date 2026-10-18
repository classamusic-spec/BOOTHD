/// Compiling and loading a render, shared by the export renderer and every
/// on-screen preview, so both draw the same scene from the same inputs
/// (A-07 steps 1-2, AC-0407).
library;

import 'dart:typed_data';

import '../../domain/services/composition_renderer.dart';
import '../../domain/template/document_scene.dart';
import '../../domain/template/geometry.dart';
import 'scene_images.dart';
import 'scene_loader.dart';
import 'scene_painter.dart';
import 'template_fonts.dart';

/// A template compiled against the photos chosen for its slots.
final class CompiledRender {
  const CompiledRender._(this.render, this.scene, this._photoBytes);

  final TemplateRender render;
  final DocumentScene scene;

  /// Each slot photo's bytes, read once to measure it and kept for loading.
  final Map<String, Uint8List> _photoBytes;
}

/// Validates [render]'s document, reads and measures each slot's photo as
/// it will decode, and compiles the scene. Throws [RenderFailure], as the
/// [RenderSource] does for a missing file.
Future<CompiledRender> compileRender(TemplateRender render) async {
  final document = render.document;
  final errors = document.errors;
  if (errors.isNotEmpty) {
    throw RenderFailure(
      RenderFailureCode.invalidDocument,
      detail: errors.map((e) => e.code.diagnostic).join(', '),
    );
  }
  final photoBytes = <String, Uint8List>{};
  final bindings = <int, SlotBinding>{};
  for (final slot in document.photoSlots) {
    final photo = render.photos[slot.slotIndex];
    if (photo == null) {
      throw RenderFailure(
        RenderFailureCode.missingPhoto,
        detail: 'photo ${slot.slotIndex + 1}',
      );
    }
    final bytes = photoBytes[photo.photoId] ??= await render.source.readPhoto(
      photo.photoId,
    );
    final PixelSize size;
    try {
      size = await probeImageSize(bytes);
    } on ImageDecodeException {
      throw RenderFailure(
        RenderFailureCode.unreadableImage,
        detail: 'photo ${slot.slotIndex + 1}',
      );
    }
    bindings[slot.slotIndex] = SlotBinding(
      photoId: photo.photoId,
      size: size,
      mirrored: photo.mirrored,
    );
  }
  try {
    return CompiledRender._(
      render,
      compileScene(document, bindings: bindings),
      photoBytes,
    );
  } on SceneCompileException catch (error) {
    throw RenderFailure(
      RenderFailureCode.invalidDocument,
      detail: error.issues.map((i) => i.code.diagnostic).join(', '),
    );
  }
}

/// Decodes and resolves everything [compiled] draws, for output at [scale]
/// page pixels per pixel (1 for exports). Throws [RenderFailure]; the
/// caller disposes the result.
Future<SceneResources> loadRenderResources(
  CompiledRender compiled, {
  required TemplateFontLoader fonts,
  double scale = 1,
}) async {
  final source = compiled.render.source;
  try {
    return await loadSceneResources(
      compiled.scene,
      readImage: (image) => switch (image) {
        AssetImageRef(:final assetId) => source.readAsset(assetId),
        PhotoImageRef(:final photoId) =>
          compiled._photoBytes[photoId] != null
              ? Future.value(compiled._photoBytes[photoId])
              : source.readPhoto(photoId),
      },
      readFont: source.readAsset,
      fonts: fonts,
      outputScale: scale,
    );
  } on ImageMismatchException catch (error) {
    throw RenderFailure(
      RenderFailureCode.imageMismatch,
      detail:
          '${error.source}: expected ${error.expected}, '
          'decoded ${error.actual}',
    );
  } on SceneImageException catch (error) {
    throw RenderFailure(
      RenderFailureCode.unreadableImage,
      detail: '${error.source}: ${error.reason}',
    );
  }
}
