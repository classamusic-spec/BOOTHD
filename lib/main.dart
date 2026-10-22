import 'package:flutter/widgets.dart';

import 'app/bootstrap.dart';
import 'app/platform_bindings.dart';
import 'app/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The browser opens its file storage first (ADR-0018); tablets need
  // nothing.
  await preparePlatform();
  bootstrap(overrides: productionOverrides());
}
