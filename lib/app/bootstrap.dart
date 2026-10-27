import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart';

import '../core/design_system/bundled_licences.dart';
import '../core/diagnostics/error_reporting.dart';
import 'platform_bindings.dart';
import 'platform_startup.dart';
import 'providers.dart';
import 'restartable_app.dart';

/// Displays startup immediately, including a retryable storage error if
/// browser storage cannot be opened before the production services exist.
void startApplication() {
  _initialize();
  runApp(
    PlatformStartup(
      prepare: preparePlatform,
      start: () => RestartableApp(overrides: productionOverrides()),
    ),
  );
}

/// Starts the app inside [RestartableApp]'s provider scope, after sending
/// uncaught errors to the sanitized log and registering the bundled fonts'
/// licences.
///
/// [overrides] is the composition root's hook: later milestones bind domain
/// service interfaces to their infrastructure adapters here, and tests bind
/// fakes the same way (ADR-0005).
void bootstrap({List<Override> overrides = const []}) {
  _initialize();
  runApp(RestartableApp(overrides: overrides));
}

void _initialize() {
  WidgetsFlutterBinding.ensureInitialized();
  reportErrorsSafely();
  registerBundledLicences();
}
