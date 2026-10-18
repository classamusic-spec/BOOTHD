/// Problems found while reading or validating a template document (A-06,
/// A-14 `TEMPLATE_*` codes).
library;

enum IssueSeverity { error, warning }

enum DocumentIssueCode {
  // Reading.
  notAnObject('TEMPLATE_NOT_A_DOCUMENT'),
  unsupportedVersion('TEMPLATE_UNSUPPORTED_VERSION'),
  newerVersion('TEMPLATE_NEWER_VERSION'),
  unknownField('TEMPLATE_UNKNOWN_FIELD'),
  missingField('TEMPLATE_MISSING_FIELD'),
  wrongType('TEMPLATE_WRONG_TYPE'),
  invalidValue('TEMPLATE_INVALID_VALUE'),
  unknownLayerType('TEMPLATE_UNKNOWN_LAYER_TYPE'),
  tooLarge('TEMPLATE_TOO_LARGE'),

  // Meaning.
  invalidPage('TEMPLATE_INVALID_PAGE'),
  invalidLayerId('TEMPLATE_INVALID_LAYER_ID'),
  duplicateLayerId('TEMPLATE_DUPLICATE_LAYER_ID'),
  tooManyLayers('TEMPLATE_TOO_MANY_LAYERS'),
  invalidGeometry('TEMPLATE_INVALID_GEOMETRY'),
  multipleBackgrounds('TEMPLATE_MULTIPLE_BACKGROUNDS'),
  backgroundNotLowest('TEMPLATE_BACKGROUND_NOT_LOWEST'),
  invalidSlotIndex('TEMPLATE_INVALID_SLOT_INDEX'),
  duplicateSlotIndex('TEMPLATE_DUPLICATE_SLOT_INDEX'),
  slotsNotContiguous('TEMPLATE_SLOTS_NOT_CONTIGUOUS'),
  invalidAsset('TEMPLATE_INVALID_ASSET'),
  missingAsset('TEMPLATE_MISSING_ASSET'),
  wrongAssetKind('TEMPLATE_WRONG_ASSET_KIND'),
  unsupportedFontWeight('TEMPLATE_UNSUPPORTED_FONT_WEIGHT'),
  borderWithMask('TEMPLATE_BORDER_WITH_MASK'),

  // Warnings: renderable, but probably not what the designer meant.
  offPage('TEMPLATE_LAYER_OFF_PAGE'),
  emptyText('TEMPLATE_EMPTY_TEXT'),
  invisibleShape('TEMPLATE_INVISIBLE_SHAPE'),
  unusedAsset('TEMPLATE_UNUSED_ASSET');

  const DocumentIssueCode(this.diagnostic);

  /// The diagnostic code shown to operators and in logs.
  final String diagnostic;
}

final class DocumentIssue {
  const DocumentIssue(
    this.code,
    this.path,
    this.message, {
    this.severity = IssueSeverity.error,
  });

  const DocumentIssue.warning(this.code, this.path, this.message)
    : severity = IssueSeverity.warning;

  final DocumentIssueCode code;

  /// Where in the document, e.g. `layers[2].frame.w`; empty for the whole
  /// document.
  final String path;

  /// Operator-facing explanation. Never contains file paths or user data
  /// beyond the document's own field names.
  final String message;
  final IssueSeverity severity;

  bool get isError => severity == IssueSeverity.error;

  @override
  bool operator ==(Object other) =>
      other is DocumentIssue &&
      other.code == code &&
      other.path == path &&
      other.message == message &&
      other.severity == severity;

  @override
  int get hashCode => Object.hash(code, path, message, severity);

  @override
  String toString() =>
      '${code.diagnostic}${path.isEmpty ? '' : ' at $path'}: $message';
}

/// A document could not be read, or is not valid enough to use.
final class TemplateDocumentException implements Exception {
  const TemplateDocumentException(this.issues);

  final List<DocumentIssue> issues;

  @override
  String toString() =>
      'TemplateDocumentException(${issues.map((i) => '$i').join('; ')})';
}
