import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// These tests exercise browser APIs, not text or widget goldens. The
/// native test font manifest isn't served by Flutter's browser runner.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await testMain();
}
