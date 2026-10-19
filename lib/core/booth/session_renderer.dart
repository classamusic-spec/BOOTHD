import 'dart:typed_data';

import '../../domain/repositories/template_store.dart';
import '../../domain/services/camera_service.dart';
import '../../domain/services/composition_renderer.dart';
import '../../domain/services/export_service.dart';
import '../../domain/services/finished_photos.dart';
import '../../domain/session/session_shots.dart';
import '../../domain/template/template_document.dart';
import '../composition/store_render_source.dart';

/// Makes a session's finished photo (A-07, AC-0705, AC-0804): the frozen
/// template revision rendered at full resolution from the unmodified
/// originals bound to its photo spaces, with the plan's output profile and
/// output mirroring, exported atomically as a new file and read back
/// against its checksum.
///
/// The booth uses it while the guest waits and the gallery to finish or
/// re-render a session, so both make the same file from the same records.
/// Recording the result is the caller's: the booth completes the session,
/// the gallery adds a re-render.
final class SessionRenderer {
  SessionRenderer({
    required this._export,
    required this._finished,
    required this._templates,
    required this._assets,
    required this._originals,
  });

  final ExportService _export;
  final FinishedPhotos _finished;
  final TemplateRepository _templates;
  final AssetRepository _assets;
  final CapturedStillStore _originals;

  /// Renders and saves [shots]' finished photo; [document] is the plan's
  /// template revision when the caller has it loaded. Returns the saved
  /// file and its bytes as read back. Throws [RenderFailure] or
  /// [ExportFailure] (a file that does not read back intact is
  /// [ExportFailureCode.verifyFailed]); nothing is recorded.
  Future<(ExportedFile, Uint8List)> render(
    SessionShots shots, {
    TemplateDocument? document,
  }) async {
    final plan = shots.plan;
    final template =
        document ??
        (await _templates.loadRevision(plan.templateRevisionId)).document;
    final exported = await _export.export(
      TemplateRender(
        document: template,
        photos: {
          for (final MapEntry(key: slot, value: originalId)
              in shots.slotBindings.entries)
            slot: SlotPhoto(originalId, mirrored: plan.capture.mirrorOutput),
        },
        source: StoreRenderSource(assets: _assets, photos: readOriginal),
      ),
      output: plan.output,
    );
    try {
      final bytes = await _finished.read(
        relativePath: exported.relativePath,
        sha256: exported.sha256,
      );
      return (exported, bytes);
    } on FinishedPhotoUnreadable {
      throw const ExportFailure(ExportFailureCode.verifyFailed);
    }
  }

  /// The original [originalId], read back and checked against its
  /// checksum; a missing or changed file is a
  /// [RenderFailureCode.missingPhoto].
  Future<Uint8List> readOriginal(String originalId) async {
    final still = await _originals.find(originalId);
    if (still == null) {
      throw RenderFailure(RenderFailureCode.missingPhoto, detail: originalId);
    }
    try {
      return await _originals.read(still);
    } on CameraFailure {
      throw RenderFailure(RenderFailureCode.missingPhoto, detail: originalId);
    }
  }
}
