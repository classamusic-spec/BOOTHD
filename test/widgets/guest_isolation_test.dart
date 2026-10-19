// AC-0210 and AC-0305: guest screens have no print, save-to-gallery,
// share, settings, back or escape controls. The welcome skeleton, and the
// whole Booth Mode screen, have exactly one control.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/design_system/porcelain_theme_data.dart';
import 'package:porcelain_photo_booth/core/design_system/theme_profiles.dart';
import 'package:porcelain_photo_booth/core/routing/route_paths.dart';
import 'package:porcelain_photo_booth/features/booth/booth_screen.dart';
import 'package:porcelain_photo_booth/shared/guest/guest_layout.dart';
import 'package:porcelain_photo_booth/shared/guest/guest_welcome.dart';
import 'package:porcelain_photo_booth/shared/guest/guest_welcome_sample.dart';
import 'package:porcelain_photo_booth/shared/widgets/pressable.dart';

import '../support/app_harness.dart';
import '../support/seed.dart';
import '../support/tablet_viewports.dart';

/// Words a guest control must never carry in release 1.
final forbiddenWords = RegExp(
  r'\b(print|printer|save|share|settings?|back|exit|close|gallery|download|'
  r'menu|studio|operator)\b',
  caseSensitive: false,
);

/// Every semantics node below [root] that a guest could activate.
List<SemanticsNode> actionable(SemanticsNode root) {
  final found = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (data.hasAction(SemanticsAction.tap) ||
        data.hasAction(SemanticsAction.longPress)) {
      found.add(node);
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(root);
  return found;
}

Future<void> pumpGuest(
  WidgetTester tester,
  TabletViewport viewport, {
  PorcelainThemeProfile profile = PorcelainThemeProfile.porcelainStudio,
}) async {
  useViewport(tester, viewport);
  await tester.pumpWidget(
    MaterialApp(
      theme: porcelainThemeData(profile),
      home: Scaffold(
        body: GuestWelcome(copy: sampleGuestWelcomeCopy, onStart: () {}),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final viewport in TabletViewport.values) {
    testWidgets('welcome at ${viewport.name}: one control, no escape', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpGuest(tester, viewport);
      expect(tester.takeException(), isNull);

      final controls = actionable(
        tester.getSemantics(find.byType(GuestLayout)),
      );
      expect(controls.map((n) => n.label), ['Start']);

      expect(find.byType(Pressable), findsOneWidget);
      for (final type in [
        BackButton,
        CloseButton,
        IconButton,
        PopupMenuButton,
        Drawer,
        AppBar,
      ]) {
        expect(find.byType(type), findsNothing, reason: '$type');
      }
      expect(
        find.byWidgetPredicate((w) => w is ButtonStyleButton),
        findsNothing,
      );

      final visibleText = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');
      expect(
        forbiddenWords.hasMatch(visibleText),
        isFalse,
        reason: visibleText,
      );

      // Guest primary action stays well above the 72 dp guest minimum.
      final start = tester.getSize(find.bySemanticsLabel('Start'));
      expect(start.shortestSide, greaterThanOrEqualTo(72));
      semantics.dispose();
    });
  }

  testWidgets('the layout follows the window, not a preference', (
    tester,
  ) async {
    await pumpGuest(tester, TabletViewport.ipadPortrait);
    expect(find.byType(PortraitGuestLayout), findsOneWidget);
    await pumpGuest(tester, TabletViewport.ipadLandscape);
    expect(find.byType(LandscapeGuestLayout), findsOneWidget);
    await pumpGuest(tester, TabletViewport.compactTabletLandscape);
    expect(find.byType(LandscapeGuestLayout), findsOneWidget);
  });

  testWidgets('the welcome survives 200% text without overflow', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final viewport in [
      TabletViewport.compactTabletPortrait,
      TabletViewport.compactTabletLandscape,
    ]) {
      await pumpGuest(tester, viewport);
      expect(tester.takeException(), isNull, reason: viewport.name);
    }
  });

  for (final profile in PorcelainThemeProfile.values) {
    testWidgets('welcome meets guidelines in ${profile.name}', (tester) async {
      final semantics = tester.ensureSemantics();
      for (final viewport in [
        TabletViewport.ipadPortrait,
        TabletViewport.ipadLandscape,
      ]) {
        await pumpGuest(tester, viewport, profile: profile);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      }
      semantics.dispose();
    });
  }

  test('sample welcome copy never promises a print', () {
    final copy = sampleGuestWelcomeCopy;
    final words = [
      copy.eyebrow,
      copy.title,
      copy.subtitle,
      ...copy.steps,
      copy.startLabel,
      copy.privacyNote ?? '',
    ].join(' ');
    expect(words.toLowerCase(), isNot(contains('print')));
  });

  for (final viewport in TabletViewport.values) {
    testWidgets('Booth Mode at ${viewport.name}: the whole screen offers '
        'guests only Start', (tester) async {
      final semantics = tester.ensureSemantics();
      useViewport(tester, viewport);
      await pumpApp(
        tester,
        startAs: StartAs.booth,
        boothEventId: SeedIds.active,
        seed: (db) => seedEvents(db),
      );
      expect(tester.takeException(), isNull);

      // The operator's hidden corner is not a guest control.
      final screen = tester.getSemantics(find.byType(BoothScreen));
      expect(actionable(screen).map((n) => n.label), ['Start']);
      for (final type in [
        BackButton,
        CloseButton,
        IconButton,
        PopupMenuButton,
        Drawer,
        AppBar,
      ]) {
        expect(find.byType(type), findsNothing, reason: '$type');
      }
      final visibleText = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');
      expect(
        forbiddenWords.hasMatch(visibleText),
        isFalse,
        reason: visibleText,
      );
      semantics.dispose();
    });
  }

  testWidgets('in the operator preview, the guest area itself has only '
      'Start', (tester) async {
    final semantics = tester.ensureSemantics();
    useViewport(tester, TabletViewport.ipadPortrait);
    await pumpApp(tester, location: RoutePaths.guestPreview);
    final guest = tester.getSemantics(find.byType(GuestLayout));
    expect(actionable(guest).map((n) => n.label), ['Start']);
    semantics.dispose();
  });
}
