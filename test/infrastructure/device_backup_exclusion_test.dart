// ADR-0009, ADR-0016: the booth's files stay out of the tablet's own
// backups. On iPadOS every start marks the storage root excluded from
// iCloud and computer backups through the app's channel (Android's
// manifest does the same for Android; permission_audit_test.dart). A
// failure is logged and never stops the booth.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/diagnostics/safe_log.dart';
import 'package:porcelain_photo_booth/infrastructure/device/platform_device_storage.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/managed_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('porcelain/device_storage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('porcelain_root_'));
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    root.deleteSync(recursive: true);
  });

  test('every start asks the tablet to leave the storage root out of its '
      'backups', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    final storage = FileManagedStorage(
      root: () async => root,
      keepOutOfDeviceBackups: const PlatformDeviceStorage().excludeFromBackup,
    );
    await storage.prepare();
    await storage.prepare();
    expect(calls, hasLength(2));
    expect(calls.first.method, 'excludeFromBackup');
    expect(calls.first.arguments, {'path': root.path});
  });

  test('a tablet that refuses is logged, and the booth still starts', () async {
    final lines = <String>[];
    final sink = SafeLog.sink;
    SafeLog.sink = lines.add;
    addTearDown(() => SafeLog.sink = sink);
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => throw PlatformException(code: 'unavailable'),
    );
    final storage = FileManagedStorage(
      root: () async => root,
      keepOutOfDeviceBackups: const PlatformDeviceStorage().excludeFromBackup,
    );
    await storage.prepare();
    expect(Directory('${root.path}/database').existsSync(), isTrue);
    expect(lines.first, contains('device backup exclusion'));
    expect(lines.join('\n'), isNot(contains(root.path)));
  });
}
