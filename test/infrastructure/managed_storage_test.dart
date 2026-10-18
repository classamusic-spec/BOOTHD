// Managed files setup (M03): the private directory layout and the write
// probe behind the storage launch check.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/repositories/storage_errors.dart';
import 'package:porcelain_photo_booth/domain/services/booth_capabilities.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/managed_storage.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('managed_storage_test');
  });

  tearDown(() async {
    if (root.existsSync()) {
      // Restore permissions changed by a test before deleting.
      await Process.run('chmod', ['-R', 'u+w', root.path]);
      await root.delete(recursive: true);
    }
  });

  test('prepare creates every managed area, idempotently', () async {
    final storage = FileManagedStorage(root: () async => root);
    await storage.prepare();
    await storage.prepare();
    final names = root
        .listSync()
        .whereType<Directory>()
        .map((d) => d.uri.pathSegments.where((s) => s.isNotEmpty).last)
        .toSet();
    expect(names, {
      'database',
      'originals',
      'outputs',
      'templates',
      'assets',
      'staging',
    });
    expect(
      (await storage.databaseFile()).path,
      '${root.path}/database/porcelain_booth.sqlite',
    );
  });

  test(
    'the write probe round-trips a file and leaves nothing behind',
    () async {
      final storage = FileManagedStorage(root: () async => root);
      await storage.prepare();
      expect(await storage.probeWrite(), isA<CapabilityReady>());
      final staging = await storage.directory(ManagedArea.staging);
      expect(staging.listSync(), isEmpty);
    },
  );

  test('an unwritable area is reported, not assumed', () async {
    if (Platform.isWindows) return;
    final storage = FileManagedStorage(root: () async => root);
    await storage.prepare();
    final staging = await storage.directory(ManagedArea.staging);
    await Process.run('chmod', ['a-w', staging.path]);
    final whoAmI = await Process.run('id', ['-u']);
    final isRoot = (whoAmI.stdout as String).trim() == '0';
    final result = await storage.probeWrite();
    if (isRoot) {
      // Root ignores directory permissions; nothing to assert here.
      expect(result, isA<CapabilityStatus>());
    } else {
      expect(result, isA<CapabilityProblem>());
      expect((result as CapabilityProblem).code, 'STORAGE_NOT_WRITABLE');
    }
  });

  test('an unusable root fails preparation with a code, no path', () async {
    final file = File('${root.path}/not-a-directory')..writeAsStringSync('x');
    final storage = FileManagedStorage(root: () async => Directory(file.path));
    await expectLater(
      storage.prepare(),
      throwsA(
        isA<ManagedStorageException>().having(
          (e) => e.toString(),
          'text',
          'ManagedStorageException(STORAGE_UNAVAILABLE)',
        ),
      ),
    );
  });
}
