/// Template thumbnails for the library, the new-template chooser and the
/// event editor (S04, S06): drawn by the print renderer with the slot
/// placeholder in every photo space, never a schematic or a screenshot.
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/template_store.dart';
import '../../domain/services/composition_renderer.dart';
import '../../domain/template/asset_formats.dart';
import '../../domain/template/template_assets.dart';
import '../di/service_providers.dart';
import 'bundled_decorations.dart';
import 'slot_placeholder.dart';
import 'starter_designs.dart';

/// The longest side of a thumbnail, in pixels: sharp on a 2x screen at
/// card size, small enough to keep dozens in memory.
const thumbnailMaxSidePx = 540;

/// A rendered thumbnail of a stored revision (PNG bytes). Revisions never
/// change, so each is drawn once per session.
final templateThumbnailProvider = FutureProvider.family<Uint8List, String>((
  ref,
  revisionId,
) async {
  final revision = await ref
      .watch(templateRepositoryProvider)
      .loadRevision(revisionId);
  final artifact = await ref
      .watch(compositionRendererProvider)
      .renderPreview(
        placeholderRender(
          revision.document,
          ref.watch(assetRepositoryProvider),
        ),
        maxWidthPx: thumbnailMaxSidePx,
        maxHeightPx: thumbnailMaxSidePx,
      );
  return artifact.bytes;
});

/// A rendered thumbnail of a starter design, drawn from the bundled
/// decorations without storing anything.
final starterThumbnailProvider = FutureProvider.family<Uint8List, String>((
  ref,
  designId,
) async {
  final design = starterDesigns.firstWhere((d) => d.id == designId);
  final load = ref.watch(bundledAssetLoaderProvider);
  final bytesById = <String, Uint8List>{};
  final decorations = <String, StoredAsset>{};
  for (final id in design.decorations) {
    final bytes = await load(bundledDecoration(id).assetPath);
    final header = sniffAsset(bytes).asset!;
    final assetId = assetIdOf(bytes);
    bytesById[assetId] = bytes;
    decorations[id] = StoredAsset(
      id: assetId,
      asset: TemplateAsset(
        mediaType: header.mediaType,
        byteLength: bytes.length,
        widthPx: header.widthPx,
        heightPx: header.heightPx,
        name: '${bundledDecoration(id).name}.png',
      ),
      origin: AssetOrigin.bundled,
      createdAt: ref.watch(clockProvider).now(),
    );
  }
  final document = design.build(decorations);
  final artifact = await ref
      .watch(compositionRendererProvider)
      .renderPreview(
        TemplateRender(
          document: document,
          photos: {
            for (final slot in document.photoSlots)
              slot.slotIndex: const SlotPhoto(slotPlaceholderPhotoId),
          },
          source: _BundleSource(bytesById),
        ),
        maxWidthPx: thumbnailMaxSidePx,
        maxHeightPx: thumbnailMaxSidePx,
      );
  return artifact.bytes;
});

final class _BundleSource implements RenderSource {
  const _BundleSource(this.bytes);

  final Map<String, Uint8List> bytes;

  @override
  Future<Uint8List> readAsset(String assetId) async =>
      bytes[assetId] ??
      (throw RenderFailure(RenderFailureCode.missingAsset, detail: assetId));

  @override
  Future<Uint8List> readPhoto(String photoId) => slotPlaceholderPng();
}
