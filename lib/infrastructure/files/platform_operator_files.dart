import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:file_selector/file_selector.dart' as picker;
import 'package:share_plus/share_plus.dart';

import '../../domain/services/operator_files.dart';

/// [OperatorFiles] on the platform document picker (`file_selector`:
/// UIDocumentPickerViewController on iPadOS, ACTION_OPEN_DOCUMENT on
/// Android) and share sheet (`share_plus`), ADR-0011.
///
/// Both pickers hand back a temporary copy of the file; it is read at once
/// and never referred to again (AC-0508). Formats are filtered loosely
/// here and checked by content when stored: a picker's type filter is a
/// convenience, not validation.
final class PlatformOperatorFiles implements OperatorFiles {
  static const _images = picker.XTypeGroup(
    label: 'Images',
    extensions: ['png', 'jpg', 'jpeg'],
    mimeTypes: ['image/png', 'image/jpeg'],
    uniformTypeIdentifiers: ['public.png', 'public.jpeg'],
  );

  // Packages are ZIP files with their own extension, which neither
  // platform knows; accept archives and generic data.
  static const _packages = picker.XTypeGroup(
    label: 'Template packages',
    extensions: ['porcelain-template', 'zip'],
    mimeTypes: [
      'application/zip',
      'application/x-zip-compressed',
      'application/octet-stream',
    ],
    uniformTypeIdentifiers: ['public.zip-archive', 'public.data'],
  );

  @override
  Future<PickedFile?> pick(PickableFile kind, {required int maxBytes}) async {
    final file = await picker.openFile(
      acceptedTypeGroups: [
        switch (kind) {
          PickableFile.image => _images,
          PickableFile.templatePackage => _packages,
        },
      ],
    );
    if (file == null) return null;
    final Uint8List bytes;
    try {
      if (await file.length() > maxBytes) {
        throw FilePickException(FilePickFailure.tooLarge, limitBytes: maxBytes);
      }
      bytes = await file.readAsBytes();
    } on FilePickException {
      rethrow;
    } on Object {
      throw const FilePickException(FilePickFailure.unreadable);
    }
    // The size can change between the check and the read.
    if (bytes.length > maxBytes) {
      throw FilePickException(FilePickFailure.tooLarge, limitBytes: maxBytes);
    }
    return PickedFile(name: file.name, bytes: bytes);
  }

  @override
  Future<ShareOutcome> share(
    Uint8List bytes, {
    required String fileName,
    required String mimeType,
    required ShareAnchor anchor,
  }) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: mimeType, name: fileName)],
        fileNameOverrides: [fileName],
        sharePositionOrigin: Rect.fromLTWH(
          anchor.left,
          anchor.top,
          anchor.width,
          anchor.height,
        ),
      ),
    );
    return switch (result.status) {
      ShareResultStatus.success => ShareOutcome.shared,
      ShareResultStatus.dismissed => ShareOutcome.dismissed,
      ShareResultStatus.unavailable => ShareOutcome.unknown,
    };
  }
}
