// Camera originals (AC-0608, A-11): validated before they are stored,
// committed through a journal so a crash at any point leaves either nothing
// or a complete, recorded original, immutable once recorded, and still
// there, intact, after a restart.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/atomic_file_writer.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/managed_storage.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/original_store.dart';

import '../support/fakes.dart';
import '../support/test_database.dart';

Uint8List _fixture(String name) =>
    File('test_assets/input_photos/$name').readAsBytesSync();

final _upright = _fixture('exif_orientation_1_640x480.jpg');
final _turned = _fixture('exif_orientation_6_640x480.jpg');

final _context = CaptureContext(
  lens: CameraLens.front,
  sensorOrientationDegrees: 270,
  mirrorPreviewRequested: true,
  mirrorOutputRequested: false,
  capturedAtUtc: DateTime.utc(2026, 10, 18, 9, 30),
  deviceOrientation: CaptureOrientation.landscapeLeft,
  origin: CaptureOrigin.diagnostics,
);

/// Fails the first write with a full disk.
final class _FullDisk extends FileOperations {
  const _FullDisk();

  @override
  Future<void> writeAndFlush(File file, Uint8List bytes) async =>
      throw FileSystemException(
        'write failed',
        file.path,
        const OSError('No space left on device', 28),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late File databaseFile;
  late BoothDatabase db;
  late FileManagedStorage storage;
  late OriginalStore store;
  var operations = const FileOperations();

  OriginalStore storeOver(BoothDatabase database) => OriginalStore(
    database: database,
    root: () async => root,
    writer: () => storage.writer(operations: operations),
    clock: FakeClock(),
  );

  setUp(() async {
    root = Directory.systemTemp.createTempSync('porcelain_originals_');
    databaseFile = File('${root.path}/booth.sqlite');
    db = fileDatabase(databaseFile);
    storage = FileManagedStorage(root: () async => root);
    await storage.prepare();
    operations = const FileOperations();
    store = storeOver(db);
  });

  tearDown(() async {
    await db.close();
    root.deleteSync(recursive: true);
  });

  /// Every file under originals/ and staging/, relative to the root.
  List<String> files() => [
    for (final area in ['originals', 'staging'])
      if (Directory('${root.path}/$area').existsSync())
        ...Directory('${root.path}/$area')
            .listSync(recursive: true)
            .whereType<File>()
            .map((f) => f.path.substring(root.path.length + 1)),
  ]..sort();

  Future<List<String>> journal() async => [
    for (final row in await db.select(db.pendingOriginalCommits).get()) row.id,
  ];

  Matcher refusedFor(String reason) => throwsA(
    isA<OriginalCommitException>().having((e) => e.reason, 'reason', reason),
  );

  test('commits a validated original with its record', () async {
    final still = await store.commit(
      id: 'shot-1',
      bytes: _turned,
      context: _context,
    );

    expect(files(), ['originals/shot-1.jpg']);
    expect(
      File('${root.path}/originals/shot-1.jpg').readAsBytesSync(),
      _turned,
    );
    expect(still.relativePath, 'originals/shot-1.jpg');
    // The platform decoder applies EXIF orientation 6: 640x480 becomes
    // 480x640, and the raw tag is kept for the record (ADR-0007).
    expect((still.widthPx, still.heightPx), (480, 640));
    expect(still.exifOrientation, 6);
    expect(still.byteLength, _turned.length);
    expect(still.sha256, crypto.sha256.convert(_turned).toString());
    expect(still.lens, CameraLens.front);
    expect(still.sensorOrientationDegrees, 270);
    expect(still.deviceOrientation, CaptureOrientation.landscapeLeft);
    expect(still.mirrorPreviewRequested, isTrue);
    expect(still.mirrorOutputRequested, isFalse);
    expect(still.origin, CaptureOrigin.diagnostics);
    expect(await journal(), isEmpty, reason: 'the intent is cleared');
    expect(await store.listCommitted(), [still]);
    expect(await store.read(still), _turned);
  });

  test('the stored bytes are exactly what the camera produced', () async {
    // Output mirroring is applied once, when rendering (A-07): never to
    // the original, whatever the booth asked for.
    final mirrored = await store.commit(
      id: 'mirrored',
      bytes: _upright,
      context: CaptureContext(
        lens: CameraLens.front,
        sensorOrientationDegrees: 270,
        mirrorPreviewRequested: false,
        mirrorOutputRequested: true,
        capturedAtUtc: DateTime.utc(2026, 10, 18, 9, 31),
      ),
    );
    expect(mirrored.mirrorOutputRequested, isTrue);
    expect(await store.read(mirrored), _upright);
  });

  test('refuses images that are not complete JPEGs, leaving nothing', () async {
    for (final (bytes, reason) in [
      (Uint8List.fromList(List.filled(256, 1)), 'not-jpeg'),
      (Uint8List.sublistView(_upright, 0, _upright.length ~/ 2), 'truncated'),
      // Complete markers around a damaged body.
      (
        Uint8List.fromList([
          ..._upright.take(20),
          ...List.filled(400, 7),
          0xFF,
          0xD9,
        ]),
        'undecodable',
      ),
    ]) {
      await expectLater(
        store.commit(id: 'bad', bytes: bytes, context: _context),
        refusedFor(reason),
      );
    }
    expect(files(), isEmpty);
    expect(await journal(), isEmpty);
    expect(await store.listCommitted(), isEmpty);
  });

  test('accepts the zero padding some encoders write after the end', () async {
    final padded = Uint8List.fromList([..._upright, 0, 0, 0, 0]);
    final still = await store.commit(
      id: 'padded',
      bytes: padded,
      context: _context,
    );
    expect(await store.read(still), padded);
  });

  test('never overwrites an existing original', () async {
    await store.commit(id: 'same', bytes: _upright, context: _context);
    await expectLater(
      store.commit(id: 'same', bytes: _turned, context: _context),
      refusedFor('exists'),
    );
    expect(File('${root.path}/originals/same.jpg').readAsBytesSync(), _upright);
    expect(await store.listCommitted(), hasLength(1));
  });

  test('refuses ids that could escape the store', () async {
    for (final id in ['../escape', 'a/b', '', 'x' * 65, 'dot.dot']) {
      await expectLater(
        store.commit(id: id, bytes: _upright, context: _context),
        refusedFor('invalid-id'),
      );
    }
    expect(files(), isEmpty);
  });

  test('a full disk stores nothing and says so', () async {
    operations = const _FullDisk();
    await expectLater(
      store.commit(id: 'full', bytes: _upright, context: _context),
      refusedFor('no-space'),
    );
    expect(files(), isEmpty);
    expect(await journal(), isEmpty);
  });

  test('a failed record takes the file back', () async {
    await db.customStatement(
      'CREATE TEMP TRIGGER refuse_originals BEFORE INSERT ON original_photos '
      "BEGIN SELECT RAISE(ABORT, 'refused'); END",
    );
    await expectLater(
      store.commit(id: 'unrecorded', bytes: _upright, context: _context),
      refusedFor('record-failed'),
    );
    expect(files(), isEmpty, reason: 'a failed save never surfaces later');
    expect(await journal(), isEmpty);
  });

  test('a recorded original cannot be changed', () async {
    await store.commit(id: 'fixed', bytes: _upright, context: _context);
    await expectLater(
      db.customStatement(
        "UPDATE original_photos SET mirror_output = 1 WHERE id = 'fixed'",
      ),
      throwsA(anything),
    );
  });

  test('a new store on the same database and files lists and reads every '
      'original (app restart)', () async {
    final turned = await store.commit(
      id: 'b',
      bytes: _turned,
      context: _context,
    );
    await store.commit(
      id: 'a',
      bytes: _upright,
      context: CaptureContext(
        lens: CameraLens.back,
        sensorOrientationDegrees: 90,
        mirrorPreviewRequested: false,
        mirrorOutputRequested: false,
        capturedAtUtc: DateTime.utc(2026, 10, 18, 10),
      ),
    );
    await db.close();

    db = fileDatabase(databaseFile);
    await storage.prepare();
    final reopened = storeOver(db);
    expect((await reopened.reconcile()).changedAnything, isFalse);
    final listed = await reopened.listCommitted();
    expect(listed.map((s) => s.id), ['a', 'b'], reason: 'newest first');
    expect(listed.last, turned);
    expect(listed.last.deviceOrientation, CaptureOrientation.landscapeLeft);
    expect(listed.first.lens, CameraLens.back);
    expect(await reopened.read(listed.last), _turned);
    expect(await reopened.listCommitted(limit: 1), hasLength(1));
  });

  test('a changed or missing file fails its read-back check', () async {
    final still = await store.commit(
      id: 'c',
      bytes: _upright,
      context: _context,
    );
    final file = File('${root.path}/${still.relativePath}');
    file.writeAsBytesSync(file.readAsBytesSync()..[100] ^= 0xFF);
    await expectLater(
      store.read(still),
      throwsA(
        isA<CameraFailure>()
            .having(
              (f) => f.code,
              'code',
              CameraFailureCode.originalNotPersisted,
            )
            .having((f) => f.detail, 'detail', 'checksum'),
      ),
    );
    file.deleteSync();
    await expectLater(
      store.read(still),
      throwsA(
        isA<CameraFailure>().having((f) => f.detail, 'detail', 'missing'),
      ),
    );
  });

  group('startup recovery', () {
    Future<void> journalIntent(CapturedStill still, {String? sha256}) => db
        .into(db.pendingOriginalCommits)
        .insert(
          PendingOriginalCommitsCompanion.insert(
            id: still.id,
            sha256: sha256 ?? still.sha256,
            byteLength: still.byteLength,
            metadata: OriginalStore.journalEntry(still),
            startedAt: DateTime.utc(2026, 10, 18, 9, 30),
          ),
        );

    test('finishes a commit whose file was complete (crash before the '
        'record)', () async {
      final still = await store.commit(
        id: 'late',
        bytes: _upright,
        context: _context,
      );
      // As if the app ended between the rename and the record.
      await db.customStatement("DELETE FROM original_photos WHERE id = 'late'");
      await journalIntent(still);

      final recovery = await storeOver(db).reconcile();
      expect(recovery.finished, 1);
      expect(recovery.undone, 0);
      expect(await store.listCommitted(), [still]);
      expect(await journal(), isEmpty);
      expect(await store.read(still), _upright);
    });

    test('undoes a commit that never wrote its file (crash while '
        'writing)', () async {
      final still = await store.commit(
        id: 'early',
        bytes: _upright,
        context: _context,
      );
      await db.customStatement(
        "DELETE FROM original_photos WHERE id = 'early'",
      );
      File('${root.path}/originals/early.jpg').deleteSync();
      // The interrupted write's staged copy.
      File('${root.path}/staging/original-1-0.tmp')
          .writeAsBytesSync(_upright.sublist(0, 100));
      await journalIntent(still);

      await storage.prepare();
      final recovery = await storeOver(db).reconcile();
      expect(recovery.undone, 1);
      expect(recovery.finished, 0);
      expect(await store.listCommitted(), isEmpty);
      expect(await journal(), isEmpty);
      expect(files(), isEmpty, reason: 'the staged copy is discarded');
    });

    test('moves aside, never deletes, a file that is not what the journal '
        'expected', () async {
      final still = await store.commit(
        id: 'odd',
        bytes: _upright,
        context: _context,
      );
      await db.customStatement("DELETE FROM original_photos WHERE id = 'odd'");
      await journalIntent(still, sha256: 'f' * 64);

      final recovery = await storeOver(db).reconcile();
      expect(recovery.quarantined, 1);
      expect(recovery.undone, 1);
      expect(await store.listCommitted(), isEmpty);
      final aside = files();
      expect(aside, hasLength(1));
      expect(aside.single, startsWith('originals/.quarantine/'));
      expect(aside.single, endsWith('-odd.jpg'));
    });

    test("adopts the M01 spike's originals and leaves nothing else "
        'behind', () async {
      final originals = Directory('${root.path}/originals')
        ..createSync(recursive: true);
      Map<String, Object?> sidecar(String id, Uint8List bytes) => {
        'schemaVersion': 1,
        'id': id,
        'relativePath': 'originals/$id.jpg',
        'widthPx': 640,
        'heightPx': 480,
        'byteLength': bytes.length,
        'sha256': crypto.sha256.convert(bytes).toString(),
        'lens': 'back',
        'sensorOrientationDegrees': 90,
        'mirrorPreviewRequested': false,
        'mirrorOutputRequested': false,
        'capturedAtUtc': '2026-10-02T11:00:00.000Z',
        'exifOrientation': 1,
      };
      File('${originals.path}/spike-1.jpg').writeAsBytesSync(_upright);
      File('${originals.path}/spike-1.json')
          .writeAsStringSync(jsonEncode(sidecar('spike-1', _upright)));
      // A sidecar whose photo was changed afterwards.
      File('${originals.path}/spike-2.jpg').writeAsBytesSync(_turned);
      File('${originals.path}/spike-2.json')
          .writeAsStringSync(jsonEncode(sidecar('spike-2', _upright)));
      // The spike's own staging folder.
      Directory('${originals.path}/.staging').createSync();
      File('${originals.path}/.staging/spike-3.jpg.tmp').writeAsBytesSync([1]);

      final recovery = await storeOver(db).reconcile();
      expect(recovery.adopted, 1);
      expect(recovery.quarantined, 2, reason: 'the bad sidecar and its photo');
      final adopted = (await store.listCommitted()).single;
      expect(adopted.id, 'spike-1');
      expect(adopted.origin, CaptureOrigin.legacy);
      expect(adopted.deviceOrientation, CaptureOrientation.unknown);
      expect(await store.read(adopted), _upright);
      final left = files();
      expect(left, contains('originals/spike-1.jpg'));
      expect(
        left.where((f) => f.startsWith('originals/.quarantine/')),
        hasLength(2),
      );
      expect(left, hasLength(3), reason: 'sidecars and staging are gone');

      // Running it again changes nothing.
      expect((await storeOver(db).reconcile()).changedAnything, isFalse);
    });
  });
}
