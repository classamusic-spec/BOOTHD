import 'dart:typed_data';

import 'package:file/file.dart';

import '../../domain/services/operator_files.dart';
import '../files/managed_gallery_exporter.dart';
import '../files/platform_operator_files.dart';
import 'web_platform.dart';

/// [OperatorFiles] in the browser (ADR-0018): files are chosen with the
/// browser's picker as on tablets; sharing uses the system share sheet
/// where the browser offers one, otherwise a download.
final class WebOperatorFiles implements OperatorFiles {
  WebOperatorFiles(this._files);

  /// Managed storage: [shareFile] paths are read from it.
  final FileSystem _files;
  final _picker = PlatformOperatorFiles();

  @override
  Future<PickedFile?> pick(PickableFile kind, {required int maxBytes}) =>
      _picker.pick(kind, maxBytes: maxBytes);

  @override
  Future<PickedStream?> pickStream(PickableFile kind) =>
      _picker.pickStream(kind);

  @override
  Future<ShareOutcome> share(
    Uint8List bytes, {
    required String fileName,
    required String mimeType,
    required ShareAnchor anchor,
  }) async => (await offerFilesInBrowser([
    (name: fileName, bytes: bytes, mimeType: mimeType),
  ])).outcome;

  @override
  Future<ShareReport> shareFile(
    String path, {
    required String mimeType,
    required ShareAnchor anchor,
  }) => browserShareSheet(_files)([(path: path, mimeType: mimeType)], anchor);
}

/// The gallery's share sheet in the browser: the prepared copies are read
/// from managed storage and offered together.
ShareFilesSheet browserShareSheet(FileSystem files) =>
    (paths, anchor) async => offerFilesInBrowser([
      for (final file in paths)
        (
          name: files.path.basename(file.path),
          bytes: await files.file(file.path).readAsBytes(),
          mimeType: file.mimeType,
        ),
    ]);
