// Review the actual Template Studio with a sticker selected, on both tablet
// platforms and in both orientations. Test-only stores; no operator data.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/routing/route_paths.dart';
import 'package:porcelain_photo_booth/core/templates/bundled_decorations.dart';
import 'package:porcelain_photo_booth/core/templates/starter_designs.dart';
import 'package:porcelain_photo_booth/core/templates/template_library.dart';
import 'package:porcelain_photo_booth/features/template_studio/editor_canvas.dart';

import '../../test/flutter_test_config.dart' show loadAppFonts;
import '../../test/support/app_harness.dart';
import '../../test/support/fakes.dart';
import '../../test/support/memory_template_store.dart';
import '../../test/support/tablet_viewports.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    await loadAppFonts();
  });
  for (final viewport in [
    TabletViewport.ipadLandscape,
    TabletViewport.ipadPortrait,
    TabletViewport.androidLandscape,
    TabletViewport.androidPortrait,
  ]) {
    testWidgets('sticker builder ${viewport.name}', (tester) async {
      useViewport(tester, viewport, pixelRatio: 1);
      final store = MemoryTemplateStore(clock: FakeClock());
      final library = TemplateLibrary(
        assets: store.assets,
        templates: store.templates,
        packages: store.packages,
        drafts: store.drafts,
        clock: store.clock,
        loadBundled: (path) async => File(path).readAsBytesSync(),
      );
      final made = await library.create(
        starterDesigns.firstWhere((d) => d.id == 'classic-strip'),
        name: 'Celebration memories',
      );
      await pumpApp(
        tester,
        templates: store,
        location: RoutePaths.templateEditor(made.templateId),
      );
      await settleRendering(tester);
      final controller = tester
          .widget<EditorCanvas>(find.byType(EditorCanvas))
          .controller;
      final sticker = await library.storeDecoration(
        bundledDecoration('sticker_christmas_bauble'),
      );
      await tester.runAsync(() => controller.addImage(sticker, sticker: true));
      await settleRendering(tester);
      await controller.save();
      await tester.pumpAndSettle();
      final boundaries = tester
          .renderObjectList<RenderRepaintBoundary>(find.byType(RepaintBoundary))
          .where(
            (b) =>
                b.hasSize &&
                b.size.width >= viewport.logicalSize.width &&
                b.size.height >= viewport.logicalSize.height,
          )
          .toList();
      expect(boundaries, isNotEmpty);
      await tester.runAsync(() async {
        final image = await boundaries.first.toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final dir = Directory('build/local-verification/sticker-builder')
          ..createSync(recursive: true);
        File('${dir.path}/${viewport.name}.png')
            .writeAsBytesSync(data!.buffer.asUint8List());
        image.dispose();
      });
      expect(controller.hasUnsavedChanges, isFalse);
      expect(tester.takeException(), isNull);
    });
  }
}
