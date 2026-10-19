import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart';

import '../core/design_system/bundled_licences.dart';
import '../core/diagnostics/error_reporting.dart';
import 'restartable_app.dart';

/// Starts the app inside [RestartableApp]'s provider scope, after sending
/// uncaught errors to the sanitized log and registering the bundled fonts'
/// licences.
///
/// [overrides] is the composition root's hook: later milestones bind domain
/// service interfaces to their infrastructure adapters here, and tests bind
/// fakes the same way (ADR-0005).
void bootstrap({List<Override> overrides = const []}) {
  WidgetsFlutterBinding.ensureInitialized();
  reportErrorsSafely();
  registerBundledLicences();
  runApp(RestartableApp(overrides: overrides));
}
