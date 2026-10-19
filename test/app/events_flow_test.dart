// AC-0302 (create, edit, duplicate, archive and reopen offline, surviving a
// restart), AC-0303 (capture settings, templates, theme override and
// orientation persist) and AC-0306 (drafts, missing templates and invalid
// settings block or warn at preflight), through the whole app.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/access/access_controller.dart';
import 'package:porcelain_photo_booth/core/routing/route_paths.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/domain/value_objects/appearance.dart';
import 'package:porcelain_photo_booth/domain/value_objects/orientation.dart';
import 'package:porcelain_photo_booth/features/booth/booth_screen.dart';
import 'package:porcelain_photo_booth/features/dashboard/dashboard_screen.dart';
import 'package:porcelain_photo_booth/features/events/event_copy.dart';
import 'package:porcelain_photo_booth/features/events/event_editor_screen.dart';
import 'package:porcelain_photo_booth/features/events/events_screen.dart';
import 'package:porcelain_photo_booth/features/events/preflight_screen.dart';
import 'package:porcelain_photo_booth/features/operator_access/unlock_screen.dart';
import 'package:porcelain_photo_booth/shared/operator_access/access_copy.dart';
import 'package:porcelain_photo_booth/shared/widgets/porcelain_button.dart';

import '../support/app_harness.dart';
import '../support/fakes.dart';
import '../support/seed.dart';
import '../support/tablet_viewports.dart';
import '../support/test_database.dart';

