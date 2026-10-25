// The template library on a tablet (S06, S08, S12; AC-0501, AC-0508,
// AC-0509): "Choose your style" makes a template and opens it; duplicate,
// rename, archive (after confirming) and restore; export hands the share
// sheet one package named after the template; import takes a package
// whole, or refuses a damaged, foreign or oversized file with nothing
// stored. In the studio, an image from the document picker is copied into
// the booth's own store, refused when it is not an image, and can be
// renamed, and removed only while nothing uses it.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/routing/route_paths.dart';
import 'package:porcelain_photo_booth/core/templates/starter_designs.dart';
import 'package:porcelain_photo_booth/core/templates/template_library.dart';
import 'package:porcelain_photo_booth/domain/models/template_revision_summary.dart';
import 'package:porcelain_photo_booth/domain/repositories/template_store.dart';
import 'package:porcelain_photo_booth/domain/services/operator_files.dart';
import 'package:porcelain_photo_booth/domain/template/editing/document_edits.dart';
import 'package:porcelain_photo_booth/domain/template/template_assets.dart';
import 'package:porcelain_photo_booth/domain/template/template_layers.dart';
import 'package:porcelain_photo_booth/features/template_library/library_actions.dart';
import 'package:porcelain_photo_booth/features/template_library/template_library_screen.dart';
import 'package:porcelain_photo_booth/features/template_studio/editor_canvas.dart';

import '../support/app_harness.dart';
import '../support/fakes.dart';
import '../support/memory_template_store.dart';
import '../support/tablet_viewports.dart';

TemplateLibrary _library(MemoryTemplateStore store) => TemplateLibrary(
  assets: store.assets,
  templates: store.templates,
  packages: store.packages,
  drafts: store.drafts,
  clock: store.clock,
  loadBundled: (path) async => File(path).readAsBytesSync(),
);

Future<TemplateRevisionSummary> _garden(MemoryTemplateStore store) =>
    _library(store).create(
      starterDesigns.firstWhere((d) => d.id == 'floral-elegance'),
      name: 'Garden party',
    );

Future<List<TemplateListing>> _listings(MemoryTemplateStore store) =>
    store.templates.watchLibrary().first;

/// Opens the More sheet of the card for [template] (the first card when
/// null) and picks [action].
Future<void> _more(
  WidgetTester tester,
  String action, {
  String? template,
}) async {
  final cards = template == null
      ? find.byType(TemplateCard)
      : find.ancestor(
          of: find.text(template),
          matching: find.byType(TemplateCard),
        );
  final more = find.descendant(of: cards.first, matching: find.text('More'));
  await tester.ensureVisible(more);
  await tester.pumpAndSettle();
  await tester.tap(more);
  await tester.pumpAndSettle();
  await tester.tap(find.text(action).last);
  await tester.pumpAndSettle();
}

/// A transparent PNG an artist might export: the app's confetti, which
/// Floral Elegance does not use.
Uint8List _transparentPng() =>
    File('assets/decorations/gold_confetti.png').readAsBytesSync();

