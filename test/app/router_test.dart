import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/app/app.dart';
import 'package:porcelain_photo_booth/app/providers.dart';
import 'package:porcelain_photo_booth/app/router.dart';
import 'package:porcelain_photo_booth/features/dashboard/baseline_home_screen.dart';

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
}
