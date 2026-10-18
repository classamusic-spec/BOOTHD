import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import 'app.dart';

/// Starts the app inside the root [ProviderScope].
///
/// [overrides] is the composition root's hook: later milestones bind domain
/// service interfaces to their infrastructure adapters here, and tests bind
/// fakes the same way (ADR-0005).
void bootstrap({List<Override> overrides = const []}) {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(overrides: overrides, child: const PorcelainApp()));
}