void main() {
  for (final viewport in [
    TabletViewport.ipadLandscape,
    TabletViewport.androidPortrait,
  ]) {
    testWidgets('${viewport.name}: choose a style, name it, and the studio '
        'opens on it', (tester) async {
      useViewport(tester, viewport);
      final booth = await pumpApp(tester, location: RoutePaths.templates);
      await settleRendering(tester);
      expect(find.text('No templates yet'), findsOneWidget);

      await tester.tap(find.text('New template').first);
      await tester.pumpAndSettle();
      expect(find.text('Choose your style'), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('design-search')),
          matching: find.byType(TextField),
        ),
        'Retro Film',
      );
      await tester.pumpAndSettle();
      final retro = find.bySemanticsLabel(RegExp('^Retro Film,'));
      await tester.ensureVisible(retro);
      await tester.tap(retro);
      await tester.pumpAndSettle();
      // The name stays beside the gallery instead of below every design.
      final name = find.descendant(
        of: find.byKey(const ValueKey('new-template-name')),
        matching: find.byType(TextField),
      );
      expect(tester.widget<TextField>(name).controller!.text, 'Retro Film');
      await tester.enterText(name, 'Film night');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      final listings = await _listings(booth.templates);
      expect(listings, hasLength(1));
      final created = listings.single.latest;
      expect(created.templateName, 'Film night');
      expect(
        booth.router.routerDelegate.currentConfiguration.uri.path,
        RoutePaths.templateEditor(created.templateId),
      );
      final document = (await booth.templates.templates.loadLatest(
        created.templateId,
      )).document;
      // The design as chosen: a 2x6 strip at 300 dpi with four photos.
      expect((document.page.widthPx, document.page.heightPx), (600, 1800));
      expect(document.page.dpi, 300);
      expect(document.photoSlotCount, 4);
      expect(find.byType(EditorCanvas), findsOneWidget);
    });
  }

  testWidgets(
    'occasion search and collection filters create an editable Christmas template',
    (tester) async {
      useViewport(tester, TabletViewport.ipadLandscape);
      final booth = await pumpApp(tester, location: RoutePaths.templates);
      await settleRendering(tester);
      await tester.tap(find.text('New template').first);
      await tester.pumpAndSettle();
      final search = find.descendant(
        of: find.byKey(const ValueKey('design-search')),
        matching: find.byType(TextField),
      );
      for (final (query, title) in [
        ('Silk & Vows', 'Silk & Vows'),
        ('Make a Wish', 'Make a Wish'),
        ('Golden Together', 'Golden Together'),
        ('easter', 'Easter Garden'),
        ('dinosaur', 'Dino Birthday'),
        ('xmas', 'Christmas Keepsake'),
        ('christmas', 'Christmas Keepsake'),
      ]) {
        await tester.enterText(search, query);
        await tester.pumpAndSettle();
        expect(find.text(title), findsWidgets, reason: query);
      }
      final christmas = find.widgetWithText(ChoiceChip, 'Christmas');
      await tester.ensureVisible(christmas);
      await tester.tap(christmas);
      await tester.pumpAndSettle();
      expect(find.text('2 designs · 300 dpi · Fully editable'), findsOneWidget);
      final design = find.bySemanticsLabel(RegExp('^Christmas Keepsake,'));
      await tester.ensureVisible(design);
      await tester.tap(design);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      final saved = (await _listings(booth.templates)).single.latest;
      expect(saved.templateName, 'Christmas Keepsake');
      expect(saved.tags.occasionTags, contains('christmas'));
      final document = (await booth.templates.templates.loadLatest(
        saved.templateId,
      )).document;
      expect(document.photoSlotCount, 2);
      expect(
        document.layers.whereType<TextLayer>().map((l) => l.id),
        containsAll(['title', 'subtitle', 'personalization']),
      );
      expect(document.layers.whereType<ImageLayer>(), hasLength(2));
    },
  );

  testWidgets('duplicate, rename, archive after confirming, and restore', (
    tester,
  ) async {
    useViewport(tester, TabletViewport.ipadLandscape);
    final booth = await pumpApp(
      tester,
      location: RoutePaths.templates,
      seedTemplates: _garden,
    );
    await settleRendering(tester);

    await _more(tester, 'Duplicate');
    var listings = await _listings(booth.templates);
    expect(
      listings.map((l) => l.latest.templateName),
      containsAll(['Garden party', 'Garden party copy']),
    );
    expect(find.text('Made "Garden party copy".'), findsOneWidget);
    final copy = listings.firstWhere(
      (l) => l.latest.templateName == 'Garden party copy',
    );
    final original = listings.firstWhere(
      (l) => l.latest.templateName == 'Garden party',
    );
    expect(
      (await booth.templates.templates.loadLatest(copy.templateId)).document,
      (await booth.templates.templates.loadLatest(original.templateId))
          .document,
    );

    // Rename the copy.
    await _more(tester, 'Rename', template: 'Garden party copy');
    await tester.enterText(find.byType(TextField).last, 'Spring wedding');
    await tester.tap(find.text('Rename').last);
    await tester.pumpAndSettle();
    listings = await _listings(booth.templates);
    expect(
      listings.map((l) => l.latest.templateName),
      containsAll(['Garden party', 'Spring wedding']),
    );
    expect(find.text('Spring wedding'), findsOneWidget);

    // Archive asks first; "Keep it" changes nothing.
    await _more(tester, 'Archive', template: 'Spring wedding');
    expect(find.text('Archive "Spring wedding"?'), findsOneWidget);
    await tester.tap(find.text('Keep it'));
    await tester.pumpAndSettle();
    expect(
      (await _listings(booth.templates)).every((l) => !l.archived),
      isTrue,
    );

    await _more(tester, 'Archive', template: 'Spring wedding');
    await tester.tap(find.text('Archive').last);
    await tester.pumpAndSettle();
    listings = await _listings(booth.templates);
    expect(
      listings.firstWhere((l) => l.templateId == copy.templateId).archived,
      isTrue,
    );
    // It leaves the main list; the Archived filter shows it, to restore.
    expect(find.text('Spring wedding'), findsNothing);
    await tester.tap(find.text('Archived').first);
    await tester.pumpAndSettle();
    expect(find.text('Spring wedding'), findsOneWidget);
    await _more(tester, 'Restore', template: 'Spring wedding');
    listings = await _listings(booth.templates);
    expect(listings.every((l) => !l.archived), isTrue);
  });

  testWidgets('export hands the share sheet one package named after the '
      'template, and it imports elsewhere as the same design', (tester) async {
    useViewport(tester, TabletViewport.ipadLandscape);
    final booth = await pumpApp(
      tester,
      location: RoutePaths.templates,
      seedTemplates: _garden,
    );
    await settleRendering(tester);
    await _more(tester, 'Export package');

    expect(booth.files.shared, hasLength(1));
    final shared = booth.files.shared.single;
    expect(shared.fileName, 'Garden-party-r1.porcelain-template');
    expect(shared.mimeType, templatePackageMimeType);
    expect(
      find.text('Sent "Garden-party-r1.porcelain-template".'),
      findsOneWidget,
    );

    final elsewhere = MemoryTemplateStore(clock: FakeClock());
    final imported = await _library(elsewhere).importPackage(shared.bytes);
    final original = (await _listings(booth.templates)).single;
    expect(
      (await elsewhere.templates.loadLatest(imported.templateId)).document,
      (await booth.templates.templates.loadLatest(original.templateId))
          .document,
    );
  });

  testWidgets('a dismissed share sheet claims nothing', (tester) async {
    useViewport(tester, TabletViewport.ipadLandscape);
    final booth = await pumpApp(
      tester,
      location: RoutePaths.templates,
      seedTemplates: _garden,
    );
    await settleRendering(tester);
    booth.files.shareOutcome = ShareOutcome.dismissed;
    await _more(tester, 'Export package');
    expect(booth.files.shared, hasLength(1));
    expect(find.textContaining('Sent'), findsNothing);
  });

  testWidgets('import takes a package whole, or refuses with nothing '
      'stored', (tester) async {
    useViewport(tester, TabletViewport.ipadLandscape);
    final booth = await pumpApp(tester, location: RoutePaths.templates);
    await settleRendering(tester);

    Future<void> import(PickedFile? file, {FilePickException? error}) async {
      booth.files
        ..nextPick = file
        ..nextPickError = error;
      await tester.tap(find.text('Import').first);
      await tester.pumpAndSettle();
    }

    // Not a package: refused by its content, whatever its name says.
    await import(
      PickedFile(
        name: 'Garden party.porcelain-template',
        bytes: Uint8List.fromList(utf8.encode('not a package')),
      ),
    );
    expect(
      find.textContaining("isn't a Porcelain template package"),
      findsOneWidget,
    );
    expect(find.textContaining('Nothing was imported.'), findsOneWidget);
    expect(await _listings(booth.templates), isEmpty);

    // Too large for the picker's limit.
    await import(
      null,
      error: const FilePickException(
        FilePickFailure.tooLarge,
        limitBytes: LibraryActions.maxPackageBytes,
      ),
    );
    expect(find.text('That file is larger than 100 MB.'), findsOneWidget);
    expect(await _listings(booth.templates), isEmpty);

    // Cancelled: nothing happens.
    await import(null);
    expect(booth.files.picks, hasLength(3));
    expect(await _listings(booth.templates), isEmpty);

    // A real package from another booth.
    final elsewhere = MemoryTemplateStore(clock: FakeClock());
    final made = await _garden(elsewhere);
    final package = await _library(elsewhere).exportPackage(made);
    await import(PickedFile(name: package.fileName, bytes: package.bytes));
    expect(find.text('Imported "Garden party".'), findsOneWidget);
    final listings = await _listings(booth.templates);
    expect(listings, hasLength(1));
    expect(
      (await booth.templates.templates.loadLatest(listings.single.templateId))
          .document,
      (await elsewhere.templates.loadLatest(made.templateId)).document,
    );
  });

  group('images in the studio (S08, AC-0508)', () {
    Future<TestBooth> openStudio(WidgetTester tester) async {
      useViewport(tester, TabletViewport.ipadLandscape);
      final store = MemoryTemplateStore(clock: FakeClock());
      final created = await _garden(store);
      final booth = await pumpApp(
        tester,
        location: RoutePaths.templateEditor(created.templateId),
        templates: store,
      );
      await settleRendering(tester);
      await tester.tap(find.bySemanticsLabel('Artwork').first);
      await tester.pumpAndSettle();
      expect(find.text('Add artwork'), findsOneWidget);
      await tester.tap(find.text('Your images'));
      await tester.pumpAndSettle();
      return booth;
    }

    testWidgets(
      'search finds a transparent goose sticker and adds an editable layer',
      (tester) async {
        final booth = await openStudio(tester);
        await tester.tap(find.text('Stickers & art'));
        await tester.pumpAndSettle();
        final search = find.descendant(
          of: find.byKey(const ValueKey('artwork-search')),
          matching: find.byType(TextField),
        );
        await tester.enterText(search, 'goose with blue');
        await tester.pumpAndSettle();
        final choice = find.bySemanticsLabel('Use Goose with blue bow');
        await tester.ensureVisible(choice);
        await tester.tap(choice);
        await settleRendering(tester);
        final controller = tester
            .widget<EditorCanvas>(find.byType(EditorCanvas))
            .controller;
        final png = File('assets/decorations/sticker_goose_blue.png')
            .readAsBytesSync();
        final id = assetIdOf(png);
        final layer = controller.document.layers
            .whereType<ImageLayer>()
            .singleWhere((l) => l.assetId == id);
        expect(layer.visible, isTrue);
        expect(layer.locked, isFalse);
        expect(
          layer.zIndex,
          greaterThan(controller.document.photoSlots.last.zIndex),
        );
        expect(await booth.templates.assets.read(id), png);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('a picked PNG is copied into the booth and placed', (
      tester,
    ) async {
      final booth = await openStudio(tester);
      final assetsBefore = booth.templates.assets.count;
      final png = _transparentPng();
      booth.files.nextPick = PickedFile(name: 'logo.png', bytes: png);
      await tester.tap(find.text('Import an image…'));
      await tester.pumpAndSettle();
      await settleRendering(tester);

      // Stored under its content id; the picker's file is not needed again.
      final id = assetIdOf(png);
      expect(booth.templates.assets.count, assetsBefore + 1);
      expect(await booth.templates.assets.read(id), png);
      expect(booth.files.picks, [PickableFile.image]);

      final controller = tester
          .widget<EditorCanvas>(find.byType(EditorCanvas))
          .controller;
      final added = controller.document.layers.whereType<ImageLayer>().where(
        (l) => l.assetId == id,
      );
      expect(added, hasLength(1));
      expect(controller.document.assets[id]!.mediaType.kind, AssetKind.image);
    });

    testWidgets('an image is renamed, removed when unused, and kept while a '
        'template uses it', (tester) async {
      useViewport(tester, TabletViewport.ipadLandscape);
      final store = MemoryTemplateStore(clock: FakeClock());
      final library = _library(store);
      final unused = await library.importImage(
        _transparentPng(),
        name: 'confetti.png',
      );
      final used = await library.importImage(
        File('assets/decorations/film_edges.png').readAsBytesSync(),
        name: 'film.png',
      );
      final strip = await library.create(
        starterDesigns.firstWhere((d) => d.id == 'blank-2x6'),
        name: 'Film strip',
      );
      final opened = await library.open(strip.templateId);
      await library.save(
        strip.templateId,
        DocumentEdits.add(
          opened.revision.document,
          NewLayers.image(
            opened.revision.document,
            'film',
            used.id,
            used.asset,
          ),
          assets: {used.id: used.asset},
        ),
      );
      final created = await _garden(store);
      await pumpApp(
        tester,
        location: RoutePaths.templateEditor(created.templateId),
        templates: store,
      );
      await settleRendering(tester);
      await tester.tap(find.bySemanticsLabel('Artwork').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Your images'));
      await tester.pumpAndSettle();
      await settleRendering(tester);

      // Rename.
      await tester.tap(find.bySemanticsLabel('Rename confetti.png'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Gold confetti');
      await tester.tap(find.text('Rename').last);
      await tester.pumpAndSettle();
      expect((await store.assets.find(unused.id))!.asset.name, 'Gold confetti');
      expect(find.text('Gold confetti'), findsOneWidget);

      // The image a saved template uses cannot be removed; it says why.
      await tester.tap(find.bySemanticsLabel('Remove film.png'));
      await tester.pumpAndSettle();
      expect(find.text('Remove this image?'), findsNothing);
      expect(
        find.text('A template or unsaved work uses this image.'),
        findsOneWidget,
      );
      expect(await store.assets.find(used.id), isNotNull);

      // The unused one goes, after confirming.
      await tester.tap(find.bySemanticsLabel('Remove Gold confetti'));
      await tester.pumpAndSettle();
      expect(find.text('Remove this image?'), findsOneWidget);
      await tester.tap(find.text('Remove').last);
      await tester.pumpAndSettle();
      expect(await store.assets.find(unused.id), isNull);
      expect(await store.assets.find(used.id), isNotNull);
    });

    testWidgets('a file that is not an image is refused and not stored', (
      tester,
    ) async {
      final booth = await openStudio(tester);
      final assetsBefore = booth.templates.assets.count;
      booth.files.nextPick = PickedFile(
        name: 'photo.png',
        bytes: Uint8List.fromList(utf8.encode('just some text')),
      );
      await tester.tap(find.text('Import an image…'));
      await tester.pumpAndSettle();
      expect(
        find.text('That file is not a PNG or JPEG image.'),
        findsOneWidget,
      );
      expect(booth.templates.assets.count, assetsBefore);

      booth.files.nextPickError = const FilePickException(
        FilePickFailure.tooLarge,
        limitBytes: AssetLimits.maxImageBytes,
      );
      await tester.tap(find.text('Import an image…'));
      await tester.pumpAndSettle();
      expect(find.text('That file is larger than 50 MB.'), findsOneWidget);
      expect(booth.templates.assets.count, assetsBefore);
    });
  });
}
