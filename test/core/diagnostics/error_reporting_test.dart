// AC-1007: errors nobody caught reach the device log only through
// SafeLog, cleaned of paths and numbers.
import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/diagnostics/error_reporting.dart';
import 'package:porcelain_photo_booth/core/diagnostics/safe_log.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('framework and uncaught errors are logged cleaned', () {
    final lines = <String>[];
    final sink = SafeLog.sink;
    final flutterHandler = FlutterError.onError;
    final dispatcher = PlatformDispatcher.instance;
    final platformHandler = dispatcher.onError;
    SafeLog.sink = lines.add;
    try {
      reportErrorsSafely();
      FlutterError.onError!(
        FlutterErrorDetails(
          exception: const FileSystemException(
            'Cannot open file',
            '/data/user/0/app/files/originals/guest.jpg',
          ),
          context: ErrorDescription('while saving a photo'),
        ),
      );
      final handled = dispatcher.onError!(
        StateError('number +1 415 555 0147 stuck'),
        StackTrace.empty,
      );
      expect(handled, isTrue, reason: 'nothing else prints it');
    } finally {
      FlutterError.onError = flutterHandler;
      dispatcher.onError = platformHandler;
      SafeLog.sink = sink;
    }
    expect(lines.first, contains('(while saving a photo)'));
    expect(lines.first, contains('FileSystemException'));
    expect(lines.join('\n'), isNot(contains('/data/user')));
    expect(lines.join('\n'), isNot(contains('555')));
    expect(
      lines.where((line) => line.contains('(uncaught): StateError')),
      hasLength(1),
    );
  });
}
