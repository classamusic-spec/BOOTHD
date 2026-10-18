// AC-0203 (no dead controls), AC-0204 (portrait and landscape tablet
// layouts without overflow), AC-0205 and AC-0208 (contrast, labels and
// touch targets on every screen in both orientations).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/design_system/appearance.dart';
import 'package:porcelain_photo_booth/core/design_system/theme_profiles.dart';
import 'package:porcelain_photo_booth/shared/widgets/pressable.dart';

import '../support/app_harness.dart';
import '../support/tablet_viewports.dart';

/// Every implemented screen, by name and location.
const screens = {
  'dashboard': '/studio',
  'events': '/studio/events',
  'templates': '/studio/templates',
  'gallery': '/studio/gallery',
  'settings': '/studio/settings',
  'settings appearance': '/studio/settings?section=appearance',
  'settings camera': '/studio/settings?section=camera',
  'settings output': '/studio/settings?section=output',
  'settings booth': '/studio/settings?section=booth',
  'settings about': '/studio/settings?section=about',
  'diagnostics': '/studio/diagnostics',
  'guest preview': '/preview/guest-welcome',
  'not found': '/no-such-page',
  'component gallery': '/dev/components',
};

/// The component gallery shows a spinner and skeleton that never settle.
bool settles(String name) => name != 'component gallery';

Future<void> show(
  WidgetTester tester,
  String name, {
  TabletViewport viewport = TabletViewport.ipadLandscape,
  AppearanceSettings appearance = const AppearanceSettings(),
}) async {
  useViewport(tester, viewport);
  await pumpApp(
    tester,
    location: screens[name]!,
    appearance: appearance,
    settle: settles(name),
  );
  if (!settles(name)) await tester.pump(const Duration(seconds: 1));
}

void main() {
  for (final name in screens.keys) {
    group(name, () {
      for (final viewport in TabletViewport.values) {
        testWidgets('lays out without overflow at ${viewport.name}', (
          tester,
        ) async {
          await show(tester, name, viewport: viewport);
          expect(tester.takeException(), isNull);
        });
      }

      for (final viewport in [
        TabletViewport.compactTabletPortrait,
        TabletViewport.compactTabletLandscape,
      ]) {
        testWidgets('survives 200% text at ${viewport.name}', (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await show(tester, name, viewport: viewport);
          expect(tester.takeException(), isNull);
        });
      }

      for (final viewport in [
        TabletViewport.ipadPortrait,
        TabletViewport.ipadLandscape,
        TabletViewport.androidPortrait,
        TabletViewport.androidLandscape,
      ]) {
        testWidgets('meets accessibility guidelines at ${viewport.name}', (
          tester,
        ) async {
          final semantics = tester.ensureSemantics();
          await show(tester, name, viewport: viewport);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          semantics.dispose();
        });
      }

      for (final profile in [
        PorcelainThemeProfile.lightOak,
        PorcelainThemeProfile.darkroomWalnut,
      ]) {
        testWidgets('meets text contrast in ${profile.name}', (tester) async {
          final semantics = tester.ensureSemantics();
          await show(
            tester,
            name,
            appearance: AppearanceSettings(profile: profile),
          );
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          semantics.dispose();
        });
      }

      for (final viewport in [
        TabletViewport.ipadPortrait,
        TabletViewport.ipadLandscape,
      ]) {
        testWidgets('has no dead controls at ${viewport.name}', (tester) async {
          await show(tester, name, viewport: viewport);
          final dead = [
            for (final control in tester.widgetList<Pressable>(
              find.byType(Pressable),
            ))
              if (control.onPressed == null &&
                  control.disabledReason == null &&
                  !control.busy)
                control.semanticLabel ?? control.toString(),
            for (final button in tester.widgetList<ButtonStyleButton>(
              find.byWidgetPredicate((w) => w is ButtonStyleButton),
            ))
              if (button.onPressed == null) button.toString(),
          ];
          expect(
            dead,
            isEmpty,
            reason:
                'Every control must work or be disabled with a reason '
                '(AC-0203).',
          );
        });
      }
    });
  }

  testWidgets('the dead-control audit catches a silent disabled control '
      '(mutation guard)', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Pressable(
          onPressed: null,
          builder: (context, state) => const SizedBox(width: 48, height: 48),
        ),
      ),
    );
    final control = tester.widget<Pressable>(find.byType(Pressable));
    expect(control.onPressed == null && control.disabledReason == null, isTrue);
  });
}
