import 'package:drift/drift.dart';

import '../../domain/models/template_revision_summary.dart';
import '../../domain/repositories/template_catalog.dart';
import 'booth_database.dart';

/// Template revision summaries from the booth database. Nothing in M03
/// writes templates, so in a real booth this is empty until the template
/// library arrives (M04, M05).
final class DriftTemplateCatalog implements TemplateCatalog {
  DriftTemplateCatalog(this._db);

  final BoothDatabase _db;

  JoinedSelectStatement<HasResultSet, dynamic> _summaries() =>
      _db.select(_db.templateRevisions).join([
        innerJoin(
          _db.templates,
          _db.templates.id.equalsExp(_db.templateRevisions.templateId),
        ),
      ]);

  @override
  Stream<List<TemplateRevisionSummary>> watchSelectable() {
    final newer = _db.alias(_db.templateRevisions, 'newer');
    final latest = notExistsQuery(
      _db.select(newer)..where(
        (row) =>
            row.templateId.equalsExp(_db.templateRevisions.templateId) &
            row.revisionNumber.isBiggerThan(
              _db.templateRevisions.revisionNumber,
            ),
      ),
    );
    final query = _summaries()
      ..where(_db.templates.archivedAt.isNull() & latest)
      ..orderBy([
        OrderingTerm.asc(_db.templates.displayName.collate(Collate.noCase)),
        OrderingTerm.asc(_db.templates.id),
      ]);
    return query.watch().map(
      (rows) => [for (final row in rows) _toDomain(row)],
    );
  }

  @override
  Future<Map<String, TemplateRevisionSummary>> findRevisions(
    Iterable<String> revisionIds,
  ) async {
    final ids = revisionIds.toSet();
    if (ids.isEmpty) return const {};
    final rows = await (_summaries()..where(_db.templateRevisions.id.isIn(ids)))
        .get();
    return {
      for (final row in rows)
        row.readTable(_db.templateRevisions).id: _toDomain(row),
    };
  }

  TemplateRevisionSummary _toDomain(TypedResult row) {
    final revision = row.readTable(_db.templateRevisions);
    final template = row.readTable(_db.templates);
    return TemplateRevisionSummary(
      revisionId: revision.id,
      templateId: template.id,
      templateName: template.displayName,
      revisionNumber: revision.revisionNumber,
      pageWidthPx: revision.pageWidthPx,
      pageHeightPx: revision.pageHeightPx,
      photoSlotCount: revision.photoSlotCount,
      templateArchived: template.archivedAt != null,
    );
  }
}
