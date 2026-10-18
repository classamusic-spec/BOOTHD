import '../../domain/repositories/template_store.dart';
import '../../domain/template/document_issues.dart';
import '../../domain/template/template_json.dart';
import '../database/booth_database.dart';
import '../database/persistence_guard.dart';

/// Editor drafts in the booth database (A-08 autosave, AC-0507): one row
/// per template, written in a single statement, so a draft is either the
/// last one saved or the one before it.
final class DriftTemplateDraftRepository implements TemplateDraftRepository {
  DriftTemplateDraftRepository(this._db);

  final BoothDatabase _db;

  @override
  Future<TemplateDraft?> load(String templateId) async {
    final row = await (_db.select(
      _db.templateDrafts,
    )..where((d) => d.templateId.equals(templateId))).getSingleOrNull();
    if (row == null) return null;
    try {
      return TemplateDraft(
        templateId: row.templateId,
        baseRevisionId: row.baseRevisionId,
        document: TemplateJson.decode(row.document),
        savedAt: row.updatedAt,
      );
    } on TemplateDocumentException {
      // Written by this app, so only damage gets here: drop it rather than
      // offer something that cannot be opened.
      await discard(templateId);
      return null;
    }
  }

  @override
  Future<void> save(TemplateDraft draft) => guardPersistence(
    () => _db
        .into(_db.templateDrafts)
        .insertOnConflictUpdate(
          TemplateDraftsCompanion.insert(
            templateId: draft.templateId,
            baseRevisionId: draft.baseRevisionId,
            document: TemplateJson.encode(draft.document),
            updatedAt: draft.savedAt,
          ),
        ),
  );

  @override
  Future<void> discard(String templateId) => (_db.delete(
    _db.templateDrafts,
  )..where((d) => d.templateId.equals(templateId))).go();
}