Future<void> tapText(WidgetTester tester, String text) async {
  final target = find.text(text).last;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> tapLabel(WidgetTester tester, String label) async {
  final target = find.bySemanticsLabel(label).last;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// The button labelled [label] in the row or card that shows [text].
Finder buttonNear(String text, String label) => find.descendant(
  of: find.ancestor(of: find.text(text), matching: find.byType(Row)).first,
  matching: find.widgetWithText(PorcelainButton, label),
);

/// The event card titled [title] in the list.
Finder card(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(EventCard));

/// Every stored event (a one-off read: drift streams start their first
/// query from a timer, which a fake-async test body would never run).
Future<List<BoothEvent>> storedEvents(TestBooth booth) async {
  final rows = await booth.db.customSelect('SELECT id FROM events').get();
  return [
    for (final row in rows)
      (await booth.events.findById(row.read<String>('id')))!,
  ];
}

PorcelainButton button(WidgetTester tester, String label) => tester
    .widget<PorcelainButton>(find.widgetWithText(PorcelainButton, label).last);

void main() {
  testWidgets('an event configured in the editor is stored exactly and '
      'survives a restart', (tester) async {
    useViewport(tester, TabletViewport.ipadLandscape);
    final temp = Directory.systemTemp.createTempSync('events_flow');
    addTearDown(() => temp.deleteSync(recursive: true));
    final file = File('${temp.path}/booth.sqlite');
    final clock = FakeClock();
    final first = await pumpApp(
      tester,
      location: RoutePaths.events,
      database: fileDatabase(file, clock: clock),
      clock: clock,
      seed: seedTemplates,
    );

    await tapText(tester, 'New event');
    expect(find.byType(EventEditorScreen), findsOneWidget);
    expect(find.text('Not saved yet'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Garden party');
    await tester.pumpAndSettle();

    await tapText(tester, 'Camera');
    await tapText(tester, 'Rear camera');
    await tapText(tester, 'Mirror saved photos');
    await tapText(tester, 'Landscape');
    await tapLabel(tester, 'Fewer photos');
    await tapLabel(tester, 'Longer countdown');
    await tapLabel(tester, 'Longer countdown');
    await tapText(tester, 'Whole session');
    await tapLabel(tester, 'More retakes');

    await tapText(tester, 'Templates');
    await tester.ensureVisible(buttonNear('Two-up classic', 'Add'));
    await tester.tap(buttonNear('Two-up classic', 'Add'));
    await tester.pumpAndSettle();
    expect(find.text('Default'), findsOneWidget);

    await tapText(tester, 'Experience');
    await tapText(tester, 'Light Oak');
    await tapText(tester, 'Privacy');
    await tapText(tester, 'For a set time');

    await tapText(tester, 'Save');
    expect(find.text('Saved.'), findsOneWidget);
    await tapText(tester, 'Event');
    await tapText(tester, 'Activate event');
    expect(find.text('“Garden party” is active.'), findsOneWidget);
    final id = (await storedEvents(first)).single.id;

    // Restart: the database is closed and opened again from the file.
    await tester.pumpWidget(const SizedBox());
    await first.db.close();
    final second = await pumpApp(
      tester,
      location: RoutePaths.events,
      database: fileDatabase(file, clock: clock),
      clock: clock,
      pins: first.pins,
      alreadySetUp: true,
      startAs: StartAs.locked,
    );
    expect(find.byType(UnlockScreen), findsOneWidget);
    await enterPin(tester, testPin);
    expect(find.byType(EventsScreen), findsOneWidget);
    expect(find.text('Garden party'), findsOneWidget);
    expect(find.text('Active · 1'), findsOneWidget);

    final stored = (await second.events.findById(id))!;
    expect(stored.status, EventStatus.active);
    expect(
      stored.capture,
      const CaptureSettings(
        lens: CameraLens.back,
        mirrorPreview: true,
        mirrorOutput: true,
        orientation: GuestOrientationPreference.landscape,
        shotCount: 2,
        countdownSeconds: 5,
        retakePolicy: RetakePolicy.wholeSession,
        retakeLimit: 2,
      ),
    );
    expect(
      stored.templates,
      const TemplateSelection(
        revisionIds: [TestIds.revisionA1],
        defaultRevisionId: TestIds.revisionA1,
      ),
    );
    expect(stored.guest.themeOverride, PorcelainThemeProfile.lightOak);
    expect(stored.retention, const RetentionPolicy.deleteAfterDays(30));
  });

  testWidgets('duplicate, archive and reopen from the list', (tester) async {
    useViewport(tester, TabletViewport.ipadLandscape);
    final booth = await pumpApp(
      tester,
      location: RoutePaths.events,
      seed: (db) => seedEvents(db),
    );
    expect(find.text('Active · 1'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: card('Hannah & Theo’s wedding'),
        matching: find.text('Duplicate'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Duplicated as “Hannah & Theo’s wedding (copy)” in Drafts.'),
      findsOneWidget,
    );
    expect(find.text('Drafts · 2'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: card('Hannah & Theo’s wedding'),
        matching: find.text('Archive'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Archive “Hannah & Theo’s wedding”?'), findsOneWidget);
    await tapText(tester, 'Archive');
    expect(find.text('Active · 0'), findsOneWidget);
    expect(find.text('Archived · 2'), findsOneWidget);
    final archived = await booth.events.findById(SeedIds.active);
    expect(archived!.status, EventStatus.archived);
    expect(archived.templates.revisionIds, hasLength(2), reason: 'kept');

    await tapText(tester, 'Archived · 2');
    await tester.tap(
      find.descendant(of: card('Office party'), matching: find.text('Reopen')),
    );
    await tester.pumpAndSettle();
    expect(find.text('“Office party” is back in Drafts.'), findsOneWidget);
    expect(find.text('Drafts · 3'), findsOneWidget);
  });

  testWidgets('archived events are read-only until reopened', (tester) async {
    useViewport(tester, TabletViewport.ipadLandscape);
    await pumpApp(
      tester,
      location: RoutePaths.event(SeedIds.archived),
      seed: (db) => seedEvents(db),
    );
    final title = tester.widget<TextField>(find.byType(TextField).first);
    expect(title.enabled, isFalse);
    expect(button(tester, 'Save').onPressed, isNull);
    expect(button(tester, 'Save').disabledReason, EventCopy.archivedReadOnly);

    await tapText(tester, 'Reopen as draft');
    expect(find.text('Draft'), findsWidgets);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).enabled,
      isTrue,
    );
  });

  testWidgets('leaving with unsaved changes asks first', (tester) async {
    useViewport(tester, TabletViewport.ipadLandscape);
    final booth = await pumpApp(
      tester,
      location: RoutePaths.events,
      seed: (db) => seedEvents(db),
    );
    await tapText(tester, 'Drafts · 1');
    await tester.tap(
      find.descendant(of: card('Spring fair'), matching: find.text('Edit')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Summer fair');
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);

    await tapText(tester, 'Events');
    expect(find.text('Discard your changes?'), findsOneWidget);
    await tapText(tester, 'Keep editing');
    expect(find.byType(EventEditorScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Discard your changes?'), findsOneWidget);
    await tapText(tester, 'Discard');
    expect(find.byType(EventEditorScreen), findsNothing);
    expect(find.byType(EventsScreen), findsOneWidget);
    expect((await booth.events.findById(SeedIds.draft))!.title, 'Spring fair');
  });

  testWidgets('invalid settings cannot be saved; a draft without a fitting '
      'template cannot be activated', (tester) async {
    useViewport(tester, TabletViewport.ipadLandscape);
    await pumpApp(tester, location: RoutePaths.newEvent, seed: seedTemplates);
    expect(find.text('Fix before saving'), findsOneWidget);
    expect(find.text('Give the event a title.'), findsWidgets);
    expect(button(tester, 'Save').onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'Gala');
    await tester.pumpAndSettle();
    expect(
      find.text('Needed before this event can be activated'),
      findsOneWidget,
    );
    expect(find.text('Choose at least one template.'), findsOneWidget);
    await tapText(tester, 'Save');
    expect(button(tester, 'Activate event').onPressed, isNull);
    expect(
      button(tester, 'Activate event').disabledReason,
      'First fix what is listed at the top.',
    );

    // Three photo slots, but the event takes three photos only after a
    // change: until then the mismatch blocks activation.
    await tapText(tester, 'Templates');
    await tester.ensureVisible(buttonNear('Three-up square', 'Add'));
    await tester.tap(buttonNear('Three-up square', 'Add'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        '“Three-up square” has 3 photo slots but the event takes 3 photos '
        'per session.',
      ),
      findsNothing,
    );
    await tapText(tester, 'Camera');
    await tapLabel(tester, 'Fewer photos');
    expect(
      find.text(
        '“Three-up square” has 3 photo slots but the event takes 2 photos '
        'per session.',
      ),
      findsOneWidget,
    );
  });

  group('launch checks', () {
    testWidgets('a draft is blocked; the camera, free space, renderer and '
        'template checks run', (tester) async {
      useViewport(tester, TabletViewport.ipadLandscape);
      await pumpApp(
        tester,
        location: RoutePaths.preflight(SeedIds.draft),
        seed: (db) => seedEvents(db),
      );
      expect(find.byType(PreflightScreen), findsOneWidget);
      expect(find.textContaining('checks block the launch'), findsOneWidget);
      expect(
        find.text(
          'This event is a draft. Activate it once its templates and '
          'settings are complete.',
        ),
        findsOneWidget,
      );
      expect(find.text('Choose at least one template.'), findsOneWidget);
      // Every check is made; the tablet is not locked to the app, which
      // only warns.
      expect(find.text('Not yet available'), findsNothing);
      expect(find.text('Passed'), findsWidgets);
      expect(
        find.text(
          'Camera access is allowed and the tablet has a front camera. '
          'Diagnostics > Camera test shows its picture and saves a test '
          'photo.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('At least 1 GB free. Diagnostics shows the exact amount.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'A test page rendered at full print size as JPEG; nothing was '
          'saved.',
        ),
        findsOneWidget,
      );
      expect(find.text('No templates to check yet.'), findsOneWidget);
      expect(button(tester, 'Start Booth Mode').onPressed, isNull);

      await tester.tap(find.text('Start Booth Mode'));
      await tester.pump();
      expect(find.textContaining('checks block the launch.'), findsWidgets);
    });

    testWidgets('an orientation mismatch only warns', (tester) async {
      useViewport(tester, TabletViewport.ipadLandscape);
      await pumpApp(
        tester,
        location: RoutePaths.preflight(SeedIds.active),
        probe: FakeCapabilityProbe.allReady(),
        seed: (db) => seedEvents(db),
      );
      // The event prefers portrait; the tablet is landscape.
      expect(find.text('Warning'), findsOneWidget);
      expect(find.text('Ready to start'), findsOneWidget);
    });

    testWidgets('with every check passing, Start Booth Mode locks the tablet '
        'to the guest screens', (tester) async {
      useViewport(tester, TabletViewport.ipadPortrait);
      final booth = await pumpApp(
        tester,
        probe: FakeCapabilityProbe.allReady(),
        seed: (db) => seedEvents(db),
      );
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.text('Hannah & Theo’s wedding'), findsWidgets);
      await tapText(tester, 'Start Booth');
      expect(find.byType(PreflightScreen), findsOneWidget);
      expect(find.text('Ready to start'), findsOneWidget);
      await tapText(tester, 'Start Booth Mode');
      expect(find.byType(BoothScreen), findsOneWidget);
      expect(booth.accessState.phase, AccessPhase.booth);
      expect((await booth.settings.load()).boothEventId, SeedIds.active);
    });
  });

  group('settings', () {
    testWidgets('camera, output and orientation defaults shape new events', (
      tester,
    ) async {
      useViewport(tester, TabletViewport.ipadLandscape);
      final booth = await pumpApp(
        tester,
        location: RoutePaths.settingsSection('camera'),
      );
      await tapText(tester, 'Rear camera');
      await tapText(tester, 'Mirror saved photos');
      booth.router.go(RoutePaths.settingsSection('output'));
      await tester.pumpAndSettle();
      await tapText(tester, 'PNG');
      booth.router.go(RoutePaths.settingsSection('booth'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Landscape');

      final defaults = (await booth.settings.load()).profile.defaults;
      expect(defaults.lens, CameraLens.back);
      expect(defaults.mirrorOutput, isTrue);
      expect(defaults.output.format, OutputFormat.png);
      expect(defaults.orientation, GuestOrientationPreference.landscape);

      booth.router.go(RoutePaths.newEvent);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Defaults');
      await tapText(tester, 'Save');
      final saved = (await storedEvents(booth)).single;
      expect(saved.capture.lens, CameraLens.back);
      expect(saved.capture.mirrorOutput, isTrue);
      expect(saved.capture.orientation, GuestOrientationPreference.landscape);
      expect(saved.output.format, OutputFormat.png);
    });

    testWidgets('the booth name, the PIN and the recovery code can be '
        'changed', (tester) async {
      useViewport(tester, TabletViewport.ipadLandscape);
      final booth = await pumpApp(
        tester,
        location: RoutePaths.settingsSection('booth'),
      );
      await tester.enterText(find.byType(TextField).first, 'Foyer');
      await tester.pumpAndSettle();
      await tapText(tester, 'Save name');
      expect((await booth.settings.load()).profile.name, 'Foyer');

      await tapText(tester, 'Change PIN');
      await enterPin(tester, testPin);
      await enterPin(tester, '905172');
      await enterPin(tester, '905172');
      expect(find.text('The new PIN is in use.'), findsOneWidget);

      final before = (await booth.access.read()).recoveryVerifier;
      await tapText(tester, 'New recovery code');
      await enterPin(tester, '905172');
      expect(find.text(AccessCopy.recoveryCodeTitle), findsOneWidget);
      await tapText(tester, AccessCopy.recoveryCodeStored);
      await tapText(tester, 'Done');
      expect((await booth.access.read()).recoveryVerifier, isNot(before));

      await tapText(tester, 'Lock the Studio now');
      expect(find.byType(UnlockScreen), findsOneWidget);
      await enterPin(tester, testPin);
      expect(find.text(AccessCopy.wrongPin(4)), findsOneWidget);
      await enterPin(tester, '905172');
      expect(find.byType(UnlockScreen), findsNothing);
    });
  });
}
