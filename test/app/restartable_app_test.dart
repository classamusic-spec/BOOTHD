// ADR-0016: a staged restore is swapped in by starting the app again. The
// old scope is disposed (services stop, the database closes) and the new
// one is created only once every tracked connection has closed, so the
// restore never replaces a database file still in use.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/app/restartable_app.dart';
import 'package:porcelain_photo_booth/core/di/service_providers.dart';

final _starts = <int>[];
final _stops = <int>[];
final _closing = <Completer<void>>[];

/// Off once a test's checks are done: the framework then takes the tree
/// down, and a close tracked then would outlive the test (the list of
/// connections closing is the app's, shared by every test here).
var _tracking = true;

/// Stands in for the database: each scope opens one, and closing it is
/// tracked and finishes only when the test says so.
final _connectionProvider = Provider<int>((ref) {
  final id = _starts.length + 1;
  _starts.add(id);
  ref.onDispose(() {
    _stops.add(id);
    if (!_tracking) return;
    final close = Completer<void>();
    _closing.add(close);
    DatabaseClosing.track(close.future);
  });
  return id;
});

class _Probe extends ConsumerWidget {
  const _Probe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(_connectionProvider);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        onTap: () => unawaited(ref.read(appRestartProvider)()),
        child: Text('connection $id'),
      ),
    );
  }
}

void main() {
  setUp(() {
    _tracking = true;
    _starts.clear();
    _stops.clear();
    _closing.clear();
  });

  testWidgets('starting again disposes the old scope and waits for its '
      'database to close before starting a new one', (tester) async {
    await tester.pumpWidget(
      const RestartableApp(overrides: [], child: _Probe()),
    );
    expect(find.text('connection 1'), findsOneWidget);

    await tester.tap(find.text('connection 1'));
    await tester.pump();
    await tester.pump();
    expect(_stops, [1], reason: 'the old scope was disposed');
    expect(find.textContaining('connection'), findsNothing);
    expect(_starts, [1], reason: 'nothing starts while the database closes');

    _closing.single.complete();
    await tester.pump();
    await tester.pump();
    expect(find.text('connection 2'), findsOneWidget);
    expect(_starts, [1, 2]);
    _tracking = false;
  });

  testWidgets('a second request while stopping is ignored', (tester) async {
    await tester.pumpWidget(
      const RestartableApp(overrides: [], child: _Probe()),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(_Probe)),
    );
    final restart = container.read(appRestartProvider);
    unawaited(restart());
    unawaited(restart());
    await tester.pump();
    await tester.pump();
    _closing.single.complete();
    await tester.pump();
    await tester.pump();
    expect(_starts, [1, 2], reason: 'one new scope');
    expect(find.text('connection 2'), findsOneWidget);
    _tracking = false;
  });

  testWidgets('a connection that fails to close does not stop the app '
      'starting again', (tester) async {
    await tester.pumpWidget(
      const RestartableApp(overrides: [], child: _Probe()),
    );
    await tester.tap(find.text('connection 1'));
    await tester.pump();
    await tester.pump();
    _closing.single.completeError(StateError('close failed'));
    await tester.pump();
    await tester.pump();
    expect(find.text('connection 2'), findsOneWidget);
    _tracking = false;
  });
}
