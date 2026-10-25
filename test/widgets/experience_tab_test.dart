// EP07 and EP08 (AC-EP01, AC-EP07): the Experience tab customises an
// existing event, switching packs keeps the event's other settings, and
// Reset to pack defaults clears only the experience's own choices. New
// events are made in the three-step flow (UX-P1, quick_event_test.dart),
// which replaced the eight-step builder.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/routing/route_paths.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_catalog.dart';
import 'package:porcelain_photo_booth/shared/widgets/porcelain_text_field.dart';

import '../support/app_harness.dart';
import '../support/seed.dart';
import '../support/tablet_viewports.dart';

Future<void> _tapLabel(WidgetTester tester, String label) async {
  final target = find.bySemanticsLabel(label).last;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final target = find.text(text).last;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String field, String text) async {
  final input = find.descendant(
    of: find.widgetWithText(PorcelainTextField, field),
    matching: find.byType(TextField),
  );
  await tester.ensureVisible(input);
  await tester.enterText(input, text);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('switching packs keeps the event; reset clears only the '
      "experience's own choices", (tester) async {
    useViewport(tester, TabletViewport.ipadLandscape);
    final booth = await pumpApp(
      tester,
      location: RoutePaths.event(SeedIds.active, tab: 'guest'),
      seed: (db) => seedEvents(db),
    );
    final before = (await booth.events.findById(SeedIds.active))!;
    // Darkroom keeps only accents its dark text-on-accent can be read on.
    expect(find.bySemanticsLabel('Sky'), findsOneWidget);
    expect(find.bySemanticsLabel('Navy'), findsNothing);

    await _tapLabel(tester, 'Retro Game Quest');
    await _tapLabel(tester, 'Arcade Cabinet');
    await _type(tester, 'Finished title', 'Game over, well played');
    await _tapLabel(tester, 'Gala Elegant');
    await _tapText(tester, 'Off');
    await _tapText(tester, 'Save');
    var saved = (await booth.events.findById(SeedIds.active))!;
    expect(saved.experience.packId, 'retro-game-quest');
    expect(saved.experience.variantId, 'arcade');
    expect(saved.experience.finishText, 'Game over, well played');
    expect(saved.experience.countdownPresetId, 'gala-elegant');
    expect(saved.experience.animation, AnimationIntensity.off);
    expect(saved.templates, before.templates, reason: 'templates kept');
    expect(saved.capture, before.capture, reason: 'camera settings kept');
    expect(saved.guest, before.guest, reason: 'welcome words kept');

    await _tapText(tester, 'Reset to pack defaults');
    await _tapText(tester, 'Save');
    saved = (await booth.events.findById(SeedIds.active))!;
    final experience = saved.experience;
    expect(experience.packId, 'retro-game-quest');
    expect(experience.variantId, 'arcade', reason: 'the variant is the pack');
    expect(experience.finishText, isNull);
    expect(experience.countdownPresetId, isNull);
    expect(experience.animation, isNull);
    expect(experience.accentColor, isNull);
    expect(
      find.widgetWithText(TextField, 'Game over, well played'),
      findsNothing,
    );
  });

  test('every accent choice is opaque and named once', () {
    final names = {
      for (final (name, _) in ExperienceCatalog.accentChoices) name,
    };
    expect(names, hasLength(ExperienceCatalog.accentChoices.length));
    for (final (_, argb) in ExperienceCatalog.accentChoices) {
      expect(argb >> 24, 0xFF);
    }
    expect(
      ExperienceCatalog.countdownNames.keys.toSet(),
      ExperienceCatalog.countdowns,
    );
  });
}
