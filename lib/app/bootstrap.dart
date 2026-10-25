import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart';

import '../core/design_system/bundled_licences.dart';
import '../core/diagnostics/error_reporting.dart';
import 'platform_bindings.dart';
import 'restartable_app.dart';

/// Starts the app inside [RestartableApp]'s provider scope, after preparing
/// the platform, sending uncaught errors to the sanitized log and
/// registering the bundled fonts' licences.
///
/// [overrides] is the composition root's hook, called once the platform is
/// ready: later milestones bind domain service interfaces to their
/// infrastructure adapters here, and tests bind fakes the same way
/// (ADR-0005).
Future<void> bootstrap({
  List<Override> Function() overrides = _noOverrides,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  // The browser opens its file storage first (ADR-0018); tablets need
  // nothing.
  await preparePlatform();
  reportErrorsSafely();
  registerBundledLicences();
  runApp(RestartableApp(overrides: overrides()));
}

List<Override> _noOverrides() => const [];
