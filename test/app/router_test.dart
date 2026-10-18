import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/app/app.dart';
import 'package:porcelain_photo_booth/app/providers.dart';
import 'package:porcelain_photo_booth/app/router.dart';
import 'package:porcelain_photo_booth/core/platform/app_environment.dart';
import 'package:porcelain_photo_booth/core/routing/route_paths.dart';
import 'package:porcelain_photo_booth/features/dashboard/baseline_home_screen.dart';
import 'package:porcelain_photo_booth/features/diagnostics/spikes/render_spike_screen.dart';

void main() {
  testWidgets('starts on the baseline home screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PorcelainApp()));
    await tester.pumpAndSettle();

    expect(find.byType(BaselineHomeScreen), findsOneWidget);
  });

  testWidgets('unknown locations get a detail-free fallback with a way back', (
    tester,
  ) async {
    final router = buildRouter(initialLocation: '/no-such-page');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [routerProvider.overrideWithValue(router)],
        child: const PorcelainApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("This page isn't available"), findsOneWidget);
    expect(find.textContaining('no-such-page'), findsNothing);
    expect(find.textContaining('Exception'), findsNothing);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    await tester.tap(find.text('Return to start'));
    await tester.pumpAndSettle();

    expect(find.byType(BaselineHomeScreen), findsOneWidget);
  });

  testWidgets('debug builds open the render spike from the home screen', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: PorcelainApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Render spike'));
    await tester.pumpAndSettle();

    expect(find.byType(RenderSpikeScreen), findsOneWidget);
  });

  testWidgets('release builds cannot reach the developer spikes', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appEnvironmentProvider.overrideWithValue(
            const AppEnvironment(
              platform: TargetPlatform.iOS,
              buildMode: BuildMode.release,
            ),
          ),
        ],
        child: const PorcelainApp(),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(BaselineHomeScreen)),
    );
    for (final path in [RoutePaths.renderSpike, RoutePaths.cameraSpike]) {
      container.read(routerProvider).go(path);
      await tester.pumpAndSettle();
      expect(find.text("This page isn't available"), findsOneWidget);
    }
  });
}
