// Airplane mode (M10 audit; CLAUDE.md: "No network dependency for core
// capture/editor/events/export"). With texting off or the booth unpaired,
// a whole guest session and the Studio's screens (events, launch checks,
// the template editor, gallery, a session, settings, backup, diagnostics
// and the camera test) open no network connection at all: every attempt
// to create an HTTP client is recorded and refused. Services that are
// stand-ins here (the camera, the export) are tested on real files
// elsewhere; this test guards the app's own code against reaching for the
// network, such as an image or font loaded from the internet.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/features/booth/booth_copy.dart';
import 'package:porcelain_photo_booth/features/booth/guest_finished.dart';

import '../support/app_harness.dart';
import '../support/screen_catalog.dart';
import '../support/seed.dart';
import '../support/tablet_viewports.dart';

/// Every connection attempt, recorded and refused.
final class _NoNetwork extends HttpOverrides {
  final attempts = <String>[];

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts.add('HttpClient');
    throw const SocketException('airplane mode (test)');
  }
}

_NoNetwork _airplaneMode() {
  final network = _NoNetwork();
  final previous = HttpOverrides.current;
  HttpOverrides.global = network;
  addTearDown(() => HttpOverrides.global = previous);
  return network;
}

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _countdown(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
  await _frames(tester);
}

void main() {
  test('the stand-in airplane mode catches a connection attempt', () {
    final network = _airplaneMode();
    expect(HttpClient.new, throwsA(isA<SocketException>()));
    expect(network.attempts, ['HttpClient']);
  });

  testWidgets('a guest session needs no network at all', (tester) async {
    final network = _airplaneMode();
    useViewport(tester, TabletViewport.ipadPortrait);
    final booth = await pumpApp(
      tester,
      startAs: StartAs.booth,
      boothEventId: SeedIds.active,
      seed: (db) => seedEvents(db),
      seedTemplates: seedTemplateDocuments,
    );
    await tester.tap(find.bySemanticsLabel('Start').last);
    await _frames(tester);
    await _countdown(tester);
    await tester.pump(const Duration(seconds: 3));
    await _countdown(tester);
    await tester.tap(find.bySemanticsLabel(BoothCopy.keepThese).last);
    await _frames(tester);
    await settleRendering(tester);
    await _frames(tester);
    expect(find.byType(GuestFinished), findsOneWidget);
    expect(booth.exports.files, isNotEmpty, reason: 'the finished photo');
    expect(booth.stills.stills, hasLength(2), reason: 'both originals');
    expect(network.attempts, isEmpty);
    expect(booth.delivery.calls, isEmpty, reason: 'unpaired: no requests');
  });

  testWidgets("the Studio's screens need no network at all", (tester) async {
    final network = _airplaneMode();
    for (final name in [
      'dashboard with events',
      'events',
      'event general',
      'preflight',
      'templates library',
      'template editor',
      'gallery sessions',
      'session detail',
      'settings storage',
      'settings backup made',
      'settings kiosk',
      'diagnostics self-test',
      'camera test saved',
    ]) {
      await show(tester, name);
      expect(network.attempts, isEmpty, reason: name);
    }
  });
}
