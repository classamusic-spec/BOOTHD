import 'dart:typed_data';

import '../../core/composition/scene_images.dart';
import '../../domain/models/booth_event.dart';
import '../../domain/models/template_revision_summary.dart';
import '../../domain/repositories/template_store.dart';
import '../../domain/services/booth_capabilities.dart';
import '../../domain/services/composition_renderer.dart';
import '../../domain/services/managed_storage.dart';
import '../../domain/template/geometry.dart';
import '../../domain/template/page_spec.dart';
import '../../domain/template/template_assets.dart';
import '../../domain/template/template_document.dart';
import '../../domain/template/template_layers.dart';
import '../codecs/jpeg_encoder.dart';
import '../templates/store_render_source.dart';

/// The launch checks this build can actually make. Storage writes, the
/// renderer and template assets are tested for real (M03, M04); everything
/// else names the milestone that adds the check and is never reported as
/// ready.
final class DeviceCapabilityProbe implements BoothCapabilityProbe {
  DeviceCapabilityProbe(
    this._storage, {
    required this._renderer,
    required this._templates,
    required this._assets,
  });

  final ManagedStorage _storage;
  final CompositionRenderer _renderer;
  final TemplateRepository _templates;
  final AssetRepository _assets;

  @override
  Future<CapabilityStatus> camera(CaptureSettings capture) async =>
      const CapabilityNotYetAvailable('M06');

  @override
  Future<CapabilityStatus> storageWrite() => _storage.probeWrite();

  @override
  Future<CapabilityStatus> freeSpace() async =>
      const CapabilityNotYetAvailable('M06');

  /// Renders every template at full print size in the event's format, with
  /// a stand-in photo in each slot, and checks the file decodes at the page
  /// size. Nothing is saved. With no templates, a plain page is rendered so
  /// the encoder is still exercised.
  @override
  Future<CapabilityStatus> renderer(
    OutputProfile output,
    List<TemplateRevisionSummary> templates,
  ) async {
    final documents = <TemplateDocument>[];
    try {
      for (final template in templates) {
        documents.add(
          (await _templates.loadRevision(template.revisionId)).document,
        );
      }
    } on TemplateStoreException catch (error) {
      return CapabilityProblem(error.code.diagnostic);
    }
    if (documents.isEmpty) documents.add(_plainPage);

    final source = StoreRenderSource(
      assets: _assets,
      photos: (_) async => _standInPhoto,
    );
    for (final document in documents) {
      try {
        final artifact = await _renderer.renderExport(
          TemplateRender(
            document: document,
            photos: {
              for (final slot in document.photoSlots)
                slot.slotIndex: const SlotPhoto(_standInId),
            },
            source: source,
          ),
          output: output,
        );
        final decoded = await probeImageSize(artifact.bytes);
        if (decoded !=
            PixelSize(document.page.widthPx, document.page.heightPx)) {
          return const CapabilityProblem('RENDER_WRONG_SIZE');
        }
      } on RenderFailure catch (failure) {
        return CapabilityProblem(failure.code.diagnostic);
      } on ImageDecodeException {
        return const CapabilityProblem('RENDER_UNREADABLE_OUTPUT');
      }
    }
    return const CapabilityReady();
  }

  /// Every template's manifest matches its checksum and every asset it
  /// lists is present, matches its content id and (images) still decodes
  /// to the size the template was made with.
  @override
  Future<CapabilityStatus> templateAssets(
    List<TemplateRevisionSummary> templates,
  ) async {
    try {
      for (final template in templates) {
        final revision = await _templates.loadRevision(template.revisionId);
        for (final MapEntry(key: id, value: asset)
            in revision.document.assets.entries) {
          final bytes = await _assets.read(id);
          if (asset.kind == AssetKind.image &&
              await probeImageSize(bytes) !=
                  PixelSize(asset.widthPx!, asset.heightPx!)) {
            return const CapabilityProblem('TEMPLATE_ASSET_MISMATCH');
          }
        }
      }
    } on TemplateStoreException catch (error) {
      return CapabilityProblem(error.code.diagnostic);
    } on ImageDecodeException {
      return const CapabilityProblem('TEMPLATE_ASSET_DAMAGED');
    }
    return const CapabilityReady();
  }

  @override
  Future<CapabilityStatus> kioskLock() async =>
      const CapabilityNotYetAvailable('M10');

  static const _standInId = 'launch-check';

  /// A mid-grey 4:3 photo, made once.
  static final Uint8List _standInPhoto = () {
    const width = 640;
    const height = 480;
    final rgba = Uint8List(width * height * 4);
    for (var i = 0; i < rgba.length; i += 4) {
      rgba
        ..[i] = 128
        ..[i + 1] = 128
        ..[i + 2] = 128
        ..[i + 3] = 255;
    }
    return encodeJpeg(rgba, width: width, height: height);
  }();

  /// A 4x6 page with one slot, for a booth with no templates yet.
  static final _plainPage = TemplateDocument(
    page: PageSpec.fourBySixPortrait,
    layers: [
      const BackgroundLayer(
        id: 'background',
        zIndex: 0,
        fill: SolidFill(ArgbColor(0xFFFFFFFF)),
      ),
      PhotoSlotLayer(
        id: 'slot',
        zIndex: 1,
        slotIndex: 0,
        frame: const NormalizedRect(x: 0.1, y: 0.1, width: 0.8, height: 0.6),
      ),
    ],
  );
}
