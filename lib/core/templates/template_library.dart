/// The template library's operations (S06, S07, S08, S12) over the
/// template store: new templates from a starter design, duplicates,
/// renames, archiving, packages, images and the editor's saves and drafts.
library;

import 'dart:typed_data';

import '../../domain/models/template_revision_summary.dart';
import '../../domain/repositories/template_store.dart';
import '../../domain/template/asset_formats.dart';
import '../../domain/template/template_assets.dart';
import '../../domain/template/template_document.dart';
import '../../domain/value_objects/clock.dart';
import 'bundled_decorations.dart';
import 'starter_designs.dart';

/// File name extension of template packages (A-06).
const templatePackageExtension = 'porcelain-template';

/// Media type packages are shared as: a ZIP archive.
const templatePackageMimeType = 'application/zip';

/// The longest template name the library accepts.
const maxTemplateNameLength = 80;

/// A package ready to hand to the share sheet.
typedef ExportedPackage = ({Uint8List bytes, String fileName});

/// A template opened for editing: its newest revision and any unsaved
/// work found for it.
typedef OpenedTemplate = ({
  StoredTemplateRevision revision,
  TemplateDraft? draft,
});

final class TemplateLibrary {
  TemplateLibrary({
    required this.assets,
    required this.templates,
    required this.packages,
    required this.drafts,
    required this.clock,
    required this.loadBundled,
  });

  final AssetRepository assets;
  final TemplateRepository templates;
  final TemplatePackages packages;
  final TemplateDraftRepository drafts;
  final Clock clock;

  /// Reads one of the app's bundled files (rootBundle in the app).
  final Future<Uint8List> Function(String assetPath) loadBundled;

  Stream<List<TemplateListing>> watch() => templates.watchLibrary();

  /// Stores [design]'s decorations, then the design as revision 1 of a new
  /// template called [name]. Throws [TemplateStoreException].
  Future<TemplateRevisionSummary> create(
    StarterDesign design, {
    required String name,
  }) async {
    final decorations = {
      for (final id in design.decorations)
        id: await storeDecoration(bundledDecoration(id)),
    };
    return templates.createTemplate(
      name: _checkedName(name),
      category: design.category,
      document: design.build(decorations),
      tags: design.tags,
    );
  }

  /// A new template with [revisionId]'s document, called [name].
  Future<TemplateRevisionSummary> duplicate(
    String revisionId, {
    required String name,
  }) async {
    final source = await templates.loadRevision(revisionId);
    return templates.createTemplate(
      name: _checkedName(name),
      category: source.category,
      document: source.document,
      tags: source.summary.tags,
    );
  }

  Future<void> rename(String templateId, String name) async =>
      templates.rename(templateId, _checkedName(name));

  Future<void> setArchived(String templateId, {required bool archived}) =>
      templates.setArchived(templateId, archived: archived);

  Future<TemplateRevisionSummary> importPackage(Uint8List package) =>
      packages.importPackage(package);

  /// [revision] as a package, named after its template.
  Future<ExportedPackage> exportPackage(
    TemplateRevisionSummary revision,
  ) async => (
    bytes: await packages.exportPackage(revision.revisionId),
    fileName: packageFileName(revision),
  );

  /// Stores an image the operator chose (S08). Only PNG and JPEG files
  /// are images; everything else is refused by its content, whatever its
  /// name says. Throws [TemplateStoreException].
  Future<StoredAsset> importImage(Uint8List bytes, {String? name}) async {
    final sniffed = sniffAsset(bytes).asset;
    if (sniffed != null && sniffed.mediaType.kind != AssetKind.image) {
      throw const TemplateStoreException(
        TemplateStoreErrorCode.assetUnknownFormat,
        detail: 'not an image',
      );
    }
    return assets.store(bytes, name: name, origin: AssetOrigin.imported);
  }

  /// Stores one of the app's decorations; storing it again returns the
  /// stored asset.
  Future<StoredAsset> storeDecoration(BundledDecoration decoration) async =>
      assets.store(
        await loadBundled(decoration.assetPath),
        name: '${decoration.name}.png',
        origin: AssetOrigin.bundled,
      );

  /// The newest revision of [templateId] and its draft, if any. A draft
  /// that only repeats the newest revision is discarded unseen.
  Future<OpenedTemplate> open(String templateId) async {
    final revision = await templates.loadLatest(templateId);
    var draft = await drafts.load(templateId);
    if (draft != null && draft.document == revision.document) {
      await drafts.discard(templateId);
      draft = null;
    }
    return (revision: revision, draft: draft);
  }

  /// Stores [document] as the next revision of [templateId] and clears
  /// its draft. Earlier revisions, and events using them, are unchanged.
  Future<StoredTemplateRevision> save(
    String templateId,
    TemplateDocument document,
  ) async {
    final summary = await templates.addRevision(templateId, document);
    await drafts.discard(templateId);
    return templates.loadRevision(summary.revisionId);
  }

  /// Keeps unsaved work for [templateId] (autosave, A-08).
  Future<void> saveDraft(
    String templateId, {
    required String baseRevisionId,
    required TemplateDocument document,
  }) => drafts.save(
    TemplateDraft(
      templateId: templateId,
      baseRevisionId: baseRevisionId,
      document: document,
      savedAt: clock.now(),
    ),
  );

  Future<void> discardDraft(String templateId) => drafts.discard(templateId);

  /// `<name>-r<revision>.porcelain-template`, with the name reduced to
  /// letters, digits and dashes.
  static String packageFileName(TemplateRevisionSummary revision) {
    final base = revision.templateName
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final name = base.isEmpty
        ? 'template'
        : base.substring(0, base.length.clamp(0, 60));
    return '$name-r${revision.revisionNumber}.$templatePackageExtension';
  }

  /// A name for a copy of [name] that fits the length limit.
  static String copyName(String name) {
    const suffix = ' copy';
    final room = maxTemplateNameLength - suffix.length;
    final trimmed = name.trim();
    return '${trimmed.length > room ? trimmed.substring(0, room) : trimmed}'
        '$suffix';
  }

  static String _checkedName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > maxTemplateNameLength) {
      throw const TemplateStoreException(
        TemplateStoreErrorCode.invalidDocument,
        detail:
            'the template name must be 1 to $maxTemplateNameLength '
            'characters',
      );
    }
    return trimmed;
  }
}
