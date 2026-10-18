import '../models/template_revision_summary.dart';

/// The template revisions events can reference (A-05, A-15). Read-only in
/// M03: revisions are created by the template model and library (M04, M05),
/// so until then the catalog is empty.
abstract interface class TemplateCatalog {
  /// The latest revision of every template that is not archived, by name;
  /// emits again on change.
  Stream<List<TemplateRevisionSummary>> watchSelectable();

  /// Summaries for [revisionIds], including revisions of archived templates
  /// and older revisions. IDs with no revision are absent from the result.
  Future<Map<String, TemplateRevisionSummary>> findRevisions(
    Iterable<String> revisionIds,
  );
}
