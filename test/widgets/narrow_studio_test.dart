// UX-P1 (CR-003, AC-UXP-05): a Studio window narrower than 600 dp (split
// screen, or a phone opening the web build) keeps its width for content:
// a top bar with the wordmark, Diagnostics and Lock Studio, and the other
// sections in a bottom bar. Each section fits such a window, with very
// large text too, and its controls stay labeled and large enough to tap.
// The guest screens stack their print above the words there, so no title
// or button label is cut short.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/features/dashboard/dashboard_screen.dart';
import 'package:porcelain_photo_booth/features/diagnostics/diagnostics_screen.dart';
import 'package:porcelain_photo_booth/features/events/events_screen.dart';
import 'package:porcelain_photo_booth/features/operator_access/unlock_screen.dart';
import 'package:porcelain_photo_booth/shared/widgets/porcelain_button.dart';
import 'package:porcelain_photo_booth/shared/widgets/porcelain_navigation.dart';

import '../support/screen_catalog.dart';
import '../support/tablet_viewports.dart';

const _phone = Size(390, 844);

/// Each Studio section as the catalog seeds it.
const _sections = [
  'dashboard with events',
  'events',
  'templates library',
  'gallery sessions',
  'settings',
  'diagnostics',
];

Finder _inBottomBar(String label) => find.descendant(
  of: find.byType(PorcelainBottomNavigation),
  matching: find.text(label),
);

Finder _topBarButton(String label) => find.byWidgetPredicate(
  (widget) => widget is PorcelainIconButton && widget.semanticLabel == label,
);

void main() {
  testWidgets('the sections move to a bottom bar, Diagnostics and Lock '
      'Studio to the top bar', (tester) async {
    final semantics = tester.ensureSemantics();
    await show(tester, 'dashboard with events', size: _phone);
    expect(find.byType(PorcelainNavigation), findsNothing);
    for (final label in [
      'Dashboard',
      'Events',
      'Templates',
      'Gallery',
      'Settings',
    ]) {
      expect(_inBottomBar(label), findsOneWidget, reason: label);
    }
    expect(_inBottomBar('Diagnostics'), findsNothing);
    expect(find.byType(DashboardScreen), findsOneWidget);

    await tester.tap(_inBottomBar('Events'));
    await tester.pumpAndSettle();
    expect(find.byType(EventsScreen), findsOneWidget);

    await tester.tap(_topBarButton('Diagnostics'));
    await tester.pumpAndSettle();
    expect(find.byType(DiagnosticsScreen), findsOneWidget);
    expect(
      tester.getSemantics(_topBarButton('Diagnostics')),
      matchesSemantics(
        label: 'Diagnostics',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
      reason: 'the top bar shows where the operator is',
    );

    await tester.tap(_topBarButton('Lock Studio'));
    await tester.pumpAndSettle();
    expect(find.byType(UnlockScreen), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a tablet-width window keeps the side navigation', (
    tester,
  ) async {
    await show(
      tester,
      'dashboard',
      viewport: TabletViewport.compactTabletPortrait,
    );
    expect(find.byType(PorcelainNavigation), findsOneWidget);
    expect(find.byType(PorcelainBottomNavigation), findsNothing);
  });

  // The guest screens, as a phone opening the web test build shows them:
  // nothing overflows and no word or button label is cut short.
  for (final name in [
    'booth welcome',
    'booth get ready',
    'booth review',
    'booth finished',
    'booth operator',
  ]) {
    testWidgets('$name fits a phone-sized window, every label whole', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await show(tester, name, size: _phone);
      expect(tester.takeException(), isNull);
      for (final paragraph in tester.renderObjectList<RenderParagraph>(
        find.byType(RichText),
      )) {
        expect(
          paragraph.didExceedMaxLines,
          isFalse,
          reason: paragraph.text.toPlainText(),
        );
      }
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    });
  }

  for (final name in _sections) {
    group(name, () {
      testWidgets('fits a phone-sized window', (tester) async {
        await show(tester, name, size: _phone);
        expect(tester.takeException(), isNull);
      });

      testWidgets('fits a phone-sized window with 200% text', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await show(tester, name, size: _phone);
        expect(tester.takeException(), isNull);
      });

      testWidgets('keeps its controls labeled and large enough to tap', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await show(tester, name, size: _phone);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        semantics.dispose();
      });
    });
  }
}
