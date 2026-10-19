// AC-1002 and AC-1003 on the operator's screens: the kiosk lock guide says
// what the tablet reports and the tablet's own two ways to lock it (iPad:
// Guided Access and Single App Mode; Android: app pinning and lock task),
// without any control that pretends to turn a lock on; the launch checks
// warn about an unlocked tablet without blocking, and open the guide.
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/routing/route_paths.dart';
import 'package:porcelain_photo_booth/domain/services/kiosk_lock.dart';
import 'package:porcelain_photo_booth/features/settings/booth_settings.dart';
import 'package:porcelain_photo_booth/shared/kiosk/kiosk_copy.dart';
import 'package:porcelain_photo_booth/shared/kiosk/kiosk_guide.dart';

import '../support/app_harness.dart';
import '../support/seed.dart';
import '../support/tablet_viewports.dart';

Future<void> _tap(WidgetTester tester, String label) async {
  final target = find.bySemanticsLabel(label).last;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Android: not locked, how to pin or use lock task, and '
      'checking again', (tester) async {
    final semantics = tester.ensureSemantics();
    useViewport(tester, TabletViewport.androidLandscape);
    final booth = await pumpApp(
      tester,
      location: RoutePaths.settingsSection('kiosk'),
    );
    expect(find.byType(KioskGuide), findsOneWidget);
    expect(find.text('Guests can leave the booth app'), findsOneWidget);
    expect(find.text('Not locked'), findsOneWidget);
    expect(find.text(KioskCopy.explain(KioskLock.none)), findsOneWidget);
    expect(find.text(KioskCopy.turnOn(debugAndroid.platform)), findsOneWidget);
    expect(find.text('App pinning'), findsOneWidget);
    expect(find.text('Lock task (managed)'), findsOneWidget);
    expect(find.text('Guided Access'), findsNothing);
    // Nothing here claims to lock the tablet.
    for (final claim in ['Lock now', 'Pin now', 'Start kiosk', 'Turn on']) {
      expect(find.bySemanticsLabel(claim), findsNothing, reason: claim);
    }

    final reads = booth.kiosk.reads;
    booth.kiosk.lock = KioskLock.pinned;
    await _tap(tester, 'Check again');
    expect(booth.kiosk.reads, reads + 1);
    expect(find.text('Pinned to the booth app'), findsOneWidget);
    expect(find.text('Locked'), findsOneWidget);
    expect(find.textContaining('Ask for PIN before unpinning'), findsWidgets);
    expect(find.text(KioskCopy.turnOn(debugAndroid.platform)), findsNothing);
    semantics.dispose();
  });

  testWidgets('iPad: locked, with Guided Access and Single App Mode', (
    tester,
  ) async {
    useViewport(tester, TabletViewport.ipadLandscape);
    await pumpApp(
      tester,
      environment: releaseIpad,
      kiosk: KioskLock.guidedAccess,
      location: RoutePaths.settingsSection('kiosk'),
    );
    expect(find.text('Locked to the booth app'), findsOneWidget);
    expect(find.text('Locked'), findsOneWidget);
    expect(find.text('Guided Access'), findsOneWidget);
    expect(find.text('Single App Mode'), findsOneWidget);
    expect(find.text('App pinning'), findsNothing);
  });

  testWidgets('a tablet that does not say is not taken as locked', (
    tester,
  ) async {
    useViewport(tester, TabletViewport.ipadPortrait);
    await pumpApp(
      tester,
      kiosk: KioskLock.unknown,
      location: RoutePaths.settingsSection('kiosk'),
    );
    expect(find.text("The tablet didn't say"), findsOneWidget);
    expect(find.text('Unknown'), findsOneWidget);
    expect(find.text('Locked'), findsNothing);
  });

  testWidgets('Booth and security leads to the kiosk lock', (tester) async {
    final semantics = tester.ensureSemantics();
    useViewport(tester, TabletViewport.ipadLandscape);
    await pumpApp(tester, location: RoutePaths.settingsSection('booth'));
    final row = find.descendant(
      of: find.byType(BoothSettings),
      matching: find.text('Kiosk lock'),
    );
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.byType(KioskGuide), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the launch checks warn about an unlocked tablet, still allow '
      'the launch, and lead to the kiosk lock (AC-1003)', (tester) async {
    final semantics = tester.ensureSemantics();
    useViewport(tester, TabletViewport.ipadLandscape);
    final booth = await pumpApp(
      tester,
      location: RoutePaths.preflight(SeedIds.active),
      seed: (db) => seedEvents(db),
      seedTemplates: seedTemplateDocuments,
      settle: false,
    );
    await settleRendering(tester, rounds: 10);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Not locked: guests could leave the booth app. '
        '${KioskCopy.turnOn(debugAndroid.platform)}',
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Start Booth Mode'), findsOneWidget);
    expect(find.textContaining('checks block the launch'), findsNothing);

    final reads = booth.kiosk.reads;
    await _tap(tester, 'How to lock');
    expect(find.byType(KioskGuide), findsOneWidget, reason: 'in a sheet');
    expect(booth.kiosk.reads, reads + 1, reason: 'the guide reads it again');
    expect(find.text('App pinning'), findsOneWidget);
    semantics.dispose();
  });
}
