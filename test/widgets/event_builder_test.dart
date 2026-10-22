// EP07 and EP08 (AC-EP01, AC-EP07): a new event is built in eight steps
// (details, experience, customisation, templates with recommendations,
// camera, texting, preview, check and launch) into the same stored event
// the editor edits; the Experience tab customises an existing event,
// switching packs keeps the event's other settings, and Reset to pack
// defaults clears only the experience's own choices.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/routing/route_paths.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_catalog.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/features/events/preflight_screen.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';
import 'package:porcelain_photo_booth/shared/widgets/porcelain_button.dart';
import 'package:porcelain_photo_booth/shared/widgets/porcelain_text_field.dart';

import '../support/app_harness.dart';
import '../support/seed.dart';
import '../support/tablet_viewports.dart';
import '../support/test_database.dart';

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

Future<List<BoothEvent>> _stored(TestBooth booth) async {
  final rows = await booth.db.customSelect('SELECT id FROM events').get();
  return [
    for (final row in rows)
      (await booth.events.findById(row.read<String>('id')))!,
  ];
}

/// The library's templates, "Retro strip" drawn for Kid Party Arcade.
Future<void> _taggedTemplates(BoothDatabase db) async {
  await seedTemplates(db);
  await db.customStatement('UPDATE templates SET tags_json = ? WHERE id = ?', [
    '{"schemaVersion":1,"categoryTags":["kids"],'
        '"recommendedExperienceIds":["kid-party-arcade"],'
        '"occasionTags":[],"visualStyleTags":[]}',
    TestIds.templateB,
  ]);
}

void main() {
  testWidgets('a new event is built step by step and opens its launch '
      'checks', (tester) async {
    useViewport(tester, TabletViewport.ipadLandscape);
    final booth = await pumpApp(
      tester,
      location: RoutePaths.newEvent,
      seed: (db) => _taggedTemplates(db),
    );
    expect(find.text('Step 1 of 8'), findsOneWidget);
    await _type(tester, 'Title', 'Maya turns 7');

    await _tapText(tester, 'Next: Experience');
    expect(find.text('Step 2 of 8'), findsOneWidget);
    await _tapLabel(tester, 'Kid Party Arcade');

    await _tapText(tester, 'Next: Customise');
    await _type(tester, 'Get ready words', 'Say cheese!');
    await _tapLabel(tester, 'Arcade Start');
    await _tapText(tester, 'Full template');

    await _tapText(tester, 'Next: Templates');
    expect(find.text('Suits Kid Party Arcade'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Retro strip')).dy,
      lessThan(tester.getTopLeft(find.text('Two-up classic')).dy),
      reason: 'the recommended design comes first',
    );
    // Recommendations never limit: an unrelated template can be added.
    final add = find.descendant(
      of: find
          .ancestor(of: find.text('Two-up classic'), matching: find.byType(Row))
          .first,
      matching: find.widgetWithText(PorcelainButton, 'Add'),
    );
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();

    await _tapText(tester, 'Next: Camera');
    await _tapText(tester, 'Next: Texting');
    await _tapText(tester, 'Next: Preview');
    expect(find.text('Preview the whole guest journey'), findsOneWidget);
    await _tapText(tester, 'Next: Check and launch');
    await _tapText(tester, 'Save and check');
    expect(find.byType(PreflightScreen), findsOneWidget);

    final event = (await _stored(booth)).single;
    expect(event.title, 'Maya turns 7');
    expect(event.status, EventStatus.draft);
    expect(event.templates.revisionIds, [TestIds.revisionA1]);
    final experience = event.experience;
    expect(experience.packId, 'kid-party-arcade');
    expect(experience.childrenMayBeGuests, isTrue, reason: 'decision 4.7');
    expect(experience.getReadyText, 'Say cheese!');
    expect(experience.countdownPresetId, 'arcade-start');
    expect(experience.cameraStage, CameraStageMode.fullTemplate);
  });

  testWidgets('steps can be visited in any order and Back returns', (
    tester,
  ) async {
    useViewport(tester, TabletViewport.ipadPortrait);
    await pumpApp(tester, location: RoutePaths.newEvent, seed: seedTemplates);
    await _tapText(tester, '7. Preview');
    expect(find.text('Step 7 of 8'), findsOneWidget);
    await _tapText(tester, 'Back');
    expect(find.text('Step 6 of 8'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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
