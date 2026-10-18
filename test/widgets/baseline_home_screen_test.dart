import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/app/app.dart';
import 'package:porcelain_photo_booth/core/platform/app_environment.dart';
import 'package:porcelain_photo_booth/domain/value_objects/orientation.dart';

import '../support/tablet_viewports.dart';

Widget _app({
  AppEnvironment environment = const AppEnvironment(
    platform: TargetPlatform.android,
    buildMode: BuildMode.debug,
  ),
}) {
  return ProviderScope(
    overrides: [appEnvironmentProvider.overrideWithValue(environment)],
    child: const PorcelainApp(),
  );
}

void main() {
  testWidgets('shows only facts the build can verify', (tester) async {
    await tester.pumpWidget(
      _app(
        environment: const AppEnvironment(
          platform: TargetPlatform.iOS,
          buildMode: BuildMode.release,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Porcelain Photo Booth'), findsOneWidget);
    expect(find.text('Engineering baseline · M01'), findsOneWidget);
    expect(find.text('iPadOS'), findsOneWidget);
    expect(find.text('release'), findsOneWidget);
  });

  testWidgets('release builds offer no controls, so none can be dead', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        environment: const AppEnvironment(
          platform: TargetPlatform.android,
          buildMode: BuildMode.release,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ButtonStyleButton ||
            widget is IconButton ||
            widget is InkWell,
      ),
      findsNothing,
    );
  });

  testWidgets('debug builds link to both developer spikes', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Developer spikes'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Render spike'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Camera spike'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });

  testWidgets('meets text contrast guideline', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });

  for (final viewport in TabletViewport.values) {
    testWidgets('lays out without overflow at ${viewport.name}', (
      tester,
    ) async {
      useViewport(tester, viewport);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final expected = ViewportOrientation.fromLogicalSize(
        width: viewport.logicalSize.width,
        height: viewport.logicalSize.height,
      );
      expect(find.textContaining('· ${expected.name}'), findsOneWidget);
    });
  }

  testWidgets('survives 200% text scale on the smallest tablet', (
    tester,
  ) async {
    useViewport(tester, TabletViewport.compactTabletLandscape);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
