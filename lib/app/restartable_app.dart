import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../core/di/service_providers.dart';
import 'app.dart';

/// Database connections being closed, so a restart can wait for them: a
/// staged restore may replace the database file only once nothing has it
/// open (M10, ADR-0016).
abstract final class DatabaseClosing {
  static final _pending = <Future<void>>[];

  /// Records a connection's [close].
  static void track(Future<void> close) {
    _pending.add(close);
    unawaited(
      close
          // A failure to close is [settled]'s to absorb, not the zone's.
          .then<void>((_) {}, onError: (Object _) {})
          .whenComplete(() => _pending.remove(close)),
    );
  }

  /// Completes when every tracked connection has closed.
  static Future<void> settled() async {
    while (_pending.isNotEmpty) {
      try {
        await Future.wait(List.of(_pending));
      } on Object {
        // A connection that failed to close is closed as far as it will be.
        _pending.clear();
      }
    }
  }
}

/// The root of the app: one [ProviderScope] that [appRestartProvider]
/// replaces with a fresh one. The old scope is disposed first (every
/// service stops, the database closes), then the new one starts exactly
/// as a cold start does: storage is prepared (a staged restore is swapped
/// in), the database opens and startup runs.
class RestartableApp extends StatefulWidget {
  const RestartableApp({
    super.key,
    required this.overrides,
    this.child = const PorcelainApp(),
  });

  final List<Override> overrides;

  /// The app inside each scope.
  final Widget child;

  @override
  State<RestartableApp> createState() => _RestartableAppState();
}

class _RestartableAppState extends State<RestartableApp> {
  var _scope = UniqueKey();
  var _stopped = false;

  Future<void> _restart() async {
    if (_stopped) return;
    setState(() => _stopped = true);
    await WidgetsBinding.instance.endOfFrame;
    await DatabaseClosing.settled();
    if (!mounted) return;
    setState(() {
      _stopped = false;
      _scope = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_stopped) {
      // A moment without the app while its services stop.
      return const ColoredBox(color: Color(0xFFF7F1E8));
    }
    return ProviderScope(
      key: _scope,
      overrides: [
        ...widget.overrides,
        appRestartProvider.overrideWithValue(_restart),
      ],
      child: widget.child,
    );
  }
}
