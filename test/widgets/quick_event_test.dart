// UX-P1 (CR-003, AC-UXP-01 to AC-UXP-04): a new event is made in three
// steps (name and occasion, look and design, create), a ready-made design
// joins the library when the event is created, the photos per guest follow
// the design, Create leaves the event active on its launch checks, Save as
// draft opens it in the editor, a missing name is asked for only when
// going on, and leaving with entered details asks first.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/routing/route_paths.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/features/events/create/quick_event_screen.dart';
import 'package:porcelain_photo_booth/features/events/event_editor_screen.dart';
import 'package:porcelain_photo_booth/features/events/events_screen.dart';
import 'package:porcelain_photo_booth/features/events/preflight_screen.dart';
import 'package:porcelain_photo_booth/shared/widgets/porcelain_text_field.dart';

import '../support/app_harness.dart';
import '../support/seed.dart';
import '../support/tablet_viewports.dart';
import '../support/test_database.dart';

Future<void> _tapText(WidgetTester tester, String text) async {
  final target = find.text(text).last;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _tapLabel(WidgetTester tester, Pattern label) async {
  final target = find.bySemanticsLabel(label).last;
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

void main() {
  testWidgets('three steps make an active event from a ready-made design '
      'and open its launch checks', (tester) async {
    useViewport(tester, TabletViewport.ipadLandscape);
    final booth = await pumpApp(
      tester,
      location: RoutePaths.newEvent,
      recordCreatedTemplates: true,
    );
    expect(find.byType(QuickEventScreen), findsOneWidget);
    // No complaint before the operator has tried to go on.
    expect(find.text('Give the event a name.'), findsNothing);
    await _tapText(tester, 'Next: choose the look');
    expect(find.text('Give the event a name.'), findsOneWidget);
    expect(find.text("Let's set up your event"), findsOneWidget);

    await _type(tester, 'Event name', 'Maya turns 7');
    expect(find.text('Give the event a name.'), findsNothing);
    await _tapLabel(tester, 'Kids party');
    await _tapText(tester, 'Next: choose the look');
    expect(find.text('Choose the look'), findsOneWidget);
    // The occasion chose the look; designs made for it come first.
    expect(
      tester.getSemantics(find.bySemanticsLabel('Kid Party Arcade').last),
      matchesSemantics(
        label: 'Kid Party Arcade',
        isSelected: true,
        hasSelectedState: true,
        isButton: true,
        hasTapAction: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasFocusAction: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
    await _tapLabel(tester, RegExp(r'^Superstar, 1 photo'));

    await _tapText(tester, 'Next: review');
    expect(find.text('READY TO CREATE'), findsOneWidget);
    expect(
      find.text('Superstar · 1 photo per guest · added to your templates'),
      findsOneWidget,
    );
    await _tapText(tester, 'Create and check the booth');
    expect(find.byType(PreflightScreen), findsOneWidget);

    final event = (await _stored(booth)).single;
    expect(event.title, 'Maya turns 7');
    expect(event.status, EventStatus.active);
    expect(event.experience.packId, 'kid-party-arcade');
    expect(event.experience.childrenMayBeGuests, isTrue, reason: 'EP00 4.7');
    expect(event.capture.shotCount, 1, reason: 'follows the design');
    final library = await booth.templates.templates.watchLibrary().first;
    final created = library.single.latest;
    expect(created.templateName, 'Superstar');
    expect(event.templates.revisionIds, [created.revisionId]);
    expect(event.templates.defaultRevisionId, created.revisionId);
  });

  testWidgets('a library design keeps its photo count; Save as draft opens '
      'the editor', (tester) async {
    useViewport(tester, TabletViewport.ipadPortrait);
    final booth = await pumpApp(
      tester,
      location: RoutePaths.newEvent,
      seed: seedTemplates,
    );
    await _type(tester, 'Event name', 'Office party');
    await _tapText(tester, 'Next: choose the look');
    await _tapLabel(tester, RegExp(r'^Two-up classic, 2 photos'));
    await _tapText(tester, 'Next: review');
    await _tapText(tester, 'Save as draft');
    expect(find.byType(EventEditorScreen), findsOneWidget);

    final event = (await _stored(booth)).single;
    expect(event.status, EventStatus.draft);
    expect(event.templates.revisionIds, [TestIds.revisionA1]);
    expect(event.capture.shotCount, 2);
    expect(
      await booth.templates.templates.watchLibrary().first,
      isEmpty,
      reason: 'a library design adds nothing to the library',
    );
  });

  testWidgets('steps already reached can be revisited from the trail', (
    tester,
  ) async {
    useViewport(tester, TabletViewport.ipadLandscape);
    await pumpApp(tester, location: RoutePaths.newEvent, seed: seedTemplates);
    // A later step cannot be reached before the event has a name.
    await _tapLabel(tester, 'Step 3 of 3: Ready');
    expect(find.text("Let's set up your event"), findsOneWidget);
    await _type(tester, 'Event name', 'Spring fair');
    await _tapLabel(tester, 'Step 3 of 3: Ready');
    expect(find.text('READY TO CREATE'), findsOneWidget);
    await _tapLabel(tester, 'Step 1 of 3: Occasion');
    expect(find.text("Let's set up your event"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving with entered details asks first', (tester) async {
    useViewport(tester, TabletViewport.ipadLandscape);
    await pumpApp(tester, location: RoutePaths.events);
    await _tapText(tester, 'New event');
    await _type(tester, 'Event name', 'Garden party');
    await _tapText(tester, 'Events');
    expect(find.text('Leave without creating the event?'), findsOneWidget);
    await _tapText(tester, 'Keep going');
    expect(find.byType(QuickEventScreen), findsOneWidget);
    await _tapText(tester, 'Events');
    await _tapText(tester, 'Leave');
    expect(find.byType(EventsScreen), findsOneWidget);
  });

  testWidgets('every step fits a phone', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(tester, location: RoutePaths.newEvent, seed: seedTemplates);
    await _type(tester, 'Event name', 'Spring fair');
    await _tapLabel(tester, 'Wedding');
    await _tapText(tester, 'Next: choose the look');
    await _tapText(tester, 'Next: review');
    expect(find.text('READY TO CREATE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
