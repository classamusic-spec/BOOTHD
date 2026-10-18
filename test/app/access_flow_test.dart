// AC-0301 (first-run PIN, verification, rate limit, no plaintext PIN) and
// AC-0305 (guest route guards against back and deep-route attempts),
// through the whole app.
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/access/access_controller.dart';
import 'package:porcelain_photo_booth/core/design_system/porcelain_theme.dart';
import 'package:porcelain_photo_booth/core/design_system/theme_profiles.dart';
import 'package:porcelain_photo_booth/core/routing/route_paths.dart';
import 'package:porcelain_photo_booth/domain/repositories/storage_errors.dart';
import 'package:porcelain_photo_booth/domain/services/operator_auth_service.dart';
import 'package:porcelain_photo_booth/domain/services/operator_secrets.dart';
import 'package:porcelain_photo_booth/features/booth/booth_operator_screen.dart';
import 'package:porcelain_photo_booth/features/booth/booth_welcome_screen.dart';
import 'package:porcelain_photo_booth/features/booth/hidden_operator_exit.dart';
import 'package:porcelain_photo_booth/features/dashboard/dashboard_screen.dart';
import 'package:porcelain_photo_booth/features/events/events_screen.dart';
import 'package:porcelain_photo_booth/features/onboarding/setup_screen.dart';
import 'package:porcelain_photo_booth/features/operator_access/unlock_screen.dart';
import 'package:porcelain_photo_booth/features/studio_shell/studio_shell.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';
import 'package:porcelain_photo_booth/infrastructure/database/database_connection.dart';
import 'package:porcelain_photo_booth/shared/operator_access/access_copy.dart';
import 'package:porcelain_photo_booth/shared/widgets/pin_pad.dart';

import '../support/app_harness.dart';
import '../support/fakes.dart';
import '../support/seed.dart';
import '../support/tablet_viewports.dart';
import '../support/test_database.dart';

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

/// Every text value stored in the booth database.
Future<String> databaseText(BoothDatabase db) async {
  final buffer = StringBuffer();
  for (final table in [
    'booth_profiles',
    'app_settings',
    'operator_access',
    'events',
    'event_templates',
    'templates',
    'template_revisions',
  ]) {
    for (final row in await db.customSelect('SELECT * FROM $table').get()) {
      buffer.writeln(row.data.values.join('|'));
    }
  }
  return buffer.toString();
}

/// Sends a deep link the way the platform would.
Future<void> platformPushRoute(WidgetTester tester, String location) async {
  final message = const JSONMethodCodec().encodeMethodCall(
    MethodCall('pushRouteInformation', {'location': location}),
  );
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    message,
    (_) {},
  );
  await tester.pumpAndSettle();
}

