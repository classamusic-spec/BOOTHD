/// Files the operator moves in and out of the booth (S08, S12): choosing a
/// file with the platform's document picker, and handing a file to the
/// platform's share sheet. Studio only; guest screens never reach either
/// (UX-04).
library;

import 'dart:typed_data';

/// What the operator is choosing a file for.
enum PickableFile {
  /// PNG or JPEG artwork for a template.
  image,

  /// A `.porcelain-template` package.
  templatePackage,
}

/// A chosen file, already read into memory. Nothing refers back to the
/// picker's temporary copy, which the platform may delete at any time
/// (AC-0508): callers store the bytes in managed storage.
final class PickedFile {
  const PickedFile({required this.name, required this.bytes});

  /// The file's name as the picker reported it, for display only.
  final String name;
  final Uint8List bytes;
}

enum FilePickFailure {
  /// Larger than the caller's limit; it was not read.
  tooLarge,

  /// The platform returned a file that could not be read.
  unreadable,
}

/// A chosen file could not be used. Nothing was stored.
final class FilePickException implements Exception {
  const FilePickException(this.failure, {this.limitBytes});

  final FilePickFailure failure;

  /// The limit a [FilePickFailure.tooLarge] file exceeded.
  final int? limitBytes;

  @override
  String toString() => 'FilePickException(${failure.name})';
}

/// Where on screen, in logical pixels, the share sheet points from (iPad
/// shows it as a popover anchored there).
typedef ShareAnchor = ({double left, double top, double width, double height});

enum ShareOutcome {
  /// The operator chose a destination (it may still be in progress there).
  shared,

  /// The operator closed the sheet.
  dismissed,

  /// The platform does not report what the operator did.
  unknown,
}

/// What the share sheet reported, as the platform gave it.
final class ShareReport {
  const ShareReport(this.outcome, {this.destination});

  final ShareOutcome outcome;

  /// The destination the operator chose, as the platform names it (an
  /// iPadOS activity type such as `com.apple.UIKit.activity.AirDrop`, or
  /// an Android app component). Null when the platform does not say.
  final String? destination;
}

abstract interface class OperatorFiles {
  /// Lets the operator choose one file for [kind]; null when they cancel.
  /// Throws [FilePickException] for a file over [maxBytes] (checked before
  /// reading it) or one that cannot be read.
  Future<PickedFile?> pick(PickableFile kind, {required int maxBytes});

  /// Offers [bytes] to the platform share sheet as [fileName].
  Future<ShareOutcome> share(
    Uint8List bytes, {
    required String fileName,
    required String mimeType,
    required ShareAnchor anchor,
  });
}
