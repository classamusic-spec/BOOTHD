/// Upgrades template documents saved by older versions of the app (A-15,
/// ADR-0010).
///
/// Each step turns version N JSON into version N + 1 without losing
/// meaning; documents from newer apps are refused, never guessed at.
/// Version 1 is the first, so there are no steps yet. Adding version 2
/// means: a step here, a committed version 1 fixture that still reads
/// (`test_assets/templates/`), and an ADR note.
library;

import 'document_issues.dart';
import 'template_document.dart';

typedef MigrationStep = Map<String, Object?> Function(Map<String, Object?>);

abstract final class TemplateMigrations {
  /// Steps by the version they upgrade from.
  static final Map<int, MigrationStep> steps = {};

  /// [json] at [TemplateDocument.currentSchemaVersion].
  static Map<String, Object?> upgrade(Map<String, Object?> json) {
    final version = json['schemaVersion'];
    if (version is! int || version < 1) {
      throw const TemplateDocumentException([
        DocumentIssue(
          DocumentIssueCode.unsupportedVersion,
          'schemaVersion',
          'The document has no valid schema version.',
        ),
      ]);
    }
    if (version > TemplateDocument.currentSchemaVersion) {
      throw TemplateDocumentException([
        DocumentIssue(
          DocumentIssueCode.newerVersion,
          'schemaVersion',
          'This template was made by a newer version of Porcelain Photo '
              'Booth (document version $version). Update the app to open it.',
        ),
      ]);
    }
    var current = json;
    for (
      var from = version;
      from < TemplateDocument.currentSchemaVersion;
      from++
    ) {
      final step = steps[from];
      if (step == null) {
        throw TemplateDocumentException([
          DocumentIssue(
            DocumentIssueCode.unsupportedVersion,
            'schemaVersion',
            'Version $from documents can no longer be read.',
          ),
        ]);
      }
      current = step(current);
    }
    return current;
  }
}