/// Holds the hidden operator corner for [duration].
Future<void> holdCorner(WidgetTester tester, Duration duration) async {
  final corner = tester.getCenter(find.byType(HiddenOperatorExit));
  final gesture = await tester.startGesture(corner);
  await tester.pump(duration);
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  group('first-run setup', () {
    testWidgets('creates the PIN, shows the recovery code once and opens '
        'the Studio', (tester) async {
      useViewport(tester, TabletViewport.ipadPortrait);
      final booth = await pumpApp(tester, startAs: StartAs.setup);
      expect(find.byType(SetupScreen), findsOneWidget);
      expect(find.text('Welcome'), findsOneWidget);

      await tapText(tester, 'Begin setup');
      expect(find.text('Everything stays on this tablet'), findsOneWidget);
      await tapText(tester, 'Continue');

      await enterPin(tester, '482916');
      expect(find.text(AccessCopy.confirmPinTitle), findsOneWidget);
      expect(booth.pins.value, isNull, reason: 'nothing stored before confirm');
      await enterPin(tester, '482916');

      expect(find.text(AccessCopy.recoveryCodeTitle), findsOneWidget);
      final groups = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? '')
          .where((text) => RegExp(r'^[0-9A-Z]{4}$').hasMatch(text))
          .toList();
      expect(groups, hasLength(4));
      final code = groups.join('-');

      // Continue says why it is unavailable until the code is confirmed.
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(find.text(AccessCopy.confirmStoredReason), findsWidgets);
      await tapText(tester, AccessCopy.recoveryCodeStored);
      await tapText(tester, 'Continue');

      expect(find.text('Name this booth'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Ballroom');
      await tapText(tester, 'Light Oak');
      await tapText(tester, 'Finish setup');

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(booth.accessState.phase, AccessPhase.operator);
      final theme = PorcelainTheme.of(
        tester.element(find.byType(DashboardScreen)),
      );
      expect(theme.profile, PorcelainThemeProfile.lightOak);

      final state = await booth.settings.load();
      expect(state.setupComplete, isTrue);
      expect(state.profile.name, 'Ballroom');
      expect(state.profile.appearance.profile, PorcelainThemeProfile.lightOak);

      // Only verifiers are stored: neither the PIN nor the code appears in
      // secure storage or anywhere in the database.
      final stored = '${booth.pins.value}\n${await databaseText(booth.db)}';
      expect(stored, isNot(contains('482916')));
      expect(stored, isNot(contains(code)));
      expect(stored, isNot(contains(RecoveryCodes.normalise(code)!)));
      expect((await booth.access.read()).recoveryVerifier, isNotNull);
      expect(await booth.auth.verifyRecoveryCode(code), isA<AccessGranted>());
    });

    testWidgets('refuses a guessable PIN and a mismatched confirmation', (
      tester,
    ) async {
      useViewport(tester, TabletViewport.ipadLandscape);
      final booth = await pumpApp(tester, startAs: StartAs.setup);
      await tapText(tester, 'Begin setup');
      await tapText(tester, 'Continue');

      await enterPin(tester, '123456');
      expect(find.text(AccessCopy.pinTooGuessable), findsOneWidget);
      expect(find.text(AccessCopy.choosePinTitle), findsOneWidget);

      await enterPin(tester, '482916');
      await enterPin(tester, '482917');
      expect(find.text(AccessCopy.pinMismatch), findsOneWidget);
      expect(find.text(AccessCopy.choosePinTitle), findsOneWidget);
      expect(booth.pins.value, isNull);
    });

    testWidgets('an interrupted setup starts again on the next launch', (
      tester,
    ) async {
      useViewport(tester, TabletViewport.ipadPortrait);
      final db = memoryDatabase();
      final pins = MemoryPinVerifierStore();
      await pumpApp(tester, startAs: StartAs.setup, database: db, pins: pins);
      await tapText(tester, 'Begin setup');
      await tapText(tester, 'Continue');
      await enterPin(tester, '482916');
      await enterPin(tester, '482916');
      expect(pins.value, isNotNull);

      // The app is killed here and launched again.
      await pumpApp(
        tester,
        startAs: StartAs.setup,
        database: db,
        pins: pins,
        alreadySetUp: true,
      );
      expect(find.byType(SetupScreen), findsOneWidget);
      expect(find.text('Welcome'), findsOneWidget);
    });
  });

  group('unlocking the Studio', () {
    testWidgets('a cold start asks for the PIN, then opens the page asked '
        'for', (tester) async {
      useViewport(tester, TabletViewport.ipadLandscape);
      await pumpApp(
        tester,
        startAs: StartAs.locked,
        location: RoutePaths.events,
      );
      expect(find.byType(UnlockScreen), findsOneWidget);
      expect(find.byType(StudioShell), findsNothing);
      await enterPin(tester, testPin);
      expect(find.byType(EventsScreen), findsOneWidget);
    });

    testWidgets('wrong PINs count down, then lock entry for a while', (
      tester,
    ) async {
      useViewport(tester, TabletViewport.ipadPortrait);
      final booth = await pumpApp(tester, startAs: StartAs.locked);
      for (var left = 4; left >= 1; left--) {
        await enterPin(tester, '000111');
        expect(find.text(AccessCopy.wrongPin(left)), findsOneWidget);
      }
      await enterPin(tester, '000111');
      expect(find.text(AccessCopy.lockedOut('0:30')), findsOneWidget);
      expect((await booth.access.read()).pinAttempts.failures, 5);

      // The keypad says why it does not respond, and nothing is checked.
      await tester.tap(find.bySemanticsLabel('4').last);
      await tester.pump();
      expect(find.text(AccessCopy.lockedReason('0:30')), findsWidgets);
      expect(tester.widget<PinPad>(find.byType(PinPad)).enabled, isFalse);

      await tester.pump(const Duration(seconds: 10));
      expect(find.text(AccessCopy.lockedOut('0:20')), findsOneWidget);
      booth.clock.advance(const Duration(seconds: 31));
      await tester.pump(const Duration(seconds: 21));
      await tester.pumpAndSettle();
      expect(tester.widget<PinPad>(find.byType(PinPad)).enabled, isTrue);

      await enterPin(tester, testPin);
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect((await booth.access.read()).pinAttempts.failures, 0);
    });

    testWidgets('a lockout is still there after a restart', (tester) async {
      useViewport(tester, TabletViewport.ipadPortrait);
      final first = await pumpApp(tester, startAs: StartAs.locked);
      for (var i = 0; i < 5; i++) {
        await enterPin(tester, '000111');
      }
      await pumpApp(
        tester,
        startAs: StartAs.locked,
        database: first.db,
        pins: first.pins,
        clock: first.clock,
        alreadySetUp: true,
      );
      expect(find.text(AccessCopy.lockedOut('0:30')), findsOneWidget);
    });

    testWidgets('Lock Studio returns to the PIN screen, and neither back nor '
        'a deep link gets past it', (tester) async {
      useViewport(tester, TabletViewport.ipadLandscape);
      final booth = await pumpApp(tester);
      await tester.tap(find.text(StudioShell.lockLabel));
      await tester.pumpAndSettle();
      expect(find.byType(UnlockScreen), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(UnlockScreen), findsOneWidget);

      booth.router.go(RoutePaths.gallery);
      await tester.pumpAndSettle();
      expect(find.byType(UnlockScreen), findsOneWidget);
      await platformPushRoute(tester, RoutePaths.settings);
      expect(find.byType(UnlockScreen), findsOneWidget);
      expect(find.byType(StudioShell), findsNothing);
    });

    testWidgets('a forgotten PIN is reset with the recovery code, which is '
        'then replaced', (tester) async {
      useViewport(tester, TabletViewport.ipadPortrait);
      final booth = await pumpApp(tester, startAs: StartAs.locked);
      await tapText(tester, AccessCopy.forgotPin);
      expect(find.text(AccessCopy.recoveryTitle), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'nope');
      await tester.pump();
      expect(find.text(AccessCopy.recoveryIncomplete), findsNothing);
      await tester.tap(find.text(AccessCopy.checkCode));
      await tester.pump();
      expect(find.text(AccessCopy.recoveryIncomplete), findsWidgets);

      await tester.enterText(
        find.byType(TextField),
        booth.recoveryCode!.toLowerCase(),
      );
      await tapText(tester, AccessCopy.checkCode);
      expect(find.text(AccessCopy.choosePinTitle), findsOneWidget);
      await enterPin(tester, '905172');
      await enterPin(tester, '905172');
      expect(find.text(AccessCopy.recoveryCodeTitle), findsOneWidget);
      await tapText(tester, AccessCopy.recoveryCodeStored);
      await tapText(tester, AccessCopy.recoveryDone);
      expect(find.byType(DashboardScreen), findsOneWidget);

      // The compact rail shows Lock as an icon with the same name.
      await tester.tap(find.bySemanticsLabel(StudioShell.lockLabel));
      await tester.pumpAndSettle();
      await enterPin(tester, testPin);
      expect(find.text(AccessCopy.wrongPin(4)), findsOneWidget);
      await enterPin(tester, '905172');
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('an unreadable PIN offers the recovery code instead', (
      tester,
    ) async {
      useViewport(tester, TabletViewport.ipadPortrait);
      final pins = MemoryPinVerifierStore();
      final db = memoryDatabase();
      await prepareBooth(
        db,
        pins: pins,
        clock: FakeClock(),
        startAs: StartAs.locked,
      );
      pins.failReads = true;
      await pumpApp(
        tester,
        startAs: StartAs.locked,
        database: db,
        pins: pins,
        alreadySetUp: true,
      );
      expect(find.text(AccessCopy.pinUnavailableTitle), findsOneWidget);
      expect(find.byType(PinPad), findsNothing);
      await tapText(tester, AccessCopy.useRecoveryCode);
      expect(find.text(AccessCopy.recoveryTitle), findsOneWidget);
    });
  });

  group('Booth Mode', () {
    Future<TestBooth> startBooth(WidgetTester tester) => pumpApp(
      tester,
      startAs: StartAs.booth,
      boothEventId: SeedIds.active,
      seed: (db) => seedEvents(db),
    );

    testWidgets("guests see the event's welcome in its own theme, and back "
        'or deep links never leave it', (tester) async {
      useViewport(tester, TabletViewport.ipadPortrait);
      final booth = await startBooth(tester);
      expect(find.byType(BoothWelcomeScreen), findsOneWidget);
      expect(find.text('Welcome, friends'), findsOneWidget);
      expect(
        PorcelainTheme.of(tester.element(find.text('Welcome, friends')))
            .profile,
        PorcelainThemeProfile.darkroomWalnut,
      );

      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(find.byType(BoothWelcomeScreen), findsOneWidget);

      for (final location in [
        RoutePaths.dashboard,
        RoutePaths.events,
        RoutePaths.newEvent,
        RoutePaths.event(SeedIds.active),
        RoutePaths.preflight(SeedIds.active),
        RoutePaths.templates,
        RoutePaths.gallery,
        RoutePaths.settingsSection('booth'),
        RoutePaths.diagnostics,
        RoutePaths.cameraTest,
        RoutePaths.guestPreview,
        RoutePaths.componentGallery,
        RoutePaths.setup,
        RoutePaths.unlock,
        '/no-such-page',
      ]) {
        booth.router.go(location);
        await tester.pumpAndSettle();
        expect(
          find.byType(BoothWelcomeScreen),
          findsOneWidget,
          reason: location,
        );
        expect(find.byType(StudioShell), findsNothing, reason: location);
      }
      await platformPushRoute(tester, RoutePaths.gallery);
      expect(find.byType(BoothWelcomeScreen), findsOneWidget);

      // Start explains, in guest-safe words, that sessions are not ready,
      // in the event's theme too.
      await tester.tap(find.bySemanticsLabel('Start'));
      await tester.pump();
      expect(find.text(BoothWelcomeScreen.notReadyMessage), findsOneWidget);
      expect(
        PorcelainTheme.of(
          tester.element(find.text(BoothWelcomeScreen.notReadyMessage)),
        ).profile,
        PorcelainThemeProfile.darkroomWalnut,
      );
      expect(booth.accessState.phase, AccessPhase.booth);
    });

    testWidgets('only a long hold on the hidden corner reaches the PIN, and '
        'only the PIN leaves Booth Mode', (tester) async {
      useViewport(tester, TabletViewport.ipadLandscape);
      final booth = await startBooth(tester);

      await tester.tap(find.byType(HiddenOperatorExit));
      await tester.pumpAndSettle();
      await holdCorner(tester, const Duration(seconds: 1));
      expect(find.byType(BoothWelcomeScreen), findsOneWidget);

      await holdCorner(tester, const Duration(milliseconds: 3100));
      expect(find.byType(BoothOperatorScreen), findsOneWidget);
      // Still the event's theme: a dim venue never gets a bright PIN pad.
      expect(
        PorcelainTheme.of(
          tester.element(
            find.text('Enter the operator PIN to manage the booth.'),
          ),
        ).profile,
        PorcelainThemeProfile.darkroomWalnut,
      );
      await enterPin(tester, '000111');
      expect(find.text(AccessCopy.wrongPin(4)), findsOneWidget);
      expect(find.text('Exit Booth Mode'), findsNothing);

      await enterPin(tester, testPin);
      expect(find.text('Booth unlocked'), findsOneWidget);
      await tapText(tester, 'Exit Booth Mode');
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(booth.accessState.phase, AccessPhase.operator);
      expect((await booth.settings.load()).boothEventId, isNull);
    });

    testWidgets('the PIN screen returns to guests when left alone', (
      tester,
    ) async {
      useViewport(tester, TabletViewport.ipadPortrait);
      await startBooth(tester);
      await holdCorner(tester, const Duration(milliseconds: 3100));
      expect(find.byType(BoothOperatorScreen), findsOneWidget);
      await tester.pump(BoothOperatorScreen.idleTimeout);
      await tester.pumpAndSettle();
      expect(find.byType(BoothWelcomeScreen), findsOneWidget);

      await holdCorner(tester, const Duration(milliseconds: 3100));
      await tapText(tester, 'Back to the guest screen');
      expect(find.byType(BoothWelcomeScreen), findsOneWidget);
    });

    testWidgets('a restart during Booth Mode returns to the guest welcome', (
      tester,
    ) async {
      useViewport(tester, TabletViewport.ipadPortrait);
      final first = await startBooth(tester);
      await pumpApp(
        tester,
        startAs: StartAs.booth,
        database: first.db,
        pins: first.pins,
        alreadySetUp: true,
        boothEventId: SeedIds.active,
      );
      expect(find.byType(BoothWelcomeScreen), findsOneWidget);
      expect(find.byType(UnlockScreen), findsNothing);
    });

    testWidgets('the hidden corner is not in the accessibility tree', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      useViewport(tester, TabletViewport.ipadPortrait);
      await startBooth(tester);
      final root = tester.getSemantics(find.byType(BoothWelcomeScreen));
      final actions = <String>[];
      void visit(SemanticsNode node) {
        final data = node.getSemanticsData();
        if (data.hasAction(SemanticsAction.tap) ||
            data.hasAction(SemanticsAction.longPress)) {
          actions.add(data.label);
        }
        node.visitChildren((child) {
          visit(child);
          return true;
        });
      }

      visit(root);
      expect(actions, ['Start']);
      semantics.dispose();
    });
  });

  group('startup problems', () {
    testWidgets('data from a newer app: plain words and a code, no retry, '
        'nothing changed', (tester) async {
      useViewport(tester, TabletViewport.ipadPortrait);
      final db = BoothDatabase(
        DatabaseConnection(
          NativeDatabase.memory(
            setup: (raw) {
              configureConnection(raw);
              raw.execute('PRAGMA user_version = 9');
            },
          ),
          closeStreamsSynchronously: true,
        ),
        ids: SequentialIds(),
        clock: FakeClock(),
      );
      await pumpApp(
        tester,
        startAs: StartAs.locked,
        database: db,
        alreadySetUp: true,
      );
      expect(find.text('This booth needs a newer app'), findsOneWidget);
      expect(find.text('Code: STORAGE_SCHEMA_NEWER'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
      expect(find.textContaining('Exception'), findsNothing);
    });

    testWidgets('unavailable storage can be retried', (tester) async {
      useViewport(tester, TabletViewport.ipadPortrait);
      final storage = FakeManagedStorage()
        ..prepareError = const ManagedStorageException('STORAGE_UNAVAILABLE');
      final booth = await pumpApp(
        tester,
        startAs: StartAs.locked,
        storage: storage,
      );
      expect(find.text("The tablet's storage isn't available"), findsOneWidget);
      expect(find.text('Code: STORAGE_UNAVAILABLE'), findsOneWidget);

      storage.prepareError = null;
      await tapText(tester, 'Try again');
      expect(find.byType(UnlockScreen), findsOneWidget);
      expect(booth.accessState.phase, AccessPhase.locked);
    });
  });
}
