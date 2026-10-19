// AC-1006 on real files and a real database file: a backup of a booth in
// use restores into an empty booth with every record and every photo byte
// for byte; it never carries the PIN's or the recovery code's verifier,
// the texting pairing or a phone number; and a restore refuses anything it
// cannot prove complete and unchanged (cut short, altered, from a newer
// app, onto a booth already in use, without room) before touching the
// booth. The swap itself survives being cut off half-way.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/backup/backup_manifest.dart';
import 'package:porcelain_photo_booth/domain/delivery/delivery_intent.dart';
import 'package:porcelain_photo_booth/domain/services/backup_service.dart';
import 'package:porcelain_photo_booth/domain/services/operator_files.dart';
import 'package:porcelain_photo_booth/infrastructure/backup/file_backup_service.dart';
import 'package:porcelain_photo_booth/infrastructure/backup/pending_restore.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_delivery_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/managed_storage.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../../support/fake_delivery.dart';
import '../../support/fakes.dart';
import '../../support/gallery_seed.dart';
import '../../support/seed.dart';
import '../../support/simulated_camera.dart';
import '../../support/test_database.dart';

final _clock = FakeClock(DateTime.utc(2026, 11, 15, 9));

/// One booth: its managed storage under [root] and its database file.
final class _Booth {
  _Booth(this.root, this.storage, this.db, this.space);

  final Directory root;
  final FileManagedStorage storage;
  BoothDatabase db;
  final FakeDeviceStorage space;

  FileBackupService get backups => FileBackupService(
    database: db,
    storage: storage,
    space: space,
    clock: _clock,
  );

  /// Closes the database, starts the storage again (which swaps a ready
  /// restore in) and opens the database again: what a restart does.
  Future<void> restart() async {
    await db.close();
    await storage.prepare();
    db = fileDatabase(await storage.databaseFile(), clock: _clock);
  }
}

Future<_Booth> _booth(Directory work, String name) async {
  final root = Directory('${work.path}/$name')..createSync();
  final storage = FileManagedStorage(root: () async => root);
  await storage.prepare();
  final db = fileDatabase(await storage.databaseFile(), clock: _clock);
  return _Booth(root, storage, db, FakeDeviceStorage());
}

/// A PNG of [size] bytes the asset table accepts (its id is its SHA-256).
Future<String> _addAsset(_Booth booth) async {
  final bytes = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
    ...List.generate(500, (i) => i % 256),
  ]);
  final id = crypto.sha256.convert(bytes).toString();
  final file = File('${booth.root.path}/assets/$id.png')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes);
  await booth.db.customStatement(
    'INSERT INTO assets (id, media_type, relative_path, byte_length, '
    'width_px, height_px, display_name, origin, created_at) '
    "VALUES (?, 'png', ?, ?, 40, 30, 'Gold leaf', 'imported', ?)",
    [
      id,
      'assets/$id.png',
      bytes.length,
      _clock.now().millisecondsSinceEpoch ~/ 1000,
    ],
  );
  expect(file.existsSync(), isTrue);
  return id;
}

/// The booth as a guest-free busy evening leaves it: events, templates,
/// an asset, sessions with photos and finished photos, a recovery code, a
/// texting pairing and one text still waiting with its number.
Future<_Booth> _usedBooth(Directory work) async {
  final booth = await _booth(work, 'source');
  await seedEvents(booth.db, clock: _clock);
  await seedGallery(
    booth.db,
    count: 6,
    filesRoot: booth.root,
    firstStart: DateTime.utc(2026, 11, 14, 19),
  );
  await _addAsset(booth);
  await booth.db.customStatement(
    "UPDATE operator_access SET recovery_verifier = 'pbkdf2-test-verifier'",
  );
  final secrets = MemoryDeliverySecrets();
  await seedPairing(booth.db, secrets, at: _clock.now());
  await seedTexts(
    booth.db,
    FakeDeliveryApi(),
    secrets,
    const [
      (2, '4410', DeliveryPhase.queuedLocally, 'OFFLINE'),
      (3, '0147', DeliveryPhase.delivered, null),
    ],
    sessionId: GalleryIds.session,
    outputId: GalleryIds.output,
  );
  return booth;
}

PickedStream _picked(String path) {
  final file = File(path);
  return PickedStream(
    name: file.uri.pathSegments.last,
    length: file.lengthSync(),
    open: file.openRead,
  );
}

/// Every row of [table], ordered, as plain values.
Future<List<Map<String, Object?>>> _rows(BoothDatabase db, String table) async {
  final rows = await db.customSelect('SELECT * FROM $table ORDER BY 1').get();
  return [for (final row in rows) row.data];
}

/// Every managed photo or asset file, by relative path, with its SHA-256.
Map<String, String> _files(Directory root) => {
  for (final area in ['originals', 'outputs', 'assets', 'templates'])
    if (Directory('${root.path}/$area').existsSync())
      for (final entity in Directory(
        '${root.path}/$area',
      ).listSync(recursive: true))
        if (entity is File)
          entity.path.substring(root.path.length + 1): crypto.sha256
              .convert(entity.readAsBytesSync())
              .toString(),
};

