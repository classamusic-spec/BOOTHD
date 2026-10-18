import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

import '../../core/composition/scene_images.dart';
import '../../domain/models/booth_event.dart';
import '../../domain/services/composition_renderer.dart';
import '../../domain/services/export_service.dart';
import '../../domain/value_objects/entity_id.dart';
import 'atomic_file_writer.dart';
import 'managed_storage.dart';

/// Saves renders under managed storage's `outputs/` (A-07 step 7, A-11).
///
/// Each export renders from the original inputs, then writes a new file
/// named by a fresh id through [AtomicFileWriter]: staged, flushed, read
/// back, decoded and checked against the page size, then renamed into
/// place. Originals are only ever read, and earlier outputs are never
/// replaced. Recording the output against its session (A-05
/// RenderedOutput) follows in M06, once sessions exist.
final class FileExportService implements ExportService {
  FileExportService({
    required this.renderer,
    required this.storage,
    required this.ids,
    this.operations = const FileOperations(),
  });

  final CompositionRenderer renderer;
  final FileManagedStorage storage;
  final IdGenerator ids;
  final FileOperations operations;

  @override
  Future<ExportedFile> export(
    TemplateRender render, {
    OutputProfile output = const OutputProfile(),
    int flattenArgb = 0xFFFFFFFF,
  }) async {
    final artifact = await renderer.renderExport(
      render,
      output: output,
      flattenArgb: flattenArgb,
    );
    final id = ids.newId();
    final extension = switch (output.format) {
      OutputFormat.jpeg => 'jpg',
      OutputFormat.png => 'png',
    };
    final area = ManagedArea.outputs.directoryName;
    final destination = File(
      '${(await storage.directory(ManagedArea.outputs)).path}/$id.$extension',
    );
    final writer = AtomicFileWriter(
      staging: await storage.directory(ManagedArea.staging),
      operations: operations,
    );
    try {
      await writer.write(
        destination,
        artifact.bytes,
        stagedPrefix: 'export-',
        verify: (onDisk) async {
          final size = await probeImageSize(onDisk);
          if (size.width != artifact.widthPx ||
              size.height != artifact.heightPx) {
            throw const FormatException('wrong size');
          }
          // Decode it all (small, to bound memory): a damaged file fails.
          (await decodeImage(onDisk, scale: 64 / artifact.widthPx)).dispose();
        },
      );
    } on AtomicWriteException catch (error) {
      throw ExportFailure(
        switch (error.reason) {
          AtomicWriteFailure.noSpace => ExportFailureCode.noSpace,
          AtomicWriteFailure.writeFailed => ExportFailureCode.writeFailed,
          AtomicWriteFailure.verifyFailed => ExportFailureCode.verifyFailed,
          AtomicWriteFailure.destinationExists ||
          AtomicWriteFailure.commitFailed => ExportFailureCode.commitFailed,
        },
        detail: error.osErrorCode == null ? null : 'errno ${error.osErrorCode}',
      );
    }
    return ExportedFile(
      id: id,
      relativePath: '$area/$id.$extension',
      sha256: crypto.sha256.convert(artifact.bytes).toString(),
      byteLength: artifact.bytes.length,
      widthPx: artifact.widthPx,
      heightPx: artifact.heightPx,
      format: output.format,
      renderVersion: rendererVersion,
      warnings: artifact.warnings,
      stats: artifact.stats,
    );
  }

  static final _outputPath = RegExp(
    r'^outputs/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
    r'\.(jpg|png)$',
  );

  /// The bytes of [file], checked against its recorded checksum.
  Future<Uint8List> read(ExportedFile file) async {
    if (!_outputPath.hasMatch(file.relativePath)) {
      throw const ExportFailure(ExportFailureCode.verifyFailed);
    }
    final outputs = await storage.directory(ManagedArea.outputs);
    final bytes = await File(
      '${outputs.path}/${file.relativePath.substring('outputs/'.length)}',
    ).readAsBytes();
    if (crypto.sha256.convert(bytes).toString() != file.sha256) {
      throw const ExportFailure(ExportFailureCode.verifyFailed);
    }
    return bytes;
  }
}
