// ADR-0018: the browser's file system (an index in memory over a blob
// store) follows dart:io's rules, survives being opened again, and runs
// the booth's real stores: managed storage, atomic writes and camera
// originals with their checks.
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/services/booth_capabilities.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/atomic_file_writer.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/blob_file_system.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/managed_storage.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/original_store.dart';

import '../support/fakes.dart';
import '../support/test_database.dart';

Uint8List _bytes(int n, [int seed = 1]) =>
    Uint8List.fromList(List.generate(n, (i) => (i * 7 + seed) % 256));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemoryBlobStore store;
  late BlobFileSystem fs;

  setUp(() async {
    store = MemoryBlobStore();
    fs = await BlobFileSystem.open(store);
  });

  group('dart:io rules', () {
    test('a file needs its folder; recursive create makes it', () async {
      final file = fs.file('/booth/a/b.bin');
      await expectLater(
        file.writeAsBytes(_bytes(4)),
        throwsA(isA<io.FileSystemException>()),
      );
      await fs.directory('/booth/a').create(recursive: true);
      await file.writeAsBytes(_bytes(4));
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), 4);
      expect(await file.readAsBytes(), _bytes(4));
      await expectLater(
        fs.directory('/x/y').create(),
        throwsA(isA<io.FileSystemException>()),
        reason: 'two missing levels need recursive',
      );
    });

    test(
      'rename replaces a file and moves a folder with its contents',
      () async {
        await fs.directory('/r/in/deep').create(recursive: true);
        await fs.file('/r/in/deep/x.txt').writeAsString('x');
        await fs.file('/r/one.txt').writeAsString('one');
        await fs.file('/r/two.txt').writeAsString('two');

        final renamed = await fs.file('/r/one.txt').rename('/r/two.txt');
        expect(await renamed.readAsString(), 'one');
        expect(fs.file('/r/one.txt').existsSync(), isFalse);

        await fs.directory('/r/in').rename('/r/out');
        expect(fs.directory('/r/in').existsSync(), isFalse);
        expect(await fs.file('/r/out/deep/x.txt').readAsString(), 'x');
      },
    );

    test('deleting a full folder needs recursive; listing is sorted', () async {
      await fs.directory('/d/sub').create(recursive: true);
      await fs.file('/d/b.txt').writeAsString('b');
      await fs.file('/d/a.txt').writeAsString('a');
      expect(
        [for (final e in fs.directory('/d').listSync()) e.path],
        ['/d/a.txt', '/d/b.txt', '/d/sub'],
      );
      expect(
        fs.directory('/d').listSync().whereType<io.Directory>(),
        hasLength(1),
      );
      await expectLater(
        fs.directory('/d').delete(),
        throwsA(isA<io.FileSystemException>()),
      );
      await fs.directory('/d').delete(recursive: true);
      expect(fs.directory('/d').existsSync(), isFalse);
      expect(fs.file('/d/a.txt').existsSync(), isFalse);
    });

    test('a failed write changes nothing', () async {
      await fs.directory('/q').create();
      await fs.file('/q/f').writeAsBytes(_bytes(3));
      store.failNextWrite = 'QuotaExceededError';
      await expectLater(
        fs.file('/q/f').writeAsBytes(_bytes(9, 2)),
        throwsA(isA<io.FileSystemException>()),
      );
      expect(fs.file('/q/f').lengthSync(), 3);
      expect(await fs.file('/q/f').readAsBytes(), _bytes(3));
    });

    test('everything is there when opened again', () async {
      await fs.directory('/p/q').create(recursive: true);
      await fs.file('/p/q/f.bin').writeAsBytes(_bytes(10));
      final again = await BlobFileSystem.open(store);
      expect(again.directory('/p/q').existsSync(), isTrue);
      expect(again.file('/p/q/f.bin').lengthSync(), 10);
      expect(await again.file('/p/q/f.bin').readAsBytes(), _bytes(10));
    });
  });

  group('the booth stores on it', () {
    late Directory root;
    late FileManagedStorage storage;

    setUp(() async {
      root = fs.directory('/booth');
      await root.create();
      storage = FileManagedStorage(root: () async => root);
      await storage.prepare();
    });

    test(
      'managed storage prepares every area and passes its write check',
      () async {
        for (final area in ManagedArea.values) {
          expect(
            fs.directory('/booth/${area.directoryName}').existsSync(),
            isTrue,
            reason: area.name,
          );
        }
        expect(await storage.probeWrite(), isA<CapabilityReady>());
      },
    );

    test('an atomic write commits once and verifies what it wrote', () async {
      final writer = await storage.writer();
      final destination = fs.file('/booth/outputs/x.png');
      await writer.write(destination, _bytes(100));
      expect(await destination.readAsBytes(), _bytes(100));
      expect(
        fs.directory('/booth/staging').listSync(),
        isEmpty,
        reason: 'no staged file left behind',
      );
      await expectLater(
        writer.write(destination, _bytes(5)),
        throwsA(
          isA<AtomicWriteException>().having(
            (e) => e.reason,
            'reason',
            AtomicWriteFailure.destinationExists,
          ),
        ),
      );
    });

    test('a camera original is checked, stored and read back', () async {
      final db = memoryDatabase(clock: FakeClock());
      addTearDown(db.close);
      final originals = OriginalStore(
        database: db,
        root: () async => root,
        writer: storage.writer,
        clock: FakeClock(),
      );
      final photo = io.File(
        'test_assets/input_photos/exif_orientation_1_640x480.jpg',
      ).readAsBytesSync();
      final still = await originals.commit(
        id: 'web-1',
        bytes: photo,
        context: CaptureContext(
          lens: CameraLens.front,
          sensorOrientationDegrees: 270,
          mirrorPreviewRequested: true,
          mirrorOutputRequested: false,
          capturedAtUtc: DateTime.utc(2026, 10, 22, 20),
          origin: CaptureOrigin.session,
        ),
      );
      expect(still.relativePath, 'originals/web-1.jpg');
      expect(fs.file('/booth/originals/web-1.jpg').existsSync(), isTrue);
      expect(await originals.read(still), photo);
      final again = await BlobFileSystem.open(store);
      expect(
        await again.file('/booth/originals/web-1.jpg').readAsBytes(),
        photo,
      );
    });
  });
}
