import 'dart:typed_data';

import '../../domain/repositories/template_store.dart';
import '../../domain/services/composition_renderer.dart';

/// A [RenderSource] over managed storage: template assets from the asset
/// store, each checked against its content id; guest photos from [photos]
/// (session originals, M06).
final class StoreRenderSource implements RenderSource {
  StoreRenderSource({required this.assets, required this.photos});

  final AssetRepository assets;
  final Future<Uint8List> Function(String photoId) photos;

  @override
  Future<Uint8List> readAsset(String assetId) async {
    try {
      return await assets.read(assetId);
    } on TemplateStoreException catch (error) {
      // Missing, or no longer the file the template was made with.
      throw RenderFailure(
        RenderFailureCode.missingAsset,
        detail: '${error.code.diagnostic}: $assetId',
      );
    }
  }

  @override
  Future<Uint8List> readPhoto(String photoId) => photos(photoId);
}
