import 'dart:typed_data';

import '../../../domain/services/composition_renderer.dart';

/// A [RenderSource] over bytes held in memory: fixtures and tests.
final class MemoryRenderSource implements RenderSource {
  const MemoryRenderSource({this.assets = const {}, this.photos = const {}});

  final Map<String, Uint8List> assets;
  final Map<String, Uint8List> photos;

  @override
  Future<Uint8List> readAsset(String assetId) async =>
      assets[assetId] ??
      (throw RenderFailure(RenderFailureCode.missingAsset, detail: assetId));

  @override
  Future<Uint8List> readPhoto(String photoId) async =>
      photos[photoId] ??
      (throw RenderFailure(RenderFailureCode.missingPhoto, detail: photoId));
}
