import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/design_system/appearance.dart';
import 'package:porcelain_photo_booth/core/routing/route_paths.dart';
import 'package:porcelain_photo_booth/shared/operator_access/access_copy.dart';

import 'app_harness.dart';
import 'seed.dart';
import 'tablet_viewports.dart';

/// How to reach a screen.
final class ScreenSpec {
  const ScreenSpec(
    this.location, {
    this.startAs = StartAs.operator,
    this.seeded = false,
    this.boothEventId,
    this.then,
  });

  final String location;
  final StartAs startAs;

  /// Start with templates and an active, a draft and an archived event.
  final bool seeded;
  final String? boothEventId;

  /// Steps after the app starts, e.g. to reach a later setup step.
  final Future<void> Function(WidgetTester tester)? then;
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

Future<void> _toPrivacyStep(WidgetTester tester) => _tap(tester, 'Begin setup');

Future<void> _toPinStep(WidgetTester tester) async {
  await _toPrivacyStep(tester);
  await _tap(tester, 'Continue');
}

Future<void> _toRecoveryStep(WidgetTester tester) async {
  await _toPinStep(tester);
  await enterPin(tester, testPin);
  await enterPin(tester, testPin);
}

Future<void> _toBoothStep(WidgetTester tester) async {
  await _toRecoveryStep(tester);
  await _tap(tester, AccessCopy.recoveryCodeStored);
  await _tap(tester, 'Continue');
}

/// The editor tabs, by their `tab` query value.
const editorTabs = [
  'general',
  'templates',
  'capture',
  'guest',
  'output',
  'privacy',
];

/// Every implemented screen, by name.
final screens = <String, ScreenSpec>{
  'dashboard': const ScreenSpec(RoutePaths.dashboard),
  'dashboard with events': const ScreenSpec(RoutePaths.dashboard, seeded: true),
  'events': const ScreenSpec('/studio/events', seeded: true),
  'events empty': const ScreenSpec('/studio/events'),
  for (final tab in editorTabs)
    'event $tab': ScreenSpec(
      RoutePaths.event(SeedIds.active, tab: tab),
      seeded: true,
    ),
  'event draft': ScreenSpec(RoutePaths.event(SeedIds.draft), seeded: true),
  'event archived': ScreenSpec(
    RoutePaths.event(SeedIds.archived),
    seeded: true,
  ),
  'new event': const ScreenSpec(RoutePaths.newEvent),
  'new event templates empty': const ScreenSpec(
    '${RoutePaths.newEvent}?tab=templates',
  ),
  'preflight': ScreenSpec(RoutePaths.preflight(SeedIds.active), seeded: true),
  'preflight draft': ScreenSpec(
    RoutePaths.preflight(SeedIds.draft),
    seeded: true,
  ),
  'templates': const ScreenSpec('/studio/templates'),
  'gallery': const ScreenSpec('/studio/gallery'),
  'settings': const ScreenSpec('/studio/settings'),
  'settings appearance': const ScreenSpec(
    '/studio/settings?section=appearance',
  ),
  'settings camera': const ScreenSpec('/studio/settings?section=camera'),
  'settings output': const ScreenSpec('/studio/settings?section=output'),
  'settings booth': const ScreenSpec('/studio/settings?section=booth'),
  'settings about': const ScreenSpec('/studio/settings?section=about'),
  'diagnostics': const ScreenSpec('/studio/diagnostics'),
  'guest preview': const ScreenSpec('/preview/guest-welcome'),
  'not found': ScreenSpec(
    RoutePaths.dashboard,
    then: (tester) async {
      routerOf(tester).go('/no-such-page');
      await tester.pumpAndSettle();
    },
  ),
  'component gallery': const ScreenSpec('/dev/components'),
  'setup welcome': const ScreenSpec('/', startAs: StartAs.setup),
  'setup privacy': const ScreenSpec(
    '/',
    startAs: StartAs.setup,
    then: _toPrivacyStep,
  ),
  'setup pin': const ScreenSpec('/', startAs: StartAs.setup, then: _toPinStep),
  'setup recovery code': const ScreenSpec(
    '/',
    startAs: StartAs.setup,
    then: _toRecoveryStep,
  ),
  'setup booth': const ScreenSpec(
    '/',
    startAs: StartAs.setup,
    then: _toBoothStep,
  ),
  'unlock': const ScreenSpec('/', startAs: StartAs.locked),
  'unlock recovery': ScreenSpec(
    '/',
    startAs: StartAs.locked,
    then: (tester) => _tap(tester, AccessCopy.forgotPin),
  ),
  'booth welcome': const ScreenSpec(
    RoutePaths.booth,
    startAs: StartAs.booth,
    seeded: true,
    boothEventId: SeedIds.active,
  ),
  'booth operator': const ScreenSpec(
    RoutePaths.boothOperator,
    startAs: StartAs.booth,
    seeded: true,
    boothEventId: SeedIds.active,
  ),
};

/// The component gallery shows a spinner and skeleton that never settle.
bool settles(String name) => name != 'component gallery';

/// Starts the app and brings up the screen called [name].
Future<void> show(
  WidgetTester tester,
  String name, {
  TabletViewport viewport = TabletViewport.ipadLandscape,
  AppearanceSettings appearance = const AppearanceSettings(),
  double pixelRatio = 2,
}) async {
  final spec = screens[name]!;
  useViewport(tester, viewport, pixelRatio: pixelRatio);
  await pumpApp(
    tester,
    location: spec.location,
    appearance: appearance,
    startAs: spec.startAs,
    boothEventId: spec.boothEventId,
    seed: spec.seeded ? (db) => seedEvents(db) : null,
    settle: settles(name),
  );
  if (!settles(name)) await tester.pump(const Duration(seconds: 1));
  await spec.then?.call(tester);
}