void main() {
  late Directory work;

  setUp(() async {
    work = await Directory.systemTemp.createTemp('backup-test');
    addTearDown(() => work.delete(recursive: true));
  });

  test('a backup of a booth in use restores into an empty booth: every '
      'record and every file, byte for byte (AC-1006)', () async {
    final source = await _usedBooth(work);
    addTearDown(() => source.db.close());
    final progress = <double>[];
    final backup = await source.backups.create(
      BackupContents.everything,
      onProgress: progress.add,
    );
    expect(progress.last, 1);
    expect(
      backup.fileName,
      matches(RegExp(r'^porcelain-backup-\d{8}-\d{4}\.tar$')),
    );
    expect(File(backup.path).parent.path, endsWith('/outgoing'));
    expect(
      backup.sha256,
      crypto.sha256.convert(File(backup.path).readAsBytesSync()).toString(),
    );
    expect(backup.manifest.counts, containsPair('sessions', 6));
    expect(backup.manifest.counts, containsPair('events', 3));
    expect(
      Directory('${source.root.path}/staging').listSync(),
      isEmpty,
      reason: 'nothing left behind',
    );

    // Standard tar can list it.
    final listed = await Process.run('tar', ['-tf', backup.path]);
    expect(listed.exitCode, 0);
    expect('${listed.stdout}', contains('porcelain-backup/manifest.json'));

    final target = await _booth(work, 'target');
    addTearDown(() => target.db.close());
    final candidate = await target.backups.inspect(_picked(backup.path));
    expect(candidate.manifest.counts, backup.manifest.counts);
    await target.backups.stage(candidate);
    expect(
      await _rows(target.db, 'events'),
      isEmpty,
      reason: 'nothing changes before the restart',
    );
    await target.restart();
    final report = await target.backups.finishRestore();
    expect(report, isNotNull);
    expect(report!.counts, backup.manifest.counts);
    expect(report.closedDeliveries, 1);
    expect(await target.backups.finishRestore(), isNull, reason: 'once');

    for (final table in [
      'events',
      'event_templates',
      'templates',
      'template_revisions',
      'assets',
      'capture_sessions',
      'session_photos',
      'original_photos',
      'session_outputs',
      'booth_profiles',
    ]) {
      expect(
        await _rows(target.db, table),
        await _rows(source.db, table),
        reason: table,
      );
    }
    expect(_files(target.root), _files(source.root));
    expect(_files(target.root), isNotEmpty);

    // What must not come back.
    expect(await _rows(target.db, 'delivery_pairings'), isEmpty);
    final access = (await _rows(target.db, 'operator_access')).single;
    expect(access['recovery_verifier'], isNull);
    final settings = (await _rows(target.db, 'app_settings')).single;
    expect(settings['setup_completed_at'], isNull);
    expect(settings['booth_event_id'], isNull);
    final intents = await DriftDeliveryRepository(target.db).open();
    expect(intents, isEmpty, reason: 'the waiting text was closed');
    final waiting = (await DriftDeliveryRepository(target.db)
        .find('e0000000-0000-4000-8000-000000000002'))!;
    expect(waiting.phase, DeliveryPhase.canceled);
    expect(waiting.lastErrorCode, 'NOT_RESTORED');
    expect(waiting.phoneStored, isFalse);
    expect(PendingRestore(target.root).area.listSync(), isEmpty);
  });

  test('the backup file holds no verifier, pairing or phone number', () async {
    final source = await _usedBooth(work);
    addTearDown(() => source.db.close());
    final backup = await source.backups.create(BackupContents.everything);
    final bytes = File(backup.path).readAsBytesSync();
    final text = latin1.decode(bytes);
    expect(text, isNot(contains('pbkdf2-test-verifier')));
    expect(text, isNot(contains('+1212555')));
    expect(text, isNot(contains('credential-')));

    final out = Directory('${work.path}/out')..createSync();
    final untar = await Process.run('tar', [
      '-xf',
      backup.path,
      '-C',
      out.path,
    ]);
    expect(untar.exitCode, 0);
    final db = sqlite.sqlite3.open(
      '${out.path}/porcelain-backup/database.sqlite',
      mode: sqlite.OpenMode.readOnly,
    );
    addTearDown(db.close);
    expect(db.select('SELECT * FROM delivery_pairings'), isEmpty);
    expect(
      db.select('SELECT recovery_verifier FROM operator_access').single.values,
      [null],
    );
  });

  test('a setup-only backup brings back events, templates and assets but '
      'no guest session or photo', () async {
    final source = await _usedBooth(work);
    addTearDown(() => source.db.close());
    final backup = await source.backups.create(BackupContents.setupOnly);
    expect(backup.manifest.counts['sessions'], 0);
    expect(
      backup.manifest.files.where(
        (file) =>
            file.path.startsWith('files/originals/') ||
            file.path.startsWith('files/outputs/'),
      ),
      isEmpty,
    );

    final target = await _booth(work, 'target');
    addTearDown(() => target.db.close());
    await target.backups.stage(
      await target.backups.inspect(_picked(backup.path)),
    );
    await target.restart();
    await target.backups.finishRestore();
    expect(await _rows(target.db, 'events'), await _rows(source.db, 'events'));
    expect(await _rows(target.db, 'assets'), hasLength(1));
    expect(await _rows(target.db, 'capture_sessions'), isEmpty);
    expect(await _rows(target.db, 'original_photos'), isEmpty);
    expect(await _rows(target.db, 'delivery_intents'), isEmpty);
    expect(
      _files(target.root).keys.where((path) => !path.startsWith('assets/')),
      isEmpty,
    );
  });

  group('a restore refuses, before touching the booth,', () {
    late _Booth source;
    late BackupResult backup;
    late _Booth target;

    setUp(() async {
      source = await _usedBooth(work);
      backup = await source.backups.create(BackupContents.everything);
      await source.db.close();
      target = await _booth(work, 'target');
      addTearDown(() => target.db.close());
    });

    Future<void> refused(
      String path,
      BackupProblem problem, {
      _Booth? booth,
    }) async {
      final into = booth ?? target;
      await expectLater(
        into.backups.inspect(_picked(path)),
        throwsA(
          isA<BackupException>().having((e) => e.problem, 'problem', problem),
        ),
      );
      expect(
        Directory('${into.root.path}/staging').listSync(),
        isEmpty,
        reason: 'the copy is removed',
      );
      expect(Directory('${into.root.path}/originals').listSync(), isEmpty);
    }

    test('an archive cut short', () async {
      final bytes = File(backup.path).readAsBytesSync();
      final cut = File('${work.path}/cut.tar')
        ..writeAsBytesSync(bytes.sublist(0, bytes.length ~/ 2));
      await refused(cut.path, BackupProblem.invalidArchive);
    });

    test('a photo changed inside it', () async {
      final bytes = File(backup.path).readAsBytesSync();
      // A byte well inside the data of an entry, never a header.
      final text = latin1.decode(bytes);
      final at = text.indexOf('porcelain-backup/files/originals/');
      final changed = Uint8List.fromList(bytes)..[at + 512 + 600] ^= 0xFF;
      final file = File('${work.path}/changed.tar')..writeAsBytesSync(changed);
      await refused(file.path, BackupProblem.invalidArchive);
    });

    test('a file that is not a backup', () async {
      final file = File('${work.path}/photo.tar')
        ..writeAsBytesSync(SimulatedStillStore.photoBytes);
      await refused(file.path, BackupProblem.invalidArchive);
    });

    test('a booth already in use', () async {
      await seedEvents(target.db, clock: _clock);
      await refused(backup.path, BackupProblem.notEmpty);
    });

    test('a tablet without room for it', () async {
      target.space.free = File(backup.path).lengthSync();
      await refused(backup.path, BackupProblem.noSpace);
    });
  });

  test('a backup from a newer app is refused', () {
    final manifest = BackupManifest(
      formatVersion: 1,
      createdAtUtc: _clock.now(),
      appVersion: '9.0.0',
      schemaVersion: BoothDatabase.currentSchemaVersion + 1,
      contents: BackupContents.everything,
      boothName: 'Booth',
      counts: const {},
      files: [BackupFile(BackupManifest.databasePath, 1, 'a' * 64)],
    );
    expect(
      () => BackupManifest.decode(
        manifest.encode(),
        maxSchemaVersion: BoothDatabase.currentSchemaVersion,
      ),
      throwsA(
        isA<BackupException>().having(
          (e) => e.problem,
          'problem',
          BackupProblem.newerVersion,
        ),
      ),
    );
  });

  test('a swap cut off half-way finishes at the next start; an extraction '
      'never marked ready is discarded (AC-1004)', () async {
    final source = await _usedBooth(work);
    final backup = await source.backups.create(BackupContents.everything);
    final expected = _files(source.root);
    await source.db.close();

    final target = await _booth(work, 'target');
    await target.backups.stage(
      await target.backups.inspect(_picked(backup.path)),
    );
    await target.db.close();
    // The first start moves some photos, then the tablet dies.
    final pending = PendingRestore(target.root);
    final incoming = Directory('${pending.incoming.path}/files/originals');
    final some = incoming.listSync().whereType<File>().take(3).toList();
    for (final file in some) {
      final name = file.uri.pathSegments.last;
      file.renameSync('${target.root.path}/originals/$name');
    }
    await target.storage.prepare();
    target.db = fileDatabase(
      await target.storage.databaseFile(),
      clock: _clock,
    );
    addTearDown(() => target.db.close());
    expect(await target.backups.finishRestore(), isNotNull);
    expect(_files(target.root), expected);

    // An unpacking cut short (no ready marker) leaves nothing behind.
    final stray = Directory('${pending.area.path}/unpack-0123456789abcdef')
      ..createSync(recursive: true);
    File('${stray.path}/half.jpg').writeAsBytesSync([1, 2, 3]);
    await target.db.close();
    await target.storage.prepare();
    target.db = fileDatabase(
      await target.storage.databaseFile(),
      clock: _clock,
    );
    expect(pending.area.listSync(), isEmpty);
    expect(_files(target.root), expected);
  });
}
