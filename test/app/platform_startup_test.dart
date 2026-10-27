import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/app/platform_startup.dart';
import 'package:porcelain_photo_booth/app/startup_screens.dart';
import 'package:porcelain_photo_booth/core/diagnostics/safe_log.dart';

void main() {
  testWidgets('storage opens before production services are constructed', (
    tester,
  ) async {
    final ready = Completer<void>();
    var starts = 0;
    await tester.pumpWidget(
      PlatformStartup(
        prepare: () => ready.future,
        start: () {
          starts++;
          return const MaterialApp(home: Text('App ready'));
        },
      ),
    );
    expect(find.byType(StartingScreen), findsOneWidget);
    expect(starts, 0);
    ready.complete();
    await tester.pumpAndSettle();
    expect(find.text('App ready'), findsOneWidget);
    expect(starts, 1);
  });

  testWidgets('storage failure is safe, retryable and never opens services', (
    tester,
  ) async {
    final sink = SafeLog.sink;
    SafeLog.sink = (_) {};
    addTearDown(() => SafeLog.sink = sink);
    var attempts = 0;
    var starts = 0;
    await tester.pumpWidget(
      PlatformStartup(
        prepare: () async {
          if (++attempts == 1) throw StateError('private file or secret');
        },
        start: () {
          starts++;
          return const MaterialApp(home: Text('App ready'));
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("The booth couldn't start"), findsOneWidget);
    expect(find.textContaining('private file or secret'), findsNothing);
    expect(starts, 0);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('App ready'), findsOneWidget);
    expect(attempts, 2);
    expect(starts, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing during storage open never starts the app', (
    tester,
  ) async {
    final ready = Completer<void>();
    var started = false;
    await tester.pumpWidget(
      PlatformStartup(
        prepare: () => ready.future,
        start: () {
          started = true;
          return const SizedBox();
        },
      ),
    );
    await tester.pumpWidget(const SizedBox());
    ready.complete();
    await tester.pump();
    expect(started, isFalse);
    expect(tester.takeException(), isNull);
  });
}
